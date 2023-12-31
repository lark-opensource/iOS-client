//
//  AWEComposerBeautyViewController.h
//  AWEStudio
//
//  Created by Shen Chen on 2019/8/5.
//

#import <UIKit/UIKit.h>
#import <CreationKitBeauty/AWEComposerBeautyEffectCategoryWrapper.h>
#import <CreationKitBeauty/AWEComposerBeautyDelegate.h>
#import <CreationKitBeauty/AWEComposerBeautyViewModel.h>
#import <CreationKitBeauty/ACCBeautyUIConfigProtocol.h>

@interface AWEComposerBeautyViewController : UIViewController

@property (nonatomic, copy) void(^dissmissBlock)(void);
@property (nonatomic, copy) void(^externalDismissBlock)(void); // use external dismiss action
@property (nonatomic, weak) id<AWEComposerBeautyDelegate> delegate;
@property (nonatomic, strong, readonly) AWEComposerBeautyViewModel *viewModel;
@property (nonatomic, strong, readonly) id<ACCBeautyUIConfigProtocol> uiConfig;

- (instancetype)initWithViewModel:(AWEComposerBeautyViewModel *)viewModel;

- (void)showOnViewController:(UIViewController *)controller;
- (void)showOnView:(UIView *)containerView;

- (void)clearSelection;

- (void)reloadPanel;

- (void)refreshSliderDefaultIndicatorPosition:(CGFloat)position;

- (void)updateUIConfig:(id<ACCBeautyUIConfigProtocol>)config;

@end
