# Spec to Ship 中文说明手册

Spec to Ship 是一个面向 AI 编码协作的工作流 skill。它的目标不是让 AI 更快地“直接写代码”，而是让 AI 从需求澄清开始，经过设计、实现、验证、发布检查和归档，产出更容易审查、恢复和迭代的工程结果。

适合场景：

- 团队想把 AI coding 用到真实项目，而不是只做一次性 demo。
- 你正在使用 OpenSpec、Superpowers，想把两者组合得更稳定。
- 你希望每次 AI 说“完成了”时，都有可检查的证据。
- 你希望长任务中断后，下一次还能从文件状态恢复。
- 你有原型、截图、Figma 或 HTML mockup，希望 AI 按原型还原，而不是“差不多实现”。
- 你想把公司研发规范逐步沉淀成可复用 skill。

## 1. 核心理念

Spec to Ship 把一次 AI 编码任务拆成三层职责：

```text
OpenSpec      管 WHAT：需求、能力规格、验收场景、归档
Superpowers   管 HOW：头脑风暴、计划、TDD、调试、代码审查、收尾
Spec to Ship  管 FLOW：阶段状态、守卫、上下文包、验证证据、发布检查
```

这样设计的原因是：需求、设计、任务、验证、发布风险不能全部混在一段聊天里。聊天上下文会丢，agent 会忘，团队也不好 review。把关键事实落到文件里，后续才能恢复、审查和迭代。

## 2. 安装

克隆仓库后执行：

```bash
git clone https://github.com/GuangjieLiao/spec-to-ship.git
cd spec-to-ship
bash scripts/install.sh
```

安装后 skill 会复制到：

```text
~/.codex/skills/spec-to-ship
```

然后重启或刷新 Codex，让 skill 被发现。之后可以在任意项目里调用：

```text
$spec-to-ship
```

## 3. 在新项目里怎么用

进入你的项目目录，直接对 Codex 说：

```text
Use $spec-to-ship for this change: 增加管理员报表 CSV 导出能力
```

或者中文也可以：

```text
使用 $spec-to-ship 来处理这个需求：修复用户登录后偶发跳回登录页的问题
```

Spec to Ship 会先判断项目是否已经使用 OpenSpec：

- 如果项目有 OpenSpec，就优先围绕 `openspec/changes/<change-name>/` 工作。
- 如果项目没有 OpenSpec，就使用 fallback 目录：

```text
spec-to-ship/changes/<change-name>/
├── .spec-to-ship.yaml
├── proposal.md
├── spec.md
├── design.md
├── tasks.md
├── verify.md
└── release.md
```

如果是原型驱动的 UI 任务，还会额外创建 `prototype.md`。

你不需要先理解所有文件。第一次使用时，只要告诉 agent 需求，它会引导你完成确认。

## 4. 一次任务会经历哪些阶段

完整流程是：

```text
open -> design -> build -> verify -> release-ready -> archive
```

### open：需求澄清

目标是把“我要做什么”说清楚。

产物：

- `proposal.md`
- `spec.md`
- `.spec-to-ship.yaml`

重点回答：

- 为什么做？
- 做什么？
- 不做什么？
- 范围边界是什么？
- 有哪些风险和未知项？
- 怎么验收？

如果你提供了原型或截图，这个阶段还要明确：

- 哪个原型/截图是准的？
- 优先匹配哪个视口尺寸？
- 是否要求精确还原颜色、字体、间距和文案？
- 交互状态是否也要还原？
- 是否允许为了接入现有设计系统做偏差？

这个阶段结束前，agent 必须停下来让你确认。

### design：技术设计

目标是把“怎么做”想清楚。

产物：

- `design.md`
- `.spec-to-ship/checkpoints/design.md`
- `.spec-to-ship/handoff/build-context.md`

重点回答：

- 采用什么方案？
- 为什么不用其他方案？
- 影响哪些模块和文件？
- 是否影响 API、数据库、安全、权限？
- 测试策略是什么？
- 如果发生产，怎么回滚或降级？

如果是原型驱动的 UI 任务，还会创建或更新：

```text
prototype.md
```

它记录原型来源、目标视口、可见文案、布局结构、组件映射、素材、交互状态、响应式行为和允许偏差。

### build：计划与实现

目标是按任务逐步实现，不偷偷扩大范围。

