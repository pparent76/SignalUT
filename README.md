# Signal UT

**Signal Desktop for Ubuntu Touch with responsive design**  

[![OpenStore](https://open-store.io/badges/en_US.svg)](https://open-store.io/app/signalut.pparent)

---

## ⚠️ Important - Alpha State

Signal UT is currently in **alpha**. Please read the limitations and usage notes carefully before using it.

### Known Issues

- **Crashes when started from OpenStore**: After installation, **launch the app from the application grid**, not directly from OpenStore.
- **High battery usage**: A bug in Xmir causes significant battery drain, especially when the phone is suspended. **Do not keep the app running in the background**.
- **Keyboard issues on startup**: Right after launching, **Enter** and **Back** keys may not work. To fix this, **lock and unlock the phone while Signal UT is in the foreground**.
- **Interface not fully responsive yet**:  
  - Hide the left panel and minimize the chat list for a usable interface on phones.  
  - The message input area is currently hidden by the keyboard.  

### About the binaries

This app is temporarily based on the **Signal-Desktop binaries** from the [official Snap](https://snapcraft.io/signal-desktop). The author **cannot be held responsible** for any issues with these binaries.

---

## 🖥️ App Variants

1. **Confined (OpenStore)**  
   - Limited: no GPU, microphone, or desktop notifications support.  
2. **Unconfined**  
   - No such limitations.

---

## 🔨 Build Instructions

### Standard (Confined)
```bash
clickable build --arch arm64
```
### Unconfined
```bash
clickable build --arch arm64 --conf clickable-unconfined.yaml
```
 
