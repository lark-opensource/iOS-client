//
//  BDPAppPreloadInfo.h
//  Timor
//
//  Created by 傅翔 on 2019/7/5.
//

#import <Foundation/Foundation.h>
#import "BDPAppLoadPublicHeader.h"
#import <OPFoundation/BDPModel.h>

NS_ASSUME_NONNULL_BEGIN

//  小程序老版本特化预加载信息

/** 预下载模式, 若增加新Mode..记得更新下 `setPreloadMode:` 方法 */
typedef NS_ENUM(NSInteger, BDPPreloadMode) {
    /** 懒下载模式: 有缓存包, 则不触发下载, 默认 */
    BDPPreloadModeLazy = 1,
    /** 强更新模式: 尝试下载最新版本的包(无缓存, 或有新版本) */
    BDPPreloadModeLatest
};

typedef void (^BDPAppPreloadCallback)(NSError *_Nullable error, BDPModel *_Nullable model);

@interface BDPAppPreloadInfo : NSObject

@property (nonatomic, copy) BDPUniqueID *uniqueID;

/** 预下载优先级, 具体描述可见 BDPPkgLoadPriority 枚举定义 */
@property (nonatomic, assign) BDPPkgLoadPriority priority;
/** 预下载模式, 详见枚举定义. 若不设BDPAppLoadPriorityHighest默认为Latest, 其他默认为Lazy */
@property (nonatomic, assign) BDPPreloadMode preloadMode;

/** extra信息, 用于埋点跟端监控, 目前会尝试读这两个key: @"launch_from", @"scene" */
@property (nonatomic, nullable, copy) NSDictionary *extraInfo;

/// Meta & Pkg download completion block
@property (nonatomic, nullable, copy) BDPAppPreloadCallback preloadCompletion;

+ (nullable instancetype)preloadInfoWithUniqueID:(BDPUniqueID *)uniqueID priority:(BDPPkgLoadPriority)priority preloadMode:(BDPPreloadMode)mode;

/** 创建预下载信息. 若优先级为Highest则下载模式默认为Latest, 否则下载模式默认为Lazy */
+ (nullable instancetype)preloadInfoWithUniqueID:(BDPUniqueID *)uniqueID priority:(BDPPkgLoadPriority)priority;

@end

NS_ASSUME_NONNULL_END
