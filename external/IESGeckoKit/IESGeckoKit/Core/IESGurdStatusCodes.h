//
//  IESGurdStatusCodes.h
//  Pods
//
//  Created by 陈煜钏 on 2021/4/27.
//

#ifndef IESGurdStatusCodes_h
#define IESGurdStatusCodes_h

typedef NS_ENUM(NSInteger, IESGurdStatusCode) {
    // 成功 - 有更新数据返回
    IESGurdStatusCodeSuccess = 0,
    // 失败 - 服务内部错误（HTTP 网络请求成功）
    IESGurdStatusCodeServerError = 1,
    // 失败 - HTTP 方法错误（非 POST）
    IESGurdStatusCodeHTTPMethodError = 2,
    // 失败 - HTTP body 解析失败
    IESGurdStatusCodeHTTPBodyFormatError = 3,
    // 失败 - 用户未登录
    IESGurdStatusCodeNotLogin = 4,
    
    /* ====== 请求参数非法 ====== */
    
    // aid 未传值
    IESGurdStatusCodeAppIdNotPass = 1001,
    // aid 格式错误
    IESGurdStatusCodeAppIdFormatError = 1002,
    // app version 未传值
    IESGurdStatusCodeAppVersionNotPass = 1003,
    // app version 格式错误
    IESGurdStatusCodeAppVersionFormatError = 1004,
    // os 未传值
    IESGurdStatusCodeOSNotPass = 1005,
    // os 取值非法（仅支持 0 / 1）
    IESGurdStatusCodeOSNotSupport = 1006,
    // device id 未传值
    IESGurdStatusCodeDeviceIdNotPass = 1007,
    // SDK version 未传值
    IESGurdStatusCodeSDKVersionNotPass = 1008,
    // device platform 不支持
    IESGurdStatusCodeDevicePlatformNotSupport = 1009,
    
    // env 未传值
    IESGurdStatusCodeEnvNotPass = 1101,
    // env 取值非法（仅支持 1 / 2）
    IESGurdStatusCodeEnvNotSupport = 1102,
    // 本地 Settings Version 在服务端不存在
    IESGurdStatusCodeSettingsVersionNotExists = 1103,
    
    /* ====== 特殊响应状态 ====== */
    
    // Settings 版本已经是最新
    IESGurdStatusCodeSettingsAlreadyUpToDate = 2100,
    // Settings 请求被频控
    IESGurdStatusCodeSettingsRequestFrequently = 2101,
    // Settings 未配置数据
    IESGurdStatusCodeSettingsNotSet = 2102,
    // Settings 命中黑名单
    IESGurdStatusCodeSettingsRequestInBlocklist = 2103
};

/**
 * 资源更新的过程中，可能出现的status集合
 */
