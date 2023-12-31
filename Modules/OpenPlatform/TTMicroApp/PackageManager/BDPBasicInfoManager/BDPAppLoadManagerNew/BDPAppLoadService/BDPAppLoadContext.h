//
//  BDPAppLoadContext.h
//  Timor
//
//  Created by 傅翔 on 2019/1/31.
//

#import <Foundation/Foundation.h>
#import <OPFoundation/BDPPkgFileReadHandleProtocol.h>
#import <OPFoundation/BDPTrackEventInfo.h>
#import <OPFoundation/BDPModuleEngineType.h>
#import "BDPTimorLaunchParam.h"

@interface OPAppUniqueID (BDPLaunchParams)
//uniqueId关联的启动参数，如果不设置，默认为空
@property (nonatomic, strong, nullable) NSString * leastVersion;
@end

@class BDPModel;

NS_ASSUME_NONNULL_BEGIN

typedef void (^BDPAppLoadCallback)(NSError *_Nullable error, BDPModel *_Nullable model);

/**
 加载小程序包的上下文Context
 */
@interface BDPAppLoadContext : NSObject

/// 是否请求线上版的小程序
@property (nonatomic, readonly) BOOL isReleasedApp;

@property (nonatomic, strong, readonly) BDPUniqueID *uniqueID;
@property (nonatomic, nullable, copy) NSString *token;

/** 埋点信息 */
@property (nonatomic, strong) BDPTrackEventInfo *trackInfo;

// 所有回调均会保证在主线程触发

/** 获得metaModel, 以及Reader的回调 */
@property (nonatomic, copy) void (^getModelCallback)(NSError *_Nullable error, BDPModel *_Nullable model, BDPPkgFileReader _Nullable reader);
/** 当前pkg包下载完的回调 */
@property (nonatomic, nullable, copy) BDPAppLoadCallback getPkgCompletion;
/** 获取新版本模型的回调 */
@property (nonatomic, nullable, copy) BDPAppLoadCallback getUpdatedModelCallback;
/** 新版本pkg包下载完的回调 */
@property (nonatomic, nullable, copy) BDPAppLoadCallback getUpdatedPkgCompletion;
/** 是否要下载pkg回调 */
@property (nonatomic, nullable, copy) BOOL (^shouldDownloadPkgBlk)(BDPModel *model);
/** 有缓存的pkg md5校验失败回调 */
@property (nonatomic, nullable, copy) dispatch_block_t md5InvalidNotifBlk;

- (instancetype)initWithUniqueID:(BDPUniqueID *)uniqueID;

- (instancetype)init NS_UNAVAILABLE;

+ (instancetype)new NS_UNAVAILABLE;

/// 触发model callback
- (void)triggerGetModelCallbackWithError:(nullable NSError *)error meta:(nullable BDPModel *)meta reader:(nullable BDPPkgFileReader)reader;
/// 触发pkg callback
- (void)triggerGetPkgCompletionWithError:(nullable NSError *)error meta:(nullable BDPModel *)meta;

@end

NS_ASSUME_NONNULL_END
