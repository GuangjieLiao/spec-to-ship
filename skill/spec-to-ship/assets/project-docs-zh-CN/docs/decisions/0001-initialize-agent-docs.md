# Decision 0001: 初始化 Agent Docs

## 状态

已接受

## 背景

本项目使用 Spec to Ship，让 AI 辅助开发更容易审查、恢复和验证。

## 决策

在每次变更的 Spec to Ship artifacts 之外，维护项目级 agent 文档。

## 影响

- 后续 agent 在进行较大范围变更前，应先阅读 `AGENTS.md` 和 `docs/agent-map.md`。
- 如果变更影响项目结构、命令、测试、架构、部署或已知技术债，必须更新相关文档。
- 随着项目发展，空白占位内容必须被基于证据的事实替换。
