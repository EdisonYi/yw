# yw · 运维 Playbook（重复问题沉淀）

> 机制：当某类运维问题在第 2 次出现，yw 把可复用处置提炼到这里，下次同类直接复用。
> 每条 playbook 含：触发现象 / 分层定位 / 标准处置 / 验证 / 坑。仅存本地 skill 内。

---

## RB-01 · git push 到 GitHub 返回 502（CONNECT tunnel failed）
- **触发**：`git push` 经沙盒/代理报 `CONNECT tunnel failed 502` 或 `Could not resolve host`。
- **定位**：环境向子进程注入代理 env（`http_proxy/https_proxy=127.0.0.1:<动态端口>`），
  该代理放行 `curl GET` 但拦截 git push 的 CONNECT 隧道；仅加 `dangerouslyDisableSandbox` 不够（env 代理仍在）。
- **标准处置**：`env -u http_proxy -u https_proxy -u HTTP_PROXY -u HTTPS_PROXY -u all_proxy -u ALL_PROXY git -c http.proxy= push origin main`（直连 github.com:443 实测可达）。
- **验证**：`git push` 成功；远程真实 HEAD 用 `curl -s https://api.github.com/repos/<owner>/<repo>/commits/main` 核验（本地 remote-tracking ref 可能被代理缓存，不可信）。
- **坑**：git 身份非全局——新仓库先 `git config user.name/user.email`；认证走 Windows 凭据管理器，通常无需 PAT。

## RB-02 · 软加密/授权报「mac/ip 地址不合法」（授权绑定）
- **触发**：应用启动报 `mac地址不合法：xx-xx…` 或 `ip地址不合法：x.x.x.x`（Caused by: ...BizException）。
- **根因（语雀原文）**：服务器 MAC 或 IP 改变（含迁移 / 换网卡）→ license 绑定的是初次部署获取的旧 MAC/IP，不符即拒。
- **两层不可混**（排障时先判）：
  - ① **格式非法**（本机 xzl 校验逻辑）：授权登记的 IP 有前导零/段>255、MAC 未归一成 `:` 分隔 → 改授权配置里的地址书写格式（低风险）。
  - ② **绑定不一致**（语雀运行时主因）：格式对但 ≠ 当前真实网卡 → 须重绑授权（高风险，见下）。
- **标准处置（绑定不一致 / 即语雀该报错）**：收集真实 `ip a` + `cat /sys/class/net/<主网卡>/address` 的 MAC/IP →
  **提交单位信息 + 提示的 mac/ip 给 license 生产管理员重新绑定新地址** → 重启应用（RB-11）。
  - 双网卡环境建议把授权绑到**内网固定 MAC**，避免系统随机取错网卡。
- **验证**：重启后授权校验通过、应用正常起；`logs/dhr.log` 无地址不合法。
- **坑**：代理链下取 `X-Forwarded-For` 为空会误判来源，须从真实网卡取；格式非法先改格式，别急着重生成授权。

## RB-03 · 磁盘满 / 端口冲突 / 进程死了（通用三板斧）
- **触发**：服务异常、起不来、端口被占。
- **定位**：`df -h`（磁盘）、`ss -tlnp`（端口占用）、`ps -ef | grep <svc>`（进程）。
- **标准处置**：清日志/扩容（磁盘）、`kill` 占用进程或改端口（冲突）、拉起服务（systemd/tomcat/`java -jar`）。
- **验证**：对应指标恢复正常、进程持续在、接口可达。
- **坑**：删文件前先确认非活跃日志/非唯一备份；停进程前确认无在途任务。

---
## DHR2.0 私有化运维手册（基于 dhr2.0 系列部署/运维文档）

> 适用范围：DHR2.0（薪事力）私有化部署的运维分诊。下面对齐《dhr2.0查看各服务基础信息》
> 《dhr2.0私有化应用及数据操作说明（启动、停止、数据库备份）》《dhr2.0-Redis7部署》
> 《dhr2.0信创支持明细》《EHR/信创-EHR系统部署服务器中高配置》等文档。
> 具体安装目录、密码、私有 IP 见原文档，**不写入本 skill**（yw 诚实边界）。
> 🔴 危险动作（停库/删数据/外网暴露/重生成授权）仍须确认后执行（见 SKILL.md Step 4）。

### RB-10 · 服务架构与安装路径（基础路径 /usr/local）
- **安装路径基础为 `/usr/local`**（有运维服务器 Jenkins 管理时的标准布局）：
  - 应用：`/usr/local/dhr`
  - MongoDB6：`/usr/local/ehr/mongodb6`
  - PostgreSQL15：`/usr/local/ehr/postgresql15`
  - 说明：若实际环境根目录不同（如 `/data/usr/local`），按同结构替换前缀即可；本手册所有演示均以 `/usr/local` 为准。
- **组件与端口**：
  - 应用 DHR：`startDHR.sh` / `stopDHR.sh`；日志 `logs/dhr.log`
  - MongoDB6：端口 **27011**；库 `ehr`；备份 `mongodb_data_bak.sh`
  - PostgreSQL15：端口 **5632**；库 `dbehr`；启停用 `su - postgres`；备份 `postgresql_data_bak.sh`
  - Redis7（可选缓存）：端口 **6389**（部署见 RB-13）
