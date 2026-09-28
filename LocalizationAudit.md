# Localization Audit — 硬编码字符串清单

> 扫描日期: 2026-02-16
> 状态: v1.0 — 首次发布前审查

## 结论

共发现 **49 处**硬编码中文字符串分布在 **12 个视图文件**中。
当前阶段 App 仅面向中文用户，因此暂不迁移到 `.strings` 文件。
本文档作为日后国际化的迁移清单。

---

## 📍 按文件分类

### 1. SecurityView.swift (5 处)
| 行号 | 原文 | 建议 Key |
|------|------|----------|
| 48 | `"请验证身份以继续"` | `security.verify_identity` |
| 76 | `"此设备未设置锁屏密码或生物识别"` | `security.no_auth_available` |
| 80 | `"安全锁定已自动关闭"` | `security.auto_disabled` |
| 113 | `"使用设备密码解锁"` | `security.use_passcode` |
| 125 | `"生物识别已暂时锁定，N秒后可重试"` | `security.biometric_lockout` |

### 2. WarningView.swift (5 处)
| 行号 | 原文 | 建议 Key |
|------|------|----------|
| 27 | `"内容警告"` | `warning.title` |
| 34 | `"本应用可能包含成人内容..."` | `warning.content_description` |
| 44 | `"继续使用本应用即表示您确认..."` | `warning.confirmation_text` |
| 63 | `"我已年满 18 周岁，同意继续"` | `warning.accept_button` |
| 72 | `"离开"` | `warning.reject_button` |

### 3. SelectSiteView.swift (5 处)
| 行号 | 原文 | 建议 Key |
|------|------|----------|
| 24 | `"欢迎使用 EhViewer"` | `site_select.welcome` |
| 29 | `"请选择默认访问的站点"` | `site_select.choose_site` |
| 54 | `"您可以稍后在设置中更改此选项"` | `site_select.change_later` |
| 60 | `"ExHentai 需要特定账号权限才能访问"` | `site_select.exh_warning` |
| 75 | `"开始使用"` | `site_select.start_button` |

### 4. RootView.swift (5 处)
| 行号 | 原文 | 建议 Key |
|------|------|----------|
| 84 | `"您已拒绝使用条款"` | `root.terms_rejected` |
| 122 | `"检测到你的账号拥有 ExHentai 访问权限..."` | `root.exh_upgrade_prompt` |
| 135 | `"磁盘剩余空间不足..."` | `root.disk_space_warning` |
| 147 | `"igneous Cookie 已失效..."` | `root.igneous_expired` |
| 185 | `"剪贴板含有画廊链接..."` | `root.clipboard_gallery` |

### 5. GalleryDetailView.swift (8 处)
| 行号 | 原文 | 建议 Key |
|------|------|----------|
| 348 | `"标签"` | `detail.tags_section` |
| 379 | `"请在设置中更新标签翻译数据库"` | `detail.update_tag_db` |
| 430 | `"预览"` | `detail.preview_section` |
| 444 | `"查看全部 (N张)"` | `detail.view_all_pages` |
| 513 | `"评论"` | `detail.comments_section` |
| 528 | `"更多评论"` | `detail.more_comments` |
| 537 | `"暂无评论"` | `detail.no_comments` |
| 905 | `"评分"` | `detail.rating_title` |

### 6. FavoritesView.swift (5 处)
| 行号 | 原文 | 建议 Key |
|------|------|----------|
| 187 | `"暂无本地收藏"` | `favorites.no_local` |
| 256 | `"本地收藏 (N)"` | `favorites.local_count` |
| 280 | `"查看全部 N 个本地收藏"` | `favorites.view_all_local` |
| 430 | `"全部"` | `favorites.tab_all` |
| 445 | `"本地收藏"` | `favorites.tab_local` |

### 7. HistoryView.swift (1 处)
| 行号 | 原文 | 建议 Key |
|------|------|----------|
| 45 | `"浏览过的画廊会显示在这里"` | `history.empty_description` |

### 8. QuickSearchView.swift (4 处)
| 行号 | 原文 | 建议 Key |
|------|------|----------|
| 24 | `"点击右上角添加常用搜索词"` | `quicksearch.empty_hint` |
| 106 | `"快速搜索"` | `quicksearch.title` |
| 136 | `"暂无快速搜索"` | `quicksearch.empty_title` |
| 202 | `"不限"` | `quicksearch.no_limit` |

### 9. FilterView.swift (2 处)
| 行号 | 原文 | 建议 Key |
|------|------|----------|
| 54 | `"已启用"` | `filter.enabled` |
| 57 | `"没有启用的过滤器"` | `filter.none_enabled` |

### 10. LoginView.swift (1 处)
| 行号 | 原文 | 建议 Key |
|------|------|----------|
| 72 | `"登录"` | `login.button` |

### 11. MainTabView.swift (1 处)
| 行号 | 原文 | 建议 Key |
|------|------|----------|
| 104 | `"选择画廊"` | `main.select_gallery` |

### 12. GalleryCommentsView.swift (1 处)
| 行号 | 原文 | 建议 Key |
|------|------|----------|
| 139 | `"最后编辑: ..."` | `comments.last_edited` |

---

## 🎨 颜色审查结论

`.foregroundStyle(.white)` 共出现 21 处，**全部合规**:
- **阅读器** (ImageReaderView.swift × 15): 背景始终为黑色/深色，白色文字正确
- **分类标签** (GalleryDetailView / GalleryListView / FavoritesView × 3): 彩色背景上的白色文字，正确
- **图片重试图标** (CachedAsyncImage × 1): 覆盖在图片上，带 shadow，正确
- **GalleryListView × 1**: 同分类标签场景

**结论**: 无需修改，所有白色使用均有合理的深色背景保证可见性。

---

## 🧹 TODO / Dead Code 清单

共 **15 个 `// TODO: Connect to Logic`** 集中在 `SettingsView.swift`:

```
Line 167: detailSize 未被 GalleryDetailView 读取
Line 234: cellularNetworkWarning 未被网络层检查
Line 245: defaultCategories/excludedTagNamespaces/excludedLanguages 未作为 URL 参数发送
Line 274: builtExHosts 未被 EhDNS 读取
Line 335: showGalleryPages 未被列表视图读取
Line 348: showGalleryRating 未被详情页读取
Line 356: showReadProgress 未被列表视图读取
Line 364: thumbSize 未被列表/图片视图读取
Line 376: thumbResolution 未被任何代码读取
Line 387: fixThumbUrl 未被图片加载代码读取
Line 530: volumePage/reverseVolumePage 未被 ImageReaderView 读取
Line 563: colorFilter/colorFilterColor 未被 ImageReaderView 读取
Line 600: imageResolution 未作为请求参数发送
Line 618: mediaScan 是 Android 概念，iOS 无意义
Line 750: saveParseErrorBody 未被解析器读取
```

**建议**: 这些是 v1.1 待连接的设置项，保留 TODO 注释作为开发路线图。
若要删除 Android 无意义项 (mediaScan)，可手动移除 Line 618 的 Toggle 及注释。

---

## 快速定位命令

```bash
# 列出所有 TODO
grep -rn "// TODO:" "ehviewer nya/" --include="*.swift"

# 列出所有硬编码中文
grep -rn 'Text("[^"]*[\x{4e00}-\x{9fff}]' "ehviewer nya/" --include="*.swift"

# 列出残留 print()  (排除 debugLog)
grep -rn 'print(' "ehviewer nya/" --include="*.swift" | grep -v debugLog | grep -v LogManager | grep -v '#Preview'
```
