//
//  ACCPropGuideView.h
//  CameraClient-Pods-Aweme
//
//  Created by Chipengliu on 2020/12/1.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN


@protocol ACCPropGuideViewDelegate <NSObject>

@optional
- (void)propGuideViewVideoDidStartPlay;
- (void)propGuideViewVideoDidStopPlay;

@end

@interface ACCPropGuideView : UIView

@property (nonatomic, assign, readonly) NSInteger loopTimes;
@property (nonatomic, assign, readonly) NSTimeInterval currentPlayTime;
@property (nonatomic, assign, readonly) NSTimeInterval videoDuration;
@property (nonatomic, weak) id<ACCPropGuideViewDelegate> delegate;

- (void)startVideoWithURL:(NSURL *)URL cover:(nullable NSArray *)coverURLList completion:(void(^ _Nullable)(void))completion;

- (void)closePlay;

+ (BOOL)isShowing;

@end

NS_ASSUME_NONNULL_END
