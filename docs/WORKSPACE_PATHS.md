# 工作区路径与清理规范

`%VSCODE_ROOT%` 表示包含 `10_Tabssh_harmonyos` 与 `99_Temp` 的工作区根；当前机器是 `F:\Visual_Studio_Code`。脚本必须从项目位置推导根目录，不能把盘符或用户名写死到源码。

| 用途 | 唯一路径 |
|---|---|
| 项目源码 | `%VSCODE_ROOT%\10_Tabssh_harmonyos` |
| 干净构建副本 | `%VSCODE_ROOT%\99_Temp\harmonyos_stage\10_Tabssh_harmonyos` |
| HAP/APP 输出 | `%VSCODE_ROOT%\99_Temp\harmonyos_build\10_Tabssh_harmonyos` |
| 构建/测试日志 | `%VSCODE_ROOT%\99_Temp\tabssh_harmonyos_logs` |
| 三方源码/编译缓存 | `%VSCODE_ROOT%\99_Temp\tabssh_harmonyos_dependencies` |
| 项目备份 | `%VSCODE_ROOT%\99_Temp\tabssh_harmonyos_backups`（只保留最新 2 份） |
| 线上资产复验 | `%VSCODE_ROOT%\99_Temp\release_inspect\10_Tabssh_harmonyos` |
| 上游参考源码 | `%VSCODE_ROOT%\99_Temp\tabssh_reference\{tabssh.github.io,android,desktop}` |

`99_Temp` 由多个项目共享：禁止整体删除、移动、重命名或全局按扩展名清理；根目录和任何子目录中的 APK 全部保留。`tabssh_backups`、`tabssh.github.io-main` 以及其他未列入本表的目录不自动视为本项目可清理项。

`tabssh_reference` 三个目录只允许 `git pull --ff-only` 更新或在明确授权后重新克隆，不属于 `clean_project.ps1` 的清理范围。现有共享目录 `tabssh.github.io-main` 保持原样，新项目统一以 `tabssh_reference\tabssh.github.io` 为参考路径。

允许删除的仓库内可再生项仅包括：`.appanalyzer`、`.codeartsdoer`、`.hvigor`、`.hvigor_home`、`.idea`、`.vscode`、`build`、`entry/build`、`entry/.cxx`、`entry/.preview`、`oh_modules`、`entry/oh_modules`、`node_modules`、`*.dmp`、`*.log`、`*.tmp`。`local.properties` 只忽略、不公开提交；需要构建时保留在本机并复制到 stage。

DevEco 签名材料只能放在 `99_Temp` 的 TabSSH 专属私有目录或用户级安全存储，严禁进入仓库。`.p12`、`.p7b`、`.cer`、`.jks`、`.keystore`、`.pem`、`.key`、`.csr`、`signing/` 和 `.idea/` 均被忽略；口令不得出现在 build-profile、脚本、文档或提交记录。

构建前使用 `scripts/stage_project_for_build.ps1`。清理使用 `scripts/clean_project.ps1`，外部清理必须显式指定 `-IncludeExternalBuild`，且脚本只能触碰本表的 TabSSH 专属路径。
