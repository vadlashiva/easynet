#!/usr/bin/env python3
"""Adds microphone / speech / internet permissions after `flutter create .`.
Safe to run more than once. Usage: python3 scripts/add_permissions.py [project_dir]"""
import re
import sys
from pathlib import Path

root = Path(sys.argv[1] if len(sys.argv) > 1 else ".")

ANDROID_PERMS = [
    "android.permission.INTERNET",
    "android.permission.RECORD_AUDIO",
    "android.permission.BLUETOOTH_CONNECT",  # lets speech use Bluetooth headsets
]
ANDROID_QUERIES = [
    '<intent><action android:name="android.speech.RecognitionService" /></intent>',
    '<intent><action android:name="android.intent.action.TTS_SERVICE" /></intent>',
    '<intent><action android:name="android.intent.action.VIEW" /><data android:scheme="https" /></intent>',
]


def android(path: Path) -> None:
    if not path.exists():
        print(f"skip: {path} not found")
        return
    xml = path.read_text(encoding="utf-8")
    for p in ANDROID_PERMS:
        if f'android:name="{p}"' not in xml:
            xml = re.sub(r"(<manifest[^>]*>)", rf'\1\n    <uses-permission android:name="{p}" />', xml, count=1)
    if "<queries>" not in xml:
        xml = xml.replace("</manifest>", "    <queries>\n    </queries>\n</manifest>")
    for q in ANDROID_QUERIES:
        action = re.search(r'action android:name="([^"]+)"', q).group(1)
        block = xml[xml.index("<queries>"):xml.index("</queries>")]
        if action not in block or (action.endswith("VIEW") and 'android:scheme="https"' not in block):
            xml = xml.replace("</queries>", f"        {q}\n    </queries>", 1)
    xml = xml.replace('android:label="easynet"', 'android:label="EasyNet"')
    path.write_text(xml, encoding="utf-8")
    print(f"ok: {path}")


IOS_KEYS = {
    "NSMicrophoneUsageDescription": "EasyNet uses the microphone so you can ask questions by voice.",
    "NSSpeechRecognitionUsageDescription": "EasyNet turns your voice into text to understand your question.",
}


def ios(path: Path) -> None:
    if not path.exists():
        print(f"skip: {path} not found")
        return
    plist = path.read_text(encoding="utf-8")
    for k, v in IOS_KEYS.items():
        if f"<key>{k}</key>" not in plist:
            idx = plist.rindex("</dict>")
            plist = plist[:idx] + f"\t<key>{k}</key>\n\t<string>{v}</string>\n" + plist[idx:]
    path.write_text(plist, encoding="utf-8")
    print(f"ok: {path}")


android(root / "android/app/src/main/AndroidManifest.xml")
ios(root / "ios/Runner/Info.plist")
