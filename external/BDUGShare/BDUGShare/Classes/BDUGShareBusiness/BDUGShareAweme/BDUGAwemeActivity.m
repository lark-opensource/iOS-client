//
//  BDUGAwemeActivity.m
//  Pods
//
//  Created by 王霖 on 6/12/16.
//
//

#import "BDUGAwemeActivity.h"
#import "BDUGAwemeShare.h"
#import "BDUGShareAdapterSetting.h"
#import "BDUGVideoImageShare.h"
#import "BDUGShareError.h"
#import "BDUGShareActivityActionManager.h"

NSString * const BDUGActivityTypePostToAweme = @"com.BDUG.UIKit.activity.PostToAweme";

@interface BDUGAwemeActivity () <BDUGAwemeShareDelegate>

@property (nonatomic,copy) BDUGActivityCompletionHandler completion;

@end

@implementation BDUGAwemeActivity

@synthesize dataSource = _dataSource, panelId = _panelId, tokenDialogDidShowBlock = _tokenDialogDidShowBlock;

- (NSString *)contentItemType {
    return BDUGActivityContentItemTypeAweme;
}

- (NSString *)activityType {
    return BDUGActivityTypePostToAweme;
}

- (NSString *)contentTitle
{
    if ([self.contentItem respondsToSelector:@selector(contentTitle)] && [self.contentItem contentTitle]) {
        return [self.contentItem contentTitle];
    } else {
        return @"抖音";
    }
}

- (NSString *)activityImageName
{
    if ([self.contentItem respondsToSelector:@selector(activityImageName)] && [self.contentItem activityImageName]) {
        return [self.contentItem activityImageName];
    } else {
        return @"BDUGShareAwemeResource.bundle/aweme_allshare";
    }
}

- (NSString *)shareLabel
{
    return @"share_aweme";
}

- (BOOL)appInstalled
{
    return [[BDUGAwemeShare sharedDouyinShare] isAvailable];
}

