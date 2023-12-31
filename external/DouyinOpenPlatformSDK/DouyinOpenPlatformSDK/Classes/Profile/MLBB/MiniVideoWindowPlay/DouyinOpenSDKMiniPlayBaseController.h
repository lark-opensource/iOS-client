//
//  DouyinOpenSDKMiniPlayBaseController.h
//  DouyinOpenPlatformSDK
//
//  Created by AnchorCat on 2022/4/19.
//

#import <UIKit/UIKit.h>
#import "DouyinOpenSDKGameProfileVideoViewController.h"
#import "DouyinOpenSDKMLBBProfile.h"
NS_ASSUME_NONNULL_BEGIN

typedef enum : NSUInteger {
    DouyinOpenSDKMiniPlayLocationLeftTop,
    DouyinOpenSDKMiniPlayLocationLeftBottom,
    DouyinOpenSDKMiniPlayLocationRightTop,
    DouyinOpenSDKMiniPlayLocationRightBottom,
} DouyinOpenSDKMiniPlayLocationType;

@interface DouyinOpenSDKMiniPlayBaseController : UIViewController

@property (nonatomic, assign, readonly) CGRect miniPlayFrame;

@property (nonatomic, copy, readwrite) NSArray <DouyinOpenSDKProfileVideoModel *> *videoModels;
@property (nonatomic, assign) NSInteger index;
@property (nonatomic, assign) BOOL isPresentFullScreenPlay;
// callback
@property (nonatomic, copy) DouyinOpenSDKVideoStateCallback videoStateCallback;
@property (nonatomic, copy) DouyinOpenSDKVideoPrePlayCallback prePlayCallback;
@property (nonatomic, copy) DouyinOpenSDKVideoNextPlayCallback nextPlayCallback;
@property (nonatomic, copy) DouyinOpenSDLVideoActionCallBack videoActionCallBack;
@property (nonatomic, copy) DouyinOpenSDKVideoDidFinishPlayingCallback videFinishCallback;

@property (nonatomic, strong, nullable) DouyinOpenSDKExtraConfig *extraConfig;

- (void)updateVideoModels:(NSArray<DouyinOpenSDKProfileVideoModel *> *)videoModels withIndex:(NSInteger)index;

/// 使用小窗自定义坐标
- (void)refreshPositionWithCustomPoint:(CGPoint)customMiniVideoPlayerPoint;

@end

NS_ASSUME_NONNULL_END
