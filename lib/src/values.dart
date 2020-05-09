import 'package:flutter/material.dart';

const defaultPreLoading = 3;
const defaultChaptersLayoutColumns = 3;
const defaultPreCaching = true;

const vPrimarySwatch = Colors.deepOrange; // 0xFFFF5722
const vNsfwTagIntValue = 4;

const vAllowNsfwHint = '未在设置中解锁 NSFW 来源';

const vInitOpeInc = 0;

/// 封面比例
/// 长:宽大约为 1.3，是常见漫画网站的封面标准
/// 注意：此处的值是宽/长
const vCoverRatio = 180 / 240;

/// 仓库和群组信息
const vRepoOwner = 'Hentioe';
const vRepoName = 'mikack-mobile';
const vRepoUrl = 'https://github.com/$vRepoOwner/$vRepoName';
const vGroupUrl = 'https://t.me/mikack';

/// 基本设置
const kStartPageKey = 'start_page';
const kDefaultPage = 'default';
const kBookshelfPage = 'bookshelf';
const kBooksUpdatePage = 'books_update';
const kLibrariesPage = 'libraries';
const kHistoriesPage = 'histories';
const kAllowNsfw = 'allow_nsfw';
const kChaptersReversed = 'chapters_reversed';

/// 阅读设置
const kReadingMode = 'reading_mode';
const kLeftToRight = 'left_to_right';
const kTopToBottom = 'top_to_bottom';
const kPaperRoll = 'paper_roll';
const kLeftHandMode = 'left_hand_mode';
const kPreLoading = 'pre_loading';
const kPreCaching = 'pre_caching';