- (void)shareWithContentItem:(id <BDUGActivityContentItemProtocol>)contentItem presentingViewController:(UIViewController *)presentingViewController onComplete:(BDUGActivityCompletionHandler)onComplete
{
    self.contentItem = (BDUGAwemeContentItem *)contentItem;
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

- (void)beginShareActionWithItemModel:(BDUGShareDataItemModel *)itemModel {
    [[BDUGShareAdapterSetting sharedService] activityWillSharedWith:self];
    
    BDUGAwemeShare *awemeShare = [BDUGAwemeShare sharedDouyinShare];
    awemeShare.delegate = self;
    
    if (![awemeShare isAvailableWithNotifyError:YES]) {
        //分享服务不可用直接返回。在delegate中处理异常。
        return;
    }
    
    BDUGAwemeContentItem *contentItem = [self contentItem];
    itemModel = contentItem.serverDataModel;
    
    BOOL hitUGStrategy = [BDUGShareActivityActionManager performShareWithActivity:self itemModel:itemModel openThirdPlatformBlock:^BOOL{
           return [BDUGAwemeShare openAweme];
       } activityTypeString:nil completion:^(id<BDUGActivityProtocol> activity, NSError *error, NSString *desc) {
           !self.completion ?: self.completion(activity, error, desc);
           [[BDUGShareAdapterSetting sharedService] activityHasSharedWith:activity error:error desc:desc];
       }];
       if (hitUGStrategy) {
           //命中UG策略，return，否则继续执行兜底SDK分享。
           return;
       }
    
    switch (contentItem.defaultShareType) {
        case BDUGShareVideo: {
            BDUGVideoImageShareInfo *info = [[BDUGVideoImageShareInfo alloc] init];
            info.panelID = self.panelId;
            info.resourceURLString = contentItem.videoURL;
            info.platformString = [self contentTitle];
            info.sandboxPath = contentItem.resourceSandboxPathString;
            info.shareStrategy = BDUGVideoImageShareStrategyResponseSaveAlbum;
            info.shareType = BDUGVideoImageShareTypeVideo;
            info.needPreviewDialog = NO;
            [BDUGShareActivityActionManager convertInfo:info contentItem:contentItem];
            info.completeBlock = ^(BDUGVideoShareStatusCode statusCode, NSString *desc, BDUGVideoImageShareContentModel *resultModel) {
                NSError *err;
                if (statusCode == BDUGVideoShareStatusCodeSuccess && desc.length > 0) {
                    [awemeShare sendVideoWithPath:resultModel.albumIdentifier extraInfo:contentItem.extraInfo state:contentItem.state hashtag:contentItem.hashtag];
                } else if (statusCode == BDUGVideoShareStatusCodeInvalidContent){
                    err = [BDUGShareError errorWithDomain:BDUGAwemeShareErrorDomain code:BDUGShareErrorTypeInvalidContent userInfo:@{NSLocalizedDescriptionKey: desc}];
                    [self awemeShare:nil sharedWithError:err];
                } else {
                    err = [BDUGShareError errorWithDomain:BDUGAwemeShareErrorDomain code:BDUGShareErrorTypeOther userInfo:@{NSLocalizedDescriptionKey: desc}];
                    [self awemeShare:nil sharedWithError:err];
                }
            };
            [BDUGVideoImageShare shareVideoWithInfo:info];
        }
            break;
        case BDUGShareImage: {
            BDUGVideoImageShareInfo *info = [[BDUGVideoImageShareInfo alloc] init];
            info.panelID = self.panelId;
            info.resourceURLString = contentItem.imageUrl;
            info.shareImage = contentItem.image;
            info.platformString = [self contentTitle];
            info.shareStrategy = BDUGVideoImageShareStrategyResponseSaveAlbum;
            info.shareType = BDUGVideoImageShareTypeImage;
            info.needPreviewDialog = NO;
            [BDUGShareActivityActionManager convertInfo:info contentItem:contentItem];
            info.completeBlock = ^(BDUGVideoShareStatusCode statusCode, NSString *desc, BDUGVideoImageShareContentModel *resultModel) {
                NSError *err;
                if (statusCode == BDUGVideoShareStatusCodeSuccess && desc.length > 0) {
                    [awemeShare sendImageWithPath:resultModel.albumIdentifier extraInfo:contentItem.extraInfo state:contentItem.state hashtag:contentItem.hashtag];
                } else if (statusCode == BDUGVideoShareStatusCodeInvalidContent){
                    err = [BDUGShareError errorWithDomain:BDUGAwemeShareErrorDomain code:BDUGShareErrorTypeInvalidContent userInfo:@{NSLocalizedDescriptionKey: desc}];
                    [self awemeShare:nil sharedWithError:err];
                } else {
                    err = [BDUGShareError errorWithDomain:BDUGAwemeShareErrorDomain code:BDUGShareErrorTypeOther userInfo:@{NSLocalizedDescriptionKey: desc}];
                    [self awemeShare:nil sharedWithError:err];
                }
            };
            [BDUGVideoImageShare shareVideoWithInfo:info];
        }
            break;
        default: {
            NSString *desc = @"暂不支持的分享类型";
            NSError *error = [BDUGShareError errorWithDomain:BDUGAwemeShareErrorDomain code:BDUGShareErrorTypeAppNotSupportShareType userInfo:@{NSLocalizedDescriptionKey:desc}];
            [self awemeShare:nil sharedWithError:error];
        }
            break;
    }
}

#pragma mark - BDUGAwemeShareDelegate

- (void)awemeShare:(BDUGAwemeShare *)awemeShare sharedWithError:(NSError *)error
{
    NSString *desc = @"分享成功";
    if (error) {
        switch (error.code) {
            case BDUGShareErrorTypeAppNotInstalled:
                desc = NSLocalizedString(@"您未安装抖音", @"您未安装抖音");
                break;
            case BDUGShareErrorTypeAppNotSupportAPI:
                desc = NSLocalizedString(@"您的抖音版本过低，无法支持分享", @"您的抖音版本过低，无法支持分享");
                break;
            case BDUGShareErrorTypeInvalidContent:
                desc = @"分享内容无效";
                break;
            default: {
                desc = NSLocalizedString(@"分享失败", @"分享失败");
            }
                break;
        }
    } else {
        
    }
    
    if (self.completion) {
        self.completion(self, error, desc);
    }
    
    [[BDUGShareAdapterSetting sharedService] activityHasSharedWith:self error:error desc:desc];
}

@end
