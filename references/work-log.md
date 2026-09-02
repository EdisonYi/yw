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

## 2026-09-02 14:4x · 基于 dhr2.0 文档补全 yw 私有化运维知识
- 类型: 变更（知识沉淀 / darwin 优化）
- 环境: 本机 `ehr私有化部署/dhr2.0` 系列文档 + yw skill（~/.workbuddy/skills/yw/）
- 现象: 用户要求按 9 篇 dhr2.0 知识库文档更新 yw，覆盖部署架构/启停/备份/报错/信创配置
- 定位: 9 篇中 5 篇本地落地（基础信息/数据操作说明/Redis7/信创部署/服务器中高配置 xlsx），
  3 篇报错专项文档（地址已在使用/错误号仍提示/各类启动报错）未取到本地副本→用其错误清单+xzl 既有覆盖编写并标 🔴 待核对
- 处置: runbook.md 增 RB-10~RB-17（双路径布局/启停顺序/备份/Jenkins/Redis7/信创栈/服务器配置/启动报错矩阵/黑名单）；
  SKILL.md 补 DHR2.0 触发词+Step2 路由+调研来源；密码/私有IP 不写入 skill
- 验证: SKILL.md 体积 <150% 上限；GitHub API 推送 /EdisonYi/yw 成功（3 文件）
- 待跟进: 用户若提供 3 篇报错文档原文，补全 RB-16 中 🔴 标记项的精确处置

## 2026-09-02 15:0x · 咨询：DHR2.0 私有化服务器配置推荐
- 类型: 咨询（无变更动作）
- 环境: DHR2.0 私有化 / 信创部署规划
- 现象: 用户问「服务器配置推荐」，需给出可落地的规格
- 定位: 回源读《EHR/信创-EHR系统部署服务器中高配置》xlsx + runbook RB-15；三角色(数据库/应用/运维)须物理分离，每角色中配(32G/4vCPU/500G SSD)与高配(64G/8vCPU/1000G SSD)两档
- 处置: 给推荐——①先选路径(普通Ubuntu22.04 vs 信创银河麒麟ky10) ②按规模选中/高配(数据库优先高配) ③路径差异(/usr/local vs /data/usr/local) ④可选扩展(报表横石/ES 9203,非xlsx三核心待确认) ⑤验收清单(分机/禁外网库/防火墙/带宽20-50M/短信平台/https证书/时间校准)
- 验证: 数字与 xlsx 一致；无变更需确认
- 待跟进: 无（咨询类）；若进入采购/部署阶段，转 RB-10~RB-12 执行

## 2026-09-02 15:1x · 咨询：如何启动 DHR（薪事力私有化）
- 类型: 咨询（无变更动作）
- 环境: DHR2.0 私有化（路径待确认：有运维 `/usr/local` vs 无运维 `/data/usr/local`）
- 现象: 用户问「如何启动 dhr」
- 定位: 启动须严格顺序 Mongo→PG→DHR（RB-11），且先认布局（RB-10）
- 处置: 给分诊框架 + 两套路径启动命令 + 验证三件套 + 常见坑（先起应用后起库报连库错/地址已在使用/授权绑定 RB-02）
- 验证: 无（咨询）
- 待跟进: 用户提供具体机器访问方式与路径后，可代执行启动并闭环验证（ps/curl/dhr.log）

## 2026-09-02 15:1x · 变更：yw runbook 路径演示统一为 /usr/local 基础
- 类型: 变更（内容一致性，darwin 把关：先备份/最小变更/一致性校验）
- 环境: yw skill `references/runbook.md`
- 现象: 用户要求「路径演示都以 /usr/local/ 作为基础」（去掉 /data/usr/local 双路径演示）
- 定位: RB-10/RB-12/RB-13 含 /data/usr/local 演示路径，与有运维布局不一致
- 处置: ① RB-10 改单基础路径 /usr/local +「前缀可替换」说明；② RB-12 删无运维同路径注、补全 PG 绝对路径；③ RB-13 Redis 路径 /data/redis-7.2.2 → /usr/local/redis-7.2.2；备份 `runbook.md.bak.20260902-1515`
- 验证: Grep 确认仅 RB-10 说明行保留 /data 作示例，演示路径全统一 /usr/local；SKILL.md 未变(7112B)；runbook 11367B→~11450B
- 待跟进: 是否同步到 GitHub（本地已改、远程仍是旧版，上次推送 commit 43a1dd5）

