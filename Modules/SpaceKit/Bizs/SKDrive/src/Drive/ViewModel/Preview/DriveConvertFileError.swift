//
//  DriveParseFileError.swift
//  SpaceKit
//
//  Created by liweiye on 2019/7/26.
//
// disable-lint: magic number

import Foundation
import SKResource

// 接口文档：https://bytedance.feishu.cn/space/doc/doccnjyJ20dBS2TEa18onyL2NRg#aVkhsd
enum DriveConvertFileErrorCode: Int {
    case failed = 100
    case xmlVersionNotSupport = 101
    case fileEncrypt = 102
    case tosFailed = 103
    case mysqlFaild = 104
    case rpcFailed = 105
    case needCharge = 11001
    case amountExceedLimit = 7000
    case hierarchyExceedLimit = 7001
    case sizeExceedLimit = 7002

    case dataLockedForMigration = 900004230 // 数据迁移中，内容被锁定
    case unavailableForCrossTenantGeo = 900004510 // 合规-同品牌的跨租户跨Geo
    case unavailableForCrossBrand = 900004511 // 合规-跨品牌不允许
}

enum DriveConvertFileNewErrorCode: Int {
    // convert前缀表示导入接口的错误码， 无前缀的表示获取导入结果错误码
    /// 导入失败，联系客服
    case creatNewMission = 1
    case convertProcessing = 2
    case xmlVersionNotSupport = 113
    case spaceOutOfLimit = 105
    case importFileExtensionNotMatch = 118
    case importFileTypeNotMatch = 120
    case importFileExpired = 121
    case fileFormatNotSupported = 112
    case fileContentParserFailed = 124
    
    case convertFileTokenNotFound = 1007
    case convertImportFileExtenNotMatch = 1010
    case convertImportFiletypeNotMatch = 1011
    case convertFileTokenExpired = 1013
    
    //DLP检测
    case dlpCheckedFailed = 1019
    case dlpChecking = 1020
    
    /// 导入内容过多，请减少内容后重试
    case convertImportFileSizeOverLimit = 1009
    
    case importSizeLimit = 115
    case amountExceedLimit = 7000
    case hierarchyExceedLimit = 7001
    case sizeExceedLimit = 7002
    
    /// 暂无导入权限，请获取权限后重试
    case noPermission = 110
    case mountNoPermission = 116
    
    case convertMountNoPermission = 1008
    case convertNoPermission = 1002
    
    /// 云盘存储空间不存在，请清理空间
    case spaceBillingUnavailable = 104
    
    /// 目标目录不存在，请检查后重试
    case mountNotExist = 119
    case mountDeleted = 117
    
    case convertMountPointNotExist = 1012
    
    /// 导入文档已被加密，导入失败
    case encryptFile = 100
    
    /// 此文档没有内容，请检查后重试
    case importFileSizeZero = 1015
    case convertImportFileSizeZero = 125
    
    /// 导入失败请重试
    case failed = 3
    case tosFailed = 101
    case mysqlFailed = 102
    case rpcFailed = 103
    case jobTimeout = 108
    case importDownloadFileFailed = 114
    case docJavaSdkParserFailed = 5000
    
    case convertMysqlError = 1001
    case convertRpcError = 1003
    case convertInternalError = 1005

    case dataLockedForMigration = 900004230 // 数据迁移中，内容被锁定
    case unavailableForCrossTenantGeo = 900004510 // 合规-同品牌的跨租户跨Geo
    case unavailableForCrossBrand = 900004511 // 合规-跨品牌不允许
    
    case dlpExternalDetcting = 900099002  // 外部租户DLP拦截
    case dlpExternalSensitive = 900099004 //外部租户dlp拦截
}

// 错误码说明： https://bytedance.sg.feishu.cn/wiki/wikcnwWgg1HA3rih4fHWOhzeqUd#
enum DriveConvertExtraCode: Int {
    // 列数超过最大限制，超出的部分将被截断丢弃
    case sheetColumnOverLimit = 2000
    // 单元格数超过最大限制，超出的部分将被截断丢弃
    case sheetUnitOverLimit = 2001
    // 图片超过4000张，超出的图片被丢弃
    case sheetImageOverLimit = 2002
    // 云空间存储空间不足，请联系企业管理员
    case sheetStorageOverLimit = 2003
    // 部分图片上传失败
    case sheetImageUploadFailed = 2004
    // 单元格字符长度超过最大限制，超出的部分将被截断丢弃
    case sheetUnitWordOverLimit = 2005
    
    var errorTips: String {
        switch self {
        case .sheetColumnOverLimit:
            return BundleI18n.SKResource.CreationMobile_Import_OverLimitOfColumn(13000)
        case .sheetUnitOverLimit:
            return BundleI18n.SKResource.CreationMobile_Import_OverLimitOfWorkSheet(2000000)
        case .sheetImageOverLimit:
            return BundleI18n.SKResource.CreationMobile_Import_OverLimitOfPicNumber(4000)
        case .sheetStorageOverLimit:
            return BundleI18n.SKResource.CreationMobile_Import_StorageNotEnough
        case .sheetImageUploadFailed:
            return BundleI18n.SKResource.CreationMobile_Import_PictureFailed
        case .sheetUnitWordOverLimit:
            return BundleI18n.SKResource.CreationMobile_Import_CelTextOverLimit()
        }
    }
}

enum DriveConvertFileError: Error {
    case invalidDataError
    case serverError(code: Int)
}
