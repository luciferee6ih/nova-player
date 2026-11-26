package com.theluciferee.novaplayer

import android.content.Context
import android.media.AudioFormat
import android.media.MediaCodec
import android.media.MediaExtractor
import android.media.MediaFormat
import android.net.Uri
import android.os.Handler
import android.os.Looper
import android.os.Process
import android.os.SystemClock
import io.flutter.plugin.common.MethodChannel
import java.io.BufferedOutputStream
import java.io.File
import java.io.FileOutputStream
import java.nio.ByteOrder
import java.util.concurrent.Executors

/**
 * Decodes a window of a song to mono 16-bit PCM for Harmonic Queue's
 * tempo/key analysis, with the platform's MediaExtractor + MediaCodec.
 *
 * Runs on one background-priority thread (one song at a time) and writes
 * the samples to a file in the cache dir, so only a short path crosses the
 * method channel: the Dart side reads and analyzes it in an isolate. The
 * mix-down and the rate change (a box filter, plenty for 65 Hz - 5 kHz
 * analysis) happen while decoding, so memory stays at one codec buffer.
 */
object PcmDecoder {
    private val executor = Executors.newSingleThreadExecutor { runnable ->
        Thread({
            Process.setThreadPriority(Process.THREAD_PRIORITY_BACKGROUND)
            runnable.run()
        }, "nova-pcm-decode")
    }
    private val main = Handler(Looper.getMainLooper())

    /** Hard stop for one decode, so a broken file can't hold the queue. */
    private const val MAX_WALL_MS = 45_000L
    private const val TIMEOUT_US = 10_000L

    fun decode(
        context: Context,
        path: String,
        startMs: Long,
        durationMs: Long,
        targetRate: Int,
        result: MethodChannel.Result,
    ) {
        val cacheDir = context.cacheDir
        executor.execute {
            val out = File(cacheDir, "nova_pcm_${SystemClock.elapsedRealtimeNanos()}.raw")
            try {
                val frames = decodeTo(context, path, startMs, durationMs, targetRate, out)
                main.post {
                    result.success(mapOf("path" to out.absolutePath, "frames" to frames, "sampleRate" to targetRate))
                }
            } catch (e: Throwable) {
                out.delete()
                main.post { result.error("DECODE_FAILED", e.message, null) }
            }
        }
    }

    private fun decodeTo(
        context: Context,
        path: String,
        startMs: Long,
        durationMs: Long,
        targetRate: Int,
        out: File,
    ): Long {
        val extractor = MediaExtractor()
        var codec: MediaCodec? = null
        val started = SystemClock.elapsedRealtime()
        try {
            if (path.startsWith("content://")) {
                extractor.setDataSource(context, Uri.parse(path), null)
            } else {
                extractor.setDataSource(path)
            }
            var trackIndex = -1
            var format: MediaFormat? = null
            for (i in 0 until extractor.trackCount) {
                val f = extractor.getTrackFormat(i)
                if (f.getString(MediaFormat.KEY_MIME)?.startsWith("audio/") == true) {
                    trackIndex = i
                    format = f
                    break
                }
            }
            if (trackIndex < 0 || format == null) throw IllegalStateException("no audio track")
            extractor.selectTrack(trackIndex)
            val startUs = startMs * 1000
            val endUs = (startMs + durationMs) * 1000
            if (startUs > 0) extractor.seekTo(startUs, MediaExtractor.SEEK_TO_PREVIOUS_SYNC)

            val mime = format.getString(MediaFormat.KEY_MIME)!!
            val c = MediaCodec.createDecoderByType(mime)
            codec = c
            c.configure(format, null, null, 0)
            c.start()

            var srcRate = format.getInteger(MediaFormat.KEY_SAMPLE_RATE)
            var channels = format.getInteger(MediaFormat.KEY_CHANNEL_COUNT)
            var floatPcm = false
            val info = MediaCodec.BufferInfo()
            var inputDone = false
            var outputDone = false
            var written = 0L
            // Box-filter resampler state.
            var acc = 0.0
            var accCount = 0
            var phase = 0L
            val sink = BufferedOutputStream(FileOutputStream(out), 64 * 1024)
            val two = ByteArray(2)
            try {
                while (!outputDone) {
                    if (SystemClock.elapsedRealtime() - started > MAX_WALL_MS) {
                        throw IllegalStateException("decode timeout")
                    }
                    if (!inputDone) {
                        val inIndex = c.dequeueInputBuffer(TIMEOUT_US)
                        if (inIndex >= 0) {
                            val buf = c.getInputBuffer(inIndex)!!
                            val size = extractor.readSampleData(buf, 0)
                            val time = extractor.sampleTime
                            if (size < 0 || time > endUs) {
                                c.queueInputBuffer(inIndex, 0, 0, 0, MediaCodec.BUFFER_FLAG_END_OF_STREAM)
                                inputDone = true
                            } else {
                                c.queueInputBuffer(inIndex, 0, size, time, 0)
                                extractor.advance()
                            }
                        }
                    }
                    val outIndex = c.dequeueOutputBuffer(info, TIMEOUT_US)
                    when {
                        outIndex == MediaCodec.INFO_OUTPUT_FORMAT_CHANGED -> {
                            val f = c.outputFormat
                            srcRate = f.getInteger(MediaFormat.KEY_SAMPLE_RATE)
                            channels = f.getInteger(MediaFormat.KEY_CHANNEL_COUNT)
                            floatPcm = f.containsKey(MediaFormat.KEY_PCM_ENCODING) &&
                                f.getInteger(MediaFormat.KEY_PCM_ENCODING) == AudioFormat.ENCODING_PCM_FLOAT
                        }
                        outIndex >= 0 -> {
                            if ((info.flags and MediaCodec.BUFFER_FLAG_END_OF_STREAM) != 0) outputDone = true
                            if (info.size > 0 && info.presentationTimeUs >= startUs && info.presentationTimeUs <= endUs) {
                                val buf = c.getOutputBuffer(outIndex)!!
                                buf.position(info.offset)
                                buf.limit(info.offset + info.size)
                                val data = buf.slice().order(ByteOrder.nativeOrder())
                                val bytesPerSample = if (floatPcm) 4 else 2
                                val frameCount = info.size / (bytesPerSample * channels)
                                for (fr in 0 until frameCount) {
                                    var sum = 0.0
                                    for (ch in 0 until channels) {
                                        val idx = (fr * channels + ch) * bytesPerSample
                                        sum += if (floatPcm) data.getFloat(idx).toDouble()
                                        else data.getShort(idx) / 32768.0
                                    }
                                    acc += sum / channels
                                    accCount++
                                    phase += targetRate
                                    if (phase >= srcRate) {
                                        phase -= srcRate
                                        val v = (acc / accCount).coerceIn(-1.0, 1.0)
                                        val s = (v * 32767).toInt()
                                        two[0] = (s and 0xff).toByte()
                                        two[1] = ((s shr 8) and 0xff).toByte()
                                        sink.write(two)
                                        written++
                                        acc = 0.0
                                        accCount = 0
                                    }
                                }
                            } else if (info.presentationTimeUs > endUs) {
                                outputDone = true
                            }
                            c.releaseOutputBuffer(outIndex, false)
                        }
                    }
                }
            } finally {
                sink.close()
            }
            return written
        } finally {
            try { codec?.stop() } catch (ignored: Throwable) {}
            try { codec?.release() } catch (ignored: Throwable) {}
            extractor.release()
        }
    }
}
