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

adb shell mkdir -p /sdcard/Music/NOVA
adb push music/. /sdcard/Music/NOVA/ >/dev/null
adb shell am broadcast -a android.intent.action.MEDIA_SCANNER_SCAN_FILE -d file:///sdcard/Music/NOVA >/dev/null 2>&1
adb shell content call --method scan_volume --uri content://media --arg external_primary >/dev/null 2>&1 || true

adb install -r -g app.apk
adb shell pm grant $PKG android.permission.READ_MEDIA_AUDIO 2>/dev/null || true
adb shell pm grant $PKG android.permission.POST_NOTIFICATIONS 2>/dev/null || true
adb shell cmd locale set-app-locales $PKG --locales "$LOCALE" 2>/dev/null || true

adb shell monkey -p $PKG -c android.intent.category.LAUNCHER 1 >/dev/null 2>&1
sleep 15
shot launch; dump launch

# Get through the welcome/setup flow, whatever it shows.
for i in 1 2 3 4 5 6 7 8; do
  for w in "شروع" "ادامه" "بعدی" "اجازه" "Allow" "Get started" "Continue" "Next" "Skip" "رد شدن" "تمام" "Done" "Finish"; do
    if tap_text "$w"; then sleep 3; shot "setup-$i"; break; fi
  done
done
sleep 5
shot home; dump home

# Home scroll: measure frames while flinging.
adb shell dumpsys gfxinfo $PKG reset >/dev/null
for i in 1 2 3 4 5 6; do adb shell input swipe 540 1900 540 500 250; sleep 0.6; done
shot home-scrolled
for i in 1 2 3 4 5 6; do adb shell input swipe 540 600 540 2000 250; sleep 0.6; done
adb shell dumpsys gfxinfo $PKG > shots/gfxinfo-home.txt

tap_text "آهنگ‌ها" || tap_text "Songs"; sleep 3; shot songs; dump songs
adb shell input tap 540 700; sleep 4; shot playing
tap_text "Midnight" || adb shell input tap 540 2050; sleep 4; shot player; dump player
adb shell dumpsys gfxinfo $PKG > shots/gfxinfo-all.txt
