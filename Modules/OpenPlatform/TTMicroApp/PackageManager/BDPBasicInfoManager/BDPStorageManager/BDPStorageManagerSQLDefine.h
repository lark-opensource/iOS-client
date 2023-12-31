//
//  BDPStorageManager+Helper.h
//  Timor
//
//  Created by liubo on 2019/1/17.
//

#import "BDPStorageManager.h"
#import "BDPStorageManagerPackageInfoSQLDefine.h"

#pragma mark - 版本升级老数据库相关语句
#define OLD_SELECT_ALL_INUSED_MODEL_STATEMENT @"SELECT model FROM BDPInuseInfoTable;"
#define OLD_DELETE_INUSED_MODEL_STATEMENT @"DELETE FROM BDPInuseInfoTable WHERE appID = ?;"

#define OLD_SELECT_ALL_UPDATED_MODEL_STATEMENT @"SELECT model FROM BDPUpdateInfoTable;"
#define OLD_DELETE_UPDATED_MODEL_STATEMENT @"DELETE FROM BDPUpdateInfoTable WHERE appID = ?;"
