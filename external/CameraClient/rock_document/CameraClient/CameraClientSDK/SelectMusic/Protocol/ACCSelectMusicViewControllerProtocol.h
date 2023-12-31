//
//  ACCSelectMusicViewControllerProtocol.h
//  AWEStudio
//
//  Created by xiaojuan on 2020/9/7.
//

#ifndef ACCSelectMusicViewControllerProtocol_h
#define ACCSelectMusicViewControllerProtocol_h

#import <CameraClient/UIViewController+ACCUIKitEmptyPage.h>

@protocol ACCTransitionViewControllerProtocol <NSObject>

- (void)wireToViewController:(UIViewController *)viewController;

- (void)setToFrame:(CGRect)frame;

- (id<UIViewControllerTransitioningDelegate>)targetTransitionDelegate;

@end

@protocol ACCInsetsLabelProtocol <NSObject>
@property (nonatomic, assign) UIEdgeInsets edgeInsets;

- (UILabel *)targetLabel;

@end

@protocol ACCViewControllerEmptyPageHelperProtocol <NSObject>

@optional
- (void)configEmptyPageState:(ACCUIKitViewControllerState)state;

@end


// TODO: @zzh, 重构时考虑和 ACCSelectMusicProtocol 合并
@protocol ACCSelectMusicViewControllerBuilderProtocol <NSObject>

- (id<ACCTransitionViewControllerProtocol>)createTransitionDelegate;

- (id<ACCInsetsLabelProtocol>)createInsetsLabel;
 
@end

#endif /* AWEStudioSelectMusicViewControllerProtocol_h */
