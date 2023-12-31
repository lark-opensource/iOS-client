//
//  ACCFlowerCampaignManagerProtocol.h
//  CameraClient-Pods-AwemeCore-CameraResource_douyin
//
//  Created by imqiuhang on 2021/11/15.
//

#import <Foundation/Foundation.h>
#import <CreativeKit/ACCServiceLocator.h>
#import <CameraClient/ACCFlowerRewardModel.h>
#import "ACCFlowerCampaignDefine.h"

@class IESEffectModel,AWEVideoPublishViewModel,LOTAnimationView;

@protocol ACCFlowerCampaignManagerProtocol <NSObject>

/// 当前时间是否在flower活动阶段内 （stage和精确时间同时判断）
+ (BOOL)isOnFlowerCampaign;

/// 当前FLower活动阶段
+ (ACCFLOActivityStageType)getCurrentActivityStage;

/// 集卡奖励活动开启，对应预约和集卡阶段
+ (BOOL)isFlowerAwardActivityOn;

/// act_hash
+ (NSString *_Nullable)activityHashString;

/// 获取scene对应的schema配置
+ (NSString *_Nullable)flowerSchemaWithSceneName:(ACCFLOSceneName)sceneName;

/// 获取编辑和发布的其你去奖励request
+ (ACCFlowerRewardRequest *)getRewardRequestIfEnableWithPublishModel:(AWEVideoPublishViewModel *)publishModel
                                                        isForPublish:(BOOL)isForPublish;

/// 发布后请求发布奖励并弹窗
+ (void)requestAndShowFlowerPublishAwardIfNeedWithPublishModel:(AWEVideoPublishViewModel *)publishModel;

/// 活动命中编辑页下一步配置
+ (NSString *_Nullable)flowerAwardActivityEditNextBtnTitle;

/// 请求奖励接口，showSchema为跳转到奖励弹窗的URL
+ (void)requestFlowerActivityAwardWithInput:(ACCFlowerRewardRequest *_Nonnull)input
                                 completion:(void (^)(NSError *_Nullable error,
                                                      ACCFlowerRewardResponse *_Nonnull result,
                                                      NSString *_Nullable showSchema))completion;

/// 网络请求
+ (NSString *_Nonnull)activityServiceDomain;

///春节底Tab入口文案
+ (NSString *_Nullable)flowerTabHint;
///春节任务入口文案
+ (NSString *_Nullable)flowerEntryHint;

+ (NSString *_Nullable)flowerEntryPropHint;
+ (NSString *_Nullable)flowerEntryPhotoHint;
+ (NSString *_Nullable)flowerEntryScanHint;
+ (NSString *_Nullable)flowerEntryGrootHint;
+ (NSTimeInterval)flowerPropGuideHiddenTime;

+ (NSTimeInterval)flowerPlusValidBeginTime;
+ (NSTimeInterval)flowerPlusValidEndTime;
+ (NSString *)flowerPlusOpenUrl;

/// 预约
+ (void)markCurrentUserAsBooked;
+ (BOOL)currentUserHasBooked;

+ (NSTimeInterval)flowerServerTimeInterval;

///春节大反转实验
///对照组:0, v1:1，v2:2，v3:3
+ (NSInteger)flowerRevExpMode;
+ (NSInteger)flowerBlockingMode;

+ (LOTAnimationView *)flowerEntryLottieView;

/// 审核模式
+ (BOOL)audit;

+ (void)logFlowerError:(NSError *_Nullable)error info:(NSString *)info;
+ (void)logFlowerInfo:(NSString *)info;

/// @param needDebugToast show toast with 'info' if YES, when  build target  is DEBUG or INHOUSE
+ (void)logFlowerError:(NSError *_Nullable)error info:(NSString *)info needDebugToast:(BOOL)needDebugToast;
+ (void)logFlowerInfo:(NSString *)info needDebugToast:(BOOL)needDebugToast;

@end


FOUNDATION_STATIC_INLINE Class<ACCFlowerCampaignManagerProtocol> ACCFlowerCampaignManager() {
    
    return [[ACCBaseServiceProvider() resolveObject:@protocol(ACCFlowerCampaignManagerProtocol)] class];
}