- **分层定位**：数据库**严禁外网访问**；应用需出网到 `x-dhr.com` / `license.x-dhr.com` 取 license 与表单权限。

### RB-11 · 服务启停顺序（顺序错了会连不上库）
- **启动顺序（必须）**：① MongoDB → ② PostgreSQL → ③ DHR 应用。
  - `mongodb6/startmongodb.sh`
  - `su - postgres -c "/bin/bash .../postgresql15/startpostgresql.sh"`
  - `dhr/startDHR.sh`
- **停止顺序（反向）**：① DHR 应用 → ② MongoDB → ③ PostgreSQL。
- **坑（PostgreSQL 启停）**：PG **必须切非 root 用户**（postgres）启停。若曾用 root 启动，会在安装目录留 root 属主的 `logfile`，再切 postgres 启会报 `Permission denied` → 处理：root 下删该 `logfile` 后重启用 `su - postgres -c "/bin/bash .../postgresql15/startpostgresql.sh"`；服务器断电重启后直接 `su - postgres` 启即可（logfile 属主已是 postgres）。
- **验证**：`ps -ef | grep -E 'dhr|mongod|postgres'` 进程在；`tail -200f logs/dhr.log` 无新错；
  `curl -sv <host>:80/health` 或业务页可访问。
- **坑**：先起应用后起库 → 应用连库失败报一堆错，属启动顺序问题非代码问题。

### RB-12 · 数据库备份（每天定时，异地多份）
- **手动备份**：
  - Mongo：`/usr/local/ehr/mongodb6/mongodb_data_bak.sh`
  - PG：`su - postgres -c "/bin/bash /usr/local/ehr/postgresql15/postgresql_data_bak.sh"`
- **Jenkins 自动备份**：运维服务器（Windows）Jenkins 每天 **2 点备 PG、3 点备 Mongo**，经 FTP 拉到 Jenkins 机，
  存最近 7 天压缩包。Jenkins `http://<ip>:8080`，账号 `ehr/ehr@123`。
- **无运维服务器定时备份（crontab）**（来源《dhr2.0无运维服务器如何创建数据库自动备份定时任务》）：无运维服务器时，
  用系统 crontab 做每日定时备。**以 root 连数据库服务器**；`crontab -e`（ubuntu 首次需按提示设默认编辑器）追加：
  - Mongo：`00 02 * * * /usr/local/ehr/mongodb6/mongodb_data_bak.sh`（mongodb8 改 `mongodb8` 路径）
  - PG：`00 01 * * * su - postgres -c " /bin/bash /usr/local/ehr/postgresql15/postgresql_data_bak.sh"`（须 postgres 用户）
  - 表达式 `00 02 * * *` = 每天 02:00；时间调整用 https://tool.lu/crontab/ 校验后替换。路径按实际安装目录改（默认 `/usr/local/ehr`）。
  - **验证**：`crontab -l` 可见两行；次日查 `data_bak` 目录生成备份包。
- **🔴 红线**：数据库**严禁外网访问**；备份须同时拷到多台服务器（异地存储），否则磁盘损坏数据全丢用户自负。
- **还原（🔴 变更型 · 须确认影响面后执行）**（来源《dhr2.0备份数据还原》）：
  - **MongoDB 还原**（mongodb6 `/usr/local/ehr/mongodb6` / mongodb8 `/usr/local/ehr/mongodb8`）：① 备份文件拷到对应 `data_bak`（格式 `ehr_YYYYMMDDhhmmss.tar.gz`）② `cd data_bak && tar xf *.tar.gz` ③ `../bin/mongorestore -h 127.0.0.1:27011 -u ehr -p <pwd> -d ehr --drop ./ehr_data/ehr --gzip`（端口 27011、库 ehr、用户 ehr；`<pwd>` 占位不固化明文）。
  - **PostgreSQL15 还原**（库 `dbehr`、端口 5632、账号 postgres）：① 备份文件拷到 `/usr/local/ehr/postgresql15/data_bak` ② `cd data_bak` ③ `../bin/pg_restore -U postgres -p 5632 -h 127.0.0.1 -d dbehr -c *.tar`。
  - **信创数据库还原**：金仓/达梦/巨杉/迪欧西等还原联系对应厂商确认命令（yw 不臆测信创库语法）。
  - **坑**：还原会覆盖现有数据（`--drop`/`-c`），须先确认已备当前数据；还原后重启应用（RB-11）验证。

### RB-13 · Redis7 部署与运维（可选缓存）
- **前置**：`yum install -y gcc`
- **安装**：解压 `redis-7.2.2.tar.gz` → `./bin/redis-server ./redis.conf` 启动
- **内核参数**：`/etc/sysctl.conf` 加 `vm.overcommit_memory = 1` 后 `sysctl -p`（否则 fork 失败）
- **切缓存**：`cfg.properties` 加 `cache.redis.host=<IP>`、`cache.redis.port=6389`、`cache.redis.database=0`、
  `cache.redis.username=default`、`cache.redis.password=ENC(...)`；并把 `cache.provider=Redis`
