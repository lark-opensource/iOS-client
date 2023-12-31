//
//  BDUGLarkShare.m
//  BDUGShare_Example
//
//  Created by 杨阳 on 2020/3/27.
//  Copyright © 2020 xunianqiang. All rights reserved.
//

#import "BDUGLarkShare.h"
#import <LarkOpenShareSDK/LarkApiObject.h>
#import <LarkOpenShareSDK/LarkShareApi.h>
#import "BDUGShareError.h"
#import "BDUGShareImageUtil.h"

NSString * const BDUGLarkShareErrorDomain = @"BDUGLarkShareErrorDomain";

#define kBDUGLarkShareMaxPreviewImageSize    (1024 * 1024 * 10)
#define kBDUGLarkShareMaxTextSize    (1024 * 1)
#define kBDUGLarkShareMaxURLSize    (1024 * 10)
#define kBDUGLarkShareMaxVideoSize    (1024 * 1024 * 10)

@interface BDUGLarkShare() <LarkShareApiDelegate>

@end

@implementation BDUGLarkShare

static BDUGLarkShare *shareInstance;
static NSString *larkShareAppID = nil;

+ (instancetype)sharedLarkShare {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        shareInstance = [[BDUGLarkShare alloc] init];
    });
    return shareInstance;
}

+ (void)registerWithID:(NSString*)appID {
    larkShareAppID = appID;
}

+ (void)registerLarkShareIDIfNeeded {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        //nothing to do
    });
}
 
+ (BOOL)handleOpenURL:(NSURL *)url {
    [[self class] registerLarkShareIDIfNeeded];
    return [LarkShareApi handleOpenURL:url delegate:[BDUGLarkShare sharedLarkShare]];
}

- (BOOL)isAvailable {
    return [self larkInstalled] && [self larkSupportAPI];
}

- (BOOL)larkInstalled {
    [[self class] registerLarkShareIDIfNeeded];
    return [LarkShareApi isAppInstalled];
}

- (BOOL)larkSupportAPI {
    [[self class] registerLarkShareIDIfNeeded];
    return [LarkShareApi isLarkSupportOpenAPI];
}

- (NSString *)currentVersion {
    [[self class] registerLarkShareIDIfNeeded];
    return @([LarkShareApi version]).stringValue;
}

+ (void)setDisplayAppName:(NSString *)displayName {
    [LarkShareApi setDisplayAppName:displayName];
}

+ (void)setAppScheme:(NSString *)scheme {
    [LarkShareApi setAppScheme:scheme];
}

#pragma mark - share

- (void)sendText:(NSString *)text {
    if (text.length > kBDUGLarkShareMaxTextSize) {
        NSError * error = [BDUGShareError errorWithDomain:BDUGLarkShareErrorDomain
                                              code:BDUGShareErrorTypeExceedMaxTitleSize
                                          userInfo:nil];
        [self callbackError:error];
        return;
    }
    if (text.length == 0) {
        NSError * error = [BDUGShareError errorWithDomain:BDUGLarkShareErrorDomain
                                              code:BDUGShareErrorTypeNoTitle
                                          userInfo:nil];
        [self callbackError:error];
        return;
    }
    [[self class] registerLarkShareIDIfNeeded];
    
    LarkMediaTextObject *obj = [[LarkMediaTextObject alloc] init];
    obj.text = text;
    LarkSendMessageRequest *request = [[LarkSendMessageRequest alloc] init];
    request.mediaObject = obj;
    if (![LarkShareApi sendRequest:request]) {
        NSError * error = [BDUGShareError errorWithDomain:BDUGLarkShareErrorDomain
                                              code:BDUGShareErrorTypeSendRequestFail
                                          userInfo:nil];
        [self callbackError:error];
    }
}

- (void)sendImage:(UIImage *)image imageURL:(NSString *)imageURL {
    if (!image && imageURL.length == 0) {
        NSError * error = [BDUGShareError errorWithDomain:BDUGLarkShareErrorDomain
                                              code:BDUGShareErrorTypeNoImage
                                          userInfo:nil];
        [self callbackError:error];
        return;
    }
    if (imageURL.length > kBDUGLarkShareMaxURLSize) {
        NSError * error = [BDUGShareError errorWithDomain:BDUGLarkShareErrorDomain
                                              code:BDUGShareErrorTypeExceedMaxImageSize
                                          userInfo:nil];
        [self callbackError:error];
        return;
    }
    [[self class] registerLarkShareIDIfNeeded];
    LarkMediaImageObject *obj = [[LarkMediaImageObject alloc] init];
    obj.imageData = [BDUGShareImageUtil compressImage:image withLimitLength:kBDUGLarkShareMaxPreviewImageSize];
    obj.imageURL = imageURL;
    LarkSendMessageRequest *request = [[LarkSendMessageRequest alloc] init];
    request.mediaObject = obj;
    if (![LarkShareApi sendRequest:request]) {
        NSError * error = [BDUGShareError errorWithDomain:BDUGLarkShareErrorDomain
                                              code:BDUGShareErrorTypeSendRequestFail
                                          userInfo:nil];
        [self callbackError:error];
    }
}

