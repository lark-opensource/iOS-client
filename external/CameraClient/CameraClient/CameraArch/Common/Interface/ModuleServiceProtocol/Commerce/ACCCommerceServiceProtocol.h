//
//  ACCCommerceServiceProtocol.h
//  Pods
//
//  Created by chengfei xiao on 2019/7/29.
//  商业化广告相关协议

#import <Foundation/Foundation.h>
#import <CreationKitInfra/ACCModuleService.h>
#import "ACCAdTrackContext.h"
#import "ACCAdTaskContext.h"

NS_ASSUME_NONNULL_BEGIN

@protocol ACCPublishRepository;

typedef void (^ACCAdTaskContextBuildBlock)(ACCAdTaskContext *context);
typedef void (^ACCAdTrackContextBuildBlock)(ACCAdTrackContext *context);

typedef NS_ENUM(NSInteger, ACCAdTaskType) {
    ACCAdTaskTypeUnknown = 0,
    ACCAdTaskTypeLandingPage,       // 打开落地页
    ACCAdTaskTypeShowcase,          // 快闪店
    ACCAdTaskTypeInAppOpenURL,      // 端内跳转
    ACCAdTaskTypeOpenOtherApp,      // 跳转其他app
    ACCAdTaskTypeUniversalLinkAndLandingPage,   // 先用 UniversalLink 打开，如果未安装则用落地页打开
};

@class AWEVideoPublishViewModel;

@protocol ACCCommerceServiceProtocol <NSObject>

/*
 * 广告贴纸跳转配置
 */
- (void)runTasksWithContext:(ACCAdTaskContextBuildBlock _Nullable)ctxBuilder runTasks:(NSArray * _Nullable)tasks;

/*
 * 广告贴纸埋点
 */
- (void)trackWithContext:(ACCAdTrackContextBuildBlock _Nullable)block;

- (BOOL)shouldUseCommerceMusic; // 是否受限于商业音乐版权

- (BOOL)isEnterFromECommerceComment:(nullable id<ACCPublishRepository>)model; //电商评价页面的编辑页需要自动应用音乐

//是否来自于全民任务的快拍任务
- (BOOL)isFromMissionQuickStartWithPublishViewModel:(nonnull AWEVideoPublishViewModel *)publishModel;

@end

NS_ASSUME_NONNULL_END
