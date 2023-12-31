//
//  ACCBeautyPanel.h
//  Pods
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import <CreativeKit/ACCPanelViewController.h>
#import <CreativeKit/ACCPanelViewProtocol.h>
#import <CreationKitBeauty/AWEComposerBeautyViewController.h>
#import <CreationKitBeauty/AWEComposerBeautyEffectCategoryWrapper.h>
#import <CreationKitBeauty/AWEComposerBeautyDelegate.h>
#import "ACCBeautyPanelViewModel.h"
#import <CreationKitBeauty/AWEComposerBeautyEffectViewModel.h>
#import <CreationKitBeauty/AWEComposerBeautyViewModel.h>

NS_ASSUME_NONNULL_BEGIN

typedef void(^ACCBeautyPanelShowBlock)(void);
typedef void(^ACCBeautyPanelDismissBlock)(BOOL isComposer);

@protocol ACCCameraService;
@protocol ACCBeautyDataService;
@protocol ACCBeautyBuildInDataSource;
@class ACCBeautyPanelViewModel;

@interface ACCBeautyPanel : NSObject
@property (nonatomic, strong, readonly) ACCBeautyPanelViewModel *viewModel;

@property (nonatomic, strong, readonly) AWEComposerBeautyViewModel *composerVM;
@property (nonatomic, strong, readonly) AWEComposerBeautyEffectViewModel *effectViewModel;
@property (nonatomic, weak) id<AWEComposerBeautyDelegate> composerBeautyDelegate;
@property (nonatomic, copy) AWEComposerBeautyFetchDataBlock fetchComposerDataBlock;

@property (nonatomic, strong) id<ACCPanelViewController> panelViewController;
@property (nonatomic, strong) id<ACCPanelViewProtocol> beautyPanelView;

@property (nonatomic, strong) id<ACCBeautyDataService> dataService;
@property (nonatomic, strong) id<ACCBeautyBuildInDataSource> composerVMDataSource;

#pragma mark - public methods

- (instancetype)initWithViewModel:(ACCBeautyPanelViewModel *)viewModel
                  effectViewModel:(AWEComposerBeautyEffectViewModel *)effectViewModel
                     publishModel:(AWEVideoPublishViewModel *)publishModel;

// open beauty panel
- (void)showPanel;


#pragma mark - Composer Beauty

- (void)updateCurrentComposerCategory;

// Called when the camera is switched
- (void)clearSelection;

//Reload the panel that is currently displaying;
- (void)reloadCurrentPanel;

@end

NS_ASSUME_NONNULL_END