## 2026-09-02 15:1x · 受阻：基于语雀 7 篇优化 yw（缺文档来源，已出规划草案）
- 类型: 受阻/待跟进（用户未附语雀链接 URL）
- 环境: yw skill + 本机 `桌面文件/ehr私有化部署/dhr2.0`
- 现象: 用户要求基于 7 篇语雀文档（Tomcat证书/进程日志/无运维升级/信创无运维升级/外网白名单/非法ip/版本更新升级）优化 yw 并"与最新规范一致"，但消息仅列标题未给可访问链接；语雀需登录无法直接抓取
- 定位: 本机可对应材料——`升级文档/DHR2.0升级步骤文档*.docx`(2023版)、`DHR2.0的升级步骤.txt`、`dhr2.0无运维服务器更新.txt`、`keytool生成jks格式证书.txt`；缺「外网白名单/进程日志/信创无运维」专属副本，且 docx 为 2023 版非语雀最新
- 处置: **未改 yw**（避免基于不确定/旧来源污染）；出 darwin Phase0 规划草案——拟新增 RB-18 升级流程 / RB-18a 无运维升级 / RB-18b 信创升级 / RB-19 证书 / RB-20 进程日志 / RB-21 出网白名单 + 扩展 RB-02 非法ip + SKILL.md 路由；请用户二选一：①贴语雀导出(.docx/.md)/全文 ②授权用本机2023版+标🔴
- 验证: 无（未执行）
- 待跟进: 用户给语雀来源后执行完整更新（含 darwin 体积/一致性校验 + 推 GitHub）

## 2026-09-02 15:2x · 咨询：如何更新 DHR（升级流程）+ 沉淀 RB-18
- 类型: 咨询 + 知识沉淀（变更型 playbook 首填）
- 环境: DHR2.0 私有化（路径 /usr/local）；yw skill
- 现象: 用户问「如何更新 dhr」
- 定位: 升级=变更型，须先认通道（有运维 Jenkins 一键 / 无运维 deployDHR.sh）与当前版本；本机有确定可用的无运维更新 txt + 2023 版升级步骤 txt（语雀 7 篇仍缺来源）
- 处置: runbook.md 新增 RB-18（更新/升级流程）——路径A 无运维更新(6步,基于本机txt确定可用) + 路径B Jenkins一键(2023框架,不写明文密码) + 部署前必查(tomcat.properties/sms/cfg转码/出网白名单🔴/信创🔴) + 验证 + 坑(横石BI遗留)；语雀专属项(Tomcat证书/外网白名单/信创无运维/非法ip)续标 🔴 待核对
- 验证: 无（咨询）；RB-18 材料来源为本机已观测 txt，非编造
- 待跟进: ①语雀7篇来源到位后补全 RB-18/19/20/21 中 🔴 项 ②是否把本次 RB-18 改动推 GitHub（本地已改，远程 commit 43a1dd5 仍是旧版）

