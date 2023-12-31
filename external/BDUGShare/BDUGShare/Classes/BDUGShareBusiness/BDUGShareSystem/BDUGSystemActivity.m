//
//  BDUGSystemActivity.m
//  NeteaseLottery
//
//  Created by 延晋 张 on 16/6/6.
//
//

#import "BDUGSystemActivity.h"
#import <MessageUI/MFMailComposeViewController.h>
#import "UIImage+Activity.h"
#import "BDUGShareAdapterSetting.h"
#import "BDUGSystemShare.h"
#import "BDUGShareFileManager.h"
#import "BDUGShareError.h"

NSString * const BDUGActivityTypePostToSystem              = @"com.BDUG.UIKit.activity.PostToSystem";

@interface BDUGSystemActivity () <MFMailComposeViewControllerDelegate>

@property (nonatomic,copy) BDUGActivityCompletionHandler completion;

@end

@implementation BDUGSystemActivity

@synthesize dataSource = _dataSource, panelId = _panelId;

#pragma mark - Identifier

- (NSString *)contentItemType
{
    return BDUGActivityContentItemTypeSystem;
}

- (NSString *)activityType
{
    return BDUGActivityTypePostToSystem;
}

#pragma mark - Display

- (NSString *)contentTitle
{
    if ([self.contentItem respondsToSelector:@selector(contentTitle)] && [self.contentItem contentTitle]) {
        return [self.contentItem contentTitle];
    } else {
        return @"系统分享";
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
    return @"share_system";
}

#pragma mark - Action

- (void)shareWithContentItem:(id <BDUGActivityContentItemProtocol>)contentItem presentingViewController:(UIViewController *)presentingViewController onComplete:(BDUGActivityCompletionHandler)onComplete
{
    self.contentItem = (BDUGSystemContentItem *)contentItem;
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
    
    BDUGSystemContentItem *contentItem = self.contentItem;

    NSString *text = [contentItem title];
    UIImage *image = [contentItem image];
    NSURL *url;
    if (text.length == 0) {
        text = contentItem.desc;
    }
    if (contentItem.webPageUrl) {
        url = [NSURL URLWithString:[contentItem webPageUrl]];
    }
    [BDUGSystemShare setPopoverRect:contentItem.popoverRect];
    [BDUGSystemShare setApplicationActivities:contentItem.applicationActivities];
    [BDUGSystemShare setExcludedActivityTypes:contentItem.excludedActivityTypes];
    
    UIActivityViewControllerCompletionWithItemsHandler itemHandler = ^(UIActivityType  _Nullable activityType, BOOL completed, NSArray * _Nullable returnedItems, NSError * _Nullable activityError) {
        if (self.completion) {
            self.completion(self, nil, nil);
        }
        
        [[BDUGShareAdapterSetting sharedService] activityHasSharedWith:self error:nil desc:nil];
    };
    if (contentItem.shareFile) {
        if (!contentItem.fileURL || !contentItem.fileName) {
            //invalid content
            NSError *error = [BDUGShareError errorWithDomain:BDUGSystemShareErrorDomain code:BDUGShareErrorTypeInvalidContent userInfo:nil];
            !self.completion ?: self.completion(self, error, error.description);
            [[BDUGShareAdapterSetting sharedService] activityHasSharedWith:self error:error desc:error.description];
        } else if ([contentItem.fileURL isFileURL]) {
            //直接分享本地文件
            [BDUGSystemShare shareFileWithSandboxPath:contentItem.fileURL.absoluteString completion:itemHandler];
        } else {
            //先下载再分享。
            [BDUGShareFileManager getFileFromURLStrings:@[contentItem.fileURL.absoluteString] fileName:contentItem.fileName downloadProgress:nil completion:^(NSError *error, NSString *filePath) {
                [BDUGSystemShare shareFileWithSandboxPath:filePath completion:itemHandler];
            }];
        }
    } else if (contentItem.systemActivityItems.count > 0) {
        [BDUGSystemShare shareWithActivityItems:contentItem.systemActivityItems completion:itemHandler];
    } else {
        [BDUGSystemShare shareWithTitle:text image:image url:url completion:itemHandler];
    }
}

@end
