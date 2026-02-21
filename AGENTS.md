# AGENTS.md

## 项目概览
- 项目名：Mouserino
- 目标：提供一个轻量的 macOS 鼠标按键映射工具（对标 Logitech Options 的最小可用替代）。
- 当前主程序位于：`/Users/ron/Documents/mouserino/MouserinoApp`
- 技术栈：Swift + SwiftUI + macOS 全局事件监听（Accessibility 权限）

## 目录约定
- `MouserinoApp/`：Swift Package 主工程
- `specs/`：产品和技术规格文档（本目录）

## 开发原则
- 保持最小可用：优先改进已支持的中键/侧键映射与稳定性。
- 避免过早抽象：在需求明确前，不引入复杂插件机制。
- 权限优先：涉及事件监听/注入时，先校验 Accessibility 权限状态并给出可理解提示。
- 配置可恢复：所有用户配置必须可持久化，且在字段新增时提供兼容默认值。

## 代码约束
- 语言：Swift（与现有代码风格一致）。
- UI：SwiftUI，设置项文案清晰，避免含糊缩写。
- 按键映射变更必须同步更新：
  - UI 枚举选项
  - 映射执行逻辑
  - 持久化结构（若有新增字段）
- 新能力至少补一条手工验证步骤（写入 `specs/testing.md`）。

## 运行与验证
- 启动：
  - `cd /Users/ron/Documents/mouserino/MouserinoApp`
  - `swift run`
- 手工验证重点：
  - 在授权/未授权两种状态下，应用行为是否可预期。
  - 开关 remap 后，侧键与中键行为是否符合设置。
  - 应用重启后设置是否保留。

## 非目标（当前阶段）
- 不实现云同步。
- 不实现复杂脚本编排。
- 不在当前迭代实现完整设备管理面板。

## 文档维护
- 每次新增功能时，更新：
  - `specs/product-spec.md`（需求边界）
  - `specs/technical-spec.md`（实现要点）
  - `specs/testing.md`（验证步骤）
