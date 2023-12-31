//
//  BDUGImageShareActivity.m
//  BDUGShare_Example
//
//  Created by 杨阳 on 2020/3/9.
//  Copyright © 2020 xunianqiang. All rights reserved.
//

#import "BDUGImageShareActivity.h"
#import "BDUGShareAdapterSetting.h"
#import "BDUGImageShare.h"
#import "BDUGShareError.h"

NSString * const BDUGActivityTypeHiddenMarkImage = @"com.BDUG.UIKit.activity.HiddenMarkImage";

@interface BDUGImageShareActivity ()

@property (nonatomic,copy) BDUGActivityCompletionHandler completion;

@end

@implementation BDUGImageShareActivity

@synthesize dataSource = _dataSource, panelId = _panelId;

- (NSString *)contentItemType
{
    return BDUGActivityContentItemTypeHiddenMarkImage;
}

- (NSString *)activityType
{
    return BDUGActivityTypeHiddenMarkImage;
}

#pragma mark - Display

- (NSString *)contentTitle
{
    if ([self.contentItem respondsToSelector:@selector(contentTitle)] && [self.contentItem contentTitle]) {
        return [self.contentItem contentTitle];
    } else {
        return @"隐码分享";
    }
}

- (NSString *)activityImageName
{
    if ([self.contentItem respondsToSelector:@selector(activityImageName)] && [self.contentItem activityImageName]) {
        return [self.contentItem activityImageName];
    } else {
        return @"BDUGShareSystemResource.bundle/airdrop_allshare";
    }
}

- (NSString *)shareLabel
{
    return @"share_hidden_mark_image";
}

- (BOOL)appInstalled
{
    return YES;
}

#pragma mark - Action

- (void)shareWithContentItem:(id<BDUGActivityContentItemProtocol>)contentItem presentingViewController:(UIViewController *)presentingViewController onComplete:(BDUGActivityCompletionHandler)onComplete
{
    self.contentItem = (BDUGImageShareContentItem *)contentItem;
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
    
    BDUGShareBaseContentItem *contentItem = self.contentItem;

    BOOL writeToken = YES;
    if (itemModel.shareMethod == BDUGShareMethodImage) {
        if ([BDUGImageShare isAvailable] && [contentItem imageShareValid] && itemModel.tokenInfo.token.length > 0) {
            writeToken = YES;
        } else {
            //口令分享不可用
            NSAssert(0, @"图片隐写不可用，imageShareValid: %d, itemModel.tokenInfo.token:%@", [contentItem imageShareValid], itemModel.tokenInfo.token);
            writeToken = NO;
        }
    } else {
        // 不是隐写分享。
        writeToken = NO;
    }
    BDUGImageShareInfo *shareInfo = [[BDUGImageShareInfo alloc] init];
    shareInfo.image = contentItem.image;
    shareInfo.imageUrl = contentItem.imageUrl;
    shareInfo.groupID = contentItem.groupID;
    shareInfo.panelID = self.panelId;
    shareInfo.panelType = contentItem.panelType;
    shareInfo.writeToken = writeToken;
    shareInfo.imageTokenDesc = itemModel.tokenInfo.token;
    shareInfo.imageTokenTips = itemModel.tokenInfo.tip;
    shareInfo.imageTokenTitle = itemModel.tokenInfo.title;
    shareInfo.channelStringForEvent = itemModel.channel;
    shareInfo.clientExtraData = contentItem.clientExtraData;
    shareInfo.completeBlock = ^(BDUGImageShareStatusCode statusCode, NSString *desc) {
        NSError *error;
        if (statusCode == BDUGImageShareStatusCodeSuccess) {
            !self.completion ?: self.completion(self, nil, nil);
        } else if (statusCode == BDUGImageShareStatusCodeUserCancel) {
            error = [BDUGShareError errorWithDomain:@"BDUGImageShare" code:BDUGShareErrorTypeUserCancel userInfo:nil];
            !self.completion ?: self.completion(self, error, desc);
        } else {
            error = [BDUGShareError errorWithDomain:@"BDUGImageShare" code:BDUGShareErrorTypeOther userInfo:nil];
            !self.completion ?: self.completion(self, error, desc);
        }
        [[BDUGShareAdapterSetting sharedService] activityHasSharedWith:self error:error desc:desc];
    };
    shareInfo.openThirdPlatformBlock = nil;
    [BDUGImageShare shareImageWithInfo:shareInfo];
}

@end
