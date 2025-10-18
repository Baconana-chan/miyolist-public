# 🚀 GitHub Actions CI/CD Setup

## Quick Start

### 1. Enable Workflow Permissions
1. Go to **Settings** → **Actions** → **General**
2. Under "Workflow permissions", select **Read and write permissions**
3. Check **Allow GitHub Actions to create and approve pull requests**
4. Click **Save**

### 2. Create a Release
```bash
# Update version in pubspec.yaml
# Then create and push tag:
git tag v1.0.2
git push origin v1.0.2
```

### 3. Download Artifacts
Go to: **Actions** → **Build Release** → Click on the latest run → Download artifacts

---

## 📦 What Gets Built

| Platform | File | Builder | Notes |
|----------|------|---------|-------|
| 🐧 Linux | `miyolist-linux-x64.tar.gz` | GitHub Actions | Automatic |
| 🍎 macOS | `miyolist-macos.dmg` | GitHub Actions | Automatic |
| 🪟 Windows | Manual | Local (your PC) | `flutter build windows` |
| 🤖 Android | Manual | Local (your PC) | `flutter build apk` |

---

## 📖 Full Documentation

See detailed documentation: [`.github/workflows/README.md`](.github/workflows/README.md)

---

## 🔧 Workflows

- **CI Build** (`ci.yml`) - Runs on every push
  - Tests Linux and macOS builds
  - Code quality checks
  - Test coverage

- **Build Release** (`build-release.yml`) - Runs on version tags
  - Builds production binaries
  - Creates GitHub Release
  - Uploads artifacts

---

## ⚡ Quick Commands

```bash
# Check workflow status
gh workflow list

# Trigger manual build
gh workflow run build-release.yml -f version=1.0.2

# View recent runs
gh run list --workflow=build-release.yml

# Download latest artifacts
gh run download
```

---

**Last Updated:** October 16, 2025
