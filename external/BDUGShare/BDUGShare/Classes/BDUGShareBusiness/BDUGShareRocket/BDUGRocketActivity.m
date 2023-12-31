//
//  BDUGRocketActivity.m
//  BDUGShare_Example
//
//  Created by 杨阳 on 2019/6/21.
//  Copyright © 2019 xunianqiang. All rights reserved.
//

#import "BDUGRocketActivity.h"
#import "BDUGShareAdapterSetting.h"
#import "BDUGShareError.h"
#import "BDUGRocketShare.h"
#import "BDUGVideoImageShare.h"
#import "BDUGShareActivityActionManager.h"

NSString * const BDUGActivityTypePostToRocket             = @"com.BDUG.UIKit.activity.PostToRocket";

@interface BDUGRocketActivity () <BDUGRocketShareDelegate>

@property (nonatomic,copy) BDUGActivityCompletionHandler completion;

@end

@implementation BDUGRocketActivity

@synthesize dataSource = _dataSource, panelId = _panelId;

- (NSString *)contentItemType
{
    return BDUGActivityContentItemTypeRocket;
}

- (NSString *)activityType
{
    return BDUGActivityTypePostToRocket;
}

#pragma mark - Display

- (NSString *)contentTitle
{
    if ([self.contentItem respondsToSelector:@selector(contentTitle)] && [self.contentItem contentTitle]) {
        return [self.contentItem contentTitle];
    } else {
        return @"飞聊";
    }
}

- (NSString *)activityImageName
{
    if ([self.contentItem respondsToSelector:@selector(activityImageName)] && [self.contentItem activityImageName]) {
        return [self.contentItem activityImageName];
    } else {
        return @"BDUGShareRocketResource.bundle/rocket_allshare";
    }
}

- (NSString *)shareLabel
{
    return @"share_rocket";
}

- (BOOL)appInstalled
{
    return [[BDUGRocketShare sharedRocketShare] isAvailable];
}

#pragma mark - Action

- (void)shareWithContentItem:(id<BDUGActivityContentItemProtocol>)contentItem presentingViewController:(UIViewController *)presentingViewController onComplete:(BDUGActivityCompletionHandler)onComplete
{
    self.contentItem = (BDUGRocketContentItem *)contentItem;
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
    
    BDUGRocketShare *basicShare = [BDUGRocketShare sharedRocketShare];
    basicShare.delegate = self;
    
    if (![basicShare isAvailableWithNotifyError:YES]) {
        return;
    }
    
    BDUGRocketContentItem *contentItem = [self contentItem];

    switch (contentItem.defaultShareType) {
        case BDUGShareText: {
            [basicShare sendTextToScene:contentItem.scene withText:contentItem.title];
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
                    [basicShare sendImageToScene:contentItem.scene withImage:resultModel.resultImage];
                } else if (statusCode == BDUGVideoShareStatusCodeInvalidContent){
                    err = [BDUGShareError errorWithDomain:BDUGRocketShareErrorDomain code:BDUGShareErrorTypeInvalidContent userInfo:@{NSLocalizedDescriptionKey: desc}];
                    [self rocketShare:nil sharedWithError:err];
                } else {
                    err = [BDUGShareError errorWithDomain:BDUGRocketShareErrorDomain code:BDUGShareErrorTypeOther userInfo:@{NSLocalizedDescriptionKey: desc}];
                    [self rocketShare:nil sharedWithError:err];
                }
            };
            [BDUGVideoImageShare shareVideoWithInfo:info];
        }
            break;
        case BDUGShareWebPage: {
            [basicShare sendWebpageToScene:contentItem.scene withWebpageURL:contentItem.webPageUrl thumbnailImage:contentItem.thumbImage title:contentItem.title description:contentItem.desc];
        }
            break;
        case BDUGShareVideo: {
            [basicShare sendVideoToScene:contentItem.scene videoURLString:contentItem.videoURL];
        }
            break;
        default:{
            NSString *desc = @"暂不支持的分享类型";
            NSError *error = [BDUGShareError errorWithDomain:BDUGRocketShareErrorDomain code:BDUGShareErrorTypeAppNotSupportShareType userInfo:@{NSLocalizedDescriptionKey:desc}];
            [self rocketShare:nil sharedWithError:error];
        }
            break;
    }
}

#pragma mark - delegate

- (void)rocketShare:(BDUGRocketShare *)rocketShare sharedWithError:(NSError *)error
{
    NSString *desc = nil;
    if (error) {
        switch (error.code) {
            case BDUGShareErrorTypeAppNotInstalled:
                desc = NSLocalizedString(@"您未安装飞聊", nil);
                break;
            case BDUGShareErrorTypeAppNotSupportAPI:
                desc = NSLocalizedString(@"您的飞聊版本过低，无法支持分享", nil);
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
