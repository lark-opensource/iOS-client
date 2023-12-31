//
//  BDUGWhatsAppActivity.m
//  AFgzipRequestSerializer
//
//  Created by 杨阳 on 2019/5/29.
//

#import "BDUGWhatsAppActivity.h"
#import "BDUGWhatsAppShare.h"
#import "BDUGShareAdapterSetting.h"
#import "BDUGVideoImageShare.h"
#import "BDUGShareError.h"
#import "BDUGShareActivityActionManager.h"

NSString * const BDUGActivityTypePostToWhatsApp = @"com.BDUG.UIKit.activity.PostToWhatsApp";

@interface BDUGWhatsAppActivity () <BDUGWhatsAppShareDelegate>

@property (nonatomic,copy) BDUGActivityCompletionHandler completion;

@end

@implementation BDUGWhatsAppActivity

@synthesize dataSource = _dataSource, panelId = _panelId;

- (NSString *)contentItemType
{
    return BDUGActivityContentItemTypeWhatsApp;
}

- (NSString *)activityType
{
    return BDUGActivityTypePostToWhatsApp;
}

#pragma mark - Display

- (NSString *)contentTitle
{
    if ([self.contentItem respondsToSelector:@selector(contentTitle)] && [self.contentItem contentTitle]) {
        return [self.contentItem contentTitle];
    } else {
        return @"WhatsApp";
    }
}

- (NSString *)activityImageName
{
    if ([self.contentItem respondsToSelector:@selector(activityImageName)] && [self.contentItem activityImageName]) {
        return [self.contentItem activityImageName];
    } else {
        return @"BDUGShareWhatsAppResource.bundle/whatsapp_allshare";
    }
}

- (NSString *)shareLabel
{
    return @"share_whatsapp";
}

- (BOOL)appInstalled
{
    return [BDUGWhatsAppShare whatsappInstalled];
}

#pragma mark - Action

- (void)shareWithContentItem:(id<BDUGActivityContentItemProtocol>)contentItem presentingViewController:(UIViewController *)presentingViewController onComplete:(BDUGActivityCompletionHandler)onComplete
{
    self.contentItem = (BDUGWhatsAppContentItem *)contentItem;
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

- (void)beginShareActionWithItemModel:(BDUGShareDataItemModel *)itemModel {
    [[BDUGShareAdapterSetting sharedService] activityWillSharedWith:self];
    
    BDUGWhatsAppShare *whatsappShare = [BDUGWhatsAppShare sharedWhatsAppShare];
    whatsappShare.delegate = self;
    
    BDUGWhatsAppContentItem *whatsappItem = [self contentItem];
    
    switch (whatsappItem.defaultShareType) {
        case BDUGShareText: {
            [whatsappShare sendText:whatsappItem.title];
        }
            break;
        case BDUGShareWebPage: {
            [whatsappShare sendText:whatsappItem.webPageUrl];
        }
            break;
        case BDUGShareImage: {
            BDUGVideoImageShareInfo *info = [[BDUGVideoImageShareInfo alloc] init];
            info.panelID = self.panelId;
            info.resourceURLString = whatsappItem.imageUrl;
            info.shareImage = whatsappItem.image;
            info.platformString = [self contentTitle];
            info.shareStrategy = BDUGVideoImageShareStrategyResponseMemory;
            info.shareType = BDUGVideoImageShareTypeImage;
            info.needPreviewDialog = NO;
            [BDUGShareActivityActionManager convertInfo:info contentItem:whatsappItem];
            info.completeBlock = ^(BDUGVideoShareStatusCode statusCode, NSString *desc, BDUGVideoImageShareContentModel *resultModel) {
                NSError *err;
                if (statusCode == BDUGVideoShareStatusCodeSuccess && desc.length > 0) {
                    [whatsappShare sendImage:resultModel.resultImage];
                } else if (statusCode == BDUGVideoShareStatusCodeInvalidContent){
                    err = [BDUGShareError errorWithDomain:BDUGWhatsAppShareErrorDomain code:BDUGShareErrorTypeInvalidContent userInfo:@{NSLocalizedDescriptionKey: desc}];
                    [self whatsappShare:nil sharedWithError:err];
                } else {
                    err = [BDUGShareError errorWithDomain:BDUGWhatsAppShareErrorDomain code:BDUGShareErrorTypeOther userInfo:@{NSLocalizedDescriptionKey: desc}];
                    [self whatsappShare:nil sharedWithError:err];
                }
            };
            [BDUGVideoImageShare shareVideoWithInfo:info];
        }
            break;
        case BDUGShareVideo: {
            BDUGVideoImageShareInfo *info = [[BDUGVideoImageShareInfo alloc] init];
            info.panelID = self.panelId;
            info.resourceURLString = whatsappItem.videoURL;
            info.platformString = [self contentTitle];
            info.sandboxPath = whatsappItem.resourceSandboxPathString;
            info.shareStrategy = BDUGVideoImageShareStrategyResponseSaveSandbox;
            info.shareType = BDUGVideoImageShareTypeVideo;
            info.needPreviewDialog = NO;
            [BDUGShareActivityActionManager convertInfo:info contentItem:whatsappItem];
            info.completeBlock = ^(BDUGVideoShareStatusCode statusCode, NSString *desc, BDUGVideoImageShareContentModel *resultModel) {
                NSError *err;
                if (statusCode == BDUGVideoShareStatusCodeSuccess && desc.length > 0) {
                    [whatsappShare sendFileWithSandboxPath:resultModel.sandboxPath];
                } else if (statusCode == BDUGVideoShareStatusCodeInvalidContent){
                    err = [BDUGShareError errorWithDomain:BDUGWhatsAppShareErrorDomain code:BDUGShareErrorTypeInvalidContent userInfo:@{NSLocalizedDescriptionKey: desc}];
                    [self whatsappShare:nil sharedWithError:err];
                } else {
                    err = [BDUGShareError errorWithDomain:BDUGWhatsAppShareErrorDomain code:BDUGShareErrorTypeOther userInfo:@{NSLocalizedDescriptionKey: desc}];
                    [self whatsappShare:nil sharedWithError:err];
                }
            };
            [BDUGVideoImageShare shareVideoWithInfo:info];
        }
            break;
        default: {
            NSString *desc = @"暂不支持的分享类型";
            NSError *error = [BDUGShareError errorWithDomain:BDUGWhatsAppShareErrorDomain code:BDUGShareErrorTypeAppNotSupportShareType userInfo:@{NSLocalizedDescriptionKey:desc}];
            [self whatsappShare:nil sharedWithError:error];
        }
            break;
    }
}

#pragma mark - BDUGWechatShareDelegate

- (void)whatsappShare:(BDUGWhatsAppShare *)whatsappShare sharedWithError:(NSError *)error
{
    NSString *desc = nil;
    if (error) {
        switch (error.code) {
            case BDUGShareErrorTypeAppNotInstalled:
                desc = NSLocalizedString(@"您未安装WhatsApp", nil);
                break;
            case BDUGShareErrorTypeInvalidContent:
                desc = NSLocalizedString(@"资源不可用", nil);
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
