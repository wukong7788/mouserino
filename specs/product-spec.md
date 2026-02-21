# Product Spec - Mouserino

## 1. 背景
Mouserino 是一个面向 macOS 的轻量鼠标按键映射工具，当前聚焦 Logitech MX Master 3 的核心按键场景。

## 2. 目标
- 提供稳定、可理解的按键重映射体验。
- 通过简洁 UI 完成启用/禁用及按键动作配置。
- 在应用重启后保留设置。

## 3. 用户场景
- 用户希望将侧键和中键映射到系统常用动作（Mission Control、Launchpad 等）。
- 用户希望随时一键关闭 remap，恢复默认行为。

## 4. 功能范围（当前）
- 全局 remap 总开关。
- 可映射按键：
  - Side Back
  - Side Forward
  - Middle Click
- 可配置动作：
  - No Action
  - Mission Control
  - App Expose
  - Launchpad
  - Show Desktop
- 设置持久化（UserDefaults）。
- 可选平滑滚动近似效果。

## 5. 非目标（当前）
- 拇指滚轮映射。
- 应用级 profile（按应用切换配置）。
- 跨设备配置同步。

## 6. 体验要求
- 未授予 Accessibility 时，提示清晰，且不导致崩溃。
- 已授予权限后，映射生效延迟应保持在可感知范围内（交互上无明显卡顿）。
- 设置界面路径直观，主要功能在单屏内可完成。

## 7. 发布准入（MVP）
- 三个按键映射可用且稳定。
- 开关状态和动作配置可持久化。
- 基础权限提示完整。
