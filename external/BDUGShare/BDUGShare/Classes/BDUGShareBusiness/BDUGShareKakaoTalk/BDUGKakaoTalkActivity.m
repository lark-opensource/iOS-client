//
//  BDUGKakaoTalkActivity.m
//  BDUGShare_Example
//
//  Created by 杨阳 on 2019/6/17.
//  Copyright © 2019 xunianqiang. All rights reserved.
//

#import "BDUGKakaoTalkActivity.h"
#import "BDUGShareAdapterSetting.h"
#import "BDUGVideoImageShare.h"
#import "BDUGShareError.h"
#import "BDUGKakaoTalkShare.h"
#import "BDUGShareActivityActionManager.h"

NSString * const BDUGActivityTypePostToKakaoTalk = @"BDUGActivityTypePostToKakaoTalk";

@interface BDUGKakaoTalkActivity () <BDUGKakaoTalkShareDelegate>

@property (nonatomic,copy) BDUGActivityCompletionHandler completion;

@end

@implementation BDUGKakaoTalkActivity

@synthesize dataSource = _dataSource, panelId = _panelId;

- (NSString *)contentItemType {
    return BDUGActivityContentItemTypeKakaoTalk;
}

- (NSString *)activityType {
    return BDUGActivityTypePostToKakaoTalk;
}

- (NSString *)contentTitle
{
    if ([self.contentItem respondsToSelector:@selector(contentTitle)] && [self.contentItem contentTitle]) {
        return [self.contentItem contentTitle];
    } else {
        return @"KakaoTalk";
    }
}

- (NSString *)activityImageName
{
    if ([self.contentItem respondsToSelector:@selector(activityImageName)] && [self.contentItem activityImageName]) {
        return [self.contentItem activityImageName];
    } else {
        return @"BDUGShareKakaoResource.bundle/kakao_allshare";
    }
}

- (NSString *)shareLabel
{
    return @"share_kakaoTalk";
}

- (BOOL)appInstalled
{
    return [[BDUGKakaoTalkShare sharedKakaoTalkShare] kakaoTalkInstalled];
}

- (void)shareWithContentItem:(id <BDUGActivityContentItemProtocol>)contentItem presentingViewController:(UIViewController *)presentingViewController onComplete:(BDUGActivityCompletionHandler)onComplete
{
    self.contentItem = (BDUGKakaoTalkContentItem *)contentItem;
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
    
    BDUGKakaoTalkShare *kakaoShare = [BDUGKakaoTalkShare sharedKakaoTalkShare];
    kakaoShare.delegate = self;
    BDUGKakaoTalkContentItem *contentItem = [self contentItem];
    
    if (![kakaoShare kakaoTalkInstalled]) {
        NSError *error = [BDUGShareError errorWithDomain:BDUGKakaoTalkShareErrorDomain code:BDUGShareErrorTypeAppNotInstalled userInfo:nil];
        [self kakaoTalkShare:nil sharedWithError:error];
        return;
    }
    
    switch (contentItem.defaultShareType) {
        case BDUGShareWebPage: {
            [kakaoShare shareURL:[NSURL URLWithString:contentItem.webPageUrl]];
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
                    [kakaoShare shareImage:resultModel.resultImage title:contentItem.title];
                } else if (statusCode == BDUGVideoShareStatusCodeInvalidContent){
                    err = [BDUGShareError errorWithDomain:BDUGKakaoTalkShareErrorDomain code:BDUGShareErrorTypeInvalidContent userInfo:@{NSLocalizedDescriptionKey: desc}];
                    [self kakaoTalkShare:nil sharedWithError:err];
                } else {
                    err = [BDUGShareError errorWithDomain:BDUGKakaoTalkShareErrorDomain code:BDUGShareErrorTypeOther userInfo:@{NSLocalizedDescriptionKey: desc}];
                    [self kakaoTalkShare:nil sharedWithError:err];
                }
            };
            [BDUGVideoImageShare shareVideoWithInfo:info];
        }
            break;
        default: {
            NSString *desc = @"暂不支持的分享类型";
            NSError *error = [BDUGShareError errorWithDomain:BDUGKakaoTalkShareErrorDomain code:BDUGShareErrorTypeAppNotSupportShareType userInfo:@{NSLocalizedDescriptionKey:desc}];
            [self kakaoTalkShare:nil sharedWithError:error];
        }
            break;
    }
}

#pragma mark - twitter delegate

- (void)kakaoTalkShare:(BDUGKakaoTalkShare *)kakaoTalkShare sharedWithError:(NSError *)error
{
    NSString *desc = nil;
    if (error) {
        switch (error.code) {
            case BDUGShareErrorTypeAppNotInstalled:
                desc = NSLocalizedString(@"未安装KakaoTalk", nil);
                break;
            case BDUGShareErrorTypeInvalidContent:
                desc = NSLocalizedString(@"分享内容错误", nil);
                break;
            case BDUGShareErrorTypeUserCancel:
                desc = nil;
                break;
            case BDUGShareErrorTypeOther:
            default:
                desc = NSLocalizedString(@"分享失败", nil);
                break;
        }
    }
    !self.completion ?: self.completion(self, error, desc);
    [[BDUGShareAdapterSetting sharedService] activityHasSharedWith:self error:error desc:desc];
}

@end
