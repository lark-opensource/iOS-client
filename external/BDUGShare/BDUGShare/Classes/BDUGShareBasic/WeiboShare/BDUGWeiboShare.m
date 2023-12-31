//
//  TTWeibo.m
//  ss_app_ios_lib_share
//
//  Created by 王霖 on 15/10/10.
//  Copyright © 2015年 王霖. All rights reserved.
//

#import "BDUGWeiboShare.h"
#import "BDUGShareImageUtil.h"
#import <CommonCrypto/CommonDigest.h>
#import "BDUGShareError.h"
#import <ByteDanceKit/NSString+BTDAdditions.h>
#import <WeiboSDK/WeiboSDK.h>
#import "BDUGShareBaseUtil.h"

NSString * const BDUGWeiboShareErrorDomain = @"BDUGWeiboShareErrorDomain";

#define kTTWeiboMaxImageSize   1024 * 1024 * 10
#define kTTWeiboMaxPreviewImageSize   1024 * 32

@interface BDUGWeiboShare ()<WeiboSDKDelegate>

@property(nonatomic, copy)NSDictionary *callbackUserInfo;

@end

@implementation BDUGWeiboShare

static BDUGWeiboShare *shareInstance;
static NSString *weiboShareAppID = nil;
static NSString *weiboShareUniversalLink = nil;

+ (instancetype)sharedWeiboShare {
    static dispatch_once_t onceTocken;
    dispatch_once(&onceTocken, ^{
        shareInstance = [[BDUGWeiboShare alloc] init];
    });
    return shareInstance;
}

+ (void)registerWithID:(NSString *)appID universalLink:(NSString *)universalLink
{
    weiboShareAppID = appID;
    weiboShareUniversalLink = universalLink;
}

+ (void)registerWeiboShareIDIfNeeded {
    if (weiboShareAppID == nil) {
        return;
    }
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        [WeiboSDK registerApp:weiboShareAppID universalLink:weiboShareUniversalLink];
    });
}

- (BOOL)isAvailable {
    return [self isAvailableWithNotifyError:NO];
}

- (NSString *)currentVersion {
    [self.class registerWeiboShareIDIfNeeded];
    return [WeiboSDK getSDKVersion];
}

+ (BOOL)handleOpenURL:(NSURL *)url {
    [self.class registerWeiboShareIDIfNeeded];
    return [WeiboSDK handleOpenURL:url delegate:[BDUGWeiboShare sharedWeiboShare]];
}

+ (BOOL)handleOpenUniversalLink:(NSUserActivity *_Nullable)userActivity {
    [self.class registerWeiboShareIDIfNeeded];
    return [WeiboSDK handleOpenUniversalLink:userActivity delegate:[BDUGWeiboShare sharedWeiboShare]];
}

- (void)sendText:(NSString *)text withCustomCallbackUserInfo:(NSDictionary *)customCallbackUserInfo {
    [self.class registerWeiboShareIDIfNeeded];

    self.callbackUserInfo = customCallbackUserInfo;
    
    if (![self isAvailableWithNotifyError:YES]) {
        return;
    }
    
    if (text.length == 0) {
        NSError * error = [BDUGShareError errorWithDomain:BDUGWeiboShareErrorDomain
                                              code:BDUGShareErrorTypeNoTitle
                                          userInfo:nil];
        [self callbackError:error];
        return;
    }
    
    if ([BDUGShareBaseUtil lengthOfWords:text] > 140) {
        NSError * error = [BDUGShareError errorWithDomain:BDUGWeiboShareErrorDomain
                                              code:BDUGShareErrorTypeExceedMaxTitleSize
                                          userInfo:nil];
        [self callbackError:error];
        return;
    }
    
    WBMessageObject *message = [WBMessageObject message];
    message.text = text;
    
    WBSendMessageToWeiboRequest *request = [WBSendMessageToWeiboRequest requestWithMessage:message];
    [WeiboSDK sendRequest:request completion:^(BOOL success) {
        if (!success) {
            NSError * error = [BDUGShareError errorWithDomain:BDUGWeiboShareErrorDomain
                                                         code:BDUGShareErrorTypeSendRequestFail
                                                     userInfo:nil];
            [self callbackError:error];
        }
    }];
}

