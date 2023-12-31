//
//  ACCEditMeteorModeComponent.m
//  CameraClient-Pods-Aweme-CameraResource_douyin
//
//  Created by Chen Long on 2021/4/27.
//

#import "ACCEditMeteorModeComponent.h"
#import "ACCVideoEditToolBarDefinition.h"
#import "ACCEditBarItemExtraData.h"
#import "AWERepoContextModel.h"
#import "AWERepoTrackModel.h"
#import "ACCRepoImageAlbumInfoModel.h"
#import "AWERepoVideoInfoModel.h"
#import "ACCBarItemToastView.h"
#import "ACCMeteorModeUtils.h"
#import "ACCToolBarItemView.h"
#import "ACCBarItem+Adapter.h"
#import "ACCToolBarContainer.h"
#import "ACCToolBarAdapterUtils.h"

#import <CreativeKit/ACCTrackProtocol.h>
#import <CreativeKit/ACCResourceHeaders.h>
#import <CreativeKit/ACCEditViewContainer.h>
#import <CreationKitArch/ACCBarItemResourceConfigManagerProtocol.h>
#import <lottie-ios/Lottie/LOTAnimationView.h>

@interface ACCEditMeteorModeComponent ()

@property (nonatomic, strong) id<ACCEditViewContainer> viewContainer;

@property (nonatomic, strong) LOTAnimationView *lottieView;

@end

@implementation ACCEditMeteorModeComponent

IESAutoInject(self.serviceProvider, viewContainer, ACCEditViewContainer)

- (ACCFeatureComponentLoadPhase)preferredLoadPhase
{
    return ACCFeatureComponentLoadPhaseEager;
}

- (void)loadComponentView
{
    [self.viewContainer addToolBarBarItem:[self barItem]];
}

- (void)componentDidMount
{
    if (![self.controller enableFirstRenderOptimize]) {
        [self loadComponentView];
    }
}

- (void)componentWillAppear
{
    AWEEditActionItemView *itemView = [self.viewContainer viewWithBarItemID:ACCEditToolBarMeteorModeContext];
    itemView.button.selected = self.repository.repoContext.isMeteorMode;
    [self p_configBarItemAccessiblity];
}

#pragma mark - bar item
- (ACCBarItem<ACCEditBarItemExtraData*>*)barItem
{
    let config = [IESAutoInline(self.serviceProvider, ACCBarItemResourceConfigManagerProtocol) configForIdentifier:ACCEditToolBarMeteorModeContext];
    
    if (!config) {
        return nil;
    }
    
    ACCBarItem<ACCEditBarItemExtraData*>* barItem = [[ACCBarItem alloc] init];
    barItem.title = config.title;
    barItem.imageName = config.imageName;
    barItem.selectedImageName = config.selectedImageName;
    barItem.location = config.location;
    barItem.placeLastUnfold = YES;
    barItem.itemId = ACCEditToolBarMeteorModeContext;
    barItem.type = ACCBarItemFunctionTypeDefault;

    @weakify(self);
    barItem.barItemActionBlock = ^(UIView * _Nonnull itemView) {
        @strongify(self);
        [self p_handleClickBarItem];
    };
    barItem.needShowBlock = ^BOOL{
        @strongify(self);
        return ![self.repository.repoImageAlbumInfo isImageAlbumEdit];
    };

    barItem.extraData = [[ACCEditBarItemExtraData alloc] initWithButtonClass:nil type:AWEEditAndPublishViewDataTypeMeteorMode];
    [self p_forceInsert];
    return barItem;
}

- (void)p_forceInsert
{
    if ([ACCToolBarAdapterUtils useAdaptedToolBarContainer]) {
        ACCToolBarContainer *barItemContainer = (ACCToolBarContainer *)self.viewContainer.topRightBarItemContainer;
        [barItemContainer forceInsertWithBarItemIdsArray:@[[NSValue valueWithPointer:ACCEditToolBarMeteorModeContext]]];
    }
}

- (void)p_configBarItemAccessiblity
{
    BOOL isMeteorModeOn = self.repository.repoContext.isMeteorMode;
    AWEEditActionItemView *itemView = (AWEEditActionItemView *)[self.viewContainer.topRightBarItemContainer viewWithBarItemID:ACCEditToolBarMeteorModeContext];
    itemView.button.accessibilityLabel = [NSString stringWithFormat:@"%@%@", @"一闪而过", isMeteorModeOn ? @"已开启" : @"已关闭"];
    itemView.button.accessibilityTraits = UIAccessibilityTraitButton;
}

- (void)p_handleClickBarItem
{
    self.repository.repoContext.isMeteorMode = !self.repository.repoContext.isMeteorMode;
    
    AWEEditActionItemView *itemView = [self.viewContainer viewWithBarItemID:ACCEditToolBarMeteorModeContext];
    itemView.button.selected = !itemView.button.selected;
    
    BOOL isMeteorModeOn = self.repository.repoContext.isMeteorMode;
    self.lottieView = [LOTAnimationView animationWithFilePath:ACCResourceFile(isMeteorModeOn ? @"acc_bar_item_meteor_mode_open.json" : @"acc_bar_item_meteor_mode_close.json")];
    self.lottieView.frame = [itemView.button convertRect:itemView.button.bounds toView:self.viewContainer.containerView];
    self.lottieView.frame = CGRectMake(self.lottieView.frame.origin.x + (self.lottieView.frame.size.width - 32) / 2,
                                        self.lottieView.frame.origin.y + (self.lottieView.frame.size.height - 32) / 2,
                                       32,
                                       32);
    [self.viewContainer.containerView addSubview:self.lottieView];
    [self.lottieView play];

    [self p_configBarItemAccessiblity];

    dispatch_block_t dismissBlock = nil;
    if ([ACCToolBarAdapterUtils useToolBarFoldStyle]) {
        ACCToolBarItemView *itemView = (ACCToolBarItemView *)[self.viewContainer.topRightBarItemContainer viewWithBarItemID:ACCEditToolBarMeteorModeContext];
        [itemView hideLabelWithDuration:0.3];
        dismissBlock = ^{
            [itemView showLabelWithDuration:0];
        };
    }

    itemView.button.hidden = YES;
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.2 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [self.lottieView removeFromSuperview];
        self.lottieView = nil;
        itemView.button.hidden = NO;
        [ACCBarItemToastView showOnAnchorBarItem:itemView.button withContent:isMeteorModeOn ? @"每个人只能查看一次" : @"已关闭" dismissBlock:dismissBlock];
    });
    
    [ACCMeteorModeUtils markHasUseMeteorMode];
    
    [ACCTracker() trackEvent:@"click_meteormode_button" params:@{
        @"enter_from" : self.repository.repoTrack.enterFrom ?: @"",
        @"shoot_way" : self.repository.repoTrack.referString ?: @"",
        @"to_status" : self.repository.repoContext.isMeteorMode ? @"on" : @"off",
        @"creation_id" : self.repository.repoContext.createId ?: @"",
    }];
}

@end