- (void)sendWebPageURL:(NSString *)webPageURL title:(NSString *)title {
    if (webPageURL.length > kBDUGLarkShareMaxURLSize) {
        NSError * error = [BDUGShareError errorWithDomain:BDUGLarkShareErrorDomain
                                              code:BDUGShareErrorTypeExceedMaxWebPageURLSize
                                          userInfo:nil];
        [self callbackError:error];
    }
    [[self class] registerLarkShareIDIfNeeded];
    LarkMediaWebObject *obj = [[LarkMediaWebObject alloc] init];
    obj.title = title;
    obj.urlStr = webPageURL;
    LarkSendMessageRequest *request = [[LarkSendMessageRequest alloc] init];
    request.mediaObject = obj;
    if (![LarkShareApi sendRequest:request]) {
        NSError * error = [BDUGShareError errorWithDomain:BDUGLarkShareErrorDomain
                                              code:BDUGShareErrorTypeSendRequestFail
                                          userInfo:nil];
        [self callbackError:error];
    }
}

- (void)sendVideoWithSandboxPath:(NSString *)videoSandboxPath {
    NSData *videoData = [[NSFileManager defaultManager] contentsAtPath:videoSandboxPath];
    if (videoData.length > kBDUGLarkShareMaxVideoSize) {
        NSError * error = [BDUGShareError errorWithDomain:BDUGLarkShareErrorDomain
                                              code:BDUGShareErrorTypeExceedMaxVideoSize
                                          userInfo:nil];
        [self callbackError:error];
    }
    [[self class] registerLarkShareIDIfNeeded];
    LarkMediaVideoObject *obj = [[LarkMediaVideoObject alloc] init];
    obj.videoData = videoData;
    LarkSendMessageRequest *request = [[LarkSendMessageRequest alloc] init];
    request.mediaObject = obj;
    if (![LarkShareApi sendRequest:request]) {
        NSError * error = [BDUGShareError errorWithDomain:BDUGLarkShareErrorDomain
                                              code:BDUGShareErrorTypeSendRequestFail
                                          userInfo:nil];
        [self callbackError:error];
    }
}

#pragma mark - res
      
- (void)onResp:(LarkSendReponse *)reponse {
    NSError *error;
    switch (reponse.errorCode) {
        case LarkOpenAPIErrorCodeSuccess:
            
            break;
        case LarkOpenAPIErrorCodeCommon:
            error = [BDUGShareError errorWithDomain:BDUGLarkShareErrorDomain
                                               code:BDUGShareErrorTypeOther
                                           userInfo:@{NSLocalizedDescriptionKey: @(reponse.errorCode).stringValue}];
            break;
        case LarkOpenAPIErrorCodeUserCancel:
            error = [BDUGShareError errorWithDomain:BDUGLarkShareErrorDomain
                                               code:BDUGShareErrorTypeUserCancel
                                           userInfo:nil];
            break;
        case LarkOpenAPIErrorCodeSendFail:
            error = [BDUGShareError errorWithDomain:BDUGLarkShareErrorDomain
                                               code:BDUGShareErrorTypeSendRequestFail
                                           userInfo:nil];
            break;
        case LarkOpenAPIErrorCodeAuthDeny:
            error = [BDUGShareError errorWithDomain:BDUGLarkShareErrorDomain
                                               code:BDUGShareErrorTypeSendRequestFail
                                           userInfo:nil];
            break;
        case LarkOpenAPIErrorCodeUnsupport:
            error = [BDUGShareError errorWithDomain:BDUGLarkShareErrorDomain
                                               code:BDUGShareErrorTypeAppNotSupportAPI
                                           userInfo:nil];
            break;
        default:
            error = [BDUGShareError errorWithDomain:BDUGLarkShareErrorDomain
                                               code:BDUGShareErrorTypeOther
                                           userInfo:@{NSLocalizedDescriptionKey: @(reponse.errorCode).stringValue}];
            break;
    }
    [self callbackError:error];
}

- (BOOL)isAvailableWithNotifyError:(BOOL)notifyError {
    [[self class] registerLarkShareIDIfNeeded];
    if(![LarkShareApi isAppInstalled]) {
        if (notifyError) {
            NSError * error = [BDUGShareError errorWithDomain:BDUGLarkShareErrorDomain
                                                  code:BDUGShareErrorTypeAppNotInstalled
                                              userInfo:nil];
            [self callbackError:error];
        }
        return NO;
    }
    else if(![LarkShareApi isLarkSupportOpenAPI]){
        if (notifyError) {
            NSError * error = [BDUGShareError errorWithDomain:BDUGLarkShareErrorDomain
                                                  code:BDUGShareErrorTypeAppNotSupportAPI
                                              userInfo:nil];
            [self callbackError:error];
        }
        return NO;
    }
    return YES;
}

- (void)callbackError:(NSError *)error {
    if (_delegate && [_delegate respondsToSelector:@selector(larkShare:sharedWithError:)]) {
        [_delegate larkShare:self sharedWithError:error];
    }
}

@end