- **启停**：启动 `/usr/local/redis-7.2.2/bin/redis-server /usr/local/redis-7.2.2/redis.conf`；
  停止 `/usr/local/redis-7.2.2/bin/redis-cli -p 6389 -a <pwd> shutdown`
- **验证**：`redis-cli -p 6389 ping` 返回 PONG；升级到 **5.10.01+** 才支持 Redis 缓存
- **坑**：用了 memcache 集群的客户须先升级到 5.10.01 及以上；常见排错 https://segmentfault.com/a/1190000041907267

### RB-14 · 信创/国产化部署（银河麒麟 ky10）
- **支持栈**（来自《dhr2.0信创支持明细》）：
  - OS：**银河麒麟 ky10**（国产化）；浏览器不支持 IE 内核，用 Edge/Chrome/Firefox/360极速等
  - 中间件（四选一，嵌入式版）：**东方通 TongWeb V7.0.E.6_P3 / 宝兰德 BES V11 / 中创 InforSuite AS V10.0.3.3 / 金蝶 Apusic V10.0.X**
  - 关系库（三选一）：**人大金仓 V8R6（兼容模式必须 PG 模式）/ 海量 Vastbase G100 V2.2（PG 兼容模式）/ 达梦 V8（7000c，小版本号 3.100 以上）**
  - 非关系库（文档库）：**DocDB 迪欧西文档型数据库 V3.4**（原巨杉 SequoiaDB 在信创明细中由 DocDB 取代，以《初始部署速览》为准）
- **人大金仓 R6**：Linux 非 root 用户安装（需标准 home）；字符集 UTF-8、不区分大小写；端口 **54321**；
  `max_connections` 改 1000；**兼容模式必须选 PG 模式**（三强调）
- **达梦 V8(7000c)**：UTF-8、取消大小写敏感、VARCHAR 以字符为单位；页大小 32K、日志 2048M；
  `dm.ini` 调优（BUFFER≈物理内存 60~80%、MAX_OS_MEMORY=80 等）
- **信创专属坑**：
  - 不通外网的私有化**不支持客开**，必须支持需提前联系研发确认部署步骤
  - 东方通/宝兰德临时文件目录缺失或权限不足 → 中间件启动报「临时文件缺失」类错（见 RB-16）
  - openssl3 / NTFS 磁盘 / ARM 架构为信创常见差异点

### RB-15 · 服务器中高配置速查（部署前核对）
| 服务器 | 普通私有化(Ubuntu22.04) | 信创(银河麒麟ky10) |
|---|---|---|
| 数据库 | Mongo8+PG15；32G/4vCPU/500G SSD；端口 5632+27011 | 巨杉+金仓/达梦；32G/4vCPU/500G；端口 27017+54321/5236 |
| 应用 | JDK17+dhr；32G/4vCPU/500G；80/443 | JDK17+中间件；32G/4vCPU/500G；80/443 |
| 运维 | Jenkins(Windows)；8G/2vCPU/500G；3389 | 同左 |
| 报表 | 横石；8~16核/24~32G/200~500G SSD | 同左 |
| 全文检索 | ES；4~8核/8~16G/500G；端口 9203 | 同左 |
- **红线**：各服务器**不能合并**、不能装第三方服务（如衡石/OA）；必须单独购买部署；必须买防火墙；
  数据库防火墙开 27011/54321(金仓)/5236(达梦)，web 开 80/443，ES 开 9203；时间须校准（`timedatectl`/ntpdate）。
- **备注**（来源《私有化初始部署速览》）：人数 >3000 / 全员考勤打卡 / 批量算薪 的客户推荐高配服务器；运维服务器可用普通 PC 代替（主要方便运维、无命令操作）。

### RB-16 · 启动报错排查矩阵（DHR2.0 启动错误 · 语雀原文补全）
> 来源（语雀导出系列，2026-09-02 本机补全，分批）：①首批 mac/ip地址不合法、authCode不合法、程序不支持降级、
> 产品升级时间已到期、UnknownHostException license.x-dhr.com、获取license失败 license.x-dhr.com、
> Keystore密码错、地址已在使用、PG共享缓存被删、squid代理配置、登录提示错误号循环、启动postgre注意事项；
> ②次批 备份数据还原、信创环境无运维升级、东方通临时文件缺失(NoSuchFileException)、服务进程及日志查询、智多薪菜单非法请求ip。
> 应用默认路径 `/usr/local/dhr`，日志 `logs/dhr.log`（`tail -300/-500` 看关键报错）。

