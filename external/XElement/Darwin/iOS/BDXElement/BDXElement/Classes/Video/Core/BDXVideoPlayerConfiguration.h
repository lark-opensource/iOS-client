//
//  BDXVideoPlayerInitModel.h
//  BDXElement
//
//  Created by bill on 2020/3/23.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM(NSInteger, BDXVideoMode) {
    BDXVideoModeShort = 0, //短视频，仅作为一个业务播放器View
    BDXVideoModeLong = 1, //长视频，会默认显示进度条
};

typedef NS_ENUM(NSInteger, BDXVideoCustomScaleMode) {
    BDXVideoCustomScaleModeAuto = 0, //不指定，播放器内部自行计算
    BDXVideoCustomScaleModeAspectFill = 1, //强制使用AspectFill模式
    BDXVideoCustomScaleModeAspectFit = 2, //强制使用AspectFit模式
    BDXVideoCustomScaleModeScaleFill = 3, //Scale模式
};

@interface BDXVideoPlayerConfiguration : NSObject

//require
@property (nonatomic, assign) BDXVideoMode   videoMode; //默认是短视频
@property (nonatomic, assign) BOOL enableHardDecode; //使用硬解码(默认YES)
@property (nonatomic, assign) BOOL enableBytevc1Decode; //使用h265解码(默认NO)
@property (nonatomic, assign) BOOL enableTTPlayer;  //使用自研播放器(默认NO)
@property (nonatomic, assign) BOOL repeated; //循环播放(默认NO)
@property (nonatomic, assign) BOOL outerRotate; //默认是NO，外部自己控制旋转，不使用自带方法
//optional
@property (nonatomic, copy)   void (^preCheckBlockBeforPlay)(void);//播放前进行条件校验,可为空
@property (nonatomic, assign) BOOL showDefaultVolumeLoading; //默认NO，显示音量和加载中的细线
@property (nonatomic, assign) BOOL mute; //静默播放(默认NO)
@property (nonatomic, assign) BOOL useTTNetUtility; //使用TTNet网络容灾(默认NO)
@property (nonatomic, assign) BOOL disableTracker; //关闭内部的埋点(默认NO)

@property (nonatomic, copy)   NSString *outCoverName; //使用外部封面;
@property (nonatomic, copy)   NSString *outBackgroundColor; //使用字符串#66666，封面的背景色
@property (nonatomic, strong) UIColor *backUIColor; //使用UIColor,所有View的背景色
@property (nonatomic, assign) BOOL useCustomLoadingView; //使用自定义loadingView，player不提供默认的loadingView（默认NO）
@property (nonatomic, assign) BDXVideoCustomScaleMode customScaleMode; //指定视频缩放模式

@end

NS_ASSUME_NONNULL_END
