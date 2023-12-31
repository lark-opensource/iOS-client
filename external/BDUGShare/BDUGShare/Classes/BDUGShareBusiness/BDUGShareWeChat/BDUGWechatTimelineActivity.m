//
//  BDUGWechatTimelineActivity.m
//  BDUGActivityViewControllerDemo
//
//  Created by 延晋 张 on 16/6/6.
//
//

#import "BDUGWechatTimelineActivity.h"
#import <WechatSDK/WXApi.h>
#import "BDUGWeChatShare.h"
#import "BDUGShareAdapterSetting.h"
#import "BDUGShareActivityActionManager.h"
#import "BDUGShareError.h"
#import "BDUGVideoImageShare.h"

NSString * const BDUGActivityTypePostToWechatTimeline     = @"com.BDUG.UIKit.activity.PostToWechatTimeline";
static NSString *const BDUGTimelineSystemActivityType = @"com.tencent.xin.sharetimeline";

@interface BDUGWechatTimelineActivity ()<BDUGWechatShareDelegate>

@property (nonatomic,copy) BDUGActivityCompletionHandler completion;

@end

@implementation BDUGWechatTimelineActivity

@synthesize dataSource = _dataSource, panelId = _panelId, tokenDialogDidShowBlock = _tokenDialogDidShowBlock;

#pragma mark - Identifier

- (NSString *)contentItemType
{
    return BDUGActivityContentItemTypeWechatTimeLine;
}

- (NSString *)activityType
{
    return BDUGActivityTypePostToWechatTimeline;
}

#pragma mark - Display

- (NSString *)contentTitle
{
    if ([self.contentItem respondsToSelector:@selector(contentTitle)] && [self.contentItem contentTitle]) {
        return [self.contentItem contentTitle];
    } else {
        return @"朋友圈";
    }
}

- (NSString *)activityImageName
{
    if ([self.contentItem respondsToSelector:@selector(activityImageName)] && [self.contentItem activityImageName]) {
        return [self.contentItem activityImageName];
    } else {
        return @"BDUGShareWechatResource.bundle/pyq_allshare";
    }
}

- (NSString *)shareLabel
{
    return @"share_weixin_moments";
}

- (BOOL)appInstalled
{
    return [[BDUGWeChatShare sharedWeChatShare] isAvailable];
}

#pragma mark - Action

- (void)shareWithContentItem:(id <BDUGActivityContentItemProtocol>)contentItem presentingViewController:(UIViewController *)presentingViewController onComplete:(BDUGActivityCompletionHandler)onComplete
{
    self.contentItem = (BDUGWechatTimelineContentItem *)contentItem;
    [self performActivityWithCompletion:^(id<BDUGActivityProtocol> activity, NSError *error, NSString *desc) {
        if (onComplete) {
            onComplete(activity, error, desc);
        }
    }];
}

-(void)performActivityWithCompletion:(BDUGActivityCompletionHandler)completion
{
    void (^performBlock)(void) = ^{
        if (self.dataSource &&
            [self.dataSource respondsToSelector:@selector(acticity:waitUntilDataIsReady:)])  {
            __weak typeof(self)weakSelf = self;
            [self.dataSource acticity:self waitUntilDataIsReady:^(BDUGShareDataItemModel *item) {
                [weakSelf beginShareActionWithItemModel:item];
            }];
        } else {
            //走兜底策略。
            [self beginShareActionWithItemModel:nil];
        }
    };
    self.completion = completion;
    if ([[BDUGShareAdapterSetting sharedService] shouldBlockShareWithActivity:self]) {
        [[BDUGShareAdapterSetting sharedService] didBlockShareWithActivity:self continueBlock:performBlock];
    } else {
        performBlock();
    }
}