## 2026-09-02 15:3x · 纠错：RB-18 区分常规升级(Jenkins一键) 与 1.0→2.0 迁移长流程
- 类型: 变更（内容纠错，darwin 把关：先备份/最小变更/一致性校验）
- 环境: yw skill `references/runbook.md`（备份 runbook.md.bak.20260902-1530）
- 现象: 用户指出 RB-18「路径B 有 Jenkins 一键升级」把 2023 长流程写成常规升级，事实错误
- 定位: 该长流程仅适用 dhr1.0→2.0 跨代迁移；常规升级=Jenkins 一键更新（无需手动停库/传包/恢复/清理）
- 处置: ① 前置判断①加注(常规走路径B / 仅 1.0→2.0 走路径C) ② 拆路径B=常规Jenkins一键(简洁) + 路径C=1.0→2.0 迁移长流程(标注仅此场景、非日常升级) ③ 两处加🔴边界标记
- 验证: Grep 确认错误标题"路径B · 有 Jenkins 一键升级"已清除；runbook 14467B→约14900B；SKILL.md 7112B 未变
- 待跟进: 同前（语雀7篇来源待补 RB-19/20/21 🔴 项；是否推 GitHub）

## 2026-09-02 15:3x · 咨询：如何更新版本（复用 RB-18 路径A/B/C）
- 类型: 咨询（无变更，同类第二次，直接复用 runbook RB-18）
- 环境: DHR2.0 私有化（路径 /usr/local）
- 现象: 用户问「如何更新版本」（与"如何更新 dhr"同类）
- 定位: 更新版本=变更型，先认通道——①有运维常规→路径B Jenkins一键(仅此,无需手动) ②无运维→路径A 手动deployDHR.sh 6步 ③仅1.0→2.0跨代→路径C长流程
- 处置: 给分诊框架+三路径+验证三件套+危险边界(停服窗口/备库红线/确认后执行)；引用 RB-18
- 验证: 无（咨询）；RB-18 落盘已核对(15419B, A/B/C 结构正确)
- 待跟进: 语雀7篇来源待补 RB-19/20/21 🔴；是否推 GitHub（本地 RB-18 含 A/B/C 修正，远程 commit 43a1dd5 旧版）

## 2026-09-02 15:37 · 咨询：如何配置证书（HTTPS/SSL）+ 沉淀 RB-19
- 类型: 咨询 + 知识沉淀（首次证书类，建 RB-19）
- 环境: DHR2.0 私有化（路径 /usr/local）；yw skill
- 现象: 用户问「如何配置证书」
- 定位: 证书配置=变更型（改 tomcat.properties/重导证书属 RB-17 高危）；本机仅 `keytool生成jks格式证书.txt` 一行生成命令（含明文密码，转 `<pwd>` 占位）
- 处置: runbook.md 新增 RB-19（Tomcat 证书配置）——①keytool 用 DHR 自带 jdk 生成 jks(本机实测命令,密码占位) ②配置 tomcat.properties 端口/证书/密码/类型/别名(项名🔴待语雀核对) ③到期更换 ④验证(curl https/浏览器无告警/dhr.log 无 Keystore 错) ⑤坑(Keystore密码错致启动失败/过期/类型不匹配/高危变更)；语雀《Tomcat证书配置操作说明》专属项标 🔴
- 验证: 无（咨询）；runbook 备份 runbook.md.bak.20260902-1537 可回滚
- 待跟进: 同前（语雀7篇来源待补 RB-19/20/21 🔴；是否推 GitHub）

## 2026-09-02 15:40 · 变更：基于语雀《Tomcat证书配置操作说明》补全 RB-19（darwin 把关）
- 类型: 变更（知识补全，darwin 2.0 把关：先备份/最小完整变更/一致性/体积复核）
- 环境: yw skill；用户提供语雀导出 `Downloads/dhr2.0Tomcat证书配置操作说明.md`（真实来源）
- 现象: RB-19 此前证书配置项名/路径/类型标 🔴 待语雀核对；现来源到位
- 定位: 语雀明确——①Nginx代理在NG侧配、无NG在Tomcat侧 ②配置路径 /usr/local/dhr/config/tomcat.properties ③证书类型 tomcat(pfx/PKCS12) ④单端口限制(不支持http+https并存) ⑤ssl三项默认注释需去# ⑥有/无运维覆盖路径差异
- 处置: ①重写 RB-19（去 🔴，补 Nginx/Tomcat 分层+配置路径+证书类型+单端口+去#启用+有/无运维覆盖）②RB-18 证书引用行去 🔴 改指 RB-19 ③SKILL.md 路由 RB-10~RB-17→RB-10~RB-19(Step2+调研来源两处)+补证书文档来源；备份 runbook.md.bak.20260902-1537 + SKILL.md.bak.20260902-1540
- 验证: Grep 确认 RB-19 内无待核对 🔴（仅"已核对补全"说明）；SKILL.md 7196B(<150% 10668)、runbook 18803B；一致性通过
- 待跟进: 语雀其余 6 篇(进程日志/无运维升级/信创无运维升级/外网白名单/非法ip/版本更新升级)待补 RB-20/21 等 🔴；是否推 GitHub（本地 RB-18/19+SKILL 路由已更新，远程 commit 43a1dd5 旧版）

