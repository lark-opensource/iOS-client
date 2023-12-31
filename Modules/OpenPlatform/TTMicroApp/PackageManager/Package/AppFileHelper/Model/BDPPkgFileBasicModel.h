//
//  BDPPkgFileBasicModel.h
//  TTHelium
//
//  Created by 傅翔 on 2019/3/5.
//

#import <Foundation/Foundation.h>
#import "BDPAppLoadPublicHeader.h"
#import "BDPPackageInfoManagerProtocol.h"
#import <OPFoundation/BDPModuleEngineType.h>
#import <OPFoundation/BDPUniqueID.h>

@class BDPUniqueID, BDPTrackEventInfo;

NS_ASSUME_NONNULL_BEGIN

/// 流式包下载基础信息
@interface BDPPkgFileBasicModel : NSObject

/** 访问类型 */
@property (nonatomic, assign) BDPPkgFileReadType readType;
/** 访问优先级 */
@property (nonatomic, assign) BDPPkgLoadPriority priority;
/** 包名. 同App不同版本包名也不一样. */
@property (nonatomic, readonly, copy) NSString *pkgName;
/** 分包中相关的path信息，如果是主包或者整包，则为空 */
@property (nonatomic, copy, nullable) NSString *pagePath;
/** md5 */
@property (nonatomic, readonly, nullable, copy) NSString *md5;
@property (nonatomic, readonly, nullable, copy) NSString *version;
/** 版本更新时间戳 */
@property (nonatomic, readonly, assign) int64_t versionCode;
/** 请求地址 */
@property (nonatomic, readonly, nullable, copy) NSArray<NSURL *> *requestURLs;
@property (nonatomic, readonly, assign) BOOL isDebugMode;
@property (nonatomic, strong) BDPUniqueID *uniqueID;

@property (nonatomic, strong) BDPTrackEventInfo *trackInfo;

@property (nonatomic, readonly) float downloadPriority;

/** 创建了App目录 */
@property (nonatomic, assign) BOOL didCreateAppFolder;
/** 使用缓存meta */
@property (nonatomic, assign) BOOL usedCacheMeta;
/** 数据库中存储的readType, 若为-1或等于BDPPkgFileReadTypePreload表明是首次打开 */
@property (nonatomic, assign) BDPPkgFileReadType dbReadType;
/// 触发包下载的访问类型
@property (nonatomic, assign) BDPPkgFileReadType firstReadType;
/** 是否复用预下载的任务 */
@property (nonatomic, assign) BOOL isReusePreload;
/** 是否断点续传的下载 */
@property (nonatomic, assign) BOOL isDownloadRange;
/** 是否首次打开(之前无任何使用记录) */
@property (nonatomic, assign) BOOL isFirstOpen;
/// 是否可使用br方式下载
@property (nonatomic, assign) BOOL canDownloadBr;

@property (nonatomic, copy, nullable) void (^completion)(NSError * _Nullable error);
@property (nonatomic, copy, nullable) dispatch_block_t md5InvliadBlk;

+ (instancetype)basicModelWithUniqueId:(BDPUniqueID *)uniqueId
                                   md5:(nullable NSString *)md5
                               pkgName:(NSString *)pkgName
                              readType:(BDPPkgFileReadType)readType
                           requestURLs:(nullable NSArray<NSURL *> *)requestURLs
                               version:(nullable NSString *)version
                           versionCode:(int64_t)versionCode
                             debugMode:(BOOL)debugMode;

@end

NS_ASSUME_NONNULL_END
