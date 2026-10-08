"""Check actual test/unsigned release packages; requires Android build-tools.

Run after debug APK and explicitly unsigned release APK/AAB builds. This does
not sign, install or upload anything. A successful check is not device testing.
"""

import argparse
from pathlib import Path
import re
import subprocess
import zipfile


APP_ID = "io.github.mohamedaymanouchker.robocode"


def run(tool: Path, *args: str) -> subprocess.CompletedProcess:
    return subprocess.run(
        [str(tool), *map(str, args)], capture_output=True, text=True, check=False
    )


def require(condition: bool, message: str) -> None:
    if not condition:
        raise SystemExit(message)


def check_apk(build_tools: Path, apk: Path, *, debug: bool) -> None:
    suffix = ".exe" if (build_tools / "aapt.exe").exists() else ""
    aapt = build_tools / f"aapt{suffix}"
    apksigner = build_tools / ("apksigner.bat" if suffix else "apksigner")
    require(apk.is_file(), f"Missing APK: {apk}")
    result = run(aapt, "dump", "badging", apk)
    require(result.returncode == 0, f"Cannot read {apk}: {result.stderr}")
    expected_id = APP_ID + (".debug" if debug else "")
    require(f"package: name='{expected_id}'" in result.stdout, "Unexpected app ID")
    require("sdkVersion:'24'" in result.stdout, "Unexpected minimum Android SDK")
    require("targetSdkVersion:'36'" in result.stdout, "Unexpected target SDK")
    require(
        "uses-feature: name='android.hardware.bluetooth_le'" in result.stdout,
        "BLE is not declared as required",
    )
    require(
        ("application-debuggable" in result.stdout) == debug,
        "Unexpected debuggable flag",
    )
    expected_label = "RoboCode (Test)" if debug else "RoboCode"
    require(f"application-label:'{expected_label}'" in result.stdout, "Wrong app label")
    permissions = run(aapt, "dump", "permissions", apk)
    require(permissions.returncode == 0, "Cannot read permissions")
    for permission in ("ACCESS_WIFI_STATE", "CHANGE_WIFI_STATE"):
        require(permission not in permissions.stdout, f"Unexpected {permission}")

    signature = run(apksigner, "verify", "--verbose", "--print-certs", apk)
    if debug:
        require(signature.returncode == 0, f"Invalid debug signature: {signature.stderr}")
    else:
        # Distinguish an expected unsigned APK from a tool error/corrupt signature.
        require(
            signature.returncode != 0
            and "DOES NOT VERIFY" in signature.stderr
            and "Missing META-INF/MANIFEST.MF" in signature.stderr,
            f"Expected an unsigned release APK: {signature.stdout}{signature.stderr}",
        )
        alignment = run(build_tools / f"zipalign{suffix}", "-c", "-P", "16", "4", apk)
        require(alignment.returncode == 0, f"APK alignment failed: {alignment.stdout}{alignment.stderr}")
    print(f"PASS {apk.name}: ID, SDKs, BLE, label, permissions and signing state")


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--build-tools", required=True, type=Path)
    args = parser.parse_args()
    app_root = Path(__file__).resolve().parents[1]
    output = app_root / "build/app/outputs"
    check_apk(args.build_tools, output / "flutter-apk/app-debug.apk", debug=True)
    check_apk(args.build_tools, output / "flutter-apk/app-release.apk", debug=False)
    bundle = output / "bundle/release/app-release.aab"
    require(bundle.is_file(), "Missing unsigned release app bundle")
    with zipfile.ZipFile(bundle) as archive:
        names = archive.namelist()
        require(archive.testzip() is None, "Corrupt app bundle")
        require("base/manifest/AndroidManifest.xml" in names, "Missing bundle manifest")
        require("base/dex/classes.dex" in names, "Missing bundle application code")
        require(
            not any(re.match(r"META-INF/[^/]+\.(SF|RSA|DSA|EC)$", name, re.I) for name in names),
            "Release check bundle must be unsigned",
        )
    print("PASS app-release.aab: archive integrity, application code and unsigned state")
    print("These are build checks only; physical-device and robot acceptance remain open.")


if __name__ == "__main__":
    main()
