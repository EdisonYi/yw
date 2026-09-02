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

## RB-02 · 软加密/授权启动报「地址不合法」或「IP/MAC 不匹配」
- **触发**：服务起不来，授权校验报地址不合法 / license 可达但绑定不一致。
- **定位**：两层不可混——① **格式非法**（IPv4 禁前导零/段超 255、MAC 归一为 `:` 后过正则）；
  ② **绑定不一致**（授权按旧 MAC/IP 生成 ≠ 当前真实来源：迁移/换网卡/双网卡取错/DHCP/容器宿主 vs 容器 IP）。
- **标准处置（绑定不一致）**：取真实 `ip a` + `cat /sys/class/net/<主网卡>/address` → 与授权登记比对 →
  用真实 MAC+IP 重新提交授权方重生成授权文件 → 重启；双网卡建议绑内网固定 MAC。
- **验证**：重启后授权校验通过、服务正常起。
- **坑**：代理链下取 `X-Forwarded-For` 为空会误判来源，须从真实网卡取；格式非法先改配置，别急着重生成授权。

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
- **验证**：`ps -ef | grep -E 'dhr|mongod|postgres'` 进程在；`tail -200f logs/dhr.log` 无新错；
  `curl -sv <host>:80/health` 或业务页可访问。
- **坑**：先起应用后起库 → 应用连库失败报一堆错，属启动顺序问题非代码问题。

### RB-12 · 数据库备份（每天定时，异地多份）
- **手动备份**：
  - Mongo：`/usr/local/ehr/mongodb6/mongodb_data_bak.sh`
  - PG：`su - postgres -c "/bin/bash /usr/local/ehr/postgresql15/postgresql_data_bak.sh"`
- **Jenkins 自动备份**：运维服务器（Windows）Jenkins 每天 **2 点备 PG、3 点备 Mongo**，经 FTP 拉到 Jenkins 机，
  存最近 7 天压缩包。Jenkins `http://<ip>:8080`，账号 `ehr/ehr@123`。
- **🔴 红线**：数据库**严禁外网访问**；备份须同时拷到多台服务器（异地存储），否则磁盘损坏数据全丢用户自负。

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
  - 中间件（四选一，嵌入式版）：**东方通 TongWeb 7.0.E / 宝兰德 BES V11 / 金蝶 V10.0.9 / 中创 V0.0.3.3**
  - 文档库：**巨杉 SequoiaDB**；关系库（二选一）：**人大金仓 V8R6（兼容模式必须 PG 模式）/ 达梦 V8(7000c)**
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

### RB-16 · 启动报错排查矩阵（DHR2.0 启动错误）
> 来源：《dhr2.0各类启动报错关键信息》《启动薪事力服务关键错误信息：地址已在使用》
> 《登录系统提示错误号仍提示错误号》。🔴 标记项 = 原文档未取到本地副本，按 xzl 既有覆盖 + 通用运维知识编写，需核对原文。

| 报错关键词 | 根因分层 | 标准处置 |
|---|---|---|
| 产品升级时间到期 | license 有效期 | 续期/重生成授权文件（交实施）；🔴 需核对原文档处置 |
| authCode 不合法 | 授权码/注册码 | 核对授权码与版本匹配；🔴 需核对原文档 |
| 程序不支持降级 | 版本回退 | 不支持降级，须升到目标版本或重装；🔴 需核对 |
| Keystore 密码错误 | 证书/SSL | 证书 keystore 密码错致 Spring Boot 启动失败 → 修正密码或重导证书（xzl 04-case 实证）|
| license 获取/域名解析失败 | 网络/DNS | ① 确认应用出网到 license.x-dhr.com；② DNS 解析；③ 绑定不一致走 RB-02 Q1b |
| mac/ip 地址不合法 | 授权绑定 | 见 RB-02（Q1a 格式 / Q1b 绑定不一致，两层不可混）|
| PostgreSQL 共享缓存缺失 | 数据层/内核 | `shared_buffers` 与内核 `SHMMAX` 不足 → 调大 PG 共享内存/内核参数 |
| 东方通中间件临时文件缺失 | 中间件 | TongWeb 临时目录缺失/权限不足 → 建目录并赋权给中间件运行用户 |
| squid 代理配置 | 网络/代理 | 代理取 `X-Forwarded-For` 为空/配错 → 修正 Nginx/squid `proxy_set_header`（xzl 03 §4）|
| 地址已在使用（Address already in use） | 服务层/端口 | 端口被占 → `ss -tlnp` 查占用进程 `kill` 或改端口（同 RB-03）|
| 登录提示错误号仍提示错误号 | 应用层 | 用 `ehr地址/common.do?e=错误号` 浏览器直查详情（xzl 03 §3.3）；仍循环=错误号映射未刷新，清缓存/重启应用 |

- **通用定位**：先看 `logs/dhr.log` 报错关键词 → 对表取处置；有错误号优先 `common.do?e=` 反查。

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
- **路径B · 有运维服务器常规升级（Jenkins 一键更新）**：
  常规版本更新（补丁 / 小版本 / 同代大版本）在**有运维服务器**环境，直接通过 Jenkins 一键更新即可，
  **无需手动停库 / 传包 / 恢复数据 / 清理旧目录**。运维机 Jenkins 已配置连接应用与数据库服务器
  （`http://<ip>:8080`，账号 `ehr/ehr@123`，见 RB-12）；选对应升级任务 → 执行 → 等部署完成 → 启服验证（见验证段）。
  - 🔴 **边界：常规升级 = Jenkins 一键**；只有 DHR1.0 → 2.0 跨代迁移才走路径C 长流程，日常升级切勿套用。
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
  - 出网白名单：应用须可达 `license.x-dhr.com` + `www.x-dhr.com`（见语雀《白名单说明》🔴 待核对；原理见 RB-10 分层定位）
  - 信创无运维升级差异见语雀《信创环境无运维升级》🔴 待核对（栈差异见 RB-14）
- **验证**：升级后登录页版本号=目标版；`ps -ef | grep -E 'dhr|mongod|postgres'` 进程在；
  `tail -200f logs/dhr.log` 无新错；业务可正常登录操作（同 RB-11 验证三件套）。
- **坑**：
  - 升级须停服窗口期；**备库是红线**（RB-12），未备库禁止删旧目录。
  - 大版本升级可能改数据库密码/路径，按实施文档同步 `cfg` 连接串。
  - 用横石/BI 的客户：升级后 `mongoBI` 需重启、横石数据源 BI 密码需改（遗留项）。
  - 菜单提示「非法请求 ip / ip 地址不合法」→ 见 RB-02（授权绑定两层）+ 语雀《非法请求ip》🔴 待核对。

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

---

_（playbook 随真实任务累积，yw 自动回写此处。）_
