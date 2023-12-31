//
//  DouyinOpenSDKMLBBProfile.h
//  Pods
//
//  Created by bytedance on 2022/7/3.
//

#import <UIKit/UIKit.h>
#import <AVKit/AVKit.h>
#import "DouyinOpenSDKProfile.h"

typedef NS_ENUM(NSInteger, DYOpenVideoPlayWindowType) {
    DYOpenVideoPlayWindowTypeFull       = 0, // 全屏
    DYOpenVideoPlayWindowTypeMini       = 1, // 小窗
};

@interface DouyinOpenSDKExtraConfig : NSObject

/// 自定义小窗播放器的初始位置，默认值为 CGRectNull.origin 表示不自定义
@property (nonatomic, assign) CGPoint customMiniVideoPlayerPoint;

/// 是否支持自动旋转，默认为 NO 不支持
@property (nonatomic, assign) BOOL shouldAutoRotate;

/// 支持的旋转方向，默认为 UIInterfaceOrientationMaskAll（需要 shouldAutoRotate 设置为 YES 才能生效）
@property (nonatomic, assign) UIInterfaceOrientationMask orientationMask;

@end

@interface DouyinOpenSDKMLBBProfile : NSObject

/// 请求资料
/// @param context openID 等请求参数
/// @param completion 回调
+ (void)requestDouyinProfileModelWithContext:(DouyinOpenSDKProfileContext *_Nonnull)context
                                 completion:(DouyinOpenSDKProfileModelCompletion _Nullable)completion;

/// 播放视频
/// @param context openID 等请求参数
/// @param index 播放第几个视频（下标从 0 开始）
/// @param type 全屏/小窗
/// @param extraConfig 可选，额外配置，如自定义初始位置
/// @param callbackModel 回调相关
+ (void)playVideoWithContext:(DouyinOpenSDKProfileContext *_Nonnull)context
                       index:(NSInteger)index
                  windowType:(DYOpenVideoPlayWindowType)type
                 extraConfig:(DouyinOpenSDKExtraConfig *_Nullable)extraConfig
               callbackModel:(DouyinOpenSDKVideoCallbackModel *_Nullable)callbackModel;

+(void)closeVideo;

+ (void)closeMiniPlay;

/// mlbb 相关 storyboard
+ (UIStoryboard *_Nullable)mlbbProfileStoryboard;

@end
