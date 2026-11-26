#!/usr/bin/env bash
# Walks NOVA Player's main screens on an emulator and saves real screenshots.
set -u
LOCALE="${1:-fa}"
PKG=com.theluciferee.novaplayer
mkdir -p shots
n=0
shot() { n=$((n+1)); adb exec-out screencap -p > "shots/$(printf %02d $n)-$1.png"; }
dump() { adb shell uiautomator dump /sdcard/ui.xml >/dev/null 2>&1; adb shell cat /sdcard/ui.xml > "shots/$(printf %02d $n)-$1.xml" 2>/dev/null; }
# Tap the first node whose text or content-desc contains $1.
tap_text() {
  adb shell uiautomator dump /sdcard/ui.xml >/dev/null 2>&1
  local b
  b=$(adb shell cat /sdcard/ui.xml | tr '>' '\n' | grep -F -- "$1" | grep -o 'bounds="[^"]*"' | head -1 | grep -oE '[0-9]+' | tr '\n' ' ')
  [ -z "$b" ] && return 1
  set -- $b
  adb shell input tap $(( ($1 + $3) / 2 )) $(( ($2 + $4) / 2 ))
}

# Wait until shared storage is mounted, or the push is refused.
for i in $(seq 1 30); do adb shell touch /sdcard/Music/.probe 2>/dev/null && break; sleep 2; done
for f in music/*.mp3; do adb push "$f" /sdcard/Music/ >/dev/null || echo "push failed: $f"; done
adb shell am broadcast -a android.intent.action.MEDIA_SCANNER_SCAN_FILE -d file:///sdcard/Music >/dev/null 2>&1
adb shell content call --method scan_volume --uri content://media --arg external_primary >/dev/null 2>&1 || true

adb install -r -g app.apk
adb shell appops set $PKG MANAGE_EXTERNAL_STORAGE allow 2>/dev/null || true
adb shell pm grant $PKG android.permission.READ_MEDIA_AUDIO 2>/dev/null || true
adb shell pm grant $PKG android.permission.POST_NOTIFICATIONS 2>/dev/null || true
adb shell cmd locale set-app-locales $PKG --locales "$LOCALE" 2>/dev/null || true

adb shell monkey -p $PKG -c android.intent.category.LAUNCHER 1 >/dev/null 2>&1
sleep 15
shot launch; dump launch

# Flutter draws its own widgets, so uiautomator cannot see them: walk the
# 4-step setup by tapping its bottom button, and bounce back if a tap
# opened another app (a browser link on the community step).
in_app() { adb shell dumpsys activity activities | grep -m1 -E "topResumedActivity|mResumedActivity" | grep -q $PKG; }
back_to_app() { in_app || { adb shell input keyevent KEYCODE_BACK; sleep 2; in_app || adb shell monkey -p $PKG -c android.intent.category.LAUNCHER 1 >/dev/null 2>&1; sleep 3; }; }
for i in 1 2 3 4 5 6; do
  adb shell input tap 630 2200; sleep 4
  # System permission dialogs are native views, so these can be found.
  tap_text "Allow" && sleep 2
  tap_text "ALLOW" && sleep 2
  back_to_app
  shot "setup-$i"
done
sleep 6
shot home

# Real-app video: home scroll, every tab, the player.
adb shell screenrecord --bit-rate 6000000 --time-limit 75 /sdcard/demo.mp4 >/dev/null 2>&1 &
REC=$!
sleep 1

adb shell dumpsys gfxinfo $PKG reset >/dev/null
for i in 1 2 3 4 5; do adb shell input swipe 540 1700 540 600 250; sleep 0.7; done
shot home-scrolled
for i in 1 2 3 4 5; do adb shell input swipe 540 700 540 1800 250; sleep 0.7; done
adb shell dumpsys gfxinfo $PKG > shots/gfxinfo-home.txt

# Bottom bar tabs (floating glass bar sits near the bottom edge).
for x in 216 432 648 864; do
  adb shell input tap $x 2235; sleep 3; back_to_app; shot "tab-$x"
done
# Back to the first tab, start a song from its list, open the player.
adb shell input tap 216 2235; sleep 3
adb shell input tap 540 1200; sleep 4; back_to_app; shot playing
adb shell input tap 540 2080; sleep 4; back_to_app; shot player
adb shell input swipe 540 1500 540 1500 10; sleep 6
adb shell dumpsys gfxinfo $PKG > shots/gfxinfo-all.txt

# Stop the recorder cleanly so the mp4 gets its index written.
adb shell pkill -INT screenrecord 2>/dev/null || true
sleep 4
kill $REC 2>/dev/null || true
adb pull /sdcard/demo.mp4 shots/demo.mp4 >/dev/null 2>&1 || true
