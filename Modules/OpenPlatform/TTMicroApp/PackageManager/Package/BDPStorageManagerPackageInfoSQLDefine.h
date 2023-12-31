//
//  BDPStorageManagerPackageInfoSQLDefine.h
//  Timor
//
//  Created by houjihu on 2020/5/24.
//

#ifndef BDPStorageManagerPackageInfoSQLDefine_h
#define BDPStorageManagerPackageInfoSQLDefine_h

#pragma mark - Pkg Info V2 Table

#define CREATE_PKG_INFO_V3_TABLE @"CREATE TABLE IF NOT EXISTS \
BDPPkgInfoTableV3(\
appID TEXT NOT NULL,\
pkgName TEXT NOT NULL,\
loadStatus INTEGER,\
readType INTEGER DEFAULT 0,\
firstReadType INTEGER DEFAULT 0,\
accessTime REAL NOT NULL,\
ext TEXT,\
PRIMARY KEY(appID, pkgName));" // ext拓展字段, 占坑

#define SELECT_PKG_INFO_V1_TABLE @"SELECT COUNT(*) FROM sqlite_master WHERE type='table' AND name='BDPPkgInfoTable';"
#define SELECT_PKG_INFO_V2_TABLE @"SELECT COUNT(*) FROM sqlite_master WHERE type='table' AND name='BDPPkgInfoTableV2';"
#define TRANSFER_PKG_INFO_FROM_V1 @"REPLACE INTO BDPPkgInfoTableV3(appID, pkgName, loadStatus, accessTime) \
SELECT appID, pkgName, loadStatus, accessTime FROM BDPPkgInfoTable;"
#define TRANSFER_PKG_INFO_FROM_V2 @"REPLACE INTO BDPPkgInfoTableV3(appID, pkgName, loadStatus, readType, firstReadType, accessTime) \
SELECT appID, pkgName, loadStatus, readType, readType AS firstReadType, accessTime FROM BDPPkgInfoTableV2;"
#define DROP_PKG_INFO_V1_TABLE @"DROP TABLE IF EXISTS BDPPkgInfoTable;"
#define DROP_PKG_INFO_V2_TABLE @"DROP TABLE IF EXISTS BDPPkgInfoTableV2;"

#define UPDATE_ALL_PKG_INFO_STATEMENT @"REPLACE INTO BDPPkgInfoTableV3(appID, pkgName, loadStatus, readType, firstReadType, accessTime) values(?, ?, ?, ?, ?, ?);"
#define UPDATE_PKG_INFO_STATUS_STATEMENT @"REPLACE INTO BDPPkgInfoTableV3(appID, pkgName, loadStatus, readType, accessTime) values(?, ?, ?, ?, ?);"

#define UPDATE_PKG_INFO_ACCESS_TIME @"UPDATE BDPPkgInfoTableV3 \
SET loadStatus = ?, readType = ?, accessTime = ? \
WHERE appID = ? AND pkgName = ?;"

#define UPDATE_PKG_INFO_LOAD_STATUS_STATEMENT @"UPDATE BDPPkgInfoTableV3 \
SET loadStatus = ?, readType = ? \
WHERE appID = ? AND pkgName = ?;"

#define DELETE_PKG_INFO_STATEMENT @"DELETE FROM BDPPkgInfoTableV3 \
WHERE appID = ? AND pkgName = ?;"

#define DELETE_PKG_INFOS_STATEMENT @"DELETE FROM BDPPkgInfoTableV3 \
WHERE appID = ?;"

#define SELECT_PKG_INFO_STATUS_STATEMENT @"SELECT loadStatus FROM BDPPkgInfoTableV3 \
WHERE appID = ? AND pkgName = ?;"

#define SELECT_PKG_INFO_READTYPE_STATEMENT @"SELECT readType, firstReadType FROM BDPPkgInfoTableV3 \
WHERE appID = ? AND pkgName = ?;"

#define SELECT_PKG_INFO_COUNT_OF_TYPE_STATEMENT @"SELECT COUNT(*) FROM BDPPkgInfoTableV3 \
WHERE appID = ? AND readType = ?;"

#define SELECT_PKG_INFO_ACCESS_DESC_LIMIT_STATEMENT @"SELECT DISTINCT appID FROM BDPPkgInfoTableV3 \
WHERE loadStatus = 2 AND readType = ? \
ORDER BY accessTime DESC LIMIT -1 OFFSET ?;" // 2是已下载完的

#define SELECT_PKG_INFO_ACCESS_DESC_EXCLUDE_LIMIT_STATEMENT @"SELECT DISTINCT appID FROM BDPPkgInfoTableV3 \
WHERE loadStatus = 2 AND readType != ? \
ORDER BY accessTime DESC LIMIT -1 OFFSET ?;"

/// 获取指定应用ID的所有包目录名称
#define SELECT_PKG_INFO_PACKAGE_NAMES_STATEMENT @"SELECT pkgName FROM BDPPkgInfoTableV3 \
WHERE appID = ? AND loadStatus = ?;"

#define DELETE_PKG_INFO_TABLE_STATEMENT @"DELETE FROM BDPPkgInfoTableV3;"

#define UPDATE_PKG_INFO_EXT_STATEMENT @"UPDATE BDPPkgInfoTableV3 \
SET ext = ? \
WHERE appID = ? AND pkgName = ?;"

#define SELECT_PKG_INFO_EXT_STATEMENT @"SELECT ext FROM BDPPkgInfoTableV3 \
WHERE appID = ? AND pkgName = ?;"
#endif /* BDPStorageManagerPackageInfoSQLDefine_h */
