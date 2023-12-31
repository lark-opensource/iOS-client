//
//  BDUGMessageShare.m
//  Article
//
//  Created by 王霖 on 16/1/28.
//
//

#import "BDUGMessageShare.h"
#import <MessageUI/MessageUI.h>
#import "BDUGShareError.h"

NSString *const BDUGMessageShareDomain = @"BDUGMessageShareDomain";

static NSString *const kTTMessageShareErrorDescriptionNotSupport = @"Message is not available.";
static NSString *const kTTMessageShareErrorDescriptionCancelled = @"Message send cancelled";
static NSString *const kTTMessageShareErrorDescriptionOther = @"Some error occurs";

@interface BDUGMessageShare ()<MFMessageComposeViewControllerDelegate>

@property(nonatomic, copy)NSDictionary *callbackUserInfo;

@end

@implementation BDUGMessageShare

static BDUGMessageShare *shareInstance;

+ (instancetype)sharedMessageShare {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        shareInstance = [[BDUGMessageShare alloc] init];
    });
    return shareInstance;
}

- (BOOL)isAvailable {
    return [self isAvailableWithNotifyError:NO];
}

- (void)sendMessageWithBody:(NSString * _Nullable)body
           inViewController:(UIViewController *)viewController
     customCallbackUserInfo:(NSDictionary * _Nullable)customCallbackUserInfo {
    [self sendMessageWithBody:body image:nil inViewController:viewController customCallbackUserInfo:customCallbackUserInfo];
}

- (void)sendMessageWithBody:(NSString * _Nullable)body
                      image:(UIImage * _Nullable)image
           inViewController:(UIViewController *)viewController
     customCallbackUserInfo:(NSDictionary * _Nullable)customCallbackUserInfo {
    self.callbackUserInfo = customCallbackUserInfo;
    if (![self isAvailableWithNotifyError:YES]) {
        return;
    }
    MFMessageComposeViewController *messageViewController = [[MFMessageComposeViewController alloc] init];
    messageViewController.modalPresentationStyle = UIModalPresentationFormSheet;
    messageViewController.messageComposeDelegate = self;
    [messageViewController setBody:body];
    
    if (image) {
        NSData *dataImg = UIImagePNGRepresentation(image);//Add the image as attachment
        [messageViewController addAttachmentData:dataImg typeIdentifier:@"public.data" filename:@"Image.png"];
    }
    
    [viewController presentViewController:messageViewController animated:YES completion:nil];
}


#pragma mark - Error
- (BOOL)isAvailableWithNotifyError:(BOOL)notifyError {
    if (![MFMessageComposeViewController canSendText]) {
        if (notifyError) {
            NSError * error = [BDUGShareError errorWithDomain:BDUGMessageShareDomain
                                                  code:BDUGShareErrorTypeAppNotSupportAPI
                                              userInfo:@{NSLocalizedDescriptionKey: kTTMessageShareErrorDescriptionNotSupport}];
            [self callbackWithError:error];
        }
        return NO;
    }
    return YES;
}

- (void)callbackWithError:(NSError *)error {
    if (_delegate && [_delegate respondsToSelector:@selector(messageShare:sharedWithError:customCallbackUserInfo:)]) {
        [_delegate messageShare:self sharedWithError:error customCallbackUserInfo:_callbackUserInfo];
    }
}

#pragma mark - MFMessageComposeViewControllerDelegate
- (void)messageComposeViewController:(MFMessageComposeViewController *)controller didFinishWithResult:(MessageComposeResult)result {
    [controller dismissViewControllerAnimated:YES completion:nil];
    if (_delegate && [_delegate respondsToSelector:@selector(messageShare:sharedWithError:customCallbackUserInfo:)]) {
        switch (result) {
            case MessageComposeResultSent:{
                [self callbackWithError:nil];
            }
                break;
            case MessageComposeResultCancelled:{
                NSError * error = [BDUGShareError errorWithDomain:BDUGMessageShareDomain
                                                      code:BDUGShareErrorTypeUserCancel
                                                  userInfo:@{NSLocalizedDescriptionKey: kTTMessageShareErrorDescriptionCancelled}];
                [self callbackWithError:error];
            }
                break;
            case MessageComposeResultFailed:{
                NSError * error = [BDUGShareError errorWithDomain:BDUGMessageShareDomain
                                                      code:BDUGShareErrorTypeOther
                                                  userInfo:@{NSLocalizedDescriptionKey: @(result).stringValue}];
                [self callbackWithError:error];
            }
                break;
            default:
                break;
        }
    }
    
}
@end

