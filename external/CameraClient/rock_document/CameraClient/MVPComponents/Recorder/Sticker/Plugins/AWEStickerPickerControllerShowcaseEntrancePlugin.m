//
//  AWEStickerPickerControllerShowcaseEntrancePlugin.m
//  CameraClient-Pods-Aweme
//
//  Created by zhangchengtao on 2020/11/18.
//

#import "AWEStickerPickerControllerShowcaseEntrancePlugin.h"
#import "ACCFriendsServiceProtocol.h"

#import <CreativeKit/ACCServiceLocator.h>

@interface AWEStickerPickerControllerShowcaseEntrancePlugin ()

@property (nonatomic, strong) ACCStickerShowcaseEntranceView *stickerShowcaseEntranceView;

@end

@implementation AWEStickerPickerControllerShowcaseEntrancePlugin

#pragma mark - AWEStickerPickerControllerPluginProtocol

- (void)controllerViewDidLoad:(AWEStickerPickerController *)controller
{
    [self p_showStickerShowcaseEntranceView:controller.model.currentSticker];
}

- (void)controller:(AWEStickerPickerController *)controller didSelectNewSticker:(IESEffectModel *)newSticker oldSticker:(IESEffectModel *)oldSticker
{
    [self p_showStickerShowcaseEntranceView:newSticker];
}

#pragma mark - Private

- (void)p_showStickerShowcaseEntranceView:(IESEffectModel *)sticker
{
    if (self.stickerShowcaseEntranceView) {
        [self.layoutManager removeShowcaseEntranceView:self.stickerShowcaseEntranceView];
        self.stickerShowcaseEntranceView = nil;
    }
    
    if (sticker) {
        self.stickerShowcaseEntranceView = [IESAutoInline(ACCBaseServiceProvider(), ACCFriendsServiceProtocol) createStickerShowcaseEntranceView];
        NSString *creationId = @"";
        if (self.getCreationId) {
            creationId = self.getCreationId();
        }
        [self.stickerShowcaseEntranceView updateWithSticker:sticker creationID:creationId];
        [self.layoutManager addShowcaseEntranceView:self.stickerShowcaseEntranceView];
    }
}

@end
