//
//  BDUGInstagramActivity.m
//  BDUGShare_Example
//
//  Created by 杨阳 on 2019/5/30.
//  Copyright © 2019 xunianqiang. All rights reserved.
//

#import "BDUGInstagramActivity.h"
#import "BDUGInstagramShare.h"
#import "BDUGShareAdapterSetting.h"
#import "BDUGVideoImageShare.h"
#import "BDUGShareError.h"
#import "BDUGShareActivityActionManager.h"

NSString * const BDUGActivityTypePostToInstagram = @"com.BDUG.UIKit.activity.PostToInstagram";

@interface BDUGInstagramActivity () <BDUGInstagramShareDelegate>

@property (nonatomic,copy) BDUGActivityCompletionHandler completion;

@end

@implementation BDUGInstagramActivity

@synthesize dataSource = _dataSource, panelId = _panelId;

- (NSString *)contentItemType
{
    return BDUGActivityContentItemTypeInstagram;
}

- (NSString *)activityType
{
    return BDUGActivityTypePostToInstagram;
}

#pragma mark - Display

- (NSString *)contentTitle
{
    if ([self.contentItem respondsToSelector:@selector(contentTitle)] && [self.contentItem contentTitle]) {
        return [self.contentItem contentTitle];
    } else {
        return @"Instagram";
    }
}

- (NSString *)activityImageName
{
    if ([self.contentItem respondsToSelector:@selector(activityImageName)] && [self.contentItem activityImageName]) {
        return [self.contentItem activityImageName];
    } else {
        return @"BDUGShareInstagramResource.bundle/instagram_allshare";
    }
}

- (NSString *)shareLabel
{
    return @"share_instagram";
}

- (BOOL)appInstalled
{
    return [BDUGInstagramShare instagramInstalled];
}

#pragma mark - Action

- (void)shareWithContentItem:(id<BDUGActivityContentItemProtocol>)contentItem presentingViewController:(UIViewController *)presentingViewController onComplete:(BDUGActivityCompletionHandler)onComplete
{
    self.contentItem = (BDUGInstagramContentItem *)contentItem;
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
    
    BDUGInstagramShare *instagramShare = [BDUGInstagramShare sharedInstagramShare];
    instagramShare.delegate = self;
    
    BDUGInstagramContentItem *contentItem = [self contentItem];

    switch (contentItem.defaultShareType) {
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
                    BOOL reallyShareToStories = NO;
                    if (@available(iOS 10.0, *)) {
                        if (contentItem.shareToStories) {
                            //如果直接分享到story，调用该API
                            [instagramShare sendImageToStories:resultModel.resultImage];
                            reallyShareToStories = YES;
                        }
                    }
                    if (!reallyShareToStories) {
                        [instagramShare sendFileWithAlbumIdentifier:resultModel.albumIdentifier];
                    }
                } else if (statusCode == BDUGVideoShareStatusCodeInvalidContent){
                    err = [BDUGShareError errorWithDomain:BDUGInstagramShareErrorDomain code:BDUGShareErrorTypeInvalidContent userInfo:@{NSLocalizedDescriptionKey: desc}];
                    [self instagramShare:nil sharedWithError:err];
                } else {
                    err = [BDUGShareError errorWithDomain:BDUGInstagramShareErrorDomain code:BDUGShareErrorTypeOther userInfo:@{NSLocalizedDescriptionKey: desc}];
                    [self instagramShare:nil sharedWithError:err];
                }
            };
            [BDUGVideoImageShare shareVideoWithInfo:info];
        }
            break;
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
                    BOOL reallyShareToStories = NO;
                    if (@available(iOS 10.0, *)) {
                        if (contentItem.shareToStories && [[NSFileManager defaultManager] fileExistsAtPath:resultModel.sandboxPath]) {
                            NSData *data = [[NSFileManager defaultManager] contentsAtPath:resultModel.sandboxPath];
                            if (data) {
                                [instagramShare sendVideoDataToStories:data];
                                reallyShareToStories = YES;
                            }
                        }
                    }
                    if (!reallyShareToStories) {
                        [instagramShare sendFileWithAlbumIdentifier:resultModel.albumIdentifier];
                    }
                } else if (statusCode == BDUGVideoShareStatusCodeInvalidContent){
                    err = [BDUGShareError errorWithDomain:BDUGInstagramShareErrorDomain code:BDUGShareErrorTypeInvalidContent userInfo:@{NSLocalizedDescriptionKey: desc}];
                    [self instagramShare:nil sharedWithError:err];
                } else {
                    err = [BDUGShareError errorWithDomain:BDUGInstagramShareErrorDomain code:BDUGShareErrorTypeOther userInfo:@{NSLocalizedDescriptionKey: desc}];
                    [self instagramShare:nil sharedWithError:err];
                }
            };
            [BDUGVideoImageShare shareVideoWithInfo:info];
        }
            break;
        default: {
            NSString *desc = @"暂不支持的分享类型";
            NSError *error = [BDUGShareError errorWithDomain:BDUGInstagramShareErrorDomain code:BDUGShareErrorTypeAppNotSupportShareType userInfo:@{NSLocalizedDescriptionKey:desc}];
            [self instagramShare:nil sharedWithError:error];
        }
            break;
    }
}

#pragma mark - BDUGinstagramShareDelegate

- (void)instagramShare:(BDUGInstagramShare *)instagramShare sharedWithError:(NSError *)error
{
    NSString *desc = nil;
    if (error) {
        switch (error.code) {
            case BDUGShareErrorTypeAppNotInstalled:
                desc = NSLocalizedString(@"您未安装Instagram", nil);
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