## 2026-09-02 15:56 · 变更：RB-19 收窄证书范围（证书由客户提供，不生成/不转换）
- 类型: 变更（范围收窄，darwin 把关：先备份/最小变更/一致性校验）
- 环境: yw skill `references/runbook.md`（备份 runbook.md.bak.20260902-1556）
- 现象: 用户明确「配置证书不需要生成自签名证书或证书转换步骤，证书一般由用户提供」
- 定位: RB-19 原「准备证书」含 keytool -genkeypair 自签命令、坑含 validity 3650 自签续期，超出"部署配置"职责，且与实际交付（证书客户提供）不符
- 处置: ① 准备证书段改为"客户提供 tomcat 证书(pfx/PKCS12)直接放 config，yw 不生成自签、不做格式转换(🔴边界声明)" ② 坑"证书过期"改为"客户提供新证书替换原文件后重启(RB-11)，勿自行生成/转换" ③ 类型一致性坑保留(客户给 pfx↔PKCS12 / jks↔JKS 仍须匹配 key-store-type)
- 验证: Grep 确认 keytool -genkeypair / validity 3650 / keytool生成jks 均无残留；runbook 18803B→18657B(精简)；SKILL.md 7196B 未变
- 待跟进: 同前（语雀其余6篇待补 RB-20/21 🔴；是否推 GitHub）

## 2026-09-02 15:58 · 咨询：如何配置证书（复用 RB-19，证书由客户提供）
- 类型: 咨询（无变更，同类复用；RB-19 已收窄为"证书由客户提供、不生成/不转换"）
- 环境: DHR2.0 私有化（路径 /usr/local）；yw skill
- 现象: 用户问「如何配置证书」（与 15:37 同类，RB-19 已沉淀并收窄）
- 定位: 证书配置=变更型（改 tomcat.properties 属 RB-17 高危）；无 Nginx 在 Tomcat 侧配，证书用户提供不生成
- 处置: 给分诊框架——①判 Nginx 代理形态 ②无 Nginx 时客户提供 pfx/PKCS12 证书放 /usr/local/dhr/config ③去#启用三配置项(server.port/ssl.key-store/ssl.key-store-password/type=PKCS12) ④改 cfg.properties 访问地址为 https ⑤覆盖并重启(RB-11) ⑥验证(curl https/浏览器无告警/dhr.log 无 Keystore 错)；引用 RB-19
- 验证: 无（咨询）；RB-19 落盘已核对(18657B, 无自签/转换步骤)
- 待跟进: 语雀其余6篇待补 RB-20/21 🔴；是否推 GitHub

## 2026-09-02 16:05 · 变更：推送 yw 全部更新到 GitHub（EdisonYi/yw, main）
- 类型: 变更（发布；走 GitHub Contents API，本环境 git push 不可用）
- 环境: 本地 ~/.workbuddy/skills/yw → 远程 https://github.com/EdisonYi/yw (main)
- 现象: 用户要求"将 yw 更新到 GitHub" / "yw更新的内容推送到github"
- 定位: 自上次推送 commit 43a1dd5 后累计改动——路径演示统一/usr/local、RB-18 升级流程(常规Jenkins一键 vs 1.0→2.0迁移长流程)、RB-19 Tomcat证书配置(语雀补全+收窄为不生成/不转换)、SKILL路由 RB-10~RB-19；远程仍旧版
- 处置: 用 Contents API 推 SKILL.md + references/runbook.md + references/work-log.md（带远程sha更新）；.bak 备份不推送；README 保留远程不动（活技能目录不含）
- 验证: 推后 API 核验远程树大小/sha 一致
- 待跟进: 语雀其余6篇待补 RB-20/21 🔴（后续单独推送）

