//
//  MetaSQLDefine.swift
//  TTMicroApp
//
//  Created by Nicholas Tau on 2022/11/17.
//

import Foundation

// MARK: Release Meta SQL 语句
/// 创建meta表
let pkm_CreateReleaseMetaTable =
"""
CREATE TABLE IF NOT EXISTS PKMReleaseMetaTable(
id INTEGER  NOT NULL  PRIMARY KEY AUTOINCREMENT,
identifier Text NOT NULL UNIQUE,
biz_type Text NOT NULL,
meta Text NOT NULL,
meta_from INTEGER NOT NULL DEFAULT 0,
app_id Text NOT NULL,
app_version Text NOT NULL,
pkg_name Text,
extra Text,
update_time INTEGER CHECK(update_time > 0) NOT NULL ,
create_time INTEGER CHECK(create_time > 0) NOT NULL DEFAULT CURRENT_TIMESTAMP
)
"""
//数据库的列名
let pkm_necessaryColumnsWhenReplace = "identifier, biz_type, meta, meta_from, app_id, app_version, pkg_name, extra, update_time";
//数据库列名对应的值，数量必须和 pkm_necessaryColumnsWhenReplace 一致
let pkm_necessaryColumnsValueWhenReplace = "?, ?, ?, ?, ?, ?, ?, ?, ?";

///
let pkm_necessaryColumnsWhenSelect =  "biz_type, meta, app_id, app_version, pkg_name, update_time";

/// 更新meta
let pkm_UpdateReleaseMetaTable = "REPLACE INTO PKMReleaseMetaTable (\(pkm_necessaryColumnsWhenReplace)) values (\(pkm_necessaryColumnsValueWhenReplace));";

/// 查询指定meta
let pkm_QueryReleaseMetaTable = "SELECT \(pkm_necessaryColumnsWhenSelect) FROM PKMReleaseMetaTable WHERE app_id = ? ORDER BY update_time DESC;"

/// 提取所有meta
let pkm_QueryReleaseMetaTableWithAppIdAndVersion = "SELECT \(pkm_necessaryColumnsWhenSelect) FROM PKMReleaseMetaTable WHERE app_id = ? and app_version = ? ORDER BY update_time DESC;"

/// 根据AppID提取所有meta
let pkm_QueryAllReleaseMetaTableWithAppId = "SELECT \(pkm_necessaryColumnsWhenSelect) FROM PKMReleaseMetaTable WHERE app_id = ? ORDER BY update_time DESC;"

/// 提取所有meta
let pkm_QueryAllReleaseMetaTable = "SELECT \(pkm_necessaryColumnsWhenSelect) FROM PKMReleaseMetaTable ORDER BY update_time DESC;"

//获取所有数据条数
let pkm_CountAllReleaseMetaTable = "SELECT COUNT(*) FROM PKMReleaseMetaTable"
/// 删除指定meta
let pkm_DeleteReleaseMetaTableWithAppId = "DELETE FROM PKMReleaseMetaTable WHERE app_id = ?;"

/// 删除指定meta
let pkm_DeleteReleaseMetaTableWithAppIdAndVersion = "DELETE FROM PKMReleaseMetaTable WHERE app_id = ? and app_version = ?;"

/// 删除所有meta
let pkm_ClearReleaseMetaTable = "DELETE FROM PKMReleaseMetaTable;";

// MARK: Preview Meta SQL 语句

/// 创建meta表
let pkm_CreatePreviewMetaTable =
"""
CREATE TABLE IF NOT EXISTS PKMPreviewMetaTable(
id INTEGER  NOT NULL  PRIMARY KEY AUTOINCREMENT,
identifier Text NOT NULL UNIQUE,
biz_type Text NOT NULL,
meta Text NOT NULL,
meta_from INTEGER NOT NULL DEFAULT 0,
app_id Text NOT NULL,
app_version Text NOT NULL,
pkg_name Text,
extra Text,
update_time INTEGER CHECK(update_time > 0) NOT NULL ,
create_time INTEGER CHECK(create_time > 0) NOT NULL DEFAULT CURRENT_TIMESTAMP
)
"""
/// 更新meta
let pkm_UpdatePreviewMetaTable = "REPLACE INTO PKMPreviewMetaTable (\(pkm_necessaryColumnsWhenReplace)) values (\(pkm_necessaryColumnsValueWhenReplace));";

/// 查询指定meta
let pkm_QueryPreviewMetaTable = "SELECT \(pkm_necessaryColumnsWhenSelect) FROM PKMPreviewMetaTable WHERE app_id = ? ORDER BY update_time DESC;"

/// 提取所有meta
let pkm_QueryPreviewMetaTableWithAppIdAndVersion = "SELECT \(pkm_necessaryColumnsWhenSelect) FROM PKMPreviewMetaTable WHERE app_id = ? and app_version = ? ORDER BY update_time DESC;"

/// 提取所有meta
let pkm_QueryAllPreviewMetaTableWithAppId = "SELECT \(pkm_necessaryColumnsWhenSelect) FROM PKMPreviewMetaTable WHERE app_id = ? ORDER BY update_time DESC;"

/// 提取所有meta
let pkm_QueryAllPreviewMetaTable = "SELECT \(pkm_necessaryColumnsWhenSelect) FROM PKMPreviewMetaTable ORDER BY update_time DESC;"

/// 删除指定meta
let pkm_DeletePreviewMetaTableWithAppId = "DELETE FROM PKMPreviewMetaTable WHERE app_id = ?;"

/// 删除指定meta
let pkm_DeletePreviewMetaTableWithAppIdAndVersion = "DELETE FROM PKMPreviewMetaTable WHERE app_id = ? and app_version = ?;"

/// 删除所有meta
let pkm_ClearPreviewMetaTable = "DELETE FROM PKMPreviewMetaTable;";

//获取所有数据条数
let pkm_CountAllPreviewMetaTable = "SELECT COUNT(*) FROM PKMPreviewMetaTable"
