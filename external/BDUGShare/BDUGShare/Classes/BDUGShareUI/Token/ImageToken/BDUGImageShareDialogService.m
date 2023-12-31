//
//  BDUGImageShareDialogService.m
//  AFgzipRequestSerializer
//
//  Created by 杨阳 on 2019/5/9.
//
#import "BDUGImageShareDialogService.h"
#import "BDUGImageShareDialogManager.h"
#import "BDUGImageSharePreviewDialog.h"
#import "BDUGTokenShareAnalysisResultTextDialogService.h"
#import "BDUGTokenShareAnalysisResultTextAndImageDialogService.h"
#import "BDUGTokenShareAnalysisResultVideoDialogService.h"
#import "BDUGDialogBaseView.h"
#import "BDUGImageShareModel.h"
#import "BDUGVideoShareUniversalDialog.h"
#import "BDUGShareEvent.h"
#import "UIColor+UGExtension.h"

static BDUGTokenShareServiceActionModel *staticActionModel;
static UIColor *staticThemeColor;

@implementation BDUGImageShareDialogService

+ (instancetype)sharedService
{
    static BDUGImageShareDialogService *sharedService = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedService = [[self class] new];
    });
    return sharedService;
}

#pragma mark - register

+ (void)registerService
{
    [self registerServiceWithAlbumPermissionAlert:NO notificationName:nil];
}

+ (void)registerServiceWithAlbumPermissionAlert:(BOOL)permissionAlert
                               notificationName:(NSString *)notificationName
{
    [BDUGImageShareDialogManager imageShareRegisterDialogBlock:^(BDUGImageShareContentModel *contentModel) {
        [BDUGImageShareDialogService showTokenDialog:contentModel];
    }];
    
    [BDUGImageShareDialogManager imageShareRegisterAlbumAuthorizationDialogBlock:^(BDUGImageShareContentModel *contentModel) {
        BDUGVideoShareDialogInfo *info = [[BDUGVideoShareDialogInfo alloc] init];
        info.titleString = @"权限开启提示";
        info.tipString = @"相册权限已禁用，需开启相册权限后保存图片";
        info.buttonString = @"开启权限";
        [self showDialogWithInfo:info confirmHandler:^(BDUGDialogBaseView *dialogView) {
            [BDUGImageShareDialogManager triggerAlbumAuthorization];
            [BDUGShareEventManager event:kShareAuthorizeClick params:@{
                @"channel_type" : (contentModel.originShareInfo.channelStringForEvent ?: @""),
                @"is_first_request" : @"no",
                @"click_result" : @"submit",
                @"share_type" : @"image",
                @"panel_type" : (contentModel.originShareInfo.panelType ?: @""),
                @"panel_id" : (contentModel.originShareInfo.panelID ?: @""),
                @"resource_id" : (contentModel.originShareInfo.groupID ?: @""),
            }];
            if ([BDUG_IMAGE_SHARE_SERVICE.delegate respondsToSelector:@selector(imageShareAlbumAuthorizationDialogDidClick:panelID:)]) {
                [BDUG_IMAGE_SHARE_SERVICE.delegate imageShareAlbumAuthorizationDialogDidClick:YES panelID:contentModel.originShareInfo.panelID];
            }
        } cancelHandler:^(BDUGDialogBaseView *dialogView) {
            [BDUGShareEventManager event:kShareAuthorizeClick params:@{
                                                            @"channel_type" : (contentModel.originShareInfo.channelStringForEvent ?: @""),
                                                            @"is_first_request" : @"no",
                                                            @"click_result" : @"cancel",
                                                            @"share_type" : @"image",
                                                            @"panel_type" : (contentModel.originShareInfo.panelType ?: @""),
                                                            @"panel_id" : (contentModel.originShareInfo.panelID ?: @""),
                                                            @"resource_id" : (contentModel.originShareInfo.groupID ?: @""),
                                                            }];
            if ([BDUG_IMAGE_SHARE_SERVICE.delegate respondsToSelector:@selector(imageShareAlbumAuthorizationDialogDidClick:panelID:)]) {
                [BDUG_IMAGE_SHARE_SERVICE.delegate imageShareAlbumAuthorizationDialogDidClick:NO panelID:contentModel.originShareInfo.panelID];
            }
        } continueBlock:nil];
        if ([BDUG_IMAGE_SHARE_SERVICE.delegate respondsToSelector:@selector(imageShareAlbumAuthorizationDialogDidShowWithPanelID:)]) {
            [BDUG_IMAGE_SHARE_SERVICE.delegate imageShareAlbumAuthorizationDialogDidShowWithPanelID:contentModel.originShareInfo.panelID];
        }
    }];
    
    [BDUGImageShareDialogManager imageAnalysisRegisterWithPermissionAlert:permissionAlert notificationName:notificationName dialogBlock:^(BDUGImageShareAnalysisResultModel *resultModel) {
        if (!resultModel || !resultModel.tokenInfo) {
            //图片口令解析失败。
            return ;
        }
        BDUGTokenShareDialogType type = resultModel.tokenInfo.mediaType;
        
        BDUGTokenShareServiceActionModel *resultActionModel = [[BDUGTokenShareServiceActionModel alloc] init];
        resultActionModel.showHander = ^(BDUGTokenShareAnalysisResultModel *resultModel) {
            !staticActionModel.showHander ?: staticActionModel.showHander(resultModel);
            //识别弹窗展示埋点。
            [BDUGShareEventManager event:kShareRecognizePopupShow params:@{
                @"show_from" : @"hidden_mark",
                @"media_type" : @(type),
            }];
        };
        resultActionModel.actionHandler = ^(BDUGTokenShareAnalysisResultModel *resultModel) {
            !staticActionModel.actionHandler ?: staticActionModel.actionHandler(resultModel);
            [BDUGShareEventManager event:kShareRecognizePopupClick params:@{
                @"show_from" : @"hidden_mark",
                @"media_type" : @(type),
                @"click_result" : @"submit",
            }];
        };
        resultActionModel.cancelHandler = ^(BDUGTokenShareAnalysisResultModel *resultModel) {
            !staticActionModel.cancelHandler ?: staticActionModel.cancelHandler(resultModel);
            [BDUGShareEventManager event:kShareRecognizePopupClick params:@{
                @"show_from" : @"hidden_mark",
                @"media_type" : @(type),
                @"click_result" : @"close",
            }];
        };
        resultActionModel.tiptapHandler = staticActionModel.tiptapHandler;
        
        switch (type) {
            default:
            case BDUGTokenShareDialogTypeText:
            {
                [BDUGTokenShareAnalysisResultTextDialogService showTokenAnalysisDialog:resultModel.tokenInfo buttonColor:staticThemeColor actionModel:resultActionModel];
                !resultActionModel.showHander ?: resultActionModel.showHander(resultModel.tokenInfo);
            }
                break;
            case BDUGTokenShareDialogTypeTextAndImage:
            case BDUGTokenShareDialogTypePhotos:
            case BDUGTokenShareDialogTypeAudio:
            {
                [BDUGTokenShareAnalysisResultTextAndImageDialogService showTokenAnalysisDialog:resultModel.tokenInfo buttonColor:staticThemeColor actionModel:resultActionModel];
                !resultActionModel.showHander ?: resultActionModel.showHander(resultModel.tokenInfo);
            }
                break;
            case BDUGTokenShareDialogTypeVideo:
            case BDUGTokenShareDialogTypeShortVideo:
            {
                [BDUGTokenShareAnalysisResultVideoDialogService showTokenAnalysisDialog:resultModel.tokenInfo buttonColor:staticThemeColor actionModel:resultActionModel];
                !resultActionModel.showHander ?: resultActionModel.showHander(resultModel.tokenInfo);
            }
                break;
        }
    }];
}

