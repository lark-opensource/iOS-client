//
//  BDNativeLiveVideoView.h
//  BDNativeWebComponent
//
//  Created by Bytedance on 2021/9/23.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@protocol BDNativeLiveVideoViewPlayerDelegate <NSObject>

@optional
- (void)didIdle;
- (void)didReady;
- (void)didPlay;
- (void)didPause;
- (void)didStop;
- (void)didError:(NSDictionary *)errorDic;
- (void)didStall;
- (void)didResume;
- (void)didVideoSizChange:(CGSize)size;

@end

@class BDImageView;
@interface BDNativeLiveVideoView : UIView

@property (nonatomic, strong, readonly) BDImageView *posterImageView;
@property (nonatomic, weak) id<BDNativeLiveVideoViewPlayerDelegate> delegate;

// props
@property (nonatomic, assign) BOOL autoPlay;
@property (nonatomic, assign) BOOL couldPlay;  // playState for Video from JS-Control
@property (nonatomic, assign) BOOL mute;
@property (nonatomic, assign) CGFloat volume;
@property (nonatomic, copy) NSString *fitMode;
@property (nonatomic, assign) CGFloat cornerRadius;  // cornerRadius for layer

- (void)setupSrc:(NSString *)src;
- (void)stop;
- (void)pause;
- (void)play;

@end

NS_ASSUME_NONNULL_END
