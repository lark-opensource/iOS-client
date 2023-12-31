//
//  BDUGToutiaoShare.m
//  TTShare
//
//  Created by chenjianneng on 2019/3/15.
//

#import "BDUGToutiaoShare.h"
#import "BDUGShareError.h"
#import <WeitoutiaoShareSDK/WeitoutiaoShareApi.h>

NSString * const BDUGToutiaoShareErrorDomain = @"BDUGToutiaoShareErrorDomain";

#define kTTMYShareMaxTextSize    (1024 * 10)

@interface BDUGToutiaoShare() <WeitoutiaoShareApiDelegate>

@end

@implementation BDUGToutiaoShare

static BDUGToutiaoShare *shareInstance;
static NSString *toutiaoShareAppID = nil;
static NSString *appSource = nil;

+ (instancetype)sharedInstance {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        shareInstance = [[BDUGToutiaoShare alloc] init];
    });
    return shareInstance;
}

+ (void)registerShareIDIfNeeded {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        [WeitoutiaoShareApi registerApp:toutiaoShareAppID source:appSource];
    });
}

+ (void)registerWithID:(NSString*)appID source:(NSString *)source{
    toutiaoShareAppID = appID;
    appSource = source;
}

+ (BOOL)handleOpenURL:(NSURL *)url {
    [[self class] registerShareIDIfNeeded];
    return [WeitoutiaoShareApi handleOpenURL:url delegate:[BDUGToutiaoShare sharedInstance]];
}

- (BOOL)isAvailable {
    return [self isAvailableWithNotifyError:NO];
}

- (NSString *)currentVersion {
    [[self class] registerShareIDIfNeeded];
    return [WeitoutiaoShareApi getSDKApiVersion];
}

#pragma mark - send

- (void)sendWebpage:(NSString *)webpageURL title:(NSString *)title imageURL:(NSString *)imageURL isVideo:(BOOL)isVideo {
    [[self class] registerShareIDIfNeeded];
    WeitoutiaoShareLinkRequest *request = [[WeitoutiaoShareLinkRequest alloc] init];
    request.title = title;
    request.coverUrl = imageURL;
    request.url = webpageURL;
    request.isVideo = isVideo;
    WeitoutiaoShareApiSendResultCode result = [WeitoutiaoShareApi sendRequest:request];

    if (result == WeitoutiaoShareApiSendSuccess) {
        // 分享成功
    } else {
        NSError *error = [BDUGShareError errorWithDomain:BDUGToutiaoShareErrorDomain code:BDUGShareErrorTypeSendRequestFail userInfo:nil];
        [self callbackError:error];
    }
}

- (void)sendImage:(UIImage *)image title:(NSString *)title postExtra:(NSString *)postExtra {
    [[self class] registerShareIDIfNeeded];

    WeitoutiaoPostRequest *request = [[WeitoutiaoPostRequest alloc] init];
    request.shareImage = image;
    request.content = title;
    request.postExtra = postExtra;
    
    WeitoutiaoShareApiSendResultCode result = [WeitoutiaoShareApi sendRequest:request];
    if (result == WeitoutiaoShareApiSendSuccess) {
        // 分享成功
    } else {
        NSError *error = [BDUGShareError errorWithDomain:BDUGToutiaoShareErrorDomain code:BDUGShareErrorTypeSendRequestFail userInfo:nil];
        [self callbackError:error];
    }
}

#pragma mark - WeitoutiaoShareApiDelegate

- (void)onResponse:(WeitoutiaoShareResponse *)response {
    if (response.code == WeitoutiaoShareApiResponseSuccess) {
        //分享成功
        [self callbackError:nil];
    } else if (response.code == WeitoutiaoShareApiResponseCancel) {
        //取消分享
        NSError * error = [BDUGShareError errorWithDomain:BDUGToutiaoShareErrorDomain
                                              code:BDUGShareErrorTypeUserCancel
                                          userInfo:nil];
        [self callbackError:error];
    } else {
        //其他分享失败
        NSError * error = [BDUGShareError errorWithDomain:BDUGToutiaoShareErrorDomain
                                              code:BDUGShareErrorTypeOther
                                          userInfo:@{NSLocalizedDescriptionKey: @(response.code).stringValue}];
        [self callbackError:error];
    }
}

#pragma mark - Error

- (BOOL)isAvailableWithNotifyError:(BOOL)notifyError {
    [[self class] registerShareIDIfNeeded];
    if(![WeitoutiaoShareApi isToutiaoAppInstalled]) {
        if (notifyError) {
            NSError * error = [BDUGShareError errorWithDomain:BDUGToutiaoShareErrorDomain
                                                  code:BDUGShareErrorTypeAppNotInstalled
                                              userInfo:nil];
            [self callbackError:error];
        }
        return NO;
    }
    else if(![WeitoutiaoShareApi isToutiaoAppSupportApi]){
        if (notifyError) {
            NSError * error = [BDUGShareError errorWithDomain:BDUGToutiaoShareErrorDomain
                                                  code:BDUGShareErrorTypeAppNotSupportAPI
                                              userInfo:nil];
            [self callbackError:error];
        }
        return NO;
    }
    return YES;
}

- (void)callbackError:(NSError *)error {
    if (_delegate && [_delegate respondsToSelector:@selector(toutiaoShare:sharedWithError:)]) {
        [_delegate toutiaoShare:self sharedWithError:error];
    }
}

@end
