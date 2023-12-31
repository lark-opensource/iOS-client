//
//  ACCEditViewContainer.h
//  CameraClient
//
//  Created by Liu Deping on 2020/2/25.
//

#import <Foundation/Foundation.h>
#import "ACCMacros.h"
#import "ACCPanelViewController.h"
#import "ACCEditTRBarItemContainerView.h"
#import "ACCEditBarItemContainerView.h"
#import "ACCEditContainerViewProtocol.h"

NS_ASSUME_NONNULL_BEGIN

@protocol ACCEditViewContainer <NSObject>

@property (nonatomic, readonly) id<ACCPanelViewController> panelViewController;

@property (nonatomic, readonly) id<ACCEditTRBarItemContainerView> topRightBarItemContainer;

@property (nonatomic, readonly) id<ACCEditBarItemContainerView> bottomBarItemContainer;

@property (nonatomic, strong, readonly) UIView *mediaView;

// sticker gesture view
// after sticker new architecture migrated，can be deleted
@property (nonatomic, strong, readonly) UIView *gestureView;

@property (nonatomic, strong, readonly) UIView<ACCEditContainerViewProtocol> *containerView;

@property (nonatomic, copy, nullable) dispatch_block_t interactionBlock;

- (UIView *)rootView;

- (void)viewContainerDidLoad;

- (void)addToolBarBarItem:(ACCBarItem*)barItem;

- (AWEEditActionItemView*)viewWithBarItemID:(nonnull void *)itemId;

- (void)injectTopRightBarItemContainer:(id<ACCEditTRBarItemContainerView>)barItemContainer;

- (void)injectBottomBarItemContainer:(id<ACCEditBarItemContainerView>)barItemContainer;

@end

NS_ASSUME_NONNULL_END