- (void)sendText:(NSString *)text withImage:(UIImage*)image customCallbackUserInfo:(NSDictionary *)customCallbackUserInfo {
    [self.class registerWeiboShareIDIfNeeded];

    self.callbackUserInfo = customCallbackUserInfo;
    
    if (![self isAvailableWithNotifyError:YES]) {
        return;
    }
    
    if (image == nil) {
        NSError * error = [BDUGShareError errorWithDomain:BDUGWeiboShareErrorDomain
                                              code:BDUGShareErrorTypeNoImage
                                          userInfo:nil];
        [self callbackError:error];
        return;
    }
    
    if ([BDUGShareBaseUtil lengthOfWords:text] > 140) {
        NSError * error = [BDUGShareError errorWithDomain:BDUGWeiboShareErrorDomain
                                              code:BDUGShareErrorTypeExceedMaxTitleSize
                                          userInfo:nil];
        [self callbackError:error];
        return;
    }
    
    WBMessageObject *message = [WBMessageObject message];
    message.text = text;
    
    WBImageObject *imageObject = [WBImageObject object];
    imageObject.imageData = [BDUGShareImageUtil compressImage:image withLimitLength:kTTWeiboMaxImageSize];
    message.imageObject = imageObject;
    
    WBSendMessageToWeiboRequest *request = [WBSendMessageToWeiboRequest requestWithMessage:message];
    [WeiboSDK sendRequest:request completion:^(BOOL success) {
        if (!success) {
            NSError * error = [BDUGShareError errorWithDomain:BDUGWeiboShareErrorDomain
                                                         code:BDUGShareErrorTypeSendRequestFail
                                                     userInfo:nil];
            [self callbackError:error];
        }
    }];
}

- (void)sendWebpageWithTitle:(NSString *)title webpageURL:(NSString *)webpageURL thumbnailImage:(UIImage *)thumbnailImage description:(NSString *)description customCallbackUserInfo:(NSDictionary *)customCallbackUserInfo {
    [self.class registerWeiboShareIDIfNeeded];

    self.callbackUserInfo = customCallbackUserInfo;
    
    if (![self isAvailableWithNotifyError:YES]) {
        return;
    }
    
    if (webpageURL.length > 255) {
        webpageURL = [webpageURL substringToIndex:254];
    }
    if (webpageURL.length == 0) {
        NSError * error = [BDUGShareError errorWithDomain:BDUGWeiboShareErrorDomain
                                              code:BDUGShareErrorTypeNoWebPageURL
                                          userInfo:nil];
        [self callbackError:error];
        return;
    }
    if (webpageURL.length > 255) {
        NSError * error = [BDUGShareError errorWithDomain:BDUGWeiboShareErrorDomain
                                                     code:BDUGShareErrorTypeExceedMaxWebPageURLSize
                                                 userInfo:nil];
        [self callbackError:error];
        return;
    }
    if ([title dataUsingEncoding:NSUTF8StringEncoding allowLossyConversion:YES].length > 1024) {
        NSError * error = [BDUGShareError errorWithDomain:BDUGWeiboShareErrorDomain
                                                     code:BDUGShareErrorTypeExceedMaxTitleSize
                                                 userInfo:nil];
        [self callbackError:error];
        return;
    }
    if ([description dataUsingEncoding:NSUTF8StringEncoding allowLossyConversion:YES].length > 1024) {
        NSError * error = [BDUGShareError errorWithDomain:BDUGWeiboShareErrorDomain
                                                     code:BDUGShareErrorTypeExceedMaxDescSize
                                                 userInfo:nil];
        [self callbackError:error];
        return;
    }
    
    WBMessageObject * messageToSend = [WBMessageObject message];
    
    WBWebpageObject *webPageObject = [WBWebpageObject object];
    webPageObject.objectID = [[self class] md5:webpageURL];
    webPageObject.title = title;
    webPageObject.description = description;
    webPageObject.webpageUrl = webpageURL;
    webPageObject.thumbnailData = [BDUGShareImageUtil compressImage:thumbnailImage withLimitLength:kTTWeiboMaxPreviewImageSize];
    
    messageToSend.mediaObject = webPageObject;
    
    WBSendMessageToWeiboRequest *request = [WBSendMessageToWeiboRequest requestWithMessage:messageToSend];
    [WeiboSDK sendRequest:request completion:^(BOOL success) {
        if (!success) {
            NSError * error = [BDUGShareError errorWithDomain:BDUGWeiboShareErrorDomain
                                                         code:BDUGShareErrorTypeSendRequestFail
                                                     userInfo:nil];
            [self callbackError:error];
        }
    }];
}

