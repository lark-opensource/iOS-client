//
//  BDUGTiktokActivity.m
//  BDUGShare_Example
//
//  Created by 杨阳 on 2019/6/11.
//  Copyright © 2019 xunianqiang. All rights reserved.
//

#import "BDUGTiktokActivity.h"
#import "BDUGTiktokShare.h"
#import "BDUGShareAdapterSetting.h"
#import "BDUGVideoImageShare.h"
#import "BDUGShareError.h"
#import "BDUGShareActivityActionManager.h"

NSString * const BDUGActivityTypePostToTiktok = @"com.BDUG.UIKit.activity.PostToTiktok";

@interface BDUGTiktokActivity () <BDUGTiktokShareDelegate>

@property (nonatomic,copy) BDUGActivityCompletionHandler completion;

@end

@implementation BDUGTiktokActivity

@synthesize dataSource = _dataSource, panelId = _panelId;

- (NSString *)contentItemType {
    return BDUGActivityContentItemTypeTiktok;
}

- (NSString *)activityType {
    return BDUGActivityTypePostToTiktok;
}

- (NSString *)contentTitle
{
    if ([self.contentItem respondsToSelector:@selector(contentTitle)] && [self.contentItem contentTitle]) {
        return [self.contentItem contentTitle];
    } else {
        return @"Tiktok";
    }
}

- (NSString *)activityImageName
{
    if ([self.contentItem respondsToSelector:@selector(activityImageName)] && [self.contentItem activityImageName]) {
        return [self.contentItem activityImageName];
    } else {
        return @"BDUGShareTiktokResource.bundle/tiktok_allshare";
    }
}

- (NSString *)shareLabel
{
    return @"share_tiktok";
}

- (BOOL)appInstalled
{
    return [[BDUGTiktokShare sharedDouyinShare] isAvailable];
}

- (void)shareWithContentItem:(id <BDUGActivityContentItemProtocol>)contentItem presentingViewController:(UIViewController *)presentingViewController onComplete:(BDUGActivityCompletionHandler)onComplete
{
    self.contentItem = (BDUGTiktokContentItem *)contentItem;
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
    
    BDUGTiktokShare *tiktokShare = [BDUGTiktokShare sharedDouyinShare];
    tiktokShare.delegate = self;
    
    if (![tiktokShare isAvailableWithNotifyError:YES]) {
        //分享服务不可用直接返回。在delegate中处理异常。
        return;
    }
    
    BDUGTiktokContentItem *contentItem = [self contentItem];
    
    switch (contentItem.defaultShareType) {
        case BDUGShareVideo: {
            BDUGVideoImageShareInfo *info = [[BDUGVideoImageShareInfo alloc] init];
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
                    [tiktokShare sendVideoWithPath:resultModel.albumIdentifier];
                } else if (statusCode == BDUGVideoShareStatusCodeInvalidContent){
                    err = [BDUGShareError errorWithDomain:BDUGTiktokShareErrorDomain code:BDUGShareErrorTypeInvalidContent userInfo:@{NSLocalizedDescriptionKey: desc}];
                    [self tiktokShare:nil sharedWithError:err];
                } else {
                    err = [BDUGShareError errorWithDomain:BDUGTiktokShareErrorDomain code:BDUGShareErrorTypeOther userInfo:@{NSLocalizedDescriptionKey: desc}];
                    [self tiktokShare:nil sharedWithError:err];
                }
            };
            [BDUGVideoImageShare shareVideoWithInfo:info];
        }
            break;
            //由于图片不支持单张，所以暂不支持该类型。
//        case BDUGShareImage: {
//            BDUGVideoImageShareInfo *info = [[BDUGVideoImageShareInfo alloc] init];
//            info.resourceURLString = tiktokItem.imageUrl;
//            info.shareImage = tiktokItem.image;
//            info.platformString = [self contentTitle];
//            info.shareStrategy = BDUGVideoImageShareStrategyResponseSaveAlbum;
//            info.shareType = BDUGVideoImageShareTypeImage;
//            info.needPreviewDialog = NO;
//            info.completeBlock = ^(BDUGVideoShareStatusCode statusCode, NSString *desc, BDUGVideoImageShareContentModel *resultModel) {
//                NSError *err;
//                if (statusCode == BDUGVideoShareStatusCodeSuccess && desc.length > 0) {
//                    [tiktokShare sendImageWithPath:resultModel.albumIdentifier];
//                } else if (statusCode == BDUGVideoShareStatusCodeInvalidContent){
//                    err = [BDUGShareError errorWithDomain:BDUGTiktokShareErrorDomain code:BDUGShareErrorTypeInvalidContent userInfo:@{NSLocalizedDescriptionKey: desc}];
//                    [self tiktokShare:nil sharedWithError:err];
//                } else {
//                    err = [BDUGShareError errorWithDomain:BDUGTiktokShareErrorDomain code:BDUGShareErrorTypeOther userInfo:@{NSLocalizedDescriptionKey: desc}];
//                    [self tiktokShare:nil sharedWithError:err];
//                }
//            };
//            [BDUGVideoImageShare shareVideoWithInfo:info];
//        }
//            break;
        default: {
            NSString *desc = @"暂不支持的分享类型";
            NSError *error = [BDUGShareError errorWithDomain:BDUGTiktokShareErrorDomain code:BDUGShareErrorTypeAppNotSupportShareType userInfo:@{NSLocalizedDescriptionKey:desc}];
            [self tiktokShare:nil sharedWithError:error];
        }
            break;
    }
}

#pragma mark - BDUGTiktokShareDelegate

- (void)tiktokShare:(BDUGTiktokShare *)tiktokShare sharedWithError:(NSError *)error
{
    NSString *desc;
    if (error) {
        desc = [error.userInfo objectForKey:NSLocalizedDescriptionKey];
    } else {
        desc = @"分享成功";
    }
    
    if (desc.length == 0) {
        desc = NSLocalizedString(@"分享失败", @"分享失败");
    }
    if (self.completion) {
        self.completion(self, error, desc);
    }
    
    [[BDUGShareAdapterSetting sharedService] activityHasSharedWith:self error:error desc:desc];
}

@end
