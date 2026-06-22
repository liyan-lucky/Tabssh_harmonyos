# 上游参考源码

三份仓库于 2026-06-22 以 `--depth 1` 浅克隆到 `%VSCODE_ROOT%\99_Temp\tabssh_reference`，不进入 HarmonyOS Git 仓库、不作为子模块或直接构建输入。

| 用途 | 本地路径 | Origin | 当前 HEAD |
|---|---|---|---|
| 官网/功能说明 | `tabssh_reference\tabssh.github.io` | `https://github.com/tabssh/tabssh.github.io.git` | `54298277bc57fb046f2ca1c1eeb8554adf30fe63` |
| Android 功能主参考 | `tabssh_reference\android` | `https://github.com/tabssh/android.git` | `0c455b8b4675d0c36b15778c919e12d10ce5bfba` |
| Desktop 交互参考 | `tabssh_reference\desktop` | `https://github.com/tabssh/desktop.git` | `79123c85ff74b3862ea53e49e57731e878f083d5` |

更新使用：

```powershell
git -C F:\Visual_Studio_Code\99_Temp\tabssh_reference\tabssh.github.io pull --ff-only
git -C F:\Visual_Studio_Code\99_Temp\tabssh_reference\android pull --ff-only
git -C F:\Visual_Studio_Code\99_Temp\tabssh_reference\desktop pull --ff-only
```

每次更新后记录新 HEAD 和日期。上游可能有不同许可证、平台假设和安全模型；复制或改写代码前必须检查对应许可证并在提交中记录来源。现有 `99_Temp\tabssh.github.io-main` 是早期共享快照，保持不动，后续统一使用本文件列出的三个路径。