+ (void)registerTokenShareWithActionModel:(BDUGTokenShareServiceActionModel *)actionModel
{
    staticActionModel = actionModel;
}

+ (void)configThemeColor:(UIColor *)themeColor
{
    staticThemeColor = themeColor;
}

+ (void)showTokenDialog:(BDUGImageShareContentModel *)contentModel {
    BDUGDialogBaseView *baseDialog = [[BDUGDialogBaseView alloc] initDialogViewWithTitle:@"保存并分享" buttonColor:staticThemeColor confirmHandler:^(BDUGDialogBaseView *dialogView) {
        [dialogView hide];
        [BDUGImageShareDialogManager shareImage:contentModel];
        if ([BDUG_IMAGE_SHARE_SERVICE.delegate respondsToSelector:@selector(imageShareSaveSucceedDialogDidClick:panelID:)]) {
            [BDUG_IMAGE_SHARE_SERVICE.delegate imageShareSaveSucceedDialogDidClick:YES panelID:contentModel.originShareInfo.panelID];
        }
    } cancelHandler:^(BDUGDialogBaseView *dialogView) {
        [dialogView hide];
        [BDUGImageShareDialogManager cancelImageShare:contentModel];
        if ([BDUG_IMAGE_SHARE_SERVICE.delegate respondsToSelector:@selector(imageShareSaveSucceedDialogDidClick:panelID:)]) {
            [BDUG_IMAGE_SHARE_SERVICE.delegate imageShareSaveSucceedDialogDidClick:NO panelID:contentModel.originShareInfo.panelID];
        }
    }];
    BDUGImageSharePreviewDialog *contentView = [[BDUGImageSharePreviewDialog alloc] initWithFrame:CGRectMake(0, 0, 300, 351)];
    [contentView refreshContent:contentModel];
    [baseDialog addDialogContentView:contentView];
    [baseDialog show];
    [baseDialog setContainerViewColor:[UIColor colorWithHexString:@"f8f8f8"]];
    if ([BDUG_IMAGE_SHARE_SERVICE.delegate respondsToSelector:@selector(imageShareSaveSucceedDialogDidShowWithPanelID:)]) {
        [BDUG_IMAGE_SHARE_SERVICE.delegate imageShareSaveSucceedDialogDidShowWithPanelID:contentModel.originShareInfo.panelID];
    }
}

+ (void)showDialogWithInfo:(BDUGVideoShareDialogInfo *)info
            confirmHandler:(BDUGDialogViewBaseEventHandler)confirmHandler
             cancelHandler:(BDUGDialogViewBaseEventHandler)cancelHandler
             continueBlock:(void(^)(void))continueBlock {
    BDUGVideoShareUniversalDialog *dialog = [[BDUGVideoShareUniversalDialog alloc] initWithFrame:CGRectMake(0, 0, 270, 118)];
    [dialog refreshContent:info];
    
    BDUGDialogBaseView *baseDialog = [[BDUGDialogBaseView alloc] initDialogViewWithTitle:info.buttonString buttonColor:staticThemeColor  confirmHandler:^(BDUGDialogBaseView *dialogView) {
        [dialogView hide];
        !continueBlock ?: continueBlock();
        !confirmHandler ?: confirmHandler(dialogView);
    } cancelHandler:^(BDUGDialogBaseView *dialogView) {
        [dialogView hide];
        !cancelHandler ?: cancelHandler(dialogView);
    }];
    [baseDialog addDialogContentView:dialog];
    [baseDialog show];
}

@end
