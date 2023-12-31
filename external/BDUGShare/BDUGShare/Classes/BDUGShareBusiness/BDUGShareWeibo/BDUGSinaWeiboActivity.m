//
//  BDUGSinaWeiboActivity.m
//  BDUGActivityViewControllerDemo
//
//  Created by 延晋 张 on 16/6/6.
//
//

#import "BDUGSinaWeiboActivity.h"
#import "BDUGWeiboShare.h"
#import "BDUGShareManager.h"
#import "BDUGShareAdapterSetting.h"
#import "BDUGShareError.h"
#import "BDUGVideoImageShare.h"
#import "BDUGShareActivityActionManager.h"

NSString * const BDUGActivityTypePostToWeibo              = @"com.BDUG.UIKit.activity.PostToWeibo";

@interface BDUGSinaWeiboActivity () <TTWeiboShareDelegate>

@property (nonatomic,copy) BDUGActivityCompletionHandler completion;

@end

@implementation BDUGSinaWeiboActivity

@synthesize dataSource = _dataSource, panelId = _panelId;

#pragma mark - Identifier

- (NSString *)contentItemType
{
    return BDUGActivityContentItemTypeWeibo;
}

- (NSString *)activityType
{
    return BDUGActivityTypePostToWeibo;
}

#pragma mark - Display

- (NSString *)contentTitle
{
    if ([self.contentItem respondsToSelector:@selector(contentTitle)] && [self.contentItem contentTitle]) {
        return [self.contentItem contentTitle];
    } else {
        return @"微博";
    }
}

- (NSString *)activityImageName
{
    if ([self.contentItem respondsToSelector:@selector(activityImageName)] && [self.contentItem activityImageName]) {
        return [self.contentItem activityImageName];
    } else {
        return @"BDUGShareWeiboResource.bundle/sina_allshare";
    }
}

#pragma mark - Tracker

- (NSString *)shareLabel {
    return nil;
}

- (BOOL)appInstalled
{
    return [[BDUGWeiboShare sharedWeiboShare] isAvailable];
}

#pragma mark - Action

- (void)shareWithContentItem:(id <BDUGActivityContentItemProtocol>)contentItem presentingViewController:(UIViewController *)presentingViewController onComplete:(BDUGActivityCompletionHandler)onComplete
{
    self.contentItem = (BDUGSinaWeiboContentItem *)contentItem;
    [self performActivityWithCompletion:^(id<BDUGActivityProtocol> activity, NSError *error, NSString *desc) {
        if (onComplete) {
            onComplete(activity, error, desc);
        }
    }];
}

- (void)performActivityWithCompletion:(BDUGActivityCompletionHandler)completion
{
    void (^performBlock)(void) = ^{
        if (self.dataSource &&
            [self.dataSource respondsToSelector:@selector(acticity:waitUntilDataIsReady:)])  {
            __weak typeof(self)weakSelf = self;
            //todo： 测试leak。FBLeak。
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

- (void)beginShareActionWithItemModel:(BDUGShareDataItemModel *)itemModel
{
    [[BDUGShareAdapterSetting sharedService] activityWillSharedWith:self];

    BDUGWeiboShare *weiboShare = [BDUGWeiboShare sharedWeiboShare];
    weiboShare.delegate = self;
    
    BDUGSinaWeiboContentItem *contentItem = self.contentItem;
    
    switch (contentItem.defaultShareType) {
        case BDUGShareText: {
            [weiboShare sendText:contentItem.title withCustomCallbackUserInfo:contentItem.callbackUserInfo];
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
                    [weiboShare sendText:contentItem.title withImage:resultModel.resultImage customCallbackUserInfo:contentItem.callbackUserInfo];
                } else if (statusCode == BDUGVideoShareStatusCodeInvalidContent){
                    err = [BDUGShareError errorWithDomain:BDUGWeiboShareErrorDomain code:BDUGShareErrorTypeInvalidContent userInfo:@{NSLocalizedDescriptionKey: desc}];
                    [self weiboShare:nil sharedWithError:err customCallbackUserInfo:nil];
                } else {
                    err = [BDUGShareError errorWithDomain:BDUGWeiboShareErrorDomain code:BDUGShareErrorTypeOther userInfo:@{NSLocalizedDescriptionKey: desc}];
                    [self weiboShare:nil sharedWithError:err customCallbackUserInfo:nil];
                }
            };
            [BDUGVideoImageShare shareVideoWithInfo:info];
        }
            break;
        case BDUGShareWebPage: {
            [weiboShare sendWebpageWithTitle:contentItem.title webpageURL:contentItem.webPageUrl thumbnailImage:contentItem.thumbImage description:contentItem.desc customCallbackUserInfo:contentItem.callbackUserInfo];
        }
            break;
        default: {
            NSString *desc = @"暂不支持的分享类型";
            NSError *error = [BDUGShareError errorWithDomain:BDUGWeiboShareErrorDomain code:BDUGShareErrorTypeAppNotSupportShareType userInfo:@{NSLocalizedDescriptionKey:desc}];
            [self weiboShare:nil sharedWithError:error customCallbackUserInfo:nil];
        }
            break;
    }
}

#pragma mark - TTWeiboShareDelegate

- (void)weiboShare:(BDUGWeiboShare *)weiboShare sharedWithError:(NSError *)error customCallbackUserInfo:(NSDictionary *)customCallbackUserInfo
{
    NSString *desc = nil;
    if(error) {
        switch (error.code) {
            case BDUGShareErrorTypeAppNotInstalled:
                desc = NSLocalizedString(@"您未安装微博", nil);
                break;
            case BDUGShareErrorTypeAppNotSupportAPI:
                desc = NSLocalizedString(@"您的微博版本过低，无法支持分享", nil);
                break;
            case BDUGShareErrorTypeExceedMaxImageSize:
                desc = NSLocalizedString(@"图片过大，分享图片不能超过10M", nil);
                break;
            default:
                desc = NSLocalizedString(@"分享失败", nil);
                break;
        }
    }else {
        desc = NSLocalizedString(@"分享成功", nil);
    }
    
    if (self.completion) {
        self.completion(self, error, desc);
    }
    [[BDUGShareAdapterSetting sharedService] activityHasSharedWith:self error:error desc:desc];
}

@end
