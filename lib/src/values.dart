import 'package:flutter/material.dart';

const primarySwatch = Colors.deepOrange; // 0xFFFF5722
const nsfwTagValue = 4;

/// 封面比例
/// 长:宽大约为 1.3，是常见漫画网站的封面标准
/// 注意：此处的值是宽/长
const coverRatio = 180 / 240;

const allowNsfwKey = 'allow_nsfw';
const chaptersReversedKey = 'chapters_reversed';

const repoOwner = 'Hentioe';
const repoName = 'mikack-mobile';
const settingsRepoUrl = 'https://github.com/$repoOwner/$repoName';
const settingsGroupUrl = 'https://t.me/mikack';

/// 基本设置
const kStartPageKey = 'start_page';
const vDefaultPage = 'default';
const vBookshelfPage = 'bookshelf';
const vBooksUpdatePage = 'books_update';
const vLibrariesPage = 'libraries';
const vHistoriesPage = 'histories';

/// 阅读设置
const kReadingMode = 'reading_mode';
const vLeftToRight = 'left_to_right';
const vTopToBottom = 'top_to_bottom';
const vPaperRoll = 'paper_roll';
const vLeftHandModeKey = 'left_hand_mode';
