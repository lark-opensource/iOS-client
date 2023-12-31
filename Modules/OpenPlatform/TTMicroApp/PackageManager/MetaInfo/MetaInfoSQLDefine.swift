//
//  MetaInfoSQLDefine.swift
//  Timor
//
//  Created by 武嘉晟 on 2020/5/20.
//

import Foundation

// MARK: Release Meta SQL 语句

/// 创建meta表
let bdp_CreateReleaseMetaTable = "CREATE TABLE IF NOT EXISTS BDPReleaseMetaTable(identifier TEXT NOT NULL PRIMARY KEY, meta TEXT NOT NULL, ts INTEGER CHECK(ts > 0));"

/// 更新meta
let bdp_UpdateReleaseMetaTable = "REPLACE INTO BDPReleaseMetaTable (identifier, meta, ts) values (?, ?, ?)";

/// 查询指定meta
let bdp_QueryReleaseMetaTable = "SELECT meta,ts FROM BDPReleaseMetaTable WHERE identifier = ?;"

/// 提取所有meta
let bdp_QueryAllReleaseMetaTable = "SELECT meta,ts FROM BDPReleaseMetaTable;"

/// 删除指定meta
let bdp_DeleteReleaseMetaTable = "DELETE FROM BDPReleaseMetaTable WHERE identifier = ?;"

/// 删除所有meta
let bdp_ClearReleaseMetaTable = "DELETE FROM BDPReleaseMetaTable;";

// MARK: Preview Meta SQL 语句

/// 创建meta表
let bdp_CreatePreviewMetaTable = "CREATE TABLE IF NOT EXISTS BDPPreviewMetaTable(identifier TEXT NOT NULL PRIMARY KEY, meta TEXT NOT NULL, ts INTEGER CHECK(ts > 0));"

/// 更新meta
let bdp_UpdatePreviewMetaTable = "REPLACE INTO BDPPreviewMetaTable (identifier, meta, ts) values (?, ?, ?)";

/// 查询指定meta
let bdp_QueryPreviewMetaTable = "SELECT meta,ts FROM BDPPreviewMetaTable WHERE identifier = ?;"

/// 提取所有meta
let bdp_QueryAllPreviewMetaTable = "SELECT meta,ts FROM BDPPreviewMetaTable;"

/// 删除指定meta
let bdp_DeletePreviewMetaTable = "DELETE FROM BDPPreviewMetaTable WHERE identifier = ?;"

/// 删除所有meta
let bdp_ClearPreviewMetaTable = "DELETE FROM BDPPreviewMetaTable;";
