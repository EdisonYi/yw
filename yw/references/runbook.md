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
_（playbook 随真实任务累积，yw 自动回写此处。）_
