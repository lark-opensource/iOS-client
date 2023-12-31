//
//  BDUGWhatsAppShare.m
//  AFgzipRequestSerializer
//
//  Created by 杨阳 on 2019/5/29.
//

static NSString *const kWhatsAppOpenURLString = @"whatsapp://app";
NSString * const BDUGWhatsAppShareErrorDomain = @"BDUGWhatsAppShareErrorDomain";

static NSString *const BDUGWhatsappSystemActivityType = @"net.whatsapp.WhatsApp.ShareExtension";
static NSString *const BDUGWhatsappSystemCopyActivityType = @"com.apple.UIKit.activity.Open.Copy.net.whatsapp.WhatsApp";

#import "BDUGWhatsAppShare.h"
#import <ByteDanceKit/ByteDanceKit.h>
#import "BDUGSystemShare.h"
#import "BDUGShareError.h"


@implementation BDUGWhatsAppShare

static BDUGWhatsAppShare *shareInstance;

+ (instancetype)sharedWhatsAppShare {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        shareInstance = [[BDUGWhatsAppShare alloc] init];
    });
    return shareInstance;
}

+ (BOOL)whatsappInstalled
{
    return [[UIApplication sharedApplication] canOpenURL:[NSURL URLWithString:kWhatsAppOpenURLString]];
}

+ (BOOL)openWhatsApp
{
    return [[UIApplication sharedApplication] openURL:[NSURL URLWithString:kWhatsAppOpenURLString]];
}

- (void)sendText:(NSString *)text
{
    if (text.length == 0) {
        [self callBackWithErrorType:BDUGShareErrorTypeNoTitle];
        return;
    }
    if (![self.class whatsappInstalled]) {
        [self callBackWithErrorType:BDUGShareErrorTypeAppNotInstalled];
        return;
    }
    NSString *urlString = [NSString stringWithFormat:@"whatsapp://send?text=%@", [text btd_stringByURLEncode]];
    NSURL *whatsappURL = [NSURL URLWithString:urlString];
    if ([[UIApplication sharedApplication] canOpenURL:whatsappURL]) {
        [[UIApplication sharedApplication] openURL:whatsappURL];
        [self callBackError:nil];
    } else {
        [self callBackWithErrorType:BDUGShareErrorTypeAppNotSupportAPI];
    }
}

- (void)sendImage:(UIImage *)image {
    if (!image) {
        [self callBackWithErrorType:BDUGShareErrorTypeNoImage];
        return;
    }
    if (![self.class whatsappInstalled]) {
        [self callBackWithErrorType:BDUGShareErrorTypeAppNotInstalled];
        return;
    }
    [BDUGSystemShare shareImage:image completion:^(UIActivityType  _Nullable activityType, BOOL completed, NSArray * _Nullable returnedItems, NSError * _Nullable activityError) {
        if ([activityType isEqualToString:BDUGWhatsappSystemActivityType]) {
            [self callBackError:nil];
        } else {
            NSError *error = [BDUGShareError errorWithDomain:BDUGWhatsAppShareErrorDomain code:BDUGShareErrorTypeUserCancel userInfo:nil];
            [self callBackError:error];
        }
    }];
}

- (void)sendFileWithSandboxPath:(NSString *)sandboxPath
{
    if (!sandboxPath || ![[NSFileManager defaultManager] fileExistsAtPath:sandboxPath]) {
        [self callBackWithErrorType:BDUGShareErrorTypeInvalidContent];
        return;
    }
    if (![self.class whatsappInstalled]) {
        [self callBackWithErrorType:BDUGShareErrorTypeAppNotInstalled];
        return;
    }
    [BDUGSystemShare shareFileWithSandboxPath:sandboxPath completion:^(UIActivityType  _Nullable activityType, BOOL completed, NSArray * _Nullable returnedItems, NSError * _Nullable activityError) {
        if ([activityType isEqualToString:BDUGWhatsappSystemActivityType] ||
            [activityType isEqualToString:BDUGWhatsappSystemCopyActivityType]) {
            [self callBackError:nil];
        } else {
            NSError *error = [BDUGShareError errorWithDomain:BDUGWhatsAppShareErrorDomain code:BDUGShareErrorTypeUserCancel userInfo:nil];
            [self callBackError:error];
        }
    }];
}

#pragma mark - call back

- (void)callBackWithErrorType:(BDUGShareErrorType)type
{
    NSError *error = [BDUGShareError errorWithDomain:BDUGWhatsAppShareErrorDomain code:type userInfo:nil];
    [self callBackError:error];
}

- (void)callBackError:(NSError *)error {
    if (_delegate && [_delegate respondsToSelector:@selector(whatsappShare:sharedWithError:)]) {
        [_delegate whatsappShare:self sharedWithError:error];
    }
}

@end
