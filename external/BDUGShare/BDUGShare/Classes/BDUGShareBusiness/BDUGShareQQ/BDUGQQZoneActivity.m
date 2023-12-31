//
//  BDUGQQZoneActivity.m
//  Pods
//
//  Created by 张 延晋 on 16/06/03.
//
//

#import "BDUGQQZoneActivity.h"
#import "BDUGQQShare.h"
#import "BDUGShareAdapterSetting.h"
#import "BDUGShareActivityActionManager.h"
#import "BDUGShareError.h"
#import "BDUGVideoImageShare.h"
#import "BDUGShareActivityActionManager.h"

NSString * const BDUGActivityTypePostToQQZone             = @"com.BDUG.UIKit.activity.PostToQQZone";
static NSString *const BDUGQZoneSystemActivityType = @"com.tencent.mqq.ShareExtension";

@interface BDUGQQZoneActivity () <BDUGQQShareDelegate>

@property (nonatomic,copy) BDUGActivityCompletionHandler completion;

@end

@implementation BDUGQQZoneActivity

@synthesize dataSource = _dataSource, panelId = _panelId, tokenDialogDidShowBlock = _tokenDialogDidShowBlock;

#pragma mark - Identifier

- (NSString *)contentItemType
{
    return BDUGActivityContentItemTypeQQZone;
}

- (NSString *)activityType
{
    return BDUGActivityTypePostToQQZone;
}

#pragma mark - Display

- (NSString *)contentTitle
{
    if ([self.contentItem respondsToSelector:@selector(contentTitle)] && [self.contentItem contentTitle]) {
        return [self.contentItem contentTitle];
    } else {
        return @"QQ空间";
    }
}

- (NSString *)activityImageName
{
    if ([self.contentItem respondsToSelector:@selector(activityImageName)] && [self.contentItem activityImageName]) {
        return [self.contentItem activityImageName];
    } else {
        return @"BDUGShareQQResource.bundle/qqkj_allshare";
    }
}

- (NSString *)shareLabel
{
    return @"share_qzone";
}

- (BOOL)appInstalled
{
    return [[BDUGQQShare sharedQQShare] isAvailable];
}

#pragma mark - Action

- (void)shareWithContentItem:(id <BDUGActivityContentItemProtocol>)contentItem presentingViewController:(UIViewController *)presentingViewController onComplete:(BDUGActivityCompletionHandler)onComplete
{
    self.contentItem = (BDUGQQZoneContentItem *)contentItem;
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
    
    BDUGQQShare *qqshare = [BDUGQQShare sharedQQShare];
    
    if (![qqshare isAvailable]) {
        NSError *error = [BDUGShareError errorWithDomain:BDUGQQShareErrorDomain code:BDUGShareErrorTypeAppNotInstalled userInfo:nil];
        NSString *desc = @"未安装QQ，请先安装";
        !self.completion ?: self.completion(self, error, desc);
        [[BDUGShareAdapterSetting sharedService] activityHasSharedWith:self error:error desc:desc];
        return;
    }
    
    qqshare.delegate = self;
    
    BDUGQQZoneContentItem *contentItem = self.contentItem;
    itemModel = contentItem.serverDataModel;
    
    BOOL hitUGStrategy = [BDUGShareActivityActionManager performShareWithActivity:self itemModel:itemModel openThirdPlatformBlock:^BOOL{
        return [BDUGQQShare openQQ];
    } activityTypeString:BDUGQZoneSystemActivityType completion:^(id<BDUGActivityProtocol> activity, NSError *error, NSString *desc) {
        !self.completion ?: self.completion(activity, error, desc);
        [[BDUGShareAdapterSetting sharedService] activityHasSharedWith:activity error:error desc:desc];
    }];
    if (hitUGStrategy) {
        //命中UG策略，return，否则继续执行兜底SDK分享。
        return;
    }
    
    switch (contentItem.defaultShareType) {
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
                    [qqshare sendImageToQZoneWithImage:resultModel.resultImage title:contentItem.title customCallbackUserInfo:contentItem.callbackUserInfo];
                } else if (statusCode == BDUGVideoShareStatusCodeInvalidContent){
                    err = [BDUGShareError errorWithDomain:BDUGQQShareErrorDomain code:BDUGShareErrorTypeInvalidContent userInfo:@{NSLocalizedDescriptionKey: desc}];
                    [self qqShare:nil sharedWithError:err customCallbackUserInfo:nil];
                } else {
                    err = [BDUGShareError errorWithDomain:BDUGQQShareErrorDomain code:BDUGShareErrorTypeOther userInfo:@{NSLocalizedDescriptionKey: desc}];
                    [self qqShare:nil sharedWithError:err customCallbackUserInfo:nil];
                }
            };
            [BDUGVideoImageShare shareVideoWithInfo:info];
        }
            break;
        case BDUGShareWebPage:{
            [qqshare sendNewsToQZoneWithURL:contentItem.webPageUrl thumbnailImage:contentItem.thumbImage thumbnailImageURL:contentItem.imageUrl title:contentItem.title description:contentItem.desc customCallbackUserInfo:contentItem.callbackUserInfo];
        }
            break;
        case BDUGShareVideo:{
            [qqshare sendNewsToQZoneWithURL:contentItem.videoURL thumbnailImage:contentItem.thumbImage thumbnailImageURL:contentItem.imageUrl title:contentItem.title description:contentItem.desc customCallbackUserInfo:contentItem.callbackUserInfo];
        }
            break;
        default: {
            NSString *desc = @"暂不支持的分享类型";
            NSError *error = [BDUGShareError errorWithDomain:BDUGQQShareErrorDomain code:BDUGShareErrorTypeAppNotSupportShareType userInfo:@{NSLocalizedDescriptionKey:desc}];
            [self qqShare:nil sharedWithError:error customCallbackUserInfo:nil];
        }
            break;
    }
}

#pragma mark - BDUGQQShareDelegate

- (void)qqShare:(BDUGQQShare *)qqShare sharedWithError:(NSError *)error customCallbackUserInfo:(NSDictionary *)customCallbackUserInfo
{
    NSString *desc = nil;
    if (!error) {
        desc = NSLocalizedString(@"QQ分享成功", nil);
    }else{
        switch (error.code) {
            case BDUGShareErrorTypeAppNotInstalled:
                desc = NSLocalizedString(@"您未安装QQ", nil);
                break;
            case BDUGShareErrorTypeAppNotSupportAPI:
                desc = NSLocalizedString(@"您的QQ版本过低，无法支持分享", nil);
                break;
            default:
                desc = NSLocalizedString(@"QQ分享失败", nil);
                break;
        }
    }

    if (self.completion) {
        self.completion(self, error, desc);
    }
    
    [[BDUGShareAdapterSetting sharedService] activityHasSharedWith:self error:error desc:desc];
}

@end