产物：

- `tasks.md`
- build 阶段 checkpoint

对复杂需求，agent 应该问你：

- 用分支还是 worktree？
- 用 TDD 还是直接实现？
- 是否需要代码审查？

`tasks.md` 中每个任务都要有 evidence，例如：

```markdown
- [ ] 增加参数校验
  - Evidence: 单元测试覆盖非法参数和正常参数
```

### verify：验证

目标是用证据证明完成，而不是只说“完成了”。

产物：

- `verify.md`

需要记录：

- 改了哪些文件？
- 跑了什么命令？
- 测试/构建/lint 结果是什么？
- 验收场景是否通过？
- 代码审查发现了什么？
- 有哪些跳过项和剩余风险？

如果验证失败，不能直接继续归档。需要回到 build 修复，或者对非关键风险做明确记录。

如果是原型还原任务，验证还必须包含视觉证据：

- 原型截图或链接
- 实现后的截图
- 视口尺寸
- 不一致点列表
- 已接受的偏差
- 最终结果：`passed`、`accepted-with-deviations` 或 `blocked`

### release-ready：发布前检查

目标是判断是否具备合并或发生产的条件。

产物：

- `release.md`

需要考虑：

- CI 或本地替代验证
- 数据库迁移影响
- feature flag 或灰度策略
- 回滚方案
- 监控和日志
- 安全和隐私影响
- 部署注意事项

小的文档/样式 tweak 可以跳过，但真实业务功能建议保留这个阶段。

### archive：归档

目标是闭环，让后续任务可以信任这次变更留下的文件。

fallback 模式会归档到：

```text
spec-to-ship/archive/YYYY-MM-DD-<change-name>/
```

OpenSpec 模式下，可以配合 OpenSpec 的 archive 能力。

## 5. 五种模式

Spec to Ship 会先给任务分模式：

| 模式 | 适合场景 | 流程重量 |
|---|---|---|
| `tweak` | 文案、文档、配置值、样式小改 | 最轻 |
| `hotfix` | 聚焦 bug fix，不改架构/API/schema | 轻量 |
| `normal` | 默认功能、重构、业务改动 | 完整 |
| `prototype` | 根据原型、截图、Figma、HTML mockup 做 UI 还原 | 完整 + 视觉验收 |
| `epic` | 大 PRD、多能力、多模块 | 先拆分 |

这叫“模式分流”。它的作用是避免两种极端：

- 小文案也走完整重流程，太慢。
- 生产级功能只靠一句 prompt 直接写代码，太危险。

## 6. 常用命令

初始化 fallback 变更：

```bash
bash ~/.codex/skills/spec-to-ship/scripts/spec-to-ship-state.sh init spec-to-ship/changes/my-change normal
```

查看状态：

```bash
bash ~/.codex/skills/spec-to-ship/scripts/spec-to-ship-state.sh get spec-to-ship/changes/my-change
```

运行阶段守卫：

```bash
bash ~/.codex/skills/spec-to-ship/scripts/spec-to-ship-guard.sh spec-to-ship/changes/my-change open
```

推进阶段：

```bash
bash ~/.codex/skills/spec-to-ship/scripts/spec-to-ship-guard.sh spec-to-ship/changes/my-change open --apply
```

生成上下文包：

```bash
bash ~/.codex/skills/spec-to-ship/scripts/spec-to-ship-context.sh write spec-to-ship/changes/my-change build
```

写入 checkpoint：

```bash
bash ~/.codex/skills/spec-to-ship/scripts/spec-to-ship-checkpoint.sh spec-to-ship/changes/my-change build "完成第一批任务"
```

运行生产可用检查：

```bash
bash ~/.codex/skills/spec-to-ship/scripts/verify-production-ready.sh spec-to-ship/changes/my-change
```

## 7. OpenSpec schema 怎么用

Spec to Ship 不强制你一开始使用自定义 schema。你可以先用 fallback Markdown 跑起来。

如果你的项目已经使用 OpenSpec，并且想让 OpenSpec 正式认识 `verify.md` 和 `release.md`，可以安装 schema：

```bash
bash ~/.codex/skills/spec-to-ship/scripts/install-openspec-schema.sh .
openspec schema validate spec-to-ship
```

为什么 schema 是可选的？

