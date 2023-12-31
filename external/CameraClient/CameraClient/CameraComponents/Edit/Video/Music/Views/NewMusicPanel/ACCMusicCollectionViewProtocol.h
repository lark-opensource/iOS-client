//
//  ACCMusicCollectionViewProtocol.h
//  CameraClient-Pods-Aweme
//
//  Created by 饶骏华 on 2021/7/4.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@protocol ACCMusicCollectionViewProtocol <NSObject>

/// 无收藏音乐内容时展示这个
@property (nonatomic, strong, readonly) UILabel *emptyCollectionLabel;
@property (nonatomic, strong, readonly) UIImageView *loadingMoreImageView;
@property (nonatomic, copy) void (^retryBlock)(void);
@property (nonatomic, assign) CGRect firstLoadingAnimationFrame;

- (void)startLoadingMoreAnimating;
- (void)stopLoadingMoreAnimating;
- (void)startFirstLoadingAnimation;
- (void)stopFirstLoadingAnimation;
- (void)showRetryButton;
- (void)hideRetryButton;

@end

NS_ASSUME_NONNULL_END
