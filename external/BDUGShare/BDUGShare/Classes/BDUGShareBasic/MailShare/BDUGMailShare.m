//
//  TTMail.m
//  Article
//
//  Created by 王霖 on 16/1/28.
//
//

#import "BDUGMailShare.h"
#import <MessageUI/MessageUI.h>
#import "BDUGShareError.h"

NSString *const BDUGMailShareDomain = @"BDUGMailShareDomain";

static NSString *const kTTMailShareErrorDescriptionNotSupport = @"Mail is not available.";
static NSString *const kTTMailShareErrorDescriptionCancelled = @"Mail send cancelled";
static NSString *const kTTMailShareErrorDescriptionSaved = @"Mail saved";
static NSString *const kTTMailShareErrorDescriptionOther = @"Some error occurs";

@interface BDUGMailShare ()<MFMailComposeViewControllerDelegate>

@property(nonatomic, copy)NSDictionary *callbackUserInfo;

@end

@implementation BDUGMailShare

static BDUGMailShare *shareInstance;
+ (nullable instancetype)sharedMailShare {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        shareInstance = [[BDUGMailShare alloc] init];
    });
    return shareInstance;
}

- (BOOL)isAvailable {
    return [self isAvailableWithNotifyError:NO];
}

- (void)sendMailWithSubject:(nullable NSString *)subject
               toRecipients:(nullable NSArray<NSString *> *)toRecipients
               ccRecipients:(nullable NSArray<NSString *> *)ccRecipients
               bcRecipients:(nullable NSArray<NSString *> *)bcRecipients
                messageBody:(nullable NSString *)body
                     isHTML:(BOOL)isHTML
          addAttachmentData:(nullable NSData *)attachment
                   mimeType:(nullable NSString *)mimeType
                   fileName:(nullable NSString *)filename
           inViewController:(nonnull UIViewController *)viewController
 withCustomCallbackUserInfo:(NSDictionary *)customCallbackUserInfo {
    
    self.callbackUserInfo = customCallbackUserInfo;
    
    if (![self isAvailableWithNotifyError:YES]) {
        return;
    }
    
    MFMailComposeViewController *mailController = [[MFMailComposeViewController alloc] init];
    mailController.modalPresentationStyle = UIModalPresentationFormSheet;
    mailController.mailComposeDelegate = self;
    if (subject.length > 0) {
        [mailController setSubject:subject];
    }
    [mailController setToRecipients:toRecipients];
    [mailController setCcRecipients:ccRecipients];
    [mailController setBccRecipients:bcRecipients];
    if (body.length > 0) {
        [mailController setMessageBody:body isHTML:isHTML];
    }
    
    if (attachment != nil && mimeType.length > 0 && filename.length > 0) {
        [mailController addAttachmentData:attachment mimeType:mimeType fileName:filename];
    }
    [viewController presentViewController:mailController animated:YES completion:nil];
}

#pragma mark - Error
- (BOOL)isAvailableWithNotifyError:(BOOL)notifyError {
    if (![MFMailComposeViewController canSendMail]) {
        if (notifyError) {
            [self callbackWithError:[BDUGShareError errorWithDomain:BDUGMailShareDomain
                                                        code:BDUGShareErrorTypeAppNotSupportAPI
                                                    userInfo:@{NSLocalizedDescriptionKey: kTTMailShareErrorDescriptionNotSupport}]];
        }
        return NO;
    }
    return YES;
}

- (void)callbackWithError:(NSError *)error {
    if (_delegate && [_delegate respondsToSelector:@selector(mailShare:sharedWithError:customCallbackUserInfo:)]) {
        [_delegate mailShare:self sharedWithError:error customCallbackUserInfo:_callbackUserInfo];
    }
}

#pragma make - MFMailComposeViewControllerDelegate
- (void)mailComposeController:(MFMailComposeViewController *)controller didFinishWithResult:(MFMailComposeResult)result error:(nullable NSError *)error {
    
    [controller dismissViewControllerAnimated:YES completion:nil];
    if (_delegate && [_delegate respondsToSelector:@selector(mailShare:sharedWithError:customCallbackUserInfo:)]) {
        switch (result) {
            case MFMailComposeResultSent:{
                [self callbackWithError:nil];
            }
                break;
            case MFMailComposeResultCancelled:{
                NSError * error = [BDUGShareError errorWithDomain:BDUGMailShareDomain
                                                      code:BDUGShareErrorTypeUserCancel
                                                  userInfo:@{NSLocalizedDescriptionKey: kTTMailShareErrorDescriptionCancelled}];
                [self callbackWithError:error];
            }
                break;
            case MFMailComposeResultSaved:{
                NSError * error = [BDUGShareError errorWithDomain:BDUGMailShareDomain
                                                      code:BDUGShareErrorTypeOther
                                                  userInfo:@{NSLocalizedDescriptionKey: kTTMailShareErrorDescriptionSaved}];
                [self callbackWithError:error];
            }
                break;
            case MFMailComposeResultFailed:{
                NSError * error = [BDUGShareError errorWithDomain:BDUGMailShareDomain
                                              code:BDUGShareErrorTypeOther
                                          userInfo:@{NSLocalizedDescriptionKey: kTTMailShareErrorDescriptionOther}];
                [self callbackWithError:error];
            }
            default:
                break;
        }
    }
    
}

@end
