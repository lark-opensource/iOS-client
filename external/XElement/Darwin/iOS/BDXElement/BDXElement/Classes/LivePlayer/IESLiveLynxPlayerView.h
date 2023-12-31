//
//  IESLiveLynxPlayerView.h
//  BDXElement
//
//  Created by chenweiwei.luna on 2020/10/13.
//

#import <UIKit/UIKit.h>
#import <IESLivePlayer/IESLivePlayerManager.h>

NS_ASSUME_NONNULL_BEGIN

@protocol IESLiveLynxPlayerDelegate <NSObject>

@optional
- (void)didPlay;
- (void)didPause;
- (void)didStop;
- (void)didError:(NSDictionary *)errorDic;
- (void)didStall;
- (void)didResume;
- (void)didReceiveSEI:(NSDictionary *)info;

- (void)reportLivePlayerLog:(NSString *)url reportParams:(NSDictionary *)reportParam;

@end

@interface IESLiveLynxPlayerView : UIView

@property (nonatomic, assign) BOOL enableHardDecode;
@property (nonatomic, assign) BOOL mute;
// Props
@property (nonatomic, assign) BOOL autoPlay;
@property (nonatomic, assign) CGFloat volume;
@property (nonatomic, assign) NSTimeInterval startTime;
@property (nonatomic, assign) NSTimeInterval playTime;

@property (nonatomic, assign) BOOL enableBGPlay;

// new props
@property (nonatomic, copy) NSString *posterURL;
@property (nonatomic, assign) BOOL needPreload;
@property (nonatomic, assign) BOOL autoLifecycle;
@property (nonatomic) NSTimeInterval rate;
@property (nonatomic, copy) NSString *fitMode;

- (instancetype)init NS_UNAVAILABLE;
- (nullable instancetype)initWithCoder:(NSCoder*)coder NS_UNAVAILABLE;
- (instancetype)initWithFrame:(CGRect)frame NS_UNAVAILABLE;

- (instancetype)initWithDelegate:(nullable id<IESLiveLynxPlayerDelegate>)delegate NS_DESIGNATED_INITIALIZER;

- (void)reloadWithStreamData:(NSString *)streamData defaultSDKKey:(NSString *)sdkKey;

#pragma mark - Player Control

- (void)stop;
- (void)pause;
- (void)play;

- (void)updateVideoQuality:(NSString *)quality;

@end

NS_ASSUME_NONNULL_END