- (void)beginShareActionWithItemModel:(BDUGShareDataItemModel *)itemModel {
    
    [[BDUGShareAdapterSetting sharedService] activityWillSharedWith:self];
    
    BDUGWeChatShare *wechatShare = [BDUGWeChatShare sharedWeChatShare];
    
    if (![wechatShare isAvailable]) {
        NSError *error = [BDUGShareError errorWithDomain:BDUGWechatShareErrorDomain code:BDUGShareErrorTypeAppNotInstalled userInfo:nil];
        NSString *desc = @"未安装微信，请先安装";
        !self.completion ?: self.completion(self, error, desc);
        [[BDUGShareAdapterSetting sharedService] activityHasSharedWith:self error:error desc:desc];
        return;
    }
    
    wechatShare.delegate = self;
    BDUGWechatTimelineContentItem *contentItem = self.contentItem;
    itemModel = contentItem.serverDataModel;
    
    BOOL hitUGStrategy = [BDUGShareActivityActionManager performShareWithActivity:self itemModel:itemModel openThirdPlatformBlock:^BOOL{
        return [BDUGWeChatShare openWechat];
    } activityTypeString:BDUGTimelineSystemActivityType completion:^(id<BDUGActivityProtocol> activity, NSError *error, NSString *desc) {
        !self.completion ?: self.completion(activity, error, desc);
        [[BDUGShareAdapterSetting sharedService] activityHasSharedWith:activity error:error desc:desc];
    }];
    if (hitUGStrategy) {
        //命中UG策略，return，否则继续执行兜底SDK分享。
        return;
    }
    
    switch (contentItem.defaultShareType) {
        case BDUGShareText: {
            [wechatShare sendTextToScene:BDUGWechatShareSceneTimeline withText:contentItem.title customCallbackUserInfo:contentItem.callbackUserInfo];
        }
            break;
        case BDUGShareImage: {
            BDUGVideoImageShareInfo *info = [[BDUGVideoImageShareInfo alloc] init];
            info.panelID = self.panelId;
            info.resourceURLString = contentItem.imageUrl;
            info.shareImage = contentItem.image;
            info.platformString = [self contentTitle];
            info.shareStrategy = BDUGVideoImageShareStrategyResponseMemory;
            info.shareType = BDUGVideoImageShareTypeImage;
            info.needPreviewDialog = NO;
            [BDUGShareActivityActionManager convertInfo:info contentItem:contentItem];
            info.completeBlock = ^(BDUGVideoShareStatusCode statusCode, NSString *desc, BDUGVideoImageShareContentModel *resultModel) {
                NSError *err;
                if (statusCode == BDUGVideoShareStatusCodeSuccess && desc.length > 0) {
                    [wechatShare sendImageToScene:BDUGWechatShareSceneTimeline withImage:resultModel.resultImage customCallbackUserInfo:contentItem.callbackUserInfo];
                } else if (statusCode == BDUGVideoShareStatusCodeInvalidContent){
                    err = [BDUGShareError errorWithDomain:BDUGWechatShareErrorDomain code:BDUGShareErrorTypeInvalidContent userInfo:@{NSLocalizedDescriptionKey: desc}];
                    [self weChatShare:nil sharedWithError:err customCallbackUserInfo:nil];
                } else {
                    err = [BDUGShareError errorWithDomain:BDUGWechatShareErrorDomain code:BDUGShareErrorTypeOther userInfo:@{NSLocalizedDescriptionKey: desc}];
                    [self weChatShare:nil sharedWithError:err customCallbackUserInfo:nil];
                }
            };
            [BDUGVideoImageShare shareVideoWithInfo:info];
        }
            break;
        case BDUGShareWebPage: {
            [wechatShare sendWebpageToScene:BDUGWechatShareSceneTimeline withWebpageURL:contentItem.webPageUrl thumbnailImage:contentItem.thumbImage imageURL:contentItem.imageUrl title:contentItem.title description:contentItem.desc customCallbackUserInfo:contentItem.callbackUserInfo];
        }
            break;
        case BDUGShareVideo: {
            [wechatShare sendVideoToScene:BDUGWechatShareSceneTimeline withVideoURL:contentItem.videoURL thumbnailImage:contentItem.thumbImage title:contentItem.title description:contentItem.desc customCallbackUserInfo:contentItem.callbackUserInfo];
        }
            break;
        default: {
            NSString *desc = @"暂不支持的分享类型";
            NSError *error = [BDUGShareError errorWithDomain:BDUGWechatShareErrorDomain code:BDUGShareErrorTypeAppNotSupportShareType userInfo:@{NSLocalizedDescriptionKey:desc}];
            [self weChatShare:nil sharedWithError:error customCallbackUserInfo:nil];
        }
            break;
    }
}

#pragma mark - BDUGWechatShareDelegate

- (void)weChatShare:(BDUGWeChatShare *)weChatShare sharedWithError:(NSError *)error customCallbackUserInfo:(NSDictionary *)customCallbackUserInfo
{
    NSString *desc = nil;
    if(error) {
        switch (error.code) {
            case BDUGShareErrorTypeAppNotInstalled:
                desc = NSLocalizedString(@"您未安装微信", nil);
                break;
            case BDUGShareErrorTypeAppNotSupportAPI:
                desc = NSLocalizedString(@"您的微信版本过低，无法支持分享", nil);
                break;
            case BDUGShareErrorTypeExceedMaxImageSize:
                desc = NSLocalizedString(@"图片过大，分享图片不能超过10M", nil);
                break;
            default:
                desc = NSLocalizedString(@"分享失败", nil);
                break;
        }
    }
    
    if (self.completion) {
        self.completion(self, error, desc);
    }
    
    [[BDUGShareAdapterSetting sharedService] activityHasSharedWith:self error:error desc:desc];
}

@end