## 2026-09-02 16:16 · 咨询：服务启动不了（现象型分诊）
- 类型: 咨询（现象型；未给报错关键词/服务名，无事实不臆断）
- 环境: DHR2.0 私有化（疑似；待用户确认服务与报错）
- 现象: 用户问「服务启动不了」
- 定位: 现象型，须先观测——需报错关键词/错误号/哪个服务起不来/能否登机。先给 RB-16 启动报错矩阵速查 + RB-03 三板斧 + RB-02 授权绑定 + RB-11 启停顺序，等用户补事实再定位
- 处置: 给分诊框架——①确认哪个服务(应用/PG/Mongo/Redis) ②看 logs/dhr.log 报错关键词对 RB-16 表 ③有错误号走 common.do?e= 反查 ④端口冲突 ss -tlnp、磁盘 df -h、进程 ps；危险动作(重启/删/改)须确认影响面后执行
- 验证: 无（咨询，等用户补事实）
- 待跟进: 用户提供①哪个服务起不来 ②报错原文/错误号 ③能否登机 → 我出精确定位与最小处置并闭环验证

## 2026-09-02 16:18 · 咨询：服务起不来报错「mac/ip 地址不合法」（命中 RB-02）
- 类型: 咨询→定位（现象型+变更型；授权绑定层）
- 环境: DHR2.0 私有化（软加密 license 绑 MAC+IP，应用服务器）
- 现象: 用户补报错关键词 = `mac/ip 地址不合法`（承接 16:16 的"服务启动不了"）
- 定位: 授权校验失败，两层不可混（RB-02）——①Q1a 格式非法(IP 前导零/段>255、MAC 未归一为`:`) ②Q1b 绑定不一致(授权按旧 MAC/IP 生成≠当前真实来源: 迁移/换网卡/双网卡取错/DHCP)。须先只读采集真实 MAC+IP 再判定哪层
- 处置: 给只读诊断命令(ip a / 主网卡 MAC / 查授权登记) + 两层判定与各自处置(Q1a 改配置地址格式低风险; Q1b 用真实 MAC+IP 联系实施重生成授权文件高风险) + 双网卡绑内网固定 MAC 建议；重生成授权属 RB-17 高危须确认影响面，不自行执行
- 验证: 无（咨询，等用户回真实 MAC/IP 与登记值比对结果）
- 待跟进: 用户跑诊断命令回真实 MAC+IP + 授权登记值 → 我判 Q1a/Q1b 并出精确处置；必要时推 GitHub 沉淀

