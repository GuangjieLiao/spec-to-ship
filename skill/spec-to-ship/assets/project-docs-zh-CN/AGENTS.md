# Agent Guide

## 项目概览

项目：{{PROJECT_NAME}}

{{PROJECT_SUMMARY}}

## 如何运行

{{RUN_COMMANDS}}

## 如何测试

{{TEST_COMMANDS}}

## 如何构建

{{BUILD_COMMANDS}}

## 重要路径

{{IMPORTANT_PATHS}}

- `docs/agent-map.md`：给后续 agent 阅读的项目地图。
- `docs/domain-map.md`：业务域、模块职责和 Controller 包入口地图。
- `docs/architecture-index.md`：架构概览和相关链接。
- `docs/decisions/`：长期决策记录。
- `docs/tech-debt.md`：已确认或待调查的技术债。
- `docs/quality-score.md`：基于证据的质量记录。
- `spec-to-ship/`：Spec to Ship 变更记录和配置。

## 项目规则

{{PROJECT_RULES}}

## Spec To Ship 工作流

功能开发、bug 修复、重构和生产敏感变更都应使用 `$spec-to-ship`。

每次变更在验证通过前，都必须检查这些项目级文档是否需要更新。

## 需要人工确认的事项

在执行不可逆操作、删除数据、改变生产行为，或接受未经验证的安全/隐私风险前，必须先询问人类。
