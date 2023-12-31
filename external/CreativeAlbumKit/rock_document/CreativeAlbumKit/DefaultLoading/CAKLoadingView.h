//
//  CAKLoadingView.h
//  CreativeAlbumKit
//
//  Created by yuanchang on 2020/12/14.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM(NSInteger, CAKLoadingViewStatus) {
    CAKLoadingViewStatusStop,
    CAKLoadingViewStatusAnimating,
};

@interface CAKLoadingView : UIView

@property (nonatomic, assign) CGFloat progress;

- (instancetype)initWithBackground;
- (instancetype)initWithBackgroundAndDisableUserInteraction;
- (instancetype)initWithDisableUserInteraction;

- (void)startAnimating;
- (void)stopAnimating;

- (void)dismiss;
- (void)dismissWithAnimated:(BOOL)animated;

@end

NS_ASSUME_NONNULL_END
