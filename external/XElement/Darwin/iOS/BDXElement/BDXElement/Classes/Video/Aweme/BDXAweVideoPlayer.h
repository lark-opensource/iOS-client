//
//  BDXVideoPlayer.h
//  BDXElement
//
//  Created by bill on 2020/3/23.
//

#import <UIKit/UIKit.h>
#import "BDXVideoPlayerProtocol.h"
#import "BDXVideoDefines.h"
#import "BDXVideoPlayerConfiguration.h"
#import "BDXVideoPlayerVideoModel.h"

#import "IESVideoPlayerProtocol.h"
#import <TTVideoEngine/TTVideoEnginePlayerDefine.h>

NS_ASSUME_NONNULL_BEGIN

@protocol BDXVideoPlayerDelegate <NSObject,IESVideoPlayerDelegate>
@optional

- (void)bdxPlayerViewDidEnterQuietMode:(BOOL)quiet;
- (void)bdxPlayerPlayTime:(NSTimeInterval)playTime
                  canPlayTime:(NSTimeInterval)canPlayTime
                    totalTime:(NSTimeInterval)totalTime;
- (void)bdxPlayerDisplayLinkPlayProgress:(CGFloat)percent;

@end

@interface BDXAweVideoPlayer : UIView

/*
 * 属性设置和读取
 */
@property (nonatomic, weak) id<BDXVideoPlayerDelegate> delegate;//代理
@property (nonatomic, assign) CGFloat fullScreenMax;
@property (nonatomic, assign) CGFloat fullScreenMin;
@property (nonatomic, strong, readonly) id<BDXVideoPlayerProtocol> playerController; //播放器本身
@property (nonatomic, assign, readonly) BDXVideoPlayState currentPlayState;//播放状态
@property (nonatomic, assign) BOOL isTTPlayer;

@property (nonatomic, strong) NSNumber *realStartPlayTime; // 外部设置起播时间 - 单位 s
@property (nonatomic, strong) NSNumber *realEndPlayTime; // 外部设置结束时间 - 单位 s
@property (nonatomic, assign) BOOL notStop;
@property (nonatomic, assign) BOOL notPlayWhenAppear; //设置appear的时候不应该播放

/*
 * 初始化方法
 */
- (instancetype)initWithFrame:(CGRect)frame
                    initModel:(BDXVideoPlayerConfiguration *)model;

/*
 * 刷新视频数据
 * paramDic 仅仅放入统计字段
 * 常见参数key值有AWEAttributeBuilder+Attribute
 */
- (void)refreshBDXVideoModel:(BDXVideoPlayerVideoModel *)model
                        paramDic:(NSDictionary *)dic;

/*
 * 播放操作
 */
- (BOOL)play;
- (BOOL)pause;
- (BOOL)stop;
- (void)realPlay;
- (void)replay; // 从起始时间开始播放 （仅用于播放过程中跳到开头）

/*
 * 拖动
 */
- (void)seekToTime:(NSTimeInterval)timeInSeconds completion:(void(^)(BOOL finished))completion;
- (void)setStartPlayTime:(CGFloat)time; //在自研使用，play之前

/*
 * 重置
 */
- (void)resetToBeginTime;
- (void)reset;

//TODO: @yyy call playController's method
- (void)setTTVideoEngineRenderEngine:(TTVideoEngineRenderEngine)renderEngine;
//TODO: @yyy call payerController's method
- (CVPixelBufferRef)currentPixelBuffer;
//TODO: @yyy call playerController's method
- (NSTimeInterval)videoDuration;
@end

NS_ASSUME_NONNULL_END
