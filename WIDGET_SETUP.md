# Adding WidgetKit Extension to PulseBar

## Step 1 — Add Widget Extension Target
1. In Xcode: **File → New → Target**
2. Choose **"Widget Extension"**
3. Product Name: `PulseBarWidget`
4. Include Configuration Intent: **NO**
5. Click **Finish** → **"Activate"** when prompted

## Step 2 — Replace generated files
Delete the auto-generated widget files and drag in:
```
PulseBarWidget/PulseBarWidget.swift
```

## Step 3 — Add App Group (both targets)
1. Select **PulseBar** target → Signing & Capabilities
2. Click **"+"** → Add **"App Groups"**
3. Add group: `group.com.danyaczhan.pulsebar`
4. Repeat for **PulseBarWidget** target

## Step 4 — Add WidgetKit to main app
1. PulseBar target → General → Frameworks & Libraries
2. Click **"+"** → search **WidgetKit.framework** → Add

## Step 5 — Build & test
- Press **⌘R** to run
- Right-click desktop → **Edit Widgets** → search **"PulseBar"**

---

> **Note:** The main app writes live metrics every 3 seconds to the
> App Group (`group.com.danyaczhan.pulsebar`) so the widget always
> has fresh data, refreshing every 30 seconds via `WidgetCenter`.
