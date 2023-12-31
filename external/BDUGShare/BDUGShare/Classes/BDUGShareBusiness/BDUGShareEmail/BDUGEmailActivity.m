//
//  BDUGEmailActivity.m
//  NeteaseLottery
//
//  Created by 延晋 张 on 16/6/6.
//
//

#import "BDUGEmailActivity.h"
#import <MessageUI/MFMailComposeViewController.h>
#import "BDUGShareAdapterSetting.h"
#import "BDUGMailShare.h"
#import "BDUGShareAdapterSetting.h"
#import "BDUGShareError.h"

NSString * const BDUGActivityTypePostToEmail              = @"com.BDUG.UIKit.activity.PostToEmail";

@interface BDUGEmailActivity () <MFMailComposeViewControllerDelegate, TTMailShareDelegate>

@property (nonatomic,copy) BDUGActivityCompletionHandler completion;

@end

@implementation BDUGEmailActivity

@synthesize dataSource = _dataSource, panelId = _panelId;

#pragma mark - Identifier

- (NSString *)contentItemType
{
    return BDUGActivityContentItemTypeEmail;
}

- (NSString *)activityType
{
    return BDUGActivityTypePostToEmail;
}

#pragma mark - Display

- (NSString *)contentTitle
{
    if ([self.contentItem respondsToSelector:@selector(contentTitle)] && [self.contentItem contentTitle]) {
        return [self.contentItem contentTitle];
    } else {
        return @"邮件";
    }
}

- (NSString *)activityImageName
{
    if ([self.contentItem respondsToSelector:@selector(activityImageName)] && [self.contentItem activityImageName]) {
        return [self.contentItem activityImageName];
    } else {
        return @"BDUGShareEmailResource.bundle/mail_allshare";
    }
}

- (NSString *)shareLabel
{
    return @"share_email";
}

#pragma mark - Action

- (void)shareWithContentItem:(id <BDUGActivityContentItemProtocol>)contentItem presentingViewController:(UIViewController *)presentingViewController onComplete:(BDUGActivityCompletionHandler)onComplete
{
    self.contentItem = (BDUGEmailContentItem *)contentItem;
    [self performActivityWithCompletion:^(id<BDUGActivityProtocol> activity, NSError *error, NSString *desc) {
        if (onComplete) {
            onComplete(activity, error, desc);
        }
    }];
}

- (void)performActivityWithCompletion:(BDUGActivityCompletionHandler)completion
{
    self.completion = completion;
    
    [[BDUGShareAdapterSetting sharedService] activityWillSharedWith:self];

    BDUGMailShare *mailShare = [BDUGMailShare sharedMailShare];
    mailShare.delegate = self;
    UIViewController *presenter = self.presentingViewController ? : [[BDUGShareAdapterSetting sharedService] topmostViewController];

    BDUGEmailContentItem *mailItem = self.contentItem;
    [mailShare sendMailWithSubject:mailItem.title toRecipients:mailItem.toRecipients ccRecipients:mailItem.ccRecipients bcRecipients:mailItem.bcRecipients messageBody:mailItem.desc isHTML:mailItem.isHTML addAttachmentData:mailItem.attachment mimeType:mailItem.mimeType fileName:mailItem.fileName inViewController:presenter withCustomCallbackUserInfo:mailItem.callbackUserInfo];
}

#pragma mark - TTMailShareDelegate

- (void)mailShare:(nonnull BDUGMailShare *)mailShare sharedWithError:(nullable NSError *)error customCallbackUserInfo:(nullable NSDictionary *)customCallbackUserInfo
{
    NSString *desc = error.localizedDescription;
    if (error.code == BDUGShareErrorTypeAppNotSupportAPI) {
        desc = @"无邮件帐户";
    }
    
    if (self.completion) {
        self.completion(self, error, desc);
    }

    [[BDUGShareAdapterSetting sharedService] activityHasSharedWith:self error:error desc:desc];
}

@end
