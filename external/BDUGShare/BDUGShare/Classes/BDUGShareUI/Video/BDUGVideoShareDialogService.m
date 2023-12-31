//
//  BDUGImageShareDialogService.m
//  AFgzipRequestSerializer
//
//  Created by 杨阳 on 2019/5/9.
//

#define BDUG_VIDEO_SHARE_SERVICE [BDUGVideoShareDialogService sharedService]

#import "BDUGVideoShareDialogService.h"
#import "BDUGVideoImageShareDialogManager.h"
#import "BDUGVideoShareUniversalDialog.h"
#import "BDUGDialogBaseView.h"
#import "BDUGVideoImageShareModel.h"
#import "BDUGDownloadProgressView.h"
#import <ByteDanceKit/ByteDanceKit.h>
#import "BDUGShareAdapterSetting.h"
#import "BDUGShareEvent.h"

@interface BDUGVideoShareDialogService ()

@property (nonatomic, strong) UIColor *buttonColor;

@end

@implementation BDUGVideoShareDialogService

#pragma mark - life cylcle

+ (void)registerService
{
    [BDUGVideoImageShareDialogManager videoPreviewShareRegisterDialogBlock:^(BDUGVideoImageShareInfo *shareInfo, BDUGVideoShareBlock continueBlock) {
        BDUGVideoShareDialogInfo *info = [[BDUGVideoShareDialogInfo alloc] init];
        info.titleString = @"保存视频分享";
        info.tipString = [NSString stringWithFormat:@"由于%@分享限制，需保存视频，到%@上传视频分享。", shareInfo.platformString, shareInfo.platformString];
        info.buttonString = @"保存并分享";
        [self showDialogWithInfo:info confirmHandler:^(BDUGDialogBaseView *dialogView) {
            if ([BDUG_VIDEO_SHARE_SERVICE.delegate respondsToSelector:@selector(videoSharePreviewDialogDidClick:panelID:)]) {
                [BDUG_VIDEO_SHARE_SERVICE.delegate videoSharePreviewDialogDidClick:YES panelID:shareInfo.panelID];
            }
            [BDUGShareEventManager event:kSharePopupClick params:@{
                @"channel_type" : (shareInfo.channelStringForEvent ?: @""),
                @"share_type" : @"video",
                @"popup_type" : @"lead_share",
                @"click_result" : @"submit",
                @"panel_type" : (shareInfo.panelType ?: @""),
                @"panel_id" : (shareInfo.panelID ?: @""),
                @"resource_id" : (shareInfo.resourceID ?: @""),
            }];
        } cancelHandler:^(BDUGDialogBaseView *dialogView) {
            if ([BDUG_VIDEO_SHARE_SERVICE.delegate respondsToSelector:@selector(videoSharePreviewDialogDidClick:panelID:)]) {
                [BDUG_VIDEO_SHARE_SERVICE.delegate videoSharePreviewDialogDidClick:NO panelID:shareInfo.panelID];
            }
            [BDUGShareEventManager event:kSharePopupClick params:@{
                                                         @"channel_type" : (shareInfo.channelStringForEvent ?: @""),
                                                         @"share_type" : @"video",
                                                         @"popup_type" : @"lead_share",
                                                         @"click_result" : @"cancel",
                                                         @"panel_type" : (shareInfo.panelType ?: @""),
                                                         @"panel_id" : (shareInfo.panelID ?: @""),
                                                         @"resource_id" : (shareInfo.resourceID ?: @""),
                                                         }];
        } continueBlock:continueBlock];
        if ([BDUG_VIDEO_SHARE_SERVICE.delegate respondsToSelector:@selector(videoSharePreviewDialogDidShowWithPanelID:)]) {
            [BDUG_VIDEO_SHARE_SERVICE.delegate videoSharePreviewDialogDidShowWithPanelID:shareInfo.panelID];
        }
        [BDUGShareEventManager event:kSharePopupShow params:@{
                                                    @"channel_type" : (shareInfo.channelStringForEvent ?: @""),
                                                    @"popup_type" : @"lead_share",
                                                    @"share_type" : @"video",
                                                    @"panel_type" : (shareInfo.panelType ?: @""),
                                                    @"panel_id" : (shareInfo.panelID ?: @""),
                                                    @"resource_id" : (shareInfo.resourceID ?: @""),
                                                    }];
    }];
    
    [BDUGVideoImageShareDialogManager albumAuthorizationRegisterDialogBlock:^(BDUGVideoImageShareInfo *shareInfo, BDUGVideoShareBlock continueBlock) {
        BDUGVideoShareDialogInfo *info = [[BDUGVideoShareDialogInfo alloc] init];
        info.titleString = @"权限开启提示";
        info.tipString = @"相册权限已禁用，需开启相册权限后保存视频";
        info.buttonString = @"开启权限";
        [self showDialogWithInfo:info confirmHandler:^(BDUGDialogBaseView *dialogView) {
            if ([BDUG_VIDEO_SHARE_SERVICE.delegate respondsToSelector:@selector(videoShareAlbumAuthorizationDialogDidClick:panelID:)]) {
                [BDUG_VIDEO_SHARE_SERVICE.delegate videoShareAlbumAuthorizationDialogDidClick:YES panelID:shareInfo.panelID];
            }
            [BDUGShareEventManager event:kShareAuthorizeClick params:@{
                                                            @"channel_type" : (shareInfo.channelStringForEvent ?: @""),
                                                            @"is_first_request" : @"no",
                                                            @"click_result" : @"submit",
                                                            @"share_type" : @"video",
                                                            @"panel_type" : (shareInfo.panelType ?: @""),
                                                            @"panel_id" : (shareInfo.panelID ?: @""),
                                                            @"resource_id" : (shareInfo.resourceID ?: @""),
                                                            }];
        } cancelHandler:^(BDUGDialogBaseView *dialogView) {
            if ([BDUG_VIDEO_SHARE_SERVICE.delegate respondsToSelector:@selector(videoShareAlbumAuthorizationDialogDidClick:panelID:)]) {
                [BDUG_VIDEO_SHARE_SERVICE.delegate videoShareAlbumAuthorizationDialogDidClick:NO panelID:shareInfo.panelID];
            }
            [BDUGShareEventManager event:kShareAuthorizeClick params:@{
                                                            @"channel_type" : (shareInfo.channelStringForEvent ?: @""),
                                                            @"is_first_request" : @"no",
                                                            @"click_result" : @"cancel",
                                                            @"share_type" : @"video",
                                                            @"panel_type" : (shareInfo.panelType ?: @""),
                                                            @"panel_id" : (shareInfo.panelID ?: @""),
                                                            @"resource_id" : (shareInfo.resourceID ?: @""),
                                                            }];
        } continueBlock:continueBlock];
        if ([BDUG_VIDEO_SHARE_SERVICE.delegate respondsToSelector:@selector(videoShareAlbumAuthorizationDialogDidShowWithPanelID:)]) {
            [BDUG_VIDEO_SHARE_SERVICE.delegate videoShareAlbumAuthorizationDialogDidShowWithPanelID:shareInfo.panelID];
        }
    }];
    
    __block BDUGDownloadProgressView *loadingView;
    [BDUGVideoImageShareDialogManager videoDownloadRegisterProgress:^(CGFloat progress) {
        if (!loadingView) {
            loadingView = [[BDUGDownloadProgressView alloc] initWithType:BDUGProgressLoadingViewTypeProgress
                                                                   title:@"正在保存到本地"];
            }
        if (loadingView.status != BDUGProgressLoadingViewStatusAnimating) {
            UIViewController *parentVC = [BTDResponder topNavigationControllerForResponder:[BTDResponder topViewController]];
            [loadingView showOnView:parentVC.view animated:YES];
        }
        loadingView.progress = progress;
    } completion:^{
        [loadingView dismissAnimated:YES];
    }];
    
    [BDUGVideoImageShareDialogManager videoSaveSucceedRegisterDialogBlock:^(BDUGVideoImageShareContentModel *contentModel, BDUGVideoShareBlock continueBlock) {
        BDUGVideoShareDialogInfo *info = [[BDUGVideoShareDialogInfo alloc] init];
        info.titleString = @"已保存至相册";
        info.tipString = [NSString stringWithFormat:@"视频已保存成功，请到%@上传视频分享。", contentModel.originShareInfo.platformString];
        info.buttonString = [NSString stringWithFormat:@"继续分享到%@", contentModel.originShareInfo.platformString];
        [self showDialogWithInfo:info confirmHandler:^(BDUGDialogBaseView *dialogView) {
            if ([BDUG_VIDEO_SHARE_SERVICE.delegate respondsToSelector:@selector(videoShareSaveSucceedDialogDidClick:panelID:)]) {
                [BDUG_VIDEO_SHARE_SERVICE.delegate videoShareSaveSucceedDialogDidClick:YES panelID:contentModel.originShareInfo.panelID];
            }
            [BDUGShareEventManager event:kSharePopupClick params:@{
                @"channel_type" : (contentModel.originShareInfo.channelStringForEvent ?: @""),
                @"share_type" : @"video",
                @"popup_type" : @"go_share",
                @"click_result" : @"submit",
                @"panel_type" : (contentModel.originShareInfo.panelType ?: @""),
                @"panel_id" : (contentModel.originShareInfo.panelID ?: @""),
                @"resource_id" : (contentModel.originShareInfo.resourceID ?: @""),
                                                         }];
        } cancelHandler:^(BDUGDialogBaseView *dialogView) {
            if ([BDUG_VIDEO_SHARE_SERVICE.delegate respondsToSelector:@selector(videoShareSaveSucceedDialogDidClick:panelID:)]) {
                [BDUG_VIDEO_SHARE_SERVICE.delegate videoShareSaveSucceedDialogDidClick:NO panelID:contentModel.originShareInfo.panelID];
            }
            [BDUGShareEventManager event:kSharePopupClick params:@{
                                                         @"channel_type" : (contentModel.originShareInfo.channelStringForEvent ?: @""),
                                                         @"share_type" : @"video",
                                                         @"popup_type" : @"go_share",
                                                         @"click_result" : @"cancel",
                                                         @"panel_type" : (contentModel.originShareInfo.panelType ?: @""),
                                                         @"panel_id" : (contentModel.originShareInfo.panelID ?: @""),
                                                         @"resource_id" : (contentModel.originShareInfo.resourceID ?: @""),
                                                         }];
        } continueBlock:continueBlock];
        if ([BDUG_VIDEO_SHARE_SERVICE.delegate respondsToSelector:@selector(videoShareSaveSucceedDialogDidShowWithPanelID:)]) {
            [BDUG_VIDEO_SHARE_SERVICE.delegate videoShareSaveSucceedDialogDidShowWithPanelID:contentModel.originShareInfo.panelID];
        }
        [BDUGShareEventManager event:kSharePopupShow params:@{
                                                    @"channel_type" : (contentModel.originShareInfo.channelStringForEvent ?: @""),
                                                    @"popup_type" : @"go_share",
                                                    @"share_type" : @"video",
                                                    @"panel_type" : (contentModel.originShareInfo.panelType ?: @""),
                                                    @"panel_id" : (contentModel.originShareInfo.panelID ?: @""),
                                                    @"resource_id" : (contentModel.originShareInfo.resourceID ?: @""),
                                                    }];
    }];
}

+ (instancetype)sharedService
{
    static BDUGVideoShareDialogService *sharedService = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedService = [[self class] new];
    });
    return sharedService;
}

+ (void)configThemeColor:(UIColor *)themeColor
{
    BDUG_VIDEO_SHARE_SERVICE.buttonColor = themeColor;
}

#pragma mark - show dialog

+ (void)showDialogWithInfo:(BDUGVideoShareDialogInfo *)info
            confirmHandler:(BDUGDialogViewBaseEventHandler)confirmHandler
             cancelHandler:(BDUGDialogViewBaseEventHandler)cancelHandler
             continueBlock:(BDUGVideoShareBlock)continueBlock {
    BDUGVideoShareUniversalDialog *dialog = [[BDUGVideoShareUniversalDialog alloc] initWithFrame:CGRectMake(0, 0, 270, 118)];
    [dialog refreshContent:info];
    
    BDUGDialogBaseView *baseDialog = [[BDUGDialogBaseView alloc] initDialogViewWithTitle:info.buttonString buttonColor:BDUG_VIDEO_SHARE_SERVICE.buttonColor confirmHandler:^(BDUGDialogBaseView *dialogView) {
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
