# EGT Android APK - GitHub Actions Cloud Build Setup

This guide explains how to build the EGT Android APK using GitHub Actions (cloud build).
This bypasses the sandbox network restrictions that block Gradle dependency downloads.

## Why Cloud Build?

The sandbox environment has an authenticated egress proxy that Gradle's HTTP client
cannot use (ClientProtocolException). GitHub Actions runners have direct internet
access, so the build works there.

## Prerequisites

1. GitHub repo: `ProfessorDroid/egt-platform` (already exists, empty)
2. The signing keystore: `~/workspace/egt-mobile/keystore/egt-release.jks`
3. Keystore passwords (in `~/workspace/egt-mobile/keystore/*.pass`)

## Setup Steps (One-Time)

### 1. Push the code to GitHub

```bash
cd ~/workspace/egt-mobile
git add .github/workflows/build-apk.yml
git commit -m "Add GitHub Actions APK build workflow"
git push origin main
```

### 2. Add the keystore as a GitHub Secret

The keystore CANNOT be committed to git (it's a signing key). Instead:

a. Convert keystore to base64:
```bash
base64 -w0 ~/workspace/egt-mobile/keystore/egt-release.jks > /tmp/keystore.b64
# Then copy the content
```

b. Go to GitHub repo → Settings → Secrets and variables → Actions → New repository secret:
   - Name: `EGT_KEYSTORE_BASE64`
   - Value: (paste the base64 content)

c. Add password secrets:
   - Name: `EGT_KEYSTORE_PASSWORD`, Value: (from `~/workspace/egt-mobile/keystore/store.pass`)
   - Name: `EGT_KEY_PASSWORD`, Value: (from `~/workspace/egt-mobile/keystore/key.pass`)

### 3. Trigger the build

- Go to GitHub repo → Actions → "Build EGT Android APK" → Run workflow
- Select flavor: `staging` (test) or `production` (live)
- Click "Run workflow"

### 4. Download the APK

- After the build completes (~5-10 min), go to the workflow run
- Download the artifact: `egt-app-staging-apk` (or production)
- The APK is signed with the EGT release key and ready for direct sharing

## Security Notes

- NEVER commit `*.jks`, `*.pass`, or `key.properties` to git
- The `.gitignore` already excludes these files
- GitHub Secrets are encrypted and only exposed to the workflow
- Back up the keystore securely offline (Sukh controls this)

## Build Flavors

- **staging**: Uses `https://sukhz-egt-staging-api.hf.space/api/v1`, package `com.eaglegoodstrading.egt.staging`
- **production**: Uses `https://api.eaglegoodstrading.com/api/v1` (placeholder, needs real backend), package `com.eaglegoodstrading.egt`
