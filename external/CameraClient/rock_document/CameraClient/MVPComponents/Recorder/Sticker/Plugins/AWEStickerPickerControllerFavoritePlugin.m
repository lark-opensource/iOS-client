//
//  AWEStickerPickerControllerFavoritePlugin.m
//  CameraClient
//
//  Created by zhangchengtao on 2019/12/25.
//

#import "AWEStickerPickerControllerFavoritePlugin.h"
#import "AWEStickerPickerModel+Favorite.h"
#import <CreationKitInfra/ACCLogProtocol.h>
#import <CreationKitArch/ACCUserServiceProtocol.h>
#import <CreationKitArch/IESEffectModel+ACCSticker.h>
#import <CameraClient/AWEStickerPickerFavoriteView.h>
#import <CreativeKit/ACCTrackProtocol.h>
#import <KVOController/KVOController.h>
#import <CameraClient/IESEffectModel+DStickerAddditions.h>
#import <CreativeKit/ACCMacros.h>

@interface AWEStickerPickerControllerFavoritePlugin ()

@property (nonatomic, weak) AWEStickerPickerController *controller;

@property (nonatomic, strong) AWEStickerPickerFavoriteView *favoriteView;

@end

@implementation AWEStickerPickerControllerFavoritePlugin

- (void)controllerViewDidLoad:(AWEStickerPickerController *)controller
{
    self.controller = controller;
    
    if (controller.model.currentSticker) {
        if (nil == self.favoriteView) {
            self.favoriteView = [[AWEStickerPickerFavoriteView alloc] init];
            [self.favoriteView.favoriteButton addTarget:self action:@selector(p_onFavoriteBtnClicked:) forControlEvents:UIControlEventTouchUpInside];
            [self.layoutManager addFavoriteView:self.favoriteView];
        }
        
        // 判断当前的道具是否是收藏状态
        self.favoriteView.selected = [self.controller.model isMyFavoriteSticker:controller.model.currentSticker];
        self.favoriteView.hidden = [controller.model.currentSticker forbidFavorite];
    }
}

//
// 道具面板加载tab分类数据成功，手动插入"我的收藏"到首位
//
- (void)controllerDidFinishLoadStickerCategories:(AWEStickerPickerController *)controller {
    self.controller = controller;

    __block AWEStickerCategoryModel *category = nil;
    [self.controller.model.stickerCategoryModels enumerateObjectsUsingBlock:^(AWEStickerCategoryModel * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        if (obj.favorite) {
            category = obj;
            *stop = YES;
        }
    }];

    if (category.favorite) {
        // 预加载收藏分类列表数据
        [category loadStickerListIfNeeded];
        
        // 监控收藏分类列表数据的变化，更新收藏按钮选中状态
        @weakify(self);
        [self.KVOController unobserve:category keyPath:FBKVOKeyPath(category.stickers)];
        [self.KVOController observe:category
                            keyPath:FBKVOKeyPath(category.stickers)
                            options:NSKeyValueObservingOptionNew
                              block:^(id  _Nullable observer, id  _Nonnull object, NSDictionary<NSString *,id> * _Nonnull change) {
            acc_dispatch_main_async_safe(^{
                @strongify(self);
                if (object == self.controller.dataSource.favoriteCategoryModel) {
                    [self p_handleFavoriteStickerListChange];
                }
            });
        }];
    }
}

//
// 选中道具后，展示收藏按钮入口；
// 取消选中后，隐藏收藏按钮入口；
//
- (void)controller:(AWEStickerPickerController *)controller
didSelectNewSticker:(IESEffectModel *)newSticker
        oldSticker:(IESEffectModel *)oldSticker {
    self.controller = controller;

    if (newSticker) {
        if (nil == self.favoriteView) {
            self.favoriteView = [[AWEStickerPickerFavoriteView alloc] init];
            [self.favoriteView.favoriteButton addTarget:self action:@selector(p_onFavoriteBtnClicked:) forControlEvents:UIControlEventTouchUpInside];
            [self.layoutManager addFavoriteView:self.favoriteView];
        }
        
        // 判断当前的道具是否是收藏状态
        self.favoriteView.selected = [self.controller.model isMyFavoriteSticker:newSticker];
        self.favoriteView.hidden = [controller.model.currentSticker forbidFavorite];

    } else {
        if (nil != self.favoriteView) {
            [self.layoutManager removeFavoriteView:self.favoriteView];
            self.favoriteView = nil;
        }
    }
}

