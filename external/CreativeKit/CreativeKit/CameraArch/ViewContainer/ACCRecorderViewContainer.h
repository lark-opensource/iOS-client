//
//  ACCRecorderViewContainer.h
//  CreativeKit-Pods-Aweme
//
//  Created by Liu Deping on 2021/3/22.
//

#import <Foundation/Foundation.h>
#import "ACCRecorderBarItemContainerView.h"
#import "ACCPanelViewController.h"
#import "ACCSwitchModeContainerView.h"
#import "ACCLayoutContainerProtocol.h"
#import "ACCLayoutViewTypeDefines.h"

/// DO NOT add more properties for indicating propPanel is showing
/// after all, not all the propPanels show at same time, one enum is enough
typedef NS_ENUM(NSUInteger, ACCRecordPropPanelType) {
    ACCRecordPropPanelNone,
//    ACCRecordPropPanelRegular,    /// not take over right now
//    ACCRecordPropPanelExposed,    /// not take over right now
    ACCRecordPropPanelRecognition,
};

NS_ASSUME_NONNULL_BEGIN

@protocol ACCRecorderViewContainerItemsHideShowObserver <NSObject>

- (void)shouldItemsShow:(BOOL)show animated:(BOOL)animated;

@end

@protocol ACCRecorderViewContainer <NSObject>

@property (nonatomic, assign, readonly) BOOL itemsShouldHide;
@property (nonatomic, readonly) id<ACCPanelViewController> panelViewController;
@property (nonatomic, readonly) id<ACCRecorderBarItemContainerView> barItemContainer;
@property (nonatomic, readonly) UIView<ACCSwitchModeContainerView> *switchModeContainerView;
@property (nonatomic, copy, nullable) dispatch_block_t interactionBlock;

- (void)injectBarItemContainer:(id<ACCRecorderBarItemContainerView>)barItemContainer;

- (void)viewContainerDidLoad;

- (void)containerViewDidLayoutSubviews;

@property (nonatomic, weak, readonly) UIView *rootView;
@property (nonatomic, strong, readonly) UIView *interactionView;
@property (nonatomic, strong, readonly) UIView *modeSwitchView;
@property (nonatomic, strong, readonly) UIView *popupContainerView;     // eg: game container
@property (nonatomic, strong, readonly) id<ACCLayoutContainerProtocol> layoutManager;

@property (nonatomic, strong) UIView *preview;

@property (nonatomic, assign) BOOL shouldClearUI;
@property (nonatomic, assign) BOOL isShowingPanel;
@property (nonatomic, assign) BOOL isShowingMVDetailVC;


- (void)addObserver:(id<ACCRecorderViewContainerItemsHideShowObserver>)observer;
- (void)showItems:(BOOL)show animated:(BOOL)animated;

@optional

@property (nonatomic, assign) ACCRecordPropPanelType propPanelType;
- (BOOL)isShowingAnyPanel;

- (void)removeObserver:(id<ACCRecorderViewContainerItemsHideShowObserver>)observer;

@end

NS_ASSUME_NONNULL_END
