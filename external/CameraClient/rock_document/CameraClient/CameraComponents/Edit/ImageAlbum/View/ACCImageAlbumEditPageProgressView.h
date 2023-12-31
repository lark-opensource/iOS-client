//
//  ACCImageAlbumEditPageProgressView.h
//  CameraClient-Pods-Aweme
//
//  Created by imqiuhang on 2021/6/28.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface ACCImageAlbumEditPageProgressView : UIView

@property (nonatomic, assign) BOOL usingPageControlType;

@property (nonatomic, assign) NSTimeInterval animationDuration;

/// default is 0
- (instancetype)initWithViewWidth:(CGFloat)viewWidth;

@property (nonatomic, assign) NSInteger numberOfPages;

- (void)pauseAnimation;

- (void)setPageIndex:(NSInteger)pageIndex animation:(BOOL)animation;

@property (nonatomic, assign) BOOL active;

+ (CGFloat)defaultHeight;

@property (nonatomic, copy) void(^selectedIndexHander)(NSInteger index);

@end

NS_ASSUME_NONNULL_END