#pragma mark - Error
- (BOOL)isAvailableWithNotifyError:(BOOL)notifyError {
    [self.class registerWeiboShareIDIfNeeded];

    if(![WeiboSDK isWeiboAppInstalled]) {
        if (notifyError) {
            NSError * error = [BDUGShareError errorWithDomain:BDUGWeiboShareErrorDomain
                                                  code:BDUGShareErrorTypeAppNotInstalled
                                              userInfo:nil];
            [self callbackError:error];
        }
        return NO;
    }
    
    if(![WeiboSDK isCanShareInWeiboAPP]) {
        if (notifyError) {
            NSError * error = [BDUGShareError errorWithDomain:BDUGWeiboShareErrorDomain
                                                  code:BDUGShareErrorTypeAppNotSupportAPI
                                              userInfo:nil];
            [self callbackError:error];
        }
        return NO;
    }
    return YES;
}

- (void)callbackError:(NSError *)error {
    if (_delegate && [_delegate respondsToSelector:@selector(weiboShare:sharedWithError:customCallbackUserInfo:)]) {
        [_delegate weiboShare:self sharedWithError:error customCallbackUserInfo:_callbackUserInfo];
    }
}

#pragma mark - WeiboSDKDelegate

- (void)didReceiveWeiboRequest:(WBBaseRequest *)request {
    if (_requestDelegate && [_requestDelegate respondsToSelector:@selector(weiboShare:receiveRequest:)]) {
        [_requestDelegate weiboShare:self receiveRequest:request];
    }
}

- (void)didReceiveWeiboResponse:(WBBaseResponse *)response {
    if ([response isKindOfClass:WBSendMessageToWeiboResponse.class]) {
        switch (response.statusCode) {
            case 0:{
                if (_delegate) {
                    [_delegate weiboShare:self sharedWithError:nil customCallbackUserInfo:_callbackUserInfo];
                }
            }
                break;
            case -1:{
                if (_delegate) {
                    NSError * error = [BDUGShareError errorWithDomain:BDUGWeiboShareErrorDomain
                                                          code:BDUGShareErrorTypeUserCancel
                                                      userInfo:nil];
                    [_delegate weiboShare:self sharedWithError:error customCallbackUserInfo:_callbackUserInfo];
                }
            }
                break;
            default:{
                if (_delegate) {
                    NSError * error = [BDUGShareError errorWithDomain:BDUGWeiboShareErrorDomain
                                                          code:BDUGShareErrorTypeOther
                                                      userInfo:@{NSLocalizedDescriptionKey: @(response.statusCode).stringValue}];
                    [_delegate weiboShare:self sharedWithError:error customCallbackUserInfo:_callbackUserInfo];
                }
            }
                break;
        }
    }
}

#pragma mark - Util

+ (NSString *)md5:(NSString *)orignalString
{
    if (orignalString.length == 0) {
        return nil;
    }
    const char* character = [orignalString UTF8String];
    
    unsigned char result[CC_MD5_DIGEST_LENGTH];
    
    CC_MD5(character, (CC_LONG)strlen(character), result);
    
    NSMutableString *md5String = [NSMutableString stringWithCapacity:CC_MD5_DIGEST_LENGTH];
    
    for(int i = 0; i < CC_MD5_DIGEST_LENGTH; i++)
    {
        [md5String appendFormat:@"%02x",result[i]];
    }
    
    return md5String;
}

@end
