//
//  BDUGAdditionalPanelActivity.m
//  BDUGShare_Example
//
//  Created by 杨阳 on 2020/5/6.
//  Copyright © 2020 xunianqiang. All rights reserved.
//

#import "BDUGAdditionalPanelActivity.h"
#import "BDUGShareAdapterSetting.h"
#import "BDUGVideoImageShare.h"
#import "BDUGShareError.h"
#import "BDUGShareActivityActionManager.h"
#import "BDUGShareEvent.h"
#import "BDUGShareManager.h"

NSString * const BDUGActivityTypeAdditionalPanel = @"com.BDUG.UIKit.activity.AdditionalPanel";
NSString * const BDUGAdditionalPanelErrorDomain = @"BDUGAdditionalPanelErrorDomain";

@interface BDUGAdditionalPanelActivity ()

@property (nonatomic,copy) BDUGActivityCompletionHandler completion;

@end

@implementation BDUGAdditionalPanelActivity

@synthesize dataSource = _dataSource, panelId = _panelId;

- (NSString *)contentItemType
{
    return BDUGActivityContentItemTypeAdditionalPanel;
}

- (NSString *)activityType
{
    return BDUGActivityTypeAdditionalPanel;
}

#pragma mark - Display

- (NSString *)contentTitle
{
    if ([self.contentItem respondsToSelector:@selector(contentTitle)] && [self.contentItem contentTitle]) {
        return [self.contentItem contentTitle];
    } else {
        return @"生成长图";
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
    self.contentItem = (BDUGAdditionalPanelContentItem *)contentItem;
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
    BDUGAdditionalPanelContentItem *contentItem = self.contentItem;
    if (contentItem.shareManager == nil || contentItem.panelContent == nil) {
        NSAssert(0, @"参数设置不全");
        NSError *err = [BDUGShareError errorWithDomain:BDUGAdditionalPanelErrorDomain code:BDUGShareErrorTypeInvalidContent userInfo:@{NSLocalizedDescriptionKey: @"分享参数设置不全"}];
        [self handleError:err];
        return;
    }
    
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
        if (statusCode == BDUGVideoShareStatusCodeSuccess && resultModel.resultImage) {
            contentItem.panelContent.shareContentItem.image = resultModel.resultImage;
            [contentItem.shareManager displayPanelWithContent:contentItem.panelContent];
            //成功调起之后不用回调，在下一轮分享中回调。
        } else if (statusCode == BDUGVideoShareStatusCodeInvalidContent){
            err = [BDUGShareError errorWithDomain:BDUGAdditionalPanelErrorDomain code:BDUGShareErrorTypeInvalidContent userInfo:@{NSLocalizedDescriptionKey: desc}];
            [self handleError:err];
        } else {
            err = [BDUGShareError errorWithDomain:BDUGAdditionalPanelErrorDomain code:BDUGShareErrorTypeOther userInfo:@{NSLocalizedDescriptionKey: desc}];
            [self handleError:err];
        }
    };
    [BDUGVideoImageShare shareVideoWithInfo:info]; 
}

- (void)handleError:(NSError *)error {
    !self.completion ?: self.completion(self, error, error.description);
    [[BDUGShareAdapterSetting sharedService] activityHasSharedWith:self error:error desc:error.description];
}

@end
