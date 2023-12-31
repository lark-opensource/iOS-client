//
//  BDUGSMSActivity.m
//  NeteaseLottery
//
//  Created by 延晋 张 on 16/6/6.
//
//

#import "BDUGSMSActivity.h"
#import <MessageUI/MessageUI.h>
#import <CoreText/CoreText.h>
#import "BDUGShareAdapterSetting.h"
#import "BDUGMessageShare.h"

NSString * const BDUGActivityTypePostToSMS                = @"com.BDUG.UIKit.activity.PostToSMS";

@interface BDUGSMSActivity ()<TTMessageShareDelegate>

@property (nonatomic,copy) BDUGActivityCompletionHandler completion;
@property (nonatomic) UIImage *defaultImage;

@end

@implementation BDUGSMSActivity

@synthesize dataSource = _dataSource, panelId = _panelId;

#pragma mark - Identifier

- (NSString *)contentItemType
{
    return BDUGActivityContentItemTypeSMS;
}

- (NSString *)activityType
{
    return BDUGActivityTypePostToSMS;
}

#pragma mark - Display

- (NSString *)contentTitle
{
    if ([self.contentItem respondsToSelector:@selector(contentTitle)] && [self.contentItem contentTitle]) {
        return [self.contentItem contentTitle];
    } else {
        return @"短信";
    }
}

- (NSString *)activityImageName
{
    if ([self.contentItem respondsToSelector:@selector(activityImageName)] && [self.contentItem activityImageName]) {
        return [self.contentItem activityImageName];
    } else {
        return @"BDUGShareSMSResource.bundle/message_allshare";
    }
}

- (NSString *)shareLabel
{
    return @"share_sms";
}

#pragma mark - Action

- (void)shareWithContentItem:(id <BDUGActivityContentItemProtocol>)contentItem presentingViewController:(UIViewController *)presentingViewController onComplete:(BDUGActivityCompletionHandler)onComplete
{
    self.contentItem = (BDUGSMSContentItem *)contentItem;
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

    BDUGMessageShare *messageShare = [BDUGMessageShare sharedMessageShare];
    messageShare.delegate = self;
    UIViewController *presenter = self.presentingViewController ? : [[BDUGShareAdapterSetting sharedService] topmostViewController];
    
    BDUGSMSContentItem *smsItem = self.contentItem;
    [messageShare sendMessageWithBody:smsItem.desc image:self.contentItem.image inViewController:presenter customCallbackUserInfo:smsItem.callbackUserInfo];
}

#pragma mark - TTMessageShareDelegate

- (void)messageShare:(nonnull BDUGMessageShare *)messageShare sharedWithError:(nullable NSError *)error customCallbackUserInfo:(nullable NSDictionary *)customCallbackUserInfo
{
    if (self.completion) {
        self.completion(self, error, error.localizedDescription);
    }
    
    [[BDUGShareAdapterSetting sharedService] activityHasSharedWith:self error:error desc:error.localizedDescription];
}

@end
