//
//  BDUGCopyActivity.m
//  NeteaseLottery
//
//  Created by 延晋 张 on 16/6/7.
//
//

#import "BDUGCopyActivity.h"
#import <MessageUI/MFMailComposeViewController.h>
#import "BDUGShareAdapterSetting.h"
#import "BDUGShareActivityActionManager.h"

NSString * const BDUGActivityTypePostToCopy              = @"com.BDUG.UIKit.activity.PostToCopy";

@interface BDUGCopyActivity () <MFMailComposeViewControllerDelegate>

@property (nonatomic,copy) BDUGActivityCompletionHandler completion;

@end

@implementation BDUGCopyActivity

@synthesize dataSource = _dataSource, panelId = _panelId;

#pragma mark - Identifier

- (NSString *)contentItemType
{
    return BDUGActivityContentItemTypeCopy;
}

- (NSString *)activityType
{
    return BDUGActivityTypePostToCopy;
}

#pragma mark - Display

- (NSString *)contentTitle
{
    if ([self.contentItem respondsToSelector:@selector(contentTitle)] && [self.contentItem contentTitle]) {
        return [self.contentItem contentTitle];
    } else {
        return @"复制链接";
    }
}

- (NSString *)activityImageName
{
    if ([self.contentItem respondsToSelector:@selector(activityImageName)] && [self.contentItem activityImageName]) {
        return [self.contentItem activityImageName];
    } else {
        return @"BDUGShareCopyResource.bundle/copy_allshare";
    }
}

- (NSString *)shareLabel
{
    return @"share_copy_link";
}

#pragma mark - Action

- (void)shareWithContentItem:(id <BDUGActivityContentItemProtocol>)contentItem presentingViewController:(UIViewController *)presentingViewController onComplete:(BDUGActivityCompletionHandler)onComplete
{
    self.contentItem = (BDUGCopyContentItem *)contentItem;
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
        
    NSString *text = self.contentItem.specificCopyString;
    if (text.length == 0) {
        if (self.contentItem.title.length > 0) {
            text = [NSString stringWithFormat:@"【%@】%@", self.contentItem.title, self.contentItem.webPageUrl];
        } else {
            text = self.contentItem.webPageUrl;
        }
    }
    NSString *desc = nil;
    NSError *error = nil;
    if ([text isKindOfClass:[NSString class]]) {
        // 记录复制内容，防止分享后，返回App触发口令分享逻辑
        [BDUGShareActivityActionManager setLastToken:text];
        
        UIPasteboard *pasteboard = [UIPasteboard generalPasteboard];
        [pasteboard setString:text];
        desc = @"复制成功";
    } else {
        error = [NSError errorWithDomain:BDUGActivityTypePostToCopy code:-100 userInfo:@{NSLocalizedDescriptionKey : @"复制失败"}];
        desc = @"复制失败";
    }
    
    if (self.completion) {
        self.completion(self, error, desc);
    }
    
    [[BDUGShareAdapterSetting sharedService] activityHasSharedWith:self error:error desc:desc];
}

@end
