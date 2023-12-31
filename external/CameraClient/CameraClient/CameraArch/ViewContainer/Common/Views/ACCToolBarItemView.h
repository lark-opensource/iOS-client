//
//  ACCToolBarItemView.h
//  CameraClient-Pods-Aweme
//
//  Created by bytedance on 2021/6/2.
//

#import <UIKit/UIKit.h>
#import <CreativeKit/ACCBarItem.h>
#import <CreativeKit/ACCBarItemCustomView.h>

typedef NS_ENUM(NSUInteger, ACCToolBarItemViewDirection) {
    ACCToolBarItemViewDirectionHorizontal = 0,
    ACCToolBarItemViewDirectionVertical = 1,
};

// attention: button and enable property would be used, when edit page's components calling viewWithBarItemId and then get this view as AWEEditActionItemView
@interface ACCToolBarItemView : UIView <ACCBarItemCustomView>
@property (nonatomic, strong, nullable) UILabel *label;
@property (nonatomic, strong, nullable) UIButton *button;
@property (nonatomic, assign) BOOL enable;
@property (nonatomic, assign) void *itemId;
@property (nonatomic, assign, readonly) BOOL shouldShowRedPoint;
@property (nonatomic, assign) BOOL shownFirstTime; // first time show in the bar
@property (nonatomic, strong) void (^lottieCompletionBlock)(BOOL animationFinished);
- (void)configWithItem:(ACCBarItem *)item direction:(ACCToolBarItemViewDirection)direction hideRedPoint:(BOOL)hideRedPoint buttonSize:(CGSize)size;
- (void)hideLabelWithDuration:(NSTimeInterval)duration;
- (void)showLabelWithDuration:(NSTimeInterval)duration;
- (void)clearHideRedPointCache;
- (void)showRedPoint;
@end