## 2026-09-02 16:25 · 变更：语雀 14 篇导出全集补全 yw runbook（darwin 把关）
- 类型: 变更（知识补全；darwin 2.0 把关：先备份/最小完整变更/一致性/体积复核）
- 环境: yw skill；用户提供 Downloads 下 14 篇语雀导出 md（启动报错关键信息系列 + 版本更新升级 + postgre启动说明 + Tomcat证书）
- 现象: RB-16 矩阵及 RB-02/RB-18 此前多处标 🔴 待核对（缺语雀原文）
- 定位: 14 篇原文与 runbook 待补项一一对应，可一次补全；备份 runbook.md.bak.20260902-1625 + SKILL.md.bak.20260902-1625
- 处置:
  - RB-16 重写：mac/ip(Q1b 重绑 license 管理员) / authCode(3 步) / 不支持降级(2 步) / 升级到期(商务延期) / UnknownHost+获取license失败(开放两 URL) / Keystore(4 步) / 地址已在使用(ss/lsof) / PG共享缓存(RemoveIPC=no) / squid(4 代理参数) / 登录错误号(库挂 ps 查) 全部去 🔴 填语雀原文
  - RB-02 精确化：mac/ip 报错=MAC/IP 变更→提交单位信息+提示 mac/ip 给 license 生产管理员重绑→重启；保留 Q1a/Q1b 两层
  - RB-11 补坑：PG 必须非 root 启停；root 启留 logfile 属主致 Permission denied→root 删 logfile 重启
  - RB-18 路径B 精确化：Jenkins EHR 视图 updateEHR 任务(含停应用+备库+拉包+更新+启动)；升级前必备份 mongo+pg+config/勿重复执行/8.04.01+ 含 number 字段视图先备份删视图
  - 新增 RB-20 进程及日志查询(🔴 待《服务进程及日志查询》原文) + RB-21 应用出网白名单(两 URL 已坐实)
  - SKILL.md 路由 RB-10~RB-19→RB-10~RB-21(两处) + 调研来源补语雀导出系列
- 验证: Grep 确认 RB-16 矩阵原 🔴 项已去(残留 🔴 仅为 RB-17 红线/无原文待补项: 东方通临时文件/信创无运维升级/非法请求ip/RB-20)；SKILL.md 7450B(<9820)、runbook 23638B；一致性通过
- 待跟进: ①仍缺原文待补四项的原文已于 16:46 批次补齐（见下）②是否推 GitHub（16:32 已推一次，本次新改动待推）

## 2026-09-02 16:32 · 推送 yw 到 GitHub（用户指令）
- 类型: 交付（GitHub Contents API + curl 经代理；git push 本环境不可用）
- 推送文件: SKILL.md(7450B) / references/runbook.md(23638B) / references/work-log.md(18834B) 三件全覆盖；README.md 保留远程；.bak 不推
- 预期: 远程 main 同步到本次语雀 14 篇补全后的完整版（RB-10~RB-21）；commit 由旧 4da9a27 前进

## 2026-09-02 16:46 · 变更：语雀次批 5 篇补全 yw runbook 剩余 🔴 待补项（darwin 把关）
- 类型: 变更（知识补全；darwin 2.0 把关：先备份/最小完整变更/一致性/体积复核）
- 来源: 用户提供 Downloads 下 5 篇语雀导出 md（备份数据还原 / 信创环境无运维升级 / 东方通临时文件缺失NoSuchFileException / 服务进程及日志查询 / 智多薪菜单非法请求ip）
- 现象: runbook 仍有 4 处 🔴 待核对（东方通临时文件/信创无运维升级/非法请求ip/RB-20 进程日志）+ RB-12 仅备份缺还原
- 备份: runbook.md.bak.20260902-1646 + SKILL.md.bak.20260902-1646
- 处置:
  - RB-12 加「还原」段: Mongo(mongodb6/8) mongorestore / PG15 pg_restore 命令（明文密码转 <pwd> 占位）；信创库还原联系厂商
  - RB-16 东方通行去🔴: tongweb.properties 加 server.tongweb.basedir=./temp（有/无运维路径差异），区分 /tmp 被清理根因
  - RB-18 信创无运维去🔴: 路径A变体——中间件 war 名(ehr_tongweb/bes/aas.war)、信创库备份联系厂商、配置备份 /tmp/properties日期
  - RB-18 坑: 菜单非法请求ip 指向新建 RB-22（与 RB-02 启动授权区分）
  - RB-20 去🔴补全: ps aux|grep dhr / tail -300f dhr.log / dhr.log.xxxx-xx-xx.0.gz gzip -d
  - 新增 RB-22 运行时非法请求ip（智多薪菜单）: 公有云开放平台加IP / 私有云 dev_ip 字段加IP重启 / license类报生产管理员；与 RB-02 启动 mac/ip 不合法明确区分
  - SKILL.md 路由 RB-10~RB-21→RB-10~RB-22（两处）+ 调研来源补次批 5 篇
