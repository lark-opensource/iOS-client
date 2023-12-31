//
//  AWEStickerPickerControllerCollectionStickerPlugin.m
//  CameraClient
//
//  Created by zhangchengtao on 2019/12/25.
//

#import "AWEStickerPickerControllerCollectionStickerPlugin.h"
#import "AWECollectionStickerPickerController.h"
#import <CreationKitInfra/NSDictionary+ACCAddition.h>
#import "AWEStickerDownloadManager.h"

#import <CreativeKit/ACCMacros.h>
#import <CreativeKit/ACCTrackProtocol.h>
#import <CreationKitRTProtocol/ACCCameraService.h>
#import <CameraClient/ACCTrackerUtility.h>

@interface AWEStickerPickerControllerCollectionStickerPlugin () <AWECollectionStickerPickerControllerDelegate>
@property (nonatomic, strong) AWECollectionStickerPickerController *collectionStickerPickerController;
@property (nonatomic, weak) AWEStickerPickerController *controller;
@property (nonatomic, copy) NSSet<NSString *> *stickerIDSet;
@end

@implementation AWEStickerPickerControllerCollectionStickerPlugin

- (void)controllerViewDidLoad:(AWEStickerPickerController *)controller
{
    self.controller = controller;
    self.currentSticker = self.controller.model.currentSticker;
    self.currentChildSticker = self.controller.model.currentChildSticker;
    if ([self.layoutManager isEqual:self.controller]) {
        [self showPanelIfNeeded];
    }
}

- (void)showPanelIfNeeded
{
    if (self.currentSticker.childrenEffects.count > 0) {
        // 如果是聚合贴纸，展示聚合贴纸子面板
        [self p_showCollectionStickersForSticker:self.currentSticker childSticker:self.currentChildSticker];
    }
}

- (void)setLayoutManager:(id<AWEStickerViewLayoutManagerProtocol>)layoutManager
{
    if (self.collectionStickerPickerController) {
        [self.layoutManager removeCollectionStickerView:self.collectionStickerPickerController.view];
    }
    _layoutManager = layoutManager;
    if (self.collectionStickerPickerController) {
        [self.layoutManager addCollectionStickerView:self.collectionStickerPickerController.view];
    }
}

- (void)controller:(AWEStickerPickerController *)controller didSelectNewSticker:(IESEffectModel *)newSticker oldSticker:(IESEffectModel *)oldSticker
{
    self.controller = controller;
    self.currentSticker = newSticker;
    self.currentChildSticker = controller.model.currentChildSticker;

    [self p_resetCollectionStickerPickerController];

    if (newSticker.childrenEffects.count > 0) {
        // 如果是聚合贴纸，展示聚合贴纸子面板
        if (self.currentChildSticker != nil && [self.currentChildSticker.parentEffectID isEqualToString:self.currentSticker.effectIdentifier]) {
            [self p_showCollectionStickersForSticker:newSticker childSticker:self.currentChildSticker];
        } else {
            [self p_showCollectionStickersForSticker:newSticker childSticker:nil];
        }
    }
}

/**
 * 展示合集道具子面板
 */
- (void)p_showCollectionStickersForSticker:(IESEffectModel *)sticker childSticker:(IESEffectModel * _Nullable)childSticker {
    if (sticker.childrenIds.count > 0) {
        self.stickerIDSet = [NSSet setWithArray:sticker.childrenIds];
    }
    
    if (nil == childSticker) {
        childSticker = sticker.childrenEffects.firstObject;
    }
    
    [self p_resetCollectionStickerPickerController];
    if (childSticker.downloaded) {
        self.collectionStickerPickerController = [[AWECollectionStickerPickerController alloc] initWithStickers:sticker.childrenEffects currentSticker:childSticker];
        if (self.didSelectStickerBlock) {
            self.didSelectStickerBlock(childSticker, [self.controller currentStickerIndexPath]? ACCRecordPropChangeReasonUserSelectColletion : ACCRecordPropChangeReasonUnkwon);
        }
    } else {
        self.collectionStickerPickerController = [[AWECollectionStickerPickerController alloc] initWithStickers:sticker.childrenEffects currentSticker:nil];
        self.collectionStickerPickerController.model.stickerWillSelect = childSticker;
        [[AWEStickerDownloadManager manager] downloadStickerIfNeed:childSticker];
    }
    self.collectionStickerPickerController.delegate = self;
    [self.layoutManager addCollectionStickerView:self.collectionStickerPickerController.view];
}

