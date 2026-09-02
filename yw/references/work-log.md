# yw · 运维工作日志（持续更新）

> 机制：每次 `/yw` 完成任务后，由 yw 在文末追加一条（格式见 SKILL.md）。这是 yw「持续更新工作内容」
> 的核心载体——它让本 Skill 越用越懂你的环境。仅存本地 skill 内，不含口令/证书/私有 IP 等敏感明文。
> 同一类问题第二次出现，提炼进 `runbook.md`。

---

## 2026-09-02 13:5x · 创建 yw 环境运维 Skill
- 类型: 变更（新建角色 Skill）
- 环境: WorkBuddy 用户级技能目录 ~/.workbuddy/skills/yw/
- 现象: 用户需要可经 `/yw` 调用的运维角色，做运维工作并持续更新工作内容
- 定位: 角色型 Skill（非人物蒸馏）；用运维工程方法论定义人格+协议+work-log/runbook 双文件机制
- 处置: 写 SKILL.md（角色/协议/心智模型/诚实边界）+ work-log.md（本文件）+ runbook.md（种子 playbook）
- 验证: 文件已落盘；`/yw` 可作为触发名调用
- 待跟进: 跑首批真实运维任务以填充 work-log；积累 2~3 次同类后回写 runbook