- 验证: Grep 确认 runbook 无「待核对/待原文」类 🔴 残留（仅 RB-17 红线/RB-12 红线/RB-18 边界/RB-19 证书原则/RB-22 已补全说明等正当标记）；runbook 23638B→27218B、SKILL 7669B(<9820 上限)
- 待跟进: ①全部 🔴 待补项已清空，yw 进入 RB-10~RB-22 完成态 ②本次改动仅在本地，是否推 GitHub（远程仍是 16:32 commit 58149fa 旧版）

## 2026-09-02 16:51 · 推送 yw 到 GitHub（用户指令「推送」）
- 类型: 交付（GitHub Contents API + curl 经代理；git push 本环境不可用）
- 推送文件: SKILL.md(7669B) / references/runbook.md(27218B) / references/work-log.md(21215B) 三件全覆盖；README.md 保留远程；.bak 不推
- 预期: 远程 main 同步到次批 5 篇补全后的 RB-10~RB-22 完成态（无遗留 🔴 待补项）；commit 由旧 58149fa 前进

## 2026-09-02 17:04 · 变更：语雀第三批 2 篇补全 yw（darwin 把关）
- 类型: 变更（知识补全；darwin 2.0 把关：先备份/最小完整变更/一致性/体积复核）
- 来源: 用户提供 Downloads 下 2 篇语雀导出 md（无运维服务器定时备份 / Tomcat端口修改）
- 备份: runbook.md.bak.20260902-1703 + SKILL.md.bak.20260902-1703
- 处置:
  - RB-12 加「无运维服务器定时备份(crontab)」子节: root 连库 + `crontab -e` 追加 Mongo(02:00 mongodb6/8 路径) / PG(01:00 `su - postgres`) 两行；tool.lu/crontab 校验表达式；`crontab -l` 验证
  - 新增 RB-23 Tomcat端口修改: 改 `tomcat.properties` 的 `server.port`(默认 443→8443) + `cfg.properties` 访问地址；有/无运维覆盖路径差异；端口变更后防火墙开新端口+外网映射；单端口限制(关联 RB-19)
  - SKILL.md 路由 RB-10~RB-22→RB-10~RB-23（两处）+ 调研来源补第三批 2 篇
- 验证: Grep 确认 RB-23 / 无运维服务器定时备份 / crontab 已落位；SKILL 7660B(<9820 红线)；runbook 体积增长可控；本回同步确认 SKILL/runbook/work-log 已无"容器"字样（17:01 清理）
- 待跟进: 本次改动 + 17:01 容器清理均仅在本地，是否推 GitHub（远程仍是 16:51 commit 1d17709）

## 2026-09-02 16:55 · 咨询：ip地址不合法（@skill:yw）
- 类型: 咨询（现象型，分诊复用 RB-02 / RB-22）
- 现象: 用户报「ip地址不合法」（未给场景，需先判启动期 vs 运行时）
- 定位: 两类须区分——
  - ① 启动期报（应用起不来，Caused by BizException mac/ip地址不合法）→ RB-02 授权绑定：license 绑旧 MAC/IP（迁移/换网卡），须收集真实 ip a + 主网卡 MAC 交 license 生产管理员重绑 → 重启
  - ② 运行时进智多薪菜单提示「非法请求 ip / ip地址不合法」→ RB-22 应用层白名单：开放平台 IP 白名单未含当前 IP（公有云开放平台加IP实时；私有云 dev_ip 字段加IP后须重启）
- 处置: 给分诊框架+只读诊断命令+两层各自处置；等用户补「启动期 or 运行时菜单」与真实 MAC/IP 再出精确动作
- 验证: 无（咨询，未动）
- 待跟进: 用户回场景与事实 → 判 RB-02(重绑) 或 RB-22(加白名单)；危险动作(重绑授权/改dev_ip重启)须确认影响面后执行
