//
//  AWEImageAndTitleBubble.h
//  Pods
//
//  Created by li xingdong on 2019/7/2.
//

#import <UIKit/UIKit.h>

typedef NS_ENUM(NSInteger, AWEImageAndTitleBubbleDirection)
{
    AWEImageAndTitleBubbleDirectionUp      = 0,
    AWEImageAndTitleBubbleDirectionDown    = 1,
    AWEImageAndTitleBubbleDirectionLeft    = 2,
    AWEImageAndTitleBubbleDirectionRight   = 3
};


@interface AWEImageAndTitleBubble : UIView

- (instancetype)initWithTitle:(NSString *)title
                     subTitle:(NSString *)subTitle
                        image:(UIImage *)image
                      forView:(UIView *)view
              inContainerView:(UIView *)containerView
             anchorAdjustment:(CGPoint)adjustPoint
                    direction:(AWEImageAndTitleBubbleDirection)direction
             isDarkBackGround:(BOOL)isDarkBackGround;

- (void)showWithAnimated:(BOOL)animated;

- (void)dismissWithAnimated:(BOOL)animated;

@end
