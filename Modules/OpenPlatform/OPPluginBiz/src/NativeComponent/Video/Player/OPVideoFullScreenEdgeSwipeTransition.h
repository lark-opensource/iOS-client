//
//  OPVideoFullScreenEdgeSwipeTransition.h
//  OPPluginBiz
//
//  Created by zhujingcheng on 2/24/23.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface OPVideoFullScreenInteractiveTranstion : UIPercentDrivenInteractiveTransition

@property (nonatomic, weak) UIViewController *vc;
@property (nonatomic, assign, readonly) BOOL isInteracting;

- (void)addScreenEdgePanGesture;

@end

@interface OPVideoFullScreenEdgeSwipeTransition : NSObject<UIViewControllerAnimatedTransitioning>

@property (nonatomic, strong, readonly) OPVideoFullScreenInteractiveTranstion *interactiveTransition;

- (instancetype)initWithVC:(UIViewController *)vc dismissCompletion:(dispatch_block_t)dismissCompletion;

@end



NS_ASSUME_NONNULL_END