- 第一阶段试跑时，最重要的是验证流程是否适合团队。
- schema 会增加项目约束，最好等团队确认 artifact 结构稳定后再启用。
- 当前项目已经提供了可验证通过的 starter schema，可以随时开启。

## 8. 上下文压缩和恢复

长任务常见问题是上下文太长，agent 忘记前面讨论了什么。

Spec to Ship 用三个机制解决：

### context pack

生成紧凑上下文包：

```text
.spec-to-ship/handoff/<stage>-context.md
.spec-to-ship/handoff/<stage>-context.json
```

它会记录 artifact 摘要和 hash。后续恢复时，不必每次重读所有文件。

### checkpoint

在关键阶段写入：

```text
.spec-to-ship/checkpoints/design.md
.spec-to-ship/checkpoints/build.md
.spec-to-ship/checkpoints/verify.md
```

checkpoint 记录已经确认的事实和进度。

### resume protocol

恢复时按顺序读：

1. `.spec-to-ship.yaml`
2. 当前阶段 artifact
3. `context_pack`
4. 当前阶段 checkpoint
5. `spec-to-ship-state.sh next <change-dir>`

这样 agent 不需要靠聊天记忆恢复。

## 9. 为什么这样设计

### 为什么要有 `.spec-to-ship.yaml`

因为 AI 会忘记当前阶段。状态文件让恢复变得确定。

### 为什么不允许直接改 phase

如果 agent 可以随便把 `phase: open` 改成 `phase: build`，阶段守卫就失效了。所以脚本会拦截直接改 phase，只允许通过 guard 或 transition 推进。

### 为什么要有 verify.md

因为“我完成了”不是证据。`verify.md` 要记录命令、结果、跳过项和剩余风险，方便人 review。

### 为什么要有 release.md

很多 AI coding 只关心代码能不能跑，但真实工程还要考虑迁移、回滚、监控、安全、发布窗口。`release.md` 把这些前置。

### 为什么要保留 fallback 模式

不是所有项目一开始都有 OpenSpec。fallback 模式让任何项目都能先跑起来。

## 10. 推荐试跑方式

第一次不要拿特别大的需求试。

建议从这类任务开始：

- 一个小 bugfix
- 一个后台接口的小功能
- 一个局部 UI 行为调整
- 一个小型重构

试跑后重点观察：

- open 阶段是否问得太多或太少？
- design 阶段是否真的帮助你发现风险？
- tasks 是否足够可执行？
- verify 是否留下了有用证据？
- release-ready 是否过重？

这些反馈都适合变成 issue 或 PR，继续迭代这个项目。

## 11. 原型不能完全还原怎么办

这是前端 AI coding 里很常见的问题。它不是“后端/前端”的问题，而是 **prototype-to-implementation fidelity** 能力没有被流程约束。

常见原因：

- agent 把原型当灵感，而不是合同。
- 没有记录目标视口、字体、间距、颜色、交互状态。
- 没有把原型截图和实现截图放在同一视口比较。
- 验证只跑了 build/test，没有做视觉验收。
- 没有把允许偏差写下来。

Spec to Ship 的解决方式：

1. 进入 `prototype` 模式。
2. 写 `prototype.md`，把原型来源和视觉要求结构化。
3. 在 `design.md` 里写视觉还原计划。
4. 在 `tasks.md` 里增加截图、布局、交互、响应式任务。
5. 在 `verify.md` 里记录截图对比和设计 QA 结果。
6. P0/P1/P2 视觉问题修完后才算通过，除非你明确接受偏差。

## 12. 贡献和迭代

这个项目适合通过真实使用持续进化。

推荐提交的问题类型：

- 某个阶段太重，影响效率。
- 某个阶段太轻，容易漏风险。
- 某个脚本在特定系统上跑不通。
- OpenSpec schema 和某个版本不兼容。
- 需要新增公司规范包。
- 某类项目需要独立流程，例如前端、后端、移动端、数据任务。

提交 issue 时不要包含：

- 公司私有代码
- 密钥
- 客户数据
- 内部 URL
- 未公开业务信息

可以提供脱敏后的 artifact 或最小复现。

## 13. 一句话总结

Spec to Ship 的目标是把 AI coding 从“聊天式写代码”推进到“有需求、有设计、有任务、有验证、有发布意识、可恢复、可审查”的工程协作流程。