- (void)p_resetCollectionStickerPickerController
{
    if (self.collectionStickerPickerController) {
        [self.layoutManager removeCollectionStickerView:self.collectionStickerPickerController.view];
        self.collectionStickerPickerController = nil;
    }
}

#pragma mark - AWECollectionStickerPickerControllerDelegate

- (void)collectionStickerPickerController:(AWECollectionStickerPickerController *)controller
                       willDisplaySticker:(IESEffectModel *)sticker
                              atIndexPath:(NSIndexPath *)indexPath
{
    NSDictionary *trackingInfoDictionary = ACCBLOCK_INVOKE(self.trackingInfoDictionaryBlock);
    NSMutableDictionary *params = [NSMutableDictionary dictionaryWithDictionary:trackingInfoDictionary];
    params[@"enter_method"] = @"click_banner";
    params[@"parent_pop_id"] = self.currentSticker.effectIdentifier ?: @"";
    params[@"tab_name"] = self.controller.model.currentCategoryModel.categoryName ?: @"";
    params[@"prop_id"] = sticker.effectIdentifier ?: @"";
    params[@"order"] = @(indexPath.item + 1).stringValue;
    params[@"prop_rec_id"] = sticker.recId ?: @"0";
    [ACCTracker() trackEvent:@"prop_show" params:params needStagingFlag:NO];
}

- (void)collectionStickerPickerController:(AWECollectionStickerPickerController *)controller
                        willSelectSticker:(IESEffectModel *)sticker
                              atIndexPath:(NSIndexPath *)indexPath
{
    NSDictionary *trackingInfoDictionary = ACCBLOCK_INVOKE(self.trackingInfoDictionaryBlock);
    NSMutableDictionary *params = [NSMutableDictionary dictionaryWithDictionary:trackingInfoDictionary];
    params[@"enter_from"] = @"video_shoot_page";
    params[@"enter_method"] = @"click_banner";
    params[@"prop_id"] = sticker.effectIdentifier ?: @"";
    params[@"order"] = @(indexPath.item + 1).stringValue;
    params[@"prop_rec_id"] = ACC_isEmptyString(sticker.recId) ? @"0": sticker.recId;
    params[@"impr_position"] = @([self.controller currentStickerIndexPath].row + 1).stringValue;

    NSString *fromPropID = [trackingInfoDictionary acc_stringValueForKey:@"from_prop_id"];
    if (!ACC_isEmptyString(fromPropID)) {
        params[@"is_default_prop"] = [self.stickerIDSet containsObject:fromPropID] ? @"1" : @"0";
    }

    NSString *searchID = self.controller.model.searchID;
    if (!ACC_isEmptyString(searchID)) {
        params[@"search_id"] = searchID;
    }

    NSString *searchMethod = self.controller.model.searchMethod;
    if (!ACC_isEmptyString(searchMethod)) {
        params[@"search_method"] = searchMethod;
    }

    //========================================================================
    id<ACCCameraService> cameraService = self.cameraServiceBlock != NULL ? self.cameraServiceBlock() : nil;
    AVCaptureDevicePosition cameraPostion = cameraService.cameraControl.currentCameraPosition;
    params[@"camera_direction"] = ACCDevicePositionStringify(cameraPostion);
    //========================================================================
    
    [ACCTracker() trackEvent:@"prop_click" params:params needStagingFlag:NO];
}

- (void)collectionStickerPickerController:(AWECollectionStickerPickerController *)controller didSelectSticker:(IESEffectModel *)sticker
{
    if (self.didSelectStickerBlock) {
        self.didSelectStickerBlock(sticker, (controller.selectedIndexPath != nil || [self.controller currentStickerIndexPath] != nil)? ACCRecordPropChangeReasonUserSelectColletion : ACCRecordPropChangeReasonUnkwon);
    }
}

@end
