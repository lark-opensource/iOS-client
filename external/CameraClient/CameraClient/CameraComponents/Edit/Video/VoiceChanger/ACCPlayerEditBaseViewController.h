//
//  ACCPlayerEditBaseViewController.h
//  Pods
//
//  Created by Shen Chen on 2020/6/29.
//

#import <UIKit/UIKit.h>
#import <CreationKitInfra/AWEMediaSmallAnimationProtocol.h>
#import <AVFoundation/AVFoundation.h>

NS_ASSUME_NONNULL_BEGIN

@protocol ACCEditServiceProtocol;
@class AWEVideoPublishViewModel;

@interface ACCPlayerEditBaseViewController : UIViewController<AWEMediaSmallAnimationProtocol>
@property (nonatomic, strong, readonly) id<ACCEditServiceProtocol> editService;
@property (nonatomic, strong, readonly) UIView *playerContainer;
@property (nonatomic, strong, readonly) UIView *bottomView;

- (instancetype)initWithEditService:(id<ACCEditServiceProtocol>)editService
                              model:(AWEVideoPublishViewModel *)model;
- (BOOL)isPlaying;
- (void)moviePause;
- (void)moviePlay;
- (void)movieRestore;
- (void)movieSeekToTime:(CMTime)time;
- (void)movieSeekToTime:(CMTime)time completion:(void (^)(BOOL finished))completionHandler;
- (void)movieDidChangePlaytime:(NSTimeInterval)playtime;
- (void)showPlayIcon:(BOOL)show animated:(BOOL)animated;
- (BOOL)shouldUpdatePlayerIndicatorWhenPlay;
- (void)onPlayIconTapped:(id)sender;

- (CGFloat)playerContainerYoffset;
- (CGFloat)bottomViewHeight;
- (CGFloat)playerBottomSpace;
- (NSArray<UIView *> *)topViews;
@end

NS_ASSUME_NONNULL_END