#pragma mark - Private

/**
 * 收藏分类道具列表数据变化时回调
 * “收藏按钮的选中状态” 判断条件是 “当前选中道具在收藏分类列表中”
 */
- (void)p_handleFavoriteStickerListChange
{
    if (!self.favoriteView) {
        return;
    }

    __block AWEStickerCategoryModel *category = nil;
    [self.controller.model.stickerCategoryModels enumerateObjectsUsingBlock:^(AWEStickerCategoryModel * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        if (obj.favorite) {
            category = obj;
            *stop = YES;
        }
    }];

    IESEffectModel *currentSticker = self.controller.model.currentSticker;
    if (category.favorite && category.stickers.count > 0 && currentSticker) {    
        self.favoriteView.selected = [self.controller.model isMyFavoriteSticker:self.controller.model.currentSticker];
    }
}

- (void)p_onFavoriteBtnClicked:(ACCCollectionButton *)button {
    NSMutableDictionary *trackerInfo = [[NSMutableDictionary alloc] init];
    trackerInfo[@"enter_method"] = @"click_favorite_prop";
    @weakify(self);
    [IESAutoInline(ACCBaseServiceProvider(), ACCUserServiceProtocol) requireLogin:^(BOOL success) {
        @strongify(self);
        if (success) {
            [self p_onFavoriteBtnClicked_IMP:button];
        }
    } withTrackerInformation:trackerInfo];
}

- (void)p_onFavoriteBtnClicked_IMP:(ACCCollectionButton *)btn {
    IESEffectModel *effectModel = self.controller.model.currentSticker;
    if (!effectModel.effectIdentifier) {
        return;
    }

    BOOL selected = btn.selected;
    @weakify(self);
    [self.controller.model updateSticker:effectModel favoriteStatus:!selected completion:^(BOOL success, NSError * _Nullable error) {
        @strongify(self);
        if (success) {
            if (!selected) {
                NSMutableDictionary *params = [NSMutableDictionary dictionaryWithDictionary:self.trackingInfoDictionary];
                params[@"enter_method"] = @"click_main_panel";
                params[@"prop_id"] = effectModel.effectIdentifier ?: @"";
                params[@"enter_from"] = @"video_shoot_page";
                [ACCTracker() trackEvent:@"prop_save" params:params needStagingFlag:NO];
            }
            if (self.favoriteObserver.favoriteResultCallback) {
                self.favoriteObserver.favoriteResultCallback(success, effectModel, !selected);
            }
            // 发送收藏或取消收藏的通知
            [[NSNotificationCenter defaultCenter] postNotificationName:@"AWEFavoriteActionNotification"
                                                                object:nil
                                                              userInfo:@{@"type":@(5),
                                                                         @"itemID":effectModel.effectIdentifier?:@"",
                                                                         @"action":@(selected)}];
        } else {
            if (error) {
                AWELogToolError(AWELogToolTagRecord, @"FavoritePlugin error: %@", error);
            }
            if (self.favoriteObserver.favoriteResultCallback) {
                self.favoriteObserver.favoriteResultCallback(success, effectModel, selected);
            }

            // 失败后恢复收藏按钮
            IESEffectModel *currentSticker = self.controller.model.currentSticker;
            if ([currentSticker.effectIdentifier isEqualToString:effectModel.effectIdentifier] && self.favoriteView) {
                [self.favoriteView.layer removeAllAnimations];
                self.favoriteView.selected = selected;
            }
        }
    }];
    
    [self.favoriteView toggleSelected];
}

@end
