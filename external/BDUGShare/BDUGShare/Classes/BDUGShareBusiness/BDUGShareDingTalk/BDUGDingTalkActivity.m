//
//  BDUGQQFriendActivity.m
//  Pods
//
//  Created by 张 延晋 on 17/01/09.
//
//

#import "BDUGDingTalkActivity.h"
#import "BDUGDingTalkShare.h"
#import "BDUGShareAdapterSetting.h"
#import "BDUGShareActivityActionManager.h"
#import "BDUGShareError.h"

NSString * const BDUGActivityTypePostToDingTalk           = @"com.BDUG.UIKit.activity.PostToDingTalk";
static NSString *const BDUGDingtalkSystemActivityType = @"com.laiwang.DingTalk.ShareExtension";

@interface BDUGDingTalkActivity () <BDUGDingTalkShareDelegate>

@property (nonatomic,copy) BDUGActivityCompletionHandler completion;

@end

@implementation BDUGDingTalkActivity

@synthesize dataSource = _dataSource, panelId = _panelId, tokenDialogDidShowBlock = _tokenDialogDidShowBlock;

#pragma mark - Identifier

-(NSString *)contentItemType
{
    return BDUGActivityContentItemTypeDingTalk;
}

-(NSString *)activityType
{
    return BDUGActivityTypePostToDingTalk;
}

#pragma mark - Display

- (NSString *)contentTitle
{
    if ([self.contentItem respondsToSelector:@selector(contentTitle)] && [self.contentItem contentTitle]) {
        return [self.contentItem contentTitle];
    } else {
        return @"钉钉";
    }
}

- (NSString *)activityImageName
{
    if ([self.contentItem respondsToSelector:@selector(activityImageName)] && [self.contentItem activityImageName]) {
        return [self.contentItem activityImageName];
    } else {
        return @"BDUGShareDingtalkResource.bundle/dingding_allshare";
    }
}

- (NSString *)shareLabel
{
    return @"share_dingding";
}

- (BOOL)appInstalled
{
    return [[BDUGDingTalkShare sharedDingTalkShare] isAvailable];
}

#pragma mark - Action

- (void)shareWithContentItem:(id <BDUGActivityContentItemProtocol>)contentItem presentingViewController:(UIViewController *)presentingViewController onComplete:(BDUGActivityCompletionHandler)onComplete
{
    self.contentItem = (BDUGDingTalkContentItem *)contentItem;
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

    BDUGDingTalkShare *dingdingShare = [BDUGDingTalkShare sharedDingTalkShare];
    
    if (![dingdingShare isAvailable]) {
        NSError *error = [BDUGShareError errorWithDomain:BDUGDingTalkShareErrorDomain code:BDUGShareErrorTypeAppNotInstalled userInfo:nil];
        NSString *desc = @"未安装钉钉，请先安装";
        !self.completion ?: self.completion(self, error, desc);
        [[BDUGShareAdapterSetting sharedService] activityHasSharedWith:self error:error desc:desc];
        return;
    }
    
    dingdingShare.delegate = self;
    BDUGDingTalkContentItem *dingTalkItem = self.contentItem;
    itemModel = dingTalkItem.serverDataModel;
    
    BOOL hitUGStrategy = [BDUGShareActivityActionManager performShareWithActivity:self itemModel:itemModel openThirdPlatformBlock:^BOOL{
        return [BDUGDingTalkShare openDingTalk];
    } activityTypeString:BDUGDingtalkSystemActivityType completion:^(id<BDUGActivityProtocol> activity, NSError *error, NSString *desc) {
        !self.completion ?: self.completion(activity, error, desc);
        [[BDUGShareAdapterSetting sharedService] activityHasSharedWith:activity error:error desc:desc];
    }];
    if (hitUGStrategy) {
        //命中UG策略，return，否则继续执行兜底SDK分享。
        return;
    }

    switch (dingTalkItem.defaultShareType) {
        case BDUGShareText:{
            [dingdingShare sendTextToScene:DTSceneSession withText:dingTalkItem.title customCallbackUserInfo:dingTalkItem.callbackUserInfo];
        }
            break;
        case BDUGShareImage: {
            if (dingTalkItem.imageUrl.length > 0) {
                [dingdingShare sendImageToScene:DTSceneSession withImageURL:dingTalkItem.imageUrl customCallbackUserInfo:dingTalkItem.callbackUserInfo];
            } else {
                [dingdingShare sendImageToScene:DTSceneSession withImage:dingTalkItem.image customCallbackUserInfo:dingTalkItem.callbackUserInfo];
            }
        }
            break;
        case BDUGShareWebPage: {
            [dingdingShare sendWebpageToScene:DTSceneSession withWebpageURL:dingTalkItem.webPageUrl thumbnailImage:dingTalkItem.thumbImage thumbnailImageURL:dingTalkItem.imageUrl title:dingTalkItem.title description:dingTalkItem.desc customCallbackUserInfo:dingTalkItem.callbackUserInfo];
        }
            break;
        case BDUGShareVideo: {
            [dingdingShare sendWebpageToScene:DTSceneSession withWebpageURL:dingTalkItem.webPageUrl thumbnailImage:dingTalkItem.thumbImage thumbnailImageURL:dingTalkItem.imageUrl title:dingTalkItem.title description:dingTalkItem.desc customCallbackUserInfo:dingTalkItem.callbackUserInfo];
        }
            break;
        default:{
            NSString *desc = @"暂不支持的分享类型";
            NSError *error = [BDUGShareError errorWithDomain:BDUGDingTalkShareErrorDomain code:BDUGShareErrorTypeAppNotSupportShareType userInfo:@{NSLocalizedDescriptionKey:desc}];
            [self dingTalkShare:nil sharedWithError:error customCallbackUserInfo:nil];
        }
            break;
    }
}

#pragma mark - BDUGQQShareDelegate

- (void)dingTalkShare:(BDUGDingTalkShare *)dingTalkShare sharedWithError:(NSError *)error customCallbackUserInfo:(NSDictionary *)customCallbackUserInfo
{
    NSString *desc = nil;
    if (!error) {
        desc = NSLocalizedString(@"分享成功", nil);
    }else{
        switch (error.code) {
            case BDUGShareErrorTypeAppNotInstalled:
                desc = NSLocalizedString(@"您未安装钉钉", nil);
                break;
            case BDUGShareErrorTypeAppNotSupportAPI:
                desc = NSLocalizedString(@"您的钉钉版本过低，无法支持分享", nil);
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
