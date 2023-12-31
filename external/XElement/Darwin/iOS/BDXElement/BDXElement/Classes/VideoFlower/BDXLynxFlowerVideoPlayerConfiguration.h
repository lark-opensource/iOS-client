// Copyright 2021 The Lynx Authors. All rights reserved.

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM(NSInteger, BDXLynxFlowerVideoCustomScaleMode) {
  BDXLynxFlowerVideoCustomScaleModeAuto = 0,        // 不指定，播放器内部自行计算
  BDXLynxFlowerVideoCustomScaleModeAspectFill = 1,  // 强制使用AspectFill模式
  BDXLynxFlowerVideoCustomScaleModeAspectFit = 2,   // 强制使用AspectFit模式
  BDXLynxFlowerVideoCustomScaleModeScaleFill = 3,   // Scale模式
};

@interface BDXLynxFlowerVideoPlayerConfiguration : NSObject

// require
@property(nonatomic, assign) BOOL enableHardDecode;     // 使用硬解码(默认YES)
@property(nonatomic, assign) BOOL enableBytevc1Decode;  // 使用h265解码(默认NO)
@property(nonatomic, assign) BOOL enableTTPlayer;       // 使用自研播放器(默认NO)
@property(nonatomic, assign) BOOL repeated;             // 循环播放(默认NO)
@property(nonatomic, assign) BOOL outerRotate;  // 默认是NO，外部自己控制旋转，不使用自带方法
// optional
@property(nonatomic, copy) void (^preCheckBlockBeforPlay)(void);  // 播放前进行条件校验,可为空
@property(nonatomic, assign) BOOL showDefaultVolumeLoading;  // 默认NO，显示音量和加载中的细线
@property(nonatomic, assign) BOOL mute;                      // 静默播放(默认NO)
@property(nonatomic, assign) BOOL useTTNetUtility;           // 使用TTNet网络容灾(默认NO)
@property(nonatomic, assign) BOOL disableTracker;            // 关闭内部的埋点(默认NO)

@property(nonatomic, copy) NSString *outCoverName;        // 使用外部封面;
@property(nonatomic, copy) NSString *outBackgroundColor;  // 使用字符串#66666，封面的背景色
@property(nonatomic, strong) UIColor *backUIColor;        // 使用UIColor,所有View的背景色
@property(nonatomic, assign)
    BOOL useCustomLoadingView;  // 使用自定义loadingView，player不提供默认的loadingView（默认NO）
@property(nonatomic, assign) BDXLynxFlowerVideoCustomScaleMode customScaleMode;  // 指定视频缩放模式

@end

NS_ASSUME_NONNULL_END