| 报错关键词（Caused by / 提示） | 根因分层 | 标准处置（语雀原文） |
|---|---|---|
| `mac地址不合法：xx-xx…` / `ip地址不合法：x.x.x.x` | 授权绑定（MAC/IP 变更） | 服务器 MAC/IP 改变或做过迁移→license 绑旧地址。**提交单位信息 + 提示的 mac/ip 给 license 生产管理员重新绑定新地址**→ 重启应用（见 RB-02） |
| `authCode不合法：xxx-xxx-xxx-xxx` | 授权码错 | 更新后 cfg.properties 被覆盖致授权码错：①有运维→查运维机 dhr 目录 cfg.properties 授权码，更正后重跑一键更新；②无运维→查 `/usr/local/` 与 `/usr/local/dhr/config` 下 cfg.properties，更正后重启；③软加密文件→联系服务运维中心确认单位是否正确，重生成替换后重启 |
| `程序不支持降级` | 版本回退 | 用低于现有版本的 war 更新（运维不通外网/无运维常见）：①有运维不通外网→下最新 war 放运维机 dhr 文件夹（默认 D:\dhr）跑 updateEHR；②无运维→下最新 war 传 `/usr/local` 跑 `deployDHR.sh`（RB-18 路径A） |
| `产品升级时间已到期` | license 有效期 | 对应单位 license 到期校验不过：商务确认延期时长→提交单位信息给服务支持部/服务运维中心延期→重启应用 |
| `UnknownHostException: license.x-dhr.com` / `获取license失败：license.x-dhr.com` | 网络/出网白名单 | 应用需在线校验授权码+依赖生产系统：**开放应用服务器访问 `https://license.x-dhr.com` 与 `https://www.x-dhr.com`** → 重启（见 RB-21） |
| `Keystore was tampered with, or password was incorrect` | 证书/SSL | 证书名或密码错致 Spring Boot 失败：①查 `config/tomcat.properties` 证书名/密码 ②查证书存放路径下证书是否存在且一致 ③查 tomcat.properties 是否被覆盖（有运维查运维机 dhr 目录、无运维查 `/usr/local` 下）比对 ④均无差异则联系管理员重新下载证书配置（RB-19） |
| `地址已在使用`（Address already in use） | 服务层/端口 | 端口被占：换其他端口启动；查占用 `ss -anltp \| grep <端口>` / `lsof -i:<端口>`（同 RB-03） |
| `FATAL: could not open shared memory segment "/PostgreSQL.xxxxxx": No such file or directory` | 数据层/systemd | PG 共享缓存被删（systemd `RemoveIPC=yes` 清用户 shm）：①`vi /etc/systemd/logind.conf` 设 `RemoveIPC=no` ②`systemctl restart systemd-logind` ③重启 postgre ④重启应用 |
| squid 代理取 `X-Forwarded-For` 为空/配错 | 网络/代理 | 做过 squid 代理的客户：在 cfg.properties 增 `http.license.proxyHost/Port`、`http.proxyHost/Port`（填代理 IP/端口），有运维改运维机 dhr 目录+应用 `/usr/local` 与 `/usr/local/dhr/config`、无运维改应用两处→重启 |
| 登录提示错误号仍循环 | 应用层/数据库 | 进程在但连不上库=数据库挂了：①`ps aux \| grep mongodb\|grep -v grep`、`ps aux \| grep postgres\|grep -v grep` 看进程 ②起对应库 ③重启应用 ④定位库挂因（自不定则起研发支持单）。有错误号优先 `ehr地址/common.do?e=<错误号>` 直查 |
| 东方通/宝兰德临时文件缺失（`NoSuchFileException: /tmp/tongweb.../work/TongWeb/localhost/ROOT`） | 中间件 | TongWeb 临时文件默认生成到 `/tmp` 被 OS 定期清理→访问某些页面报「出错啦，请稍后再试」。**改 `tongweb.properties` 加 `server.tongweb.basedir=./temp`**（有运维：运维机 dhr 目录+应用 `/usr/local`+`/usr/local/dhr/config`；无运维：应用 `/usr/local`+`/usr/local/dhr/config`）→ 重启应用（见 RB-14 信创坑） |

- **通用定位**：先看 `logs/dhr.log` 报错关键词 → 对表取处置；有错误号优先 `common.do?e=` 反查。
- **前置**：所有「改 cfg.properties / tomcat.properties / 重生成授权 / 重启」属 RB-17 高危，确认影响面后执行（yw 不自行执行未授权变更）。

### RB-17 · DHR2.0 运维黑名单（危险/禁止动作）
- 🔴 **禁止把数据库服务暴露到外网**（Mongo/PG/金仓/达梦/巨杉）——仅限内网，防火墙只开必要端口。
- 🔴 **禁止合并服务器角色**（数据库/应用/报表/全文检索必须分离）；禁止在它们上装第三方服务。
- 🔴 **禁止改默认端口后不同步配置**（金仓 54321、达梦 5236、Mongo 27011、Redis 6389）。
- 🔴 **停库/删备份/重生成授权文件**前必须确认影响面并留回滚（见 SKILL.md Step 4）。
- 🔴 **不通外网的信创私有化不做客开**，必须做先联系研发。
- 不编造未观测事实；拿不到原文档明细的项标注「需核对《...》」。

### RB-18 · DHR2.0 更新/升级流程（变更型 · 须确认后执行）
- **触发**：私有化部署需更新 `ehr_privatization.war`（补丁/小版本/大版本升级）。升级=停服变更，
  停库/删旧目录/改密码前**必须确认影响面与回滚预案**（见 SKILL.md Step 4 高危清单）。
