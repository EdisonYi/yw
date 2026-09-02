# yw · 环境运维角色 Skill（WorkBuddy）

> 一个务实的「环境运维工程师」人格 Skill，触发名 `/yw`。负责运维工作的**分诊 → 观测 → 定位 → 处置 → 验证 → 记录**，并在每次任务后把工作内容持续追加进 `work-log.md`，重复问题沉淀为 `runbook.md`。

[![GitHub](https://img.shields.io/badge/repo-EdisonYi%2Fyw--skill-blue)](https://github.com/EdisonYi/yw-skill)

---

## 一句话部署（agent 友好）

任意装了 WorkBuddy 的机器，一条命令完成部署，**无需手动配环境、无需分步操作**：

```bash
git clone https://github.com/EdisonYi/yw-skill.git && bash yw-skill/deploy.sh
```

PowerShell 用户：

```powershell
git clone https://github.com/EdisonYi/yw-skill.git; powershell -ExecutionPolicy Bypass -File yw-skill/deploy.ps1
```

部署脚本会把 `yw/` 目录整体复制到 WorkBuddy 用户级 skills 目录（`~/.workbuddy/skills/yw/`），部署完即可在对话里用 `/yw` 触发，**无需重启**。

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
yw-skill/
├── README.md          # 本文
├── deploy.sh          # 一键部署（bash / Git Bash / Linux / macOS）
├── deploy.ps1         # 一键部署（PowerShell / Windows）
└── yw/                # Skill 本体（直接对应 ~/.workbuddy/skills/yw/）
    ├── SKILL.md       # 角色定义 + Agentic Protocol + 心智模型 + 诚实边界
    └── references/
        ├── work-log.md  # 运维工作日志（持续累积）
        └── runbook.md   # 可复用 playbook（重复问题沉淀）
```

---

## 手动部署（等价于脚本）

```bash
# 1. 复制本体到用户级 skills 目录
mkdir -p ~/.workbuddy/skills/yw
cp -r yw/. ~/.workbuddy/skills/yw/

# 2. 完成。对话中输入 /yw 即可触发
```

> 部署目标可通过环境变量 `WORKBUDDY_SKILLS` 覆盖（指向你的 skills 根目录）。

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
