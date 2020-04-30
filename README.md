# Mikack for Mobile

[![GitHub release (latest by date)](https://img.shields.io/github/v/release/Hentioe/mikack-mobile)](https://github.com/Hentioe/mikack-mobile/releases/latest)
[![GitHub license](https://img.shields.io/github/license/Hentioe/mikack-mobile)](https://github.com/Hentioe/mikack-mobile/blob/master/LICENSE)
[![GitHub issues](https://img.shields.io/github/issues/Hentioe/mikack-mobile)](https://github.com/Hentioe/mikack-mobile/issues)
[![Telegram chat link](https://img.shields.io/badge/%E5%8A%A0%E5%85%A5-Telegram%20%E7%BE%A4%E7%BB%84-brightgreen.svg)](https://t.me/mikack)

Mikack 是一款开源的漫画阅读器。针对移动设备设计，实用且具有参考价值。

## 技术介绍

本软件的核心功能使用 Rust 语言实现，由 Flutter 框架构建客户端。是跨平台的 [mikack](https://github.com/Hentioe/mikack) 生态对移动领域的扩展。作为周边项目的一员，是支持程度最高的上层应用。

本应用是 Rust 参与 Flutter 应用开发的现实案例。

参考性：

1. Rust C ABI 导出和 Dart FFI 绑定
1. 对 [BLoC](https://www.didierboelens.com/2018/08/reactive-programming-streams-bloc/) 模式的完整实践

_注：Flutter 是跨平台的框架，但本项目的第一级支持目标当前只有 Android 平台。_

## 功能截图

| 书架                                                                                                              | 阅读                                                                                                              | 仓库                                                                                                              |
| ----------------------------------------------------------------------------------------------------------------- | ----------------------------------------------------------------------------------------------------------------- | ----------------------------------------------------------------------------------------------------------------- |
| ![1 shadow](https://user-images.githubusercontent.com/13946976/78420323-95d6df80-7680-11ea-8408-5db0ab332c8f.png) | ![2 shadow](https://user-images.githubusercontent.com/13946976/77260100-cb62ec80-6cc0-11ea-9699-5d5497548cb2.png) | ![3 shadow](https://user-images.githubusercontent.com/13946976/78420326-9e2f1a80-7680-11ea-9d9e-80ebc9c0eeb6.png) |

为什么和 Tachiyomi 这么相似？[有什么区别吗？](https://github.com/Hentioe/mikack-mobile/wiki/%E5%92%8C-Tachiyomi-%E7%9A%84%E5%8C%BA%E5%88%AB)

## 功能说明

- 全局搜索漫画，灵活过滤上游，轻松查找资源
- 指定来源入口访问资源列表，可连续翻页持续加载
- 收藏漫画于本地书架，批量检查书架更新
- 阅读历史，上次阅读位置，章节已阅标记
- 智能章节分组，基于组内的排序和批量标记

## 目前的不足

当前有一个显著的缺陷，它会导致跳页延迟较高。详细原因请[参考这里](https://github.com/Hentioe/mikack-mobile/wiki/%E9%A1%B5%E9%9D%A2%E8%BF%AD%E4%BB%A3%E5%99%A8%E5%B8%A6%E6%9D%A5%E7%9A%84%E9%97%AE%E9%A2%98)。

## 当前状态

项目已趋近于稳定，欢迎大家从 [Releases](https://github.com/Hentioe/mikack-mobile/releases) 页面下载安装包试用。