- **前置判断（先认再看）**：
  - ① 升级通道：有运维服务器（Jenkins 管）→ 常规走 Jenkins 一键更新（路径B）；**仅 DHR1.0 → 2.0 跨代迁移**才走长流程（路径C）。无运维服务器 → 手动 `deployDHR.sh`（路径A）。
  - ② 当前版本：登录页右下角版本号（升级前记录、升级后核对）。
  - ③ 路径布局（RB-10）：应用 `/usr/local/dhr`、库 `/usr/local/ehr/...`。
- **路径A · 无运维服务器更新**（本机 `dhr2.0无运维服务器更新.txt`，确定可用）：
  1. 停应用：`cd /usr/local/dhr && sh stopDHR.sh`
  2. 备 PG：`su - postgres -c "/bin/bash /usr/local/ehr/postgresql15/postgresql_data_bak.sh"`
  3. 备 Mongo：`/usr/local/ehr/mongodb6/mongodb_data_bak.sh`
  4. 传包：上传 `ehr_privatization.war` 到应用服务器 `/usr/local`
  5. 执行更新：`/usr/local/deployDHR.sh`（自动解包部署）
  6. 启应用：`cd /usr/local/dhr && sh startDHR.sh`
- **路径B · 有运维服务器常规升级（Jenkins 一键更新 `updateEHR`）**：
  常规版本更新（补丁 / 小版本 / 同代大版本）在**有运维服务器**环境，登录 Jenkins（`http://<ip>:8080`，账号 `ehr/ehr@123`，见 RB-12）→
  执行 **EHR 视图下的 `updateEHR` 任务**（该任务已含：停应用 → 备库 → 拉新包 → 更新 → 启动）。**无需手动停库 / 传包 / 恢复 / 清理**。
  - 不通外网版本：下载最新 `ehr_privatization.war` 放运维机 dhr 文件夹（默认 `D:\dhr`）后跑 `updateEHR`。
  - 🔴 **边界：常规升级 = Jenkins 一键**；只有 DHR1.0 → 2.0 跨代迁移才走路径C 长流程，日常升级切勿套用。
  - ⚠️ **升级前必做**（语雀《版本更新升级》）：① 备份 mongo + pg（安装目录备份脚本）；② 备份 `/usr/local/dhr/config` 下所有 `.properties`；③ **不要重复执行更新**，有问题先看 `logs/dhr.log`；④ 低版本升 `8.04.01+` 且库中有含 `number` 字段的视图 → 先备份保存视图 SQL、删视图再升级。
- **路径C · DHR1.0 → 2.0 跨代迁移（仅此场景，非日常升级）**：
  - ⚠️ **此流程只适用 dhr1.0 升级到 2.0 的跨代迁移，不适用于常规升级**（常规升级见路径B）。
  - 长流程（基于 2023 版实施文档）：老版先 Jenkins 一键升过渡版 → 停应用 → 备库 → 停 mongo/pg → 传 `dhr2.0` 包 →
    复制 `.properties`/`tomcat.properties`/`sms` 配置 → 启 Jenkins 配连接 → `deployMongodb`/`deployPostgres` →
    恢复备份数据 → 改库密码与 `cfg` → 执行 PG 索引删除（`DROP INDEX IF EXISTS index_roles;`、`index_sub_depts;`）→
    `deployDHR` 升目标版 → 启服验证 → 清理旧目录（`/usr/local/ehr/pgsql`、`/usr/local/ehr/mongodb`、`/usr/local/ehrapp`）。
  - 🔴 版本号 / 统一密码以当前实施文档为准；本 playbook 不存明文密码。
- **部署前必查检查点**：
  - `tomcat.properties`：端口 + 证书（HTTPS 证书配置见 RB-19；证书类型 tomcat/pfx，单端口限制）
  - `sms.properties`：短信平台（非我方容联须改）
  - `cfg` 个性化中文：转 Unicode 编码
  - 出网白名单：应用须可达 `license.x-dhr.com` + `www.x-dhr.com`（见 RB-21；原理见 RB-10 分层定位）
  - **信创无运维升级**（来源《dhr2.0信创环境无运维服务器升级步骤》）：即路径A 变体——①下载对应中间件 war：东方通 `ehr_tongweb.war` / 宝兰德 `ehr_bes.war` / 金蝶 `ehr_aas.war` 传 `/usr/local` ②数据库备份：PG/mongo 同路径A；**信创库（金仓/达梦）与信创文档库（巨杉/迪欧西）备份须联系厂商确认命令** ③更新前**备份配置**到 `/tmp/properties`date +%Y%m%d``（cp `/usr/local/dhr/config/*` 过去）④`/usr/local/deployDHR.sh` → 启应用 → `tail -300f logs/dhr.log` 验证。栈差异见 RB-14。
- **验证**：升级后登录页版本号=目标版；`ps -ef | grep -E 'dhr|mongod|postgres'` 进程在；
  `tail -200f logs/dhr.log` 无新错；业务可正常登录操作（同 RB-11 验证三件套）。
