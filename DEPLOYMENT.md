# AURA AR • Public Cloud & Mobile Rollout Guide

This guide explains how to deploy the **AURA AR** backend to the cloud for worldwide access and distribute the mobile app to physical devices.

---

## 1. Cloud WebAR & Reconstruction Backend Deployment

To allow anyone anywhere in the world to scan your QR codes and view 3D objects in AR without being on your home Wi-Fi, the backend must be publicly reachable with **HTTPS**.

### Option A: 1-Click Deploy to Render (Recommended & Free)

The project includes a ready-to-use [`render.yaml`](file:///Users/therampatil/Desktop/AR/webar_portal/render.yaml) blueprint:

1. Push this project repository to **GitHub** or **GitLab**.
2. Sign in to [Render.com](https://render.com) (free account).
3. In the Render Dashboard, click **New +** $\rightarrow$ **Blueprint**.
4. Select your repository. Render will automatically detect [`render.yaml`](file:///Users/therampatil/Desktop/AR/webar_portal/render.yaml) and configure:
   * **Service:** `aura-webar-server`
   * **Environment:** Node 20
   * **Build Command:** `npm install`
   * **Start Command:** `node server.js`
   * **Persistent Disk:** 1GB attached at `/app/public/models` (preserves your scanned 3D models).
5. Click **Apply**.
6. In ~2 minutes, Render gives you a free global HTTPS URL:
   ```
   https://aura-webar-server.onrender.com
   ```
7. When running on Render, the server **automatically detects this public URL** so all generated QR codes will point directly to your live public WebAR domain!

---

### Option B: Deploy to Railway

1. Install Railway CLI or use [railway.app](https://railway.app).
2. Create a new project $\rightarrow$ **Deploy from GitHub repo**.
3. Set the Root Directory to `/webar_portal`.
4. Railway will automatically build the included [Dockerfile](file:///Users/therampatil/Desktop/AR/webar_portal/Dockerfile) and assign an HTTPS domain.
5. In Railway variables, set:
   ```
   PUBLIC_URL=https://your-service.up.railway.app
   ```

---

### Option C: Instant Public Tunnel (Zero Signups — Test Right Now!)

You can instantly expose your local server to the entire internet with a public HTTPS tunnel:

```bash
# In your terminal:
npx localtunnel --port 8080
```
This generates an instant public HTTPS URL, for example:
```
https://quick-tiger-42.loca.lt
```
Set this as `PUBLIC_URL` before starting the server:
```bash
PUBLIC_URL=https://quick-tiger-42.loca.lt node webar_portal/server.js
```
Now anyone in the world scanning your QR code will load the WebAR 3D viewer directly through the secure tunnel!

---

## 2. Pointing the Mobile App to Your Public Server

In [reconstruction_pipeline.dart](file:///Users/therampatil/Desktop/AR/lib/services/reconstruction_pipeline.dart), the server endpoint is configurable via `--dart-define`:

```bash
# Run or build pointing to your public Render URL:
flutter run --dart-define=AR_SERVER_URL=https://aura-webar-server.onrender.com
```

---

## 3. Installing the Production Android Release APK

Once the APK build finishes, the production installer is located at:
```
/Users/therampatil/Desktop/AR/build/app/outputs/flutter-apk/app-release.apk
```

### How to Install on a Physical Device:

1. **Via USB with ADB:**
   ```bash
   adb install -r build/app/outputs/flutter-apk/app-release.apk
   ```
2. **Direct Download:**
   Send `app-release.apk` to your phone via WhatsApp, Telegram, Google Drive, or AirDrop, and tap the file to install.
   *(Enable "Install unknown apps" in Android settings if prompted).*

---

## 4. Summary of Production Features

* **Universal WebAR:** Anyone scanning the QR code with their default camera app gets native **Apple AR Quick Look** on iPhone (`.usdz`) or **Google Scene Viewer** on Android (`.glb`) with **zero app downloads**.
* **PBR Shaded 3D Models:** Reconstructed models include metallic-roughness textures, normals, and quad decimation.
* **Continuous Keyframing:** Auto-samples multi-tier keyframes (Eye level, Top, Bottom) with real-time motion blur stabilization.
