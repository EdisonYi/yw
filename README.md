# yw · 环境运维角色 Skill（WorkBuddy）

> 一个务实的「环境运维工程师」人格 Skill，触发名 `/yw`。负责运维工作的**分诊 → 观测 → 定位 → 处置 → 验证 → 记录**，并在每次任务后把工作内容持续追加进 `work-log.md`，重复问题沉淀为 `runbook.md`。

[![GitHub](https://img.shields.io/badge/repo-EdisonYi%2Fyw-blue)](https://github.com/EdisonYi/yw)

---

## 安装（单条命令）

在 WorkBuddy 对话里直接说：

```
/install-github-skill https://github.com/EdisonYi/yw.git
```

装完**重启一次 WorkBuddy 会话**，`/yw` 即可触发，无需任何其他配置。

---

## 它做什么

| 场景 | 示例触发 | 行为 |
|------|---------|------|
| 服务异常 | 「服务器起不来」「服务报错/挂了」 | 分诊 → 只读观测（进程/端口/日志/接口）→ 分层定位 → 给处置方案 |
| 变更操作 | 「部署/迁移/升级」「重启/换证书」 | 先确认目标与回滚预案，危险动作**等你确认**再执行 |
| 查询盘点 | 「版本/端口/资源查询」「资产盘点」 | 直接观测返回事实 |
| 咨询 | 「这类故障一般怎么排查」 | 给分诊框架 + 引用已有 playbook |

**核心机制 · 持续更新工作内容**
- 每次任务结束，yw 按固定格式把「任务/环境/现象/定位/处置/验证/待跟进」追加进 `references/work-log.md`；
- 同类问题第 2 次出现，提炼成 `references/runbook.md` 一条（RB-xx），下次直接复用——环境越用越熟。

---

## 仓库结构

```
yw/                      # 本仓库即 skill 根目录（开放 Agent Skills 协议布局）
├── README.md            # 本文
├── SKILL.md             # 角色定义 + Agentic Protocol + 心智模型 + 诚实边界
├── deploy.sh            # 一键部署到 WorkBuddy skills 目录（bash / Git Bash / Linux / macOS）
├── deploy.ps1           # 一键部署（Windows PowerShell）
└── references/
    ├── work-log.md      # 运维工作日志（持续累积）
    ├── runbook.md       # 可复用 playbook（重复问题沉淀，RB-10~RB-26）
    └── sources-index.md # 知识来源索引（官方/语雀文档溯源，不纳入二进制）
```

> 仓库根目录就是 skill 根目录，因此能被 `/install-github-skill` 直接识别安装。
> `deploy.sh` / `deploy.ps1` 仅用于将本仓库同步到本地 skills 目录（开发者工具，不参与 skill 运行时）；`references/sources-index.md` 为知识溯源，安装后亦不影响触发。

---

## 安全约定

- **只读优先**：排查阶段只观察，不动生产。
- **危险动作必确认**：重启/删文件/改配置/停服务前，yw 先给方案+影响，等你确认才执行。
- **不编造未观测事实**：没看日志就不下结论；拿不到环境权限就明说。
- work-log 仅存本地 skill 内，**不含口令/证书/私有 IP 等敏感明文**。

---

## 卸载

```bash
rm -rf ~/.workbuddy/skills/yw
```

---

## License

MIT · 自由使用、修改、再分发。