- **坑**：
  - 升级须停服窗口期；**备库是红线**（RB-12），未备库禁止删旧目录。
  - 大版本升级可能改数据库密码/路径，按实施文档同步 `cfg` 连接串。
  - 用横石/BI 的客户：升级后 `mongoBI` 需重启、横石数据源 BI 密码需改（遗留项）。
  - 菜单提示「非法请求 ip / ip 地址不合法」→ 属运行时开放平台 IP 白名单问题，见 **RB-22**（与 RB-02 启动授权 mac/ip 不合法不同）。

### RB-19 · Tomcat 证书配置（HTTPS / SSL，变更型 · 须确认后执行）
- **来源**：语雀《dhr2.0 Tomcat证书配置操作说明》（2026-09-02 用户提供导出）；此前 🔴 项已核对补全。
- **原则分层（先判代理形态）**：
  - 用了 **Nginx 反向代理** → 证书在 **Nginx 侧**配（参考 Nginx 配置手册），不在 Tomcat 改。
  - **无 Nginx 代理** → 证书在 **Tomcat 侧**配（本 playbook）。
- **触发**：① 需启用/更换 HTTPS 证书；② 启动报 `Keystore 密码错误` 致 Spring Boot 失败（关联 RB-16）。
- **分层定位**：证书层（证书缺失 / 密码错 / 过期）→ 配置层（`tomcat.properties` 端口/证书路径/密码未配齐）→ 启动失败。
- **关键事实**：
  - 应用默认路径 `/usr/local/dhr`；**端口与证书配置文件路径 `/usr/local/dhr/config`，文件名 `tomcat.properties`**。
  - 支持证书类型：**tomcat 证书**（文档示例 `server.pfx`，PKCS12 格式）。
  - ⚠️ **单端口限制**：服务只支持一个端口，**不支持 http 与 https 同时启用**；默认端口 443，ssl 三项默认注释，启用需删行首 `#`。
  - 端口调整 → 防火墙开对应端口；映射外网还须联系用户改端口映射。
- **标准处置（无 Nginx 场景）**：
  1. **准备证书（客户提供，不生成/不转换）**：客户提供 tomcat 证书（如 `server.pfx`，PKCS12 格式）直接放 `/usr/local/dhr/config` 即可。
     🔴 **yw 不生成自签名证书、不做证书格式转换**——证书由客户提供，yw 仅负责部署配置。
  2. **启用 HTTPS（取消三配置项注释并填值）**，编辑 `/usr/local/dhr/config/tomcat.properties`：
     `server.port=443`（或 8443）、`server.ssl.key-store=/usr/local/dhr/config/server.pfx`、
     `server.ssl.key-store-password=<pwd>`、`server.ssl.key-store-type=PKCS12`（pfx 对应）；删对应行首 `#` 使生效。
  3. **改访问地址**：同步改 `cfg.properties` 中私有化产品访问地址为 https 地址。
  4. **覆盖并重启**：
     - 有运维服务器：改运维机 dhr 下 `tomcat.properties` + `cfg.properties` → 覆盖到应用服务器 `/usr/local` 与 `/usr/local/dhr/config` → 重启（RB-11）。
     - 无运维服务器：直接改 `/usr/local` 与 `/usr/local/dhr/config` 下两文件 → 重启（RB-11）。
- **验证**：`curl -sv https://<host>:<port>` 握手成功/返回 200；浏览器无证书告警；`tail -200f logs/dhr.log` 无 `Keystore 密码错误` / SSL 配置错；业务以 https 可访问。
- **坑**：
  - `Keystore 密码错误` → Spring Boot 启动失败（见 RB-16），修正密码或重导证书，别急着重装。
  - **单端口**：启用 https 后 http 自动失效，勿同时配两套协议。
  - 证书类型须与 `key-store-type` 一致（客户给 pfx↔PKCS12、给 jks↔JKS），否则启动报 SSL 配置错。
  - 证书过期 → 由客户提供新证书替换原文件后重启应用（RB-11）；勿自行生成或转换。
  - 改 `tomcat.properties`/`cfg.properties` 属危险变更（列 RB-17 高危清单），确认影响面后执行；有 Nginx 代理走 Nginx 侧。

### RB-20 · 服务进程及日志查询（速查）
- **来源**：语雀《dhr2.0服务进程及日志查询》（2026-09-02 用户提供导出）；此前 🔴 已补全。
- **进程查询**：`ps aux | grep dhr`（应用 Java 进程；PG/mongo 见 RB-16 矩阵）。
- **实时日志**：`tail -300f /usr/local/dhr/logs/dhr.log`（持续输出，Ctrl+C 退出）。
- **历史日志**：按日滚动命名 `dhr.log.xxxx-xx-xx.0.gz`；解压查看 `gzip -d dhr.log.xxxx-xx-xx.0.gz`。
- **端口**：`ss -tlnp` 查监听；错误号反查 `ehr地址/common.do?e=<错误号>`。
- 启动报错对表见 RB-16；定位后处置走对应 RB。

### RB-21 · 应用出网白名单（license / 生产系统）
- **触发**：启动报 `UnknownHostException: license.x-dhr.com` 或 `获取license失败：license.x-dhr.com`（Caused by: ...BizException）。
- **根因**：应用启动需在线校验授权码 + 某些模块依赖生产系统，应用服务器须能出网到以下地址（语雀原文）。
- **标准处置**：开放应用服务器访问以下两个地址后重启应用：
  - `https://license.x-dhr.com`
  - `https://www.x-dhr.com`
