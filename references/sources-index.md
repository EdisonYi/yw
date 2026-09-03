# yw 知识来源索引（sources-index）

> 本 Skill 的 `runbook.md`（RB-10~RB-38）与 `work-log.md` 提炼自下列**官方部署文档**与**语雀导出的运维知识**。
> 原始文件存于用户本机 `Downloads/`，**不纳入本仓库版本管理**（避免 PDF/DOCX 二进制膨胀）；此处仅做溯源归类，便于回溯与补证。
> 最后整理：2026-09-03（第六批语雀文档，RB-29~RB-38）。

## 一、语雀导出 · 运维知识（playbook 直接来源）

### 首批（启动报错 / 升级 / 证书）
- `dhr2.0启动服务日志报错提示关键信息...mac地址不合法...md`
- `dhr2.0 版本更新升级操作说明.md`
- `dhr2.0 Tomcat证书配置操作说明.md`
- 涵盖：authCode不合法 / 程序不支持降级 / 产品升级时间已到期 / UnknownHost license.x-dhr.com / Keystore密码错 / 地址已在使用 / PG共享缓存被删 / squid代理 / 登录错误号循环 / postgre启动说明

### 次批（备份还原 / 信创无运维 / 东方通 / 进程日志 / 非法请求ip）
- `dhr2.0备份数据还原.md`
- `dhr2.0信创环境无运维服务器升级步骤.md`
- `dhr2.0 东方通临时文件缺失 NoSuchFileException 相关.md`
- `dhr2.0 服务进程及日志查询.md`
- `dhr2.0 智多薪菜单非法请求ip.md`

### 三批（无运维定时备份 / Tomcat端口）
- `dhr2.0无运维服务器如何创建数据库自动备份定时任务.md`
- `dhr2.0Tomcat端口修改操作说明.md`

### 四批（cfg配置项 / 屏蔽登录页 / 初始部署速览）
- `cfg.properties 其他项配置项说明.md`
- `dhr2.0屏蔽登录页面配置.md`
- `dhr2.0私有化初始部署速览.md`

### 五批（数据库部署 / 无运维完整部署）→ RB-27、RB-28
- `dhr2.0不同适配的操作系统下MongoDB8数据库部署.md`
- `dhr2.0-PostgreSQL15数据库部署.md`
- `dhr2.0无运维服务器部署手册.md`
- 涵盖：OS/CPU 架构适配矩阵（x86 须 AVX）/ 部署包与 `deployMongoDB.sh`·`deployPostgreSQL.sh`·`deployWeb.sh` 脚本 / 在线·离线两种安装 / fontconfig 依赖 / 软加密（输入 n）/ `init_PostgreSQL_Index.sql` 预置索引 / `/tmp/install.log` 排错

### 六批（limit限定量 / Mongo6集群 / 文案 / nginx / 微信 / 改密 / 金仓 / 统计 / 集群部署）→ RB-29~RB-38
- `dhr2.0私有化-配置文件limit.properties关于限定量的配置.md`
- `dhr2.0-MongoDB6集群配置（三节点）.md`
- `dhr2.0私有化文案(国际化)替换操作说明.md`
- `dhr2.0使用nginx反向代理薪事力参考配置.md`
- `dhr2.0薪事力微信服务号配置（新版）-私有化客户.md`
- `dhr2.0-Nginx反向代理有上传文件异常提示...413(Request Entity Too Large).md`
- `dhr2.0如何通过数据库修改用户默认密码.md`
- `dhr2.0出现访问某些页面报错...NoSuchFileException...tmp_tomcat...md`
- `dhr2.0信创环境人大金仓备份与还原.md`
- `dhr2.0OA表单推送数据到薪事力失败...nginx反向代理...md`
- `dhr2.0查看数据库数据文件大小、统计表数量.md`
- `dhr2.0服务器上使用startDHR.sh启动应用提示dhr.war process is running..md`
- `dhr2.0-EHR私有化集群部署文档.md`

## 二、官方部署文档（DHR2.0 私有化）
- `dhr2.0-EHR私有化部署文档 for Ubuntu20.04系统.md / .pdf / .docx`
- `dhr2.0-EHR私有化部署文档 for 银河麒麟系统ky10（国产化） for 东方通、宝兰德、金蝶、中创.docx / .pdf`
- `dhr2.0-EHR私有化部署文档 for Rocky Linux 9 或者 Red Hat Enterprise Linux 9 系统.pdf`
- `dhr2.0-EHR私有化部署文档 for centos7 或者红帽7系统.pdf`
- `dhr2.0-EHR私有化集群部署文档.docx`
- `dhr2.0私有化应用及数据操作说明（启动、停止、数据库备份）.docx`
- `DHR 2.0 私有化部署培训.pdf`

## 三、配置清单（服务器 / 端口）
- `信创-EHR系统部署服务器中高配置.xlsx`（含多个版本）
- `国运信创-HR系统部署服务器配置列表.xlsx`
- `副本常规集群-HR系统部署服务器配置-包含端口功能(1)(1).xlsx`

## 说明
- 上述文件为 yw 的知识溯源，不在本仓库内；如需纳入版本管理，请建 `sources/` 子目录并复制原文后推送。
- playbook 已吸收其核心事实，日常运维无需翻阅原文。
- `backups/` 目录存放历次编辑前的 `.bak` 快照，属本地回滚用，**不推送**本仓库。
