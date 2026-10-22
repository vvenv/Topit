# 本地维护说明

上游 [lihaoyun6/Topit](https://github.com/lihaoyun6/Topit) 基本不再维护，这个 fork（[vvenv/Topit](https://github.com/vvenv/Topit)）用于自行修复和本地编译。

## 编译安装

```bash
scripts/build-local.sh
```

脚本会编译 Release、重新签名、替换 `/Applications/Topit.app`、关闭 Sparkle 自动更新并重置权限。完成后需要在「系统设置 → 隐私与安全性」重新开启「录屏与系统录音」和「辅助功能」，再重启 Topit。

注意事项：

- 本机没有开发者证书，只能 ad-hoc 签名。主程序因此不能启用 hardened runtime，否则会因 Team ID 不一致加载 Sparkle.framework 失败、启动即崩溃。
- 签名在原文件上修改不生效（内核缓存），必须整体拷贝新的 `.app`。
- 每次重新编译，签名都会变，权限都要重新授权。
- 不要开启 Sparkle 自动更新，上游发版会覆盖本地修改。

## 本地修改

| 提交 | 说明 | 上游 PR |
| --- | --- | --- |
| `fb73d04` | 修复副屏上切换桌面后 pin 失效（浮层被移到新桌面、录屏仍在继续） | [#44](https://github.com/lihaoyun6/Topit/pull/44) |

### 副屏切换桌面后 pin 失效

在非主屏上切换 Space 时，系统播放滑动动画，`CGWindowListCopyWindowInfo` 报告的是动画中的坐标。`OverlayView` 的位置同步计时器把它当作源窗口移动，在过渡期间对浮层调用 `setFrame`，导致浮层被归到新激活的 Space。修复方法是新增 `isSpaceTransitioning(_:)`（`Topit/Supports/Accessibility.swift`）：浮层自身在 CGWindowList 中的坐标与 `frame` 不一致时，说明正在过渡，跳过本次同步。

## 回退

原版 0.1.4 备份在 `~/vvenv/backup/Topit-0.1.4.app`。
