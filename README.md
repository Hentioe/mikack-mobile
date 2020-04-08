# Mikack for Mobile

Mikack 是一款开源的漫画阅读器，为将 [mikack](https://github.com/Hentioe/mikack) 生态圈扩展到移动平台而诞生。

## 技术参考

本软件的核心功能使用 Rust 语言实现，由 Flutter 框架构建客户端。

_注：Flutter 是跨平台的框架，但本项目的第一级支持目标目前只有 Android 平台。_

### 一些细节

为了将单线程模型的 Dart 语言和大量线程阻塞的 FFI 调用糅合成为靠谱的应用程序，本项目大量使用 Isoate API。

为避免 UI 文件中参与过多的业务逻辑，代码架构正逐步向 [BLoC 模式](https://www.didierboelens.com/2018/08/reactive-programming---streams---bloc) 迁移。

## 功能截图

| 书架 | 阅读 | 仓库 |
|---|---|---|
| ![1 shadow](https://user-images.githubusercontent.com/13946976/78420323-95d6df80-7680-11ea-8408-5db0ab332c8f.png) | ![2 shadow](https://user-images.githubusercontent.com/13946976/77260100-cb62ec80-6cc0-11ea-9699-5d5497548cb2.png) | ![3 shadow](https://user-images.githubusercontent.com/13946976/78420326-9e2f1a80-7680-11ea-9d9e-80ebc9c0eeb6.png) |

## 功能说明

- 全局搜索漫画，灵活过滤上游，轻松查找资源
- 指定图源入口访问资源列表，可连续翻页持续加载
- 收藏漫画于本地书架，批量检查书架更新
- 阅读历史，上次阅读位置，章节已阅标记
- 智能章节分组，基于组内的排序和批量标记

## 目前的不足

1. 不支持跳页。这是历史原因，很快会被解决。

## 当前状态

现在项目已趋近于稳定，欢迎大家前往 [https://github.com/Hentioe/mikack-mobile/releases](releases) 页面下载安装包试用。
