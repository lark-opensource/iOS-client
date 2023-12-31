//
//  BDPPackageInfoManagerProtocol.h
//  Timor
//
//  Created by houjihu on 2020/5/24.
//

#ifndef BDPPackageInfoManagerProtocol_h
#define BDPPackageInfoManagerProtocol_h

#import <OPFoundation/BDPTrackerConstants.h>
#import <OPFoundation/BDPUniqueID.h>
#import <OPFoundation/BDPPkgFileReadHandleProtocol.h>

NS_ASSUME_NONNULL_BEGIN

// 定义迁移到: OPFoundation BDPPkgFileReadHandleProtocol.h
/// 代码包下载状态
//typedef NS_ENUM(NSInteger, BDPPkgFileLoadStatus) {
//    BDPPkgFileLoadStatusUnknown = -1,
//    /** 缺少文件描述(未开始下载或才开始)。
//     用于流式下载，在文件头下载完成后切换为downloading。
//     针对非流式包，开始下载后直接切换为downloading。
//     */
//    BDPPkgFileLoadStatusNoFileInfo,
//    /** 文件下载中 */
//    BDPPkgFileLoadStatusDownloading,
//    /** 文件下载已下载 */
//    BDPPkgFileLoadStatusDownloaded
//};

typedef NS_ENUM(NSInteger, BDPPkgFileReadType) {
    BDPPkgFileReadTypeUnknown,
    /** 正常流程访问 */
    BDPPkgFileReadTypeNormal,
    /** 异步流程访问 */
    BDPPkgFileReadTypeAsync,
    /** 预下载流程访问 */
    BDPPkgFileReadTypePreload
};

// 这个包的来源; 一般都是从服务端(CDN)直接下载的
typedef NS_ENUM(NSInteger, BDPPkgSourceType) {
    // 服务端(CDN)下载
    BDPPkgSourceTypeDefault = 0,
    // 通过本地包进行增量更新的
    BDPPkgSourceTypeIncremental
};

static inline NSString *BDPPkgFileReadTypeInfo(BDPPkgFileReadType type) {
    switch (type) {
        case BDPPkgFileReadTypeAsync:
            return BDPTrackerRequestAsync;
        case BDPPkgFileReadTypePreload:
            return BDPTrackerRequestPreload;
        case BDPPkgFileReadTypeNormal:
            return BDPTrackerRequestNormal;
        default:
            return BDPTrackerRequestUnknown;
    }
}

// BDPPkgInfoTableV3表中ext(Json字符串)中字段名
static NSString * const kPkgTableExtPrehandleSceneKey = @"prehandleSceneName";
static NSString * const kPkgTableExtPreUpdatePullTypeKey = @"preUpdatePullType";
static NSString * const kPkgTableExtPkgSource = @"packageSource";

/// 代码包下载信息管理
@protocol BDPPackageInfoManagerProtocol <NSObject>

#pragma mark - Pkg Info Table
/// 查询代码包下载状态
- (BDPPkgFileLoadStatus)queryPkgInfoStatusOfUniqueID:(BDPUniqueID *)uniqueID pkgName:(NSString *)pkgName;
/// 查询代码包下载状态，返回-1说明不存在, 元素对应关系0: readType, 1: firstReadType。可用于埋点记录打开应用时的状态
- (NSArray<NSNumber *> *)queryPkgReadTypeOfUniqueID:(BDPUniqueID *)uniqueID pkgName:(NSString *)pkgName;
/// 代码包下载信息记录数量。可用于检查当前应用是否是无缓存首次打开
- (NSInteger)queryCountOfPkgInfoWithUniqueID:(BDPUniqueID *)uniqueID readType:(BDPPkgFileReadType)readType;
/// 查询指定应用ID的所有代码包目录
- (NSArray<NSString *> *)queryPkgNamesOfUniqueID:(BDPUniqueID *)uniqueID status:(BDPPkgFileLoadStatus)status;

/// 替换或插入一条新的代码包下载信息记录
- (void)replaceInToPkgInfoWithStatus:(BDPPkgFileLoadStatus)status withUniqueID:(BDPUniqueID *)uniqueID pkgName:(NSString *)pkgName readType:(BDPPkgFileReadType)readType;
/// 更新代码包下载信息记录
- (void)updatePkgInfoStatus:(BDPPkgFileLoadStatus)status withUniqueID:(BDPUniqueID *)uniqueID pkgName:(NSString *)pkgName readType:(BDPPkgFileReadType)readType;
/// 更新状态以及访问时间
- (void)updatePkgInfoAcessTimeWithStatus:(BDPPkgFileLoadStatus)status ofUniqueID:(BDPUniqueID *)uniqueID pkgName:(NSString *)pkgName readType:(BDPPkgFileReadType)readType;

/// 删除指定应用和包存放目录名称的代码包下载信息记录
- (void)deletePkgInfoOfUniqueID:(BDPUniqueID *)uniqueID pkgName:(NSString *)pkgName;
/// 删除指定应用的所有代码包下载信息记录
- (void)deletePkgInfosOfUniqueID:(BDPUniqueID *)uniqueID;

/// 根据指定下载类型和最近访问时间倒序获取超出特定数量的Model
- (NSArray<NSString *> *)appIdsOfPkgBeyondLimit:(NSUInteger)limit withReadType:(BDPPkgFileReadType)readType;
/// 排除指定下载类型，根据最近访问时间倒序获取超出特定数量的Model
- (NSArray<NSString *> *)appIdsOfPkgBeyondLimit:(NSUInteger)limit withExcludedReadType:(BDPPkgFileReadType)readType;

/// 删除代码包下载信息存储表格
- (void)clearPkgInfoTable;

/// 释放数据库实例
- (void)closeDBQueue;

/// 更新包信息db(BDPPkgInfoTableV3)中预安装的数据(存储在ext字段中)
/// - Parameters:
///   - uniqueID: 唯一ID
///   - pkgName: 包名
///   - sceneName: 预安装场景名
///   - preUpdatePullType: 预拉的策略 0: 本地策略. 1:服务端策略; -1: 未知(默认值)
- (void)updatePackage:(BDPUniqueID *)uniqueID
              pkgName:(NSString *)pkgName
   prehandleSceneName:(NSString *)sceneName
    preUpdatePullType:(NSInteger)preUpdatePullType;

/// 更新包信息db(BDPPkgInfoTableV3)中包来源的数据(存储在ext字段中)
/// - Parameters:
///   - uniqueID: 唯一ID
///   - pkgName: 包名
///   - pkgSource: 包的来源(0: 未知. 1: 来自远端下载. 2: 来自增量更新合成)
- (void)updatePackageType:(BDPUniqueID *)uniqueID
                  pkgName:(NSString *)pkgName
            packageSource:(BDPPkgSourceType)pkgSource;

/// 获取对应包的ext字典(由BDPPkgInfoTableV3中ext的字段转换成的Dictionary)
- (nullable NSDictionary *)extDictionary:(BDPUniqueID *)uniqueID pkgName:(NSString *)pkgName;
@end

NS_ASSUME_NONNULL_END

#endif /* BDPPackageInfoManagerProtocol_h */