typedef NS_ENUM(NSInteger, IESGurdSyncStatus)
{
    // 删除缓存成功
    IESGurdSyncStatusCleanCacheSuccess = -100,
    // 删除缓存失败
    IESGurdSyncStatusCleanCacheFailed = -101,
    
    IESGurdSyncStatusDisable = -2,
    IESGurdSyncStatusUnknown = -1,
    
    /// 更新成功
    IESGurdSyncStatusSuccess = 0,
    /// 更新失败
    IESGurdSyncStatusFailed = 1,
    
    /// 更新inactive 缓存成功
    IESGurdApplyInactivePackagesStatusSuccess = 10,
    /// 更新inactive 缓存失败
    IESGurdApplyInactivePackagesStatusFailed  = 11,
    
    /**
     * 客户端Error
     */
    /// 请求参数不合法
    IESGurdSyncStatusParameterInvalid = 20,
    /// 参数没有注册
    IESGurdSyncStatusParameterNotRegister = 21,
    /// 请求参数为空
    IESGurdSyncStatusParameterEmpty = 22,
    // 存储不够
    IESGurdSyncStatusNoAvailableStorage = 23,
    /// config请求失败
    IESGurdSyncStatusFetchConfigFailed = 30,
    /// config请求的response结构不合法
    IESGurdSyncStatusFetchConfigResponseInvalid = 31,
    // 请求节流
    IESGurdSyncStatusRequestThrottle = 40,
    // 服务端不可用
    IESGurdSyncStatusServerUnavailable = 41,
    // 下载的版本已经激活
    IESGurdSyncStatusDownloadVersionIsActive = 50,
    // 下载的版本未激活
    IESGurdSyncStatusDownloadVersionIsInactive = 51,
    // 下载任务被取消
    IESGurdSyncStatusDownloadCancelled = 60,
    
    
    // 以下是update事件可能出现的err_code
    // 下载失败
    IESGurdSyncStatusDownloadFailed = 100,
    // 下载检查md5失败
    IESGurdSyncStatusDownloadCheckMd5Failed = 101,
    // package包归档失败
    IESGurdSyncStatusAchievePackageZipFailed = 102,
    
    // 解压失败
    IESGurdSyncStatusUnzipPackageFailed = 200,
    // 为解压准备tmp目录失败
    IESGurdSyncStatusCreateTmpPathForUnzipFailed = 201,
    
    // bspatch失败
    IESGurdSyncStatusBSPatchFailed = 300,
    // bspatch后检查md5失败
    IESGurdSyncStatusBSPatchCheckMd5Failed = 301,
    // 重命名patched包失败
    IESGurdSyncStatusRenamePatchedPackageFailed = 302,
    
    // zstd 解压失败
    IESGurdSyncStatusDecompressZstdFailed = 400,
    // zstd 解压检测md5失败
    IESGurdSyncStatusDecompressZstdCheckMd5Failed = 401,
    
    // 重命名文件夹失败
    IESGurdSyncStatusRenameZstdFailed = 500,
    IESGurdSyncStatusRenameFailed = 501,
    
    // 更新inactive 无更新
    IESGurdSyncStatusActiveInactiveNoCaches = 900,
    // 移动文件时目标路径为空
    IESGurdSyncStatusMoveToNilDestinationPath = 901,
    // business bundle目录不存在
    IESGurdSyncStatusBusinesspBundlePathNotExist = 902,
    // 计算文件哈希失败
    IESGurdSyncStatusFileHashFailed = 903,
    // 复制文件失败
    IESGurdSyncStatusCopyPackageFailed = 904,
    // 更新过程中被锁了
    IESGurdSyncStatusLocked = 905,
    
    // IESGurdPatch 相关错误
    IESGurdBytePatchParamsError = 1000,
//    IESGurdBytePatchModifyTimeNotExist = 1001,
//    IESGurdBytePatchModifyTimeError = 1002,
//    IESGurdBytePatchDirChanged = 1003,
//    IESGurdBytePatchSaveModifyTimeFailed = 1004,
    IESGurdBytePatchFormatError = 1005,
    IESGurdBytePatchDataError = 1006,
    IESGurdBytePatchWriteContentToFileError = 1007,
    IESGurdBytePatchBSPatchError = 1010,
    IESGurdBytePatchCheckMD5Error = 1011,
    IESGurdBytePatchFileSystemError = 1012,
    IESGurdBytePatchCopyError = 1013,
    IESGurdBytePatchRenameError = 1014,
    IESGurdBytePatchModifySameFile = 1024,
    IESGurdBytePatchReadPatchError = 1030,
    IESGurdBytePatchReachEnd = 1031,
    IESGurdBytePatchReadMd5Error = 1032,
    IESGurdBytePatchReadBytesError = 1033,
    IESGurdBytePatchReadUTFError = 1034,
    IESGurdBytePatchReadDataError = 1035,
    IESGurdBytePatchUnknown = 1099,
    
    /// 无需更新
    IESGurdSyncStatusServerPackageUnavailable = 2000,
};

typedef NS_ENUM(NSInteger, IESGurdLazyResourceStatus) {
    // 命中按需加载策略，且不在按需组里
    IESGurdLazyResourceStatusNotLazyResources = 10001,
    // 未命中按需加载，但是本地已经存在
    IESGurdLazyResourceStatusNotLazyButExist = 10002,
    // 命中按需加载，且本地已经是最新
    IESGurdLazyResourceStatusLazyResourceAlreadyNewest = 10003,
    // 命中按需，且需要下载新版本资源
    IESGurdLazyResourceStatusNewVersion = 10004,
};

#endif /* IESGurdStatusCodes_h */
