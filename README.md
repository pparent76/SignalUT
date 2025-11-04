# Signal UT

**Signal Desktop for Ubuntu Touch with responsive design**  

[![OpenStore](https://open-store.io/badges/en_US.svg)](https://open-store.io/app/signalut.pparent)

---

## ⚠️ Important - Alpha State

Signal UT is currently in **alpha**. Please read the limitations and usage notes carefully before using it.

### Known Issues

- **Keyboard issues on startup**: Right after launching, **Enter** and **Back** keys may not work. To fix this, **lock and unlock the phone while Signal UT is in the foreground**.

---

## 🖥️ App Variants

1. **Confined (OpenStore)**  
   - Limited: no GPU, microphone, or desktop notifications support.  
2. **Unconfined**  
   - No such limitations.
   
⚠️ You cannot switch seamlessly from one to the other. You need to delete all the data of the app, and then the app itself, before instaling the other variant.

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
 
