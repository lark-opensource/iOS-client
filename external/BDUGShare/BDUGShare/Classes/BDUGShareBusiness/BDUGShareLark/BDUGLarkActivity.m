//
//  BDUGLarkActivity.m
//  BDUGShare_Example
//
//  Created by 杨阳 on 2020/3/27.
//  Copyright © 2020 xunianqiang. All rights reserved.
//

#import "BDUGLarkActivity.h"
#import "BDUGLarkShare.h"
#import "BDUGShareAdapterSetting.h"
#import "BDUGShareError.h"
#import "BDUGVideoImageShare.h"
#import "BDUGShareActivityActionManager.h"

NSString * const BDUGActivityTypePostToLark = @"com.BDUG.UIKit.activity.PostToLark";

@interface BDUGLarkActivity () <BDUGLarkShareDelegate>

@property (nonatomic,copy) BDUGActivityCompletionHandler completion;

@end

@implementation BDUGLarkActivity

@synthesize dataSource = _dataSource, panelId = _panelId;

- (NSString *)contentItemType {
    return BDUGActivityContentItemTypeLark;
}

- (NSString *)activityType {
    return BDUGActivityTypePostToLark;
}

#pragma mark - Display

- (NSString *)contentTitle {
    if ([self.contentItem respondsToSelector:@selector(contentTitle)] && [self.contentItem contentTitle]) {
        return [self.contentItem contentTitle];
    } else {
        return @"飞书";
    }
}

- (NSString *)activityImageName {
    if ([self.contentItem respondsToSelector:@selector(activityImageName)] && [self.contentItem activityImageName]) {
        return [self.contentItem activityImageName];
    } else {
        return @"BDUGShareLarkResource.bundle/lark_allshare";
    }
}

- (NSString *)shareLabel {
    return @"share_lark";
}

- (BOOL)appInstalled {
    return [[BDUGLarkShare sharedLarkShare] isAvailable];
}

#pragma mark - Action

- (void)shareWithContentItem:(id<BDUGActivityContentItemProtocol>)contentItem presentingViewController:(UIViewController *)presentingViewController onComplete:(BDUGActivityCompletionHandler)onComplete {
    self.contentItem = (BDUGLarkContentItem *)contentItem;
    [self performActivityWithCompletion:^(id<BDUGActivityProtocol> activity, NSError *error, NSString *desc) {
        if (onComplete) {
            onComplete(activity, error, desc);
        }
    }];
}

- (void)performActivityWithCompletion:(BDUGActivityCompletionHandler)completion {
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
    
    BDUGLarkShare *basicShare = [BDUGLarkShare sharedLarkShare];
    basicShare.delegate = self;
    
//    if (![basicShare isAvailableWithNotifyError:YES]) {
//        return;
//    }
    
    BDUGLarkContentItem *contentItem = [self contentItem];
    
    switch (contentItem.defaultShareType) {
        case BDUGShareText: {
            [basicShare sendText:contentItem.title];
        }
            break;
        case BDUGShareImage: {
            [basicShare sendImage:contentItem.image imageURL:contentItem.imageUrl];
            
        }
            break;
        case BDUGShareWebPage: {
            [basicShare sendWebPageURL:contentItem.webPageUrl title:contentItem.title];
        }
            break;
        case BDUGShareVideo: {
            BDUGVideoImageShareInfo *info = [[BDUGVideoImageShareInfo alloc] init];
            info.panelID = self.panelId;
            info.resourceURLString = contentItem.videoURL;
            info.platformString = [self contentTitle];
            info.shareStrategy = BDUGVideoImageShareStrategyResponseSaveSandbox;
            info.shareType = BDUGVideoImageShareTypeVideo;
            info.needPreviewDialog = NO;
            [BDUGShareActivityActionManager convertInfo:info contentItem:contentItem];
            info.completeBlock = ^(BDUGVideoShareStatusCode statusCode, NSString *desc, BDUGVideoImageShareContentModel *resultModel) {
                NSError *err;
                if (statusCode == BDUGVideoShareStatusCodeSuccess && desc.length > 0) {
                    [basicShare sendVideoWithSandboxPath:resultModel.sandboxPath];
                } else if (statusCode == BDUGVideoShareStatusCodeInvalidContent){
                    err = [BDUGShareError errorWithDomain:BDUGLarkShareErrorDomain code:BDUGShareErrorTypeInvalidContent userInfo:@{NSLocalizedDescriptionKey: desc}];
                    [self larkShare:nil sharedWithError:err];
                } else {
                    err = [BDUGShareError errorWithDomain:BDUGLarkShareErrorDomain code:BDUGShareErrorTypeOther userInfo:@{NSLocalizedDescriptionKey: desc}];
                    [self larkShare:nil sharedWithError:err];
                }
            };
            [BDUGVideoImageShare shareVideoWithInfo:info];
        }
            break;
        default:{
            NSString *desc = @"暂不支持的分享类型";
            NSError *error = [BDUGShareError errorWithDomain:BDUGLarkShareErrorDomain code:BDUGShareErrorTypeAppNotSupportShareType userInfo:@{NSLocalizedDescriptionKey:desc}];
            [self larkShare:nil sharedWithError:error];
        }
            break;
    }
}

#pragma mark - delegate

- (void)larkShare:(BDUGLarkShare *)larkShare sharedWithError:(NSError *)error {
    NSString *desc = nil;
    if (error) {
        switch (error.code) {
            case BDUGShareErrorTypeAppNotInstalled:
                desc = NSLocalizedString(@"您未安装飞书", nil);
                break;
            case BDUGShareErrorTypeAppNotSupportAPI:
                desc = NSLocalizedString(@"您的飞书版本过低，无法支持分享", nil);
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
