//
//  BDUGLineActivity.m
//  BDUGShare_Example
//
//  Created by 杨阳 on 2019/6/16.
//  Copyright © 2019 xunianqiang. All rights reserved.
//

#import "BDUGLineActivity.h"
#import "BDUGLineShare.h"
#import "BDUGShareAdapterSetting.h"
#import "BDUGVideoImageShare.h"
#import "BDUGShareError.h"
#import "BDUGShareActivityActionManager.h"

NSString * const BDUGActivityTypePostToLine = @"com.BDUG.UIKit.activity.PostToLine";

@interface BDUGLineActivity () <BDUGLineShareDelegate>

@property (nonatomic,copy) BDUGActivityCompletionHandler completion;

@end

@implementation BDUGLineActivity

@synthesize dataSource = _dataSource, panelId = _panelId;

- (NSString *)contentItemType
{
    return BDUGActivityContentItemTypeLine;
}

- (NSString *)activityType
{
    return BDUGActivityTypePostToLine;
}

#pragma mark - Display

- (NSString *)contentTitle
{
    if ([self.contentItem respondsToSelector:@selector(contentTitle)] && [self.contentItem contentTitle]) {
        return [self.contentItem contentTitle];
    } else {
        return @"Line";
    }
}

- (NSString *)activityImageName
{
    if ([self.contentItem respondsToSelector:@selector(activityImageName)] && [self.contentItem activityImageName]) {
        return [self.contentItem activityImageName];
    } else {
        return @"BDUGShareLineResource.bundle/line_allshare";
    }
}

- (NSString *)shareLabel
{
    return @"share_line";
}

- (BOOL)appInstalled
{
    return [[BDUGLineShare sharedLineShare] lineAppInstalled];
}

#pragma mark - Action

- (void)shareWithContentItem:(id<BDUGActivityContentItemProtocol>)contentItem presentingViewController:(UIViewController *)presentingViewController onComplete:(BDUGActivityCompletionHandler)onComplete
{
    self.contentItem = (BDUGLineContentItem *)contentItem;
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
    
    BDUGLineShare *lineShare = [BDUGLineShare sharedLineShare];
    lineShare.delegate = self;
    
    BDUGLineContentItem *contentItem = [self contentItem];
    
    switch (contentItem.defaultShareType) {
        case BDUGShareText: {
            [lineShare shareText:contentItem.title];
        }
            break;
        case BDUGShareWebPage: {
            [lineShare shareText:contentItem.webPageUrl];
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
                    [lineShare shareImage:resultModel.resultImage];
                } else if (statusCode == BDUGVideoShareStatusCodeInvalidContent){
                    err = [BDUGShareError errorWithDomain:BDUGLineShareErrorDomain code:BDUGShareErrorTypeInvalidContent userInfo:@{NSLocalizedDescriptionKey: desc}];
                    [self lineShare:nil sharedWithError:err];
                } else {
                    err = [BDUGShareError errorWithDomain:BDUGLineShareErrorDomain code:BDUGShareErrorTypeOther userInfo:@{NSLocalizedDescriptionKey: desc}];
                    [self lineShare:nil sharedWithError:err];
                }
            };
            [BDUGVideoImageShare shareVideoWithInfo:info];
        }
            break;
        default: {
            NSString *desc = @"暂不支持的分享类型";
            NSError *error = [BDUGShareError errorWithDomain:BDUGLineShareErrorDomain code:BDUGShareErrorTypeAppNotSupportShareType userInfo:@{NSLocalizedDescriptionKey:desc}];
            [self lineShare:nil sharedWithError:error];
        }
            break;
    }
}

#pragma mark - BDUGWechatShareDelegate

- (void)lineShare:(BDUGLineShare *)lineShare sharedWithError:(NSError *)error
{
    NSString *desc = nil;
    if (error) {
        switch (error.code) {
            case BDUGShareErrorTypeAppNotInstalled:
                desc = NSLocalizedString(@"您未安装Line", nil);
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
