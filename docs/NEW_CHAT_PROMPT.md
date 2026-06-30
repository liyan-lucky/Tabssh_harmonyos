# 新对话提示词

复制下面内容到新对话：

```text
继续 OpenTabSsh HarmonyOS 项目。项目根为 E:\Visual_Studio_Code\10_Tabssh_harmonyos。

先完整读取 docs\AGENT_HANDOFF.md，再严格按 docs\README.md 的必读顺序阅读全部项目资料；随后检查 git status、当前分支、远端同步状态和完整 diff，保留所有未提交修改，不得重置或覆盖用户工作。

所有构建、测试、日志、下载、备份和临时证据统一放在 E:\Visual_Studio_Code\99_Temp 的 TabSSH 专属子目录，严格遵守 docs\WORKSPACE_PATHS.md。99_Temp 是多项目共享目录，禁止整体清理，任何 APK 都不得删除，也不得触碰 RustDesk、TabSSH Android 或其他项目内容。

当前工程已有 Mock fallback 和真实 Core HAP 构建/部分 SSH/SFTP 证据，但绝不能把 Mock 返回、页面存在或函数名存在当作真实功能完成。工作台右上角现在是工具箱，工作台主机列表直接显示已保存主机；第四个底部 Tab 已改为“设置”，系统设置内容直接展开，工具箱入口位于“设置 / 工具 / 工具箱”；顶部 Logo/标题区已改为半透明渐变过渡并继续贴近安全区，底部 Tab 区为半透明 Thin blur 胶囊，关于页显示 BuildInfo 版本与构建时间。工具箱首批纯 ArkTS/纯 HarmonyOS 工具已支持 JSON、Base64/Hash、文本、颜色、单位、系统/存储/IP 基础信息、公网 IP、访问审计跳转、默认网络/DNS/网关摘要、TCP 连通性探测、端口扫描、HTTP 下载样本测速、Nginx 配置摘要和 QR 负载摘要，其中网络拓扑、端口扫描和公网 IP 已有 Real HAP 输出，HTTP 测速/连通性/Nginx/QR 点击证据与主动子网发现、上传测速、二维码图片矩阵等仍待；浅色/深色、中文/English 和系统语言跟随偏好已覆盖主壳/工作台/设置 Tab/设置/工具箱/关于/终端设置/连接历史/访问日志/连接分组/导入导出/连接编辑/终端/SFTP/端口转发，系统语言跟随已有设置 Tab 点击和强停重启证据，仍需无障碍/高对比和完整多页面切换矩阵。优先继续贯通 libssh2/OpenSSL/zlib 双架构、HostKey 与密码/私钥安全、真实 shell/PTY 非阻塞读写、终端渲染、SFTP、local/remote/dynamic forwarding、重连、错误恢复、断开资源清理、工具箱剩余网络类能力和主题/语言验收；随后在 arm64 真机与 x86_64 模拟器完成端到端验证。

线上构建有四个手动 workflow：先用 test-harmonyos-sdk-token.yml 预检 HARMONYOS_SDK_TOKEN，再按需要运行 online-build.yml 的 4-package unsigned HAP 格式验证或 build-harmonyos.yml 的 HAP 构建/可选 Release；cleanup-releases.yml 只能在明确需要清理线上资产时运行。上述 workflow 仍缺本仓库成功 run 证据，不能写成发布链路完成。

上游参考源码位于 E:\Visual_Studio_Code\99_Temp\tabssh_reference：tabssh.github.io、android、desktop。先按 docs\UPSTREAM_REFERENCES.md 核对各仓库 origin 与 commit；只作行为、UI 和协议参考，不把它们当成本仓库子模块或构建输入，不修改其远端，不混用旧的 tabssh.github.io-main 目录。遇到联网失败时等待 5 分钟再试，最多重试 3 次。

密码、私钥、私钥口令、token 和服务器凭据只能在测试运行内存中使用，禁止写入源码、日志、文档、截图、备份说明或提交说明。所有未实现入口必须提示开发中或明确标注 Mock。所有新增/替换图标必须从 ProIcons 官网或已登记的 ProIcons 资产获取，优先使用彩色配色版本，禁止自建 SVG、Emoji 或字符图标。

本项目不要求机械重复多轮审计。每次重要修改和最终发布前执行一次完整审计、全量构建、双设备安装与相关功能检查。功能、路径、构建、测试、清理或发布状态变化后立即同步文档。完成后精准清理项目专属可再生产物，保留全部 APK 和线上验证资产，生成最新备份，提交推送并下载复验线上 Release；全部非明确搁置需求完成前不要停止。
```