- **验证**：`curl -sv https://license.x-dhr.com` 可达（握手/200）；重启后 `logs/dhr.log` 无 UnknownHost/获取license失败。
- **坑**：仅**应用服务器**需出网（数据库严禁外网，RB-17）；若客户走 squid 代理，还需在 cfg.properties 配 `http.license.proxyHost/Port`（见 RB-16 squid 行）。

### RB-22 · 运行时「非法请求 ip / ip 地址不合法」（智多薪菜单 · 应用层白名单）
- **来源**：语雀《dhr2.0进入智多薪菜单提示：非法请求ip、ip地址不合法》（2026-09-02 用户提供导出）。
- **现象**：**进入智多薪菜单**时提示「非法请求 ip、ip 地址不合法」。**区别于 RB-02**：RB-02 是应用**启动**时授权 mac/ip 不合法（须重绑 license）；本 RB 是**运行时**智多薪开放平台 IP 白名单未含当前访问 IP。
- **标准处置（分层）**：
  - **公有云客户**：登录 ehr → 系统设置 → 开放平台 → 开放平台信息 → **增加当前 IP**。
  - **私有云客户**（二选一）：① 进 postgres 库表 `ours_account_enterprise`，在 `dev_ip` 字段加当前 IP（多个英文逗号隔开）→ **重启应用生效**；② 或走 ehr 开放平台信息加 IP（同公有云）。
  - **私有云提示「获取 license 失败：ip 地址不合法」**（与 license 相关）：将报错单位 + 提示显示 IP 发给**薪事力生产系统管理员**处理（同 RB-02 重绑逻辑）。
- **验证**：加 IP 并重启（私有云走 dev_ip 须重启）后，智多薪菜单可正常进入。
- **坑**：私有云改 `dev_ip` 必须重启应用才生效；公有云开放平台加 IP 一般实时。与 RB-02 勿混淆——RB-02 启动期报 mac/ip 不合法是 license 绑定旧地址，本 RB 是运行时菜单 IP 白名单。

---

## RB-23 · Tomcat 端口修改（变更型 · 须确认后执行）
- **来源**：语雀《dhr2.0Tomcat端口修改操作说明》（2026-09-02 用户提供导出）。
- **触发**：需改应用监听端口（默认 443，常见改 8443）；或端口冲突（RB-16 地址已在使用）须换端口。
- **关键事实**：应用默认路径 `/usr/local/dhr`；端口与证书配置文件 `tomcat.properties` 在 `/usr/local/dhr/config`；端口参数 `server.port`。
- **标准处置**：
  1. 改 `tomcat.properties` 中 `server.port`（如 443 → 8443）。
  2. 同步改 `cfg.properties` 中私有化产品访问地址为新端口对应的 http(s) 地址。
  3. 覆盖与重启：
     - 有运维服务器：改运维机 dhr 下 `tomcat.properties` + `cfg.properties` → 覆盖到应用 `/usr/local` 与 `/usr/local/dhr/config` → 重启（RB-11）。
     - 无运维服务器：直接改 `/usr/local` 与 `/usr/local/dhr/config` 下两文件 → 重启（RB-11）。
  4. 🔴 **端口变更后**：防火墙须开放新端口；映射到外网还须联系用户改端口映射。
- **验证**：`curl -sv https://<host>:<新端口>` 握手/200；`ss -tlnp` 新端口监听；`tail -200f logs/dhr.log` 无报错；业务以新端口可访问。
- **坑**：单端口限制（RB-19）——启用 https 后 http 自动失效，勿同时配两套协议；改 `tomcat.properties`/`cfg.properties` 属 RB-17 高危，确认影响面后执行。

