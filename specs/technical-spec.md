# Technical Spec - Mouserino

## 1. 架构概览
- UI 层：SwiftUI（`ContentView`）
- 配置层：`SettingsStore`（基于 UserDefaults）
- 映射模型：`MouseMapping`
- 事件管理：`MouseEventManager`（全局鼠标事件监听与动作触发）

## 2. 模块职责
- `ContentView.swift`
  - 展示配置项、开关与权限请求入口。
- `SettingsStore.swift`
  - 读写 remap 开关和按钮动作配置。
  - 提供默认值与兼容读取逻辑。
- `MouseMapping.swift`
  - 定义按钮到动作的映射结构与可选动作枚举。
- `MouseEventManager.swift`
  - 监听输入事件，按当前映射决定是否拦截与执行系统动作。
- `MouserinoApp.swift`
  - 应用入口，组装状态与视图。

## 3. 权限与系统交互
- 使用 macOS Accessibility 能力完成全局输入事件处理。
- 未授权场景必须：
  - 不崩溃
  - 给出明确引导（去系统设置授权）

## 4. 数据模型与持久化
- 使用 UserDefaults 持久化：
  - remapEnabled（布尔）
  - back/forward/middle 的动作值
- 新增字段时要求：
  - 提供默认值
  - 保持向后兼容

## 5. 可扩展点
- 新按钮支持：在 `MouseMapping` 与 UI 同步扩展。
- 新动作支持：补充动作枚举 + 执行分支 + UI 文案。
- 应用级 profile（未来）：建议在现有 SettingsStore 之上增加 profile 维度，不破坏现有 key。

## 6. 可靠性要求
- 监听器启动/停止应与开关状态一致，避免重复注册。
- 权限变更后应支持重新初始化监听状态。
- 映射执行失败时应安全降级，不影响系统默认输入。
