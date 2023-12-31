//
//  CAKSwipeInteractionController.h
//  CreativeAlbumKit
//
//  Created by yuanchang on 2020/12/9.
//

#import <UIKit/UIKit.h>

@protocol CAKSwipeInteractionControllerDelegate <NSObject>

- (void)didCompleteTransitionWithPanProgress:(CGFloat)progress;

@end


@interface CAKSwipeInteractionController : UIPercentDrivenInteractiveTransition

@property (nonatomic, assign) BOOL interactionInProgress;
@property (nonatomic, assign) BOOL shouldCompleteTransition;
@property (nonatomic, weak, nullable) UIViewController *viewController;
@property (nonatomic, assign) BOOL forbidTransitionGes;
@property (nonatomic, assign) BOOL forbidSimultaneousScrollViewPanGesture;
@property (nonatomic, weak, nullable) id<CAKSwipeInteractionControllerDelegate> delegate;

- (void)wireToViewController:(UIViewController * _Nullable)viewController;

@end