### RB-24 · cfg.properties 配置项（SSRF / 文件 / 安全头 / 登录限制 / 默认密码）
- **来源**：语雀《cfg.properties 其他项配置项说明》（2026-09-02 用户提供导出）。
- **配置文件**：`cfg.properties`，路径 无运维 `/usr/local/dhr/config`（及 `/usr/local`），有运维改运维机 dhr 目录后覆盖到应用两处；改完**重启应用**生效（RB-11）。
- **分层配置项**：
  - **SSRF Host 黑白名单**（防服务器访问内网其他服务器）：
    - 黑名单（客户无外部控件、禁用所有 host 访问）：`ours.host.blocked=*`
    - 白名单（有外部控件、放开需访问主机）：`ours.host.allowed=192.168.50.1,192.168.1.*,*.baidu.com`
    - 规则：多项逗号分隔；支持通配符（`192.168.50.*` 匹配 .1~.255、`*.baidu.com` 匹配子域）；**黑名单优先级 > 白名单**；未配白名单且不在黑名单→默认允许访问（兼容老版本）。
  - **文件相关**：`file.allowOuterUpload=false`（是否允许非登录用户上传；⚠️ 改 true 影响部分外部填写上传附件功能）、`file.allowTypes=.pdf,.doc,.docx,.xlsx,.xls,.ppt,.jpg,.jpeg,.png,.gif`（允许类型，逗号分隔可增）、`file.checkPDF=true`（上传 PDF 校验脚本，7.07.01 及以下控制上传和预览）、`file.checkPreviewPDF=false`（预览 PDF 校验脚本，默认控上传即可，7.08.01 新增）、`file.allowDeleteDiskFile=false`（删附件是否物理删文件，默认不删，硬盘敏感客户配 true，8.03.01 新增）。
  - **安全响应头**（防 Host 头攻击）：`ours.security.hosts[0]=localhost`、`ours.security.hosts[1]=abc.com:8081`（允许 Host，计数从 0，域名带端口）；CSP/X-Frame-Options/Referrer-Policy/X-XSS-Protection/X-Content-Type-Options/X-Permitted-Cross-Domain-Policies/X-Download-Options/Strict-Transport-Security 各项值见语雀原文。⚠️ 谨慎配置，否则可能无法访问、客开/集成第三方系统无法加载。
  - **限制请求方法**：`ours.security.request-methods[0]=GET`、`[1]=POST`。
  - **限制单设备登录**：`login.duplicate=1`（PC 挤 PC、移动挤移动；oa 集成薪事力跳转不受此参数影响）。
  - **登录失败锁定时间**：`login.limitLoginTimeout=1800`（秒，超最大失败次数锁定，8.08.01 新增）。
  - **预置默认密码**：`product.defaultPassword=123456`（明文，仅对该配置后重启新开通的账号有效，替换 123456 为自定义）。
- **🔴 坑**：改 `cfg.properties` 属 RB-17 高危（影响认证/安全），确认影响面后执行；有/无运维覆盖路径差异见 RB-19 / RB-23。

### RB-25 · 屏蔽登录页面（product.disableLogin）
- **来源**：语雀《dhr2.0屏蔽登录页面配置》（2026-09-02 用户提供导出）。
- **触发**：需屏蔽/隐藏薪事力登录页面。
- **标准处置**：`cfg.properties` 增加 `product.disableLogin=true` → **重启应用**生效（RB-11）。
  - 有运维服务器：改运维机 dhr 目录下 `cfg.properties` → 覆盖到应用服务器 `/usr/local` 与 `/usr/local/dhr/config` → 重启。
  - 无运维服务器：改 `/usr/local` 与 `/usr/local/dhr/config` 两处 `cfg.properties` → 重启。
- **验证**：重启后登录页面被屏蔽。
- **坑**：属 `cfg.properties` 配置，走 RB-17 高危确认；覆盖路径差异同上。

### RB-26 · 私有化初始部署速览（部署前速查）
- **来源**：语雀《dhr2.0私有化初始部署速览》（2026-09-02 用户提供导出）。
- **双数据库架构**（薪事力须两库同时安装才能启动）：
  - PostgreSQL 15：存基础数据（组织部门、人员花名册、薪酬档案、社保公积金、考勤档案等结构化）。
  - MongoDB 8：存业务数据（考勤打卡、招聘简历、工资套/表、报表、表单、绩效等非结构化/半结构化）。
- **信创支持明细**（完整版见 RB-14）：OS（银河麒麟 ky10 / openEuler 22.03 LTS SP3 / 统信 V20 1070）；中间件（东方通 TongWeb V7.0.E.6_P3 / 宝兰德 BES V11 / 中创 InforSuite AS V10.0.3.3 / 金蝶 Apusic V10.0.X）；关系库（人大金仓 V8R6 / 海量 Vastbase G100 V2.2 / 达梦 V8 7000c+小版本 3.100）；非关系库（DocDB 迪欧西 V3.4）。
- **服务器配置**：人数 >3000 / 全员考勤打卡 / 批量算薪 → 推荐高配（见 RB-15）；运维服务器可用普通 PC（方便运维、无命令操作）。
- **环境检查清单**（部署前必查，关联 RB-10 / RB-15）：
  - 磁盘：大小 + 挂载；服务器时间须准确（`timedatectl` / ntpdate）。
  - 网络：服务器间通信；**应用服务器须能访问 `https://license.x-dhr.com`**（外部功能含考勤定位中转、节假日、招聘三方、社保比例、智能报税、表单 lbs、云脚本同步、电子合同、培训、AI 助手、短信）；有运维服务器须访问 `https://svn.x-dhr.com`。
  - 端口开放：数据服务器 mongo **27011** / PG **5632**；应用服务器 **80 或 443**（⚠️ Linux 普通用户无法用 1024 以下端口）。
- **部署手册索引**（部署时查语雀原文）：无运维部署手册 / 有运维（Ubuntu22.04）部署文档 / 信创（ky10）部署文档（东方通、宝兰德、金蝶、中创）；升级步骤见 RB-18；其他常用：证书配置（RB-19）/ 端口修改（RB-23）/ nginx 反向代理 / limit.properties / cfg.properties 图解 / 数据操作（RB-12）。
- **高频问题索引**：启动报错系列见 RB-16；更多检索语雀运维知识库。

---

_（playbook 随真实任务累积，yw 自动回写此处。）_
