//
//  BDUGTiktokShare.m
//  BDUGShare_Example
//
//  Created by 杨阳 on 2019/6/11.
//  Copyright © 2019 xunianqiang. All rights reserved.
//

#import "BDUGTiktokShare.h"
#import "BDUGShareError.h"
#import <TikTokOpenPlatformSDK/BDOpenPlatformShare.h>
#import <TikTokOpenPlatformSDK/BDOpenPlatformApplicationDelegate+Inner.h>

NSString * const BDUGTiktokShareErrorDomain = @"BDUGTiktokShareErrorDomain";
static TikTokOpenPlatformAppType const BDUGTiktokShareAppType = TikTokOpenPlatformAppTypeI18N;

static NSString * const kBDUGTiktokShareErrorDescriptionTiktokNotInstall = @"Tiktok is not installed.";
static NSString * const kBDUGTiktokShareErrorDescriptionTiktokNotSupportAPI = @"Tiktok do not support api.";
static NSString * const kBDUGTiktokShareErrorDescriptionExceedMaxImageSize = @"(Image/Preview image) excced max size.";
static NSString * const kBDUGTiktokShareErrorDescriptionExceedMaxTextSize = @"Text excced max length.";
static NSString * const kBDUGTiktokShareErrorDescriptionContentInvalid = @"Content is invalid.";
static NSString * const kBDUGTiktokShareErrorDescriptionCancel = @"User cancel.";
static NSString * const kBDUGTiktokShareErrorDescriptionOther = @"Some error occurs.";

@interface BDUGTiktokShare ()

@end

@implementation BDUGTiktokShare

static BDUGTiktokShare *shareInstance;
static NSString *douyinShareAppID = nil;

+ (instancetype)sharedDouyinShare {
    static dispatch_once_t onceToken;
    static BDUGTiktokShare *shareInstance;
    dispatch_once(&onceToken, ^{
        shareInstance = [[BDUGTiktokShare alloc] init];
    });
    return shareInstance;
}

+ (void)registerWithID:(NSString *)appID {
    douyinShareAppID = appID;
}

+ (void)registerDouyinShareIDIfNeeded {
    if (!douyinShareAppID || douyinShareAppID.length == 0) {
        return;
    }
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        //注册tiktok
        [[BDOpenPlatformApplicationDelegate sharedInstance] registerAppId:douyinShareAppID appType:BDUGTiktokShareAppType];
    });
}

- (BOOL)isAvailable {
    return [self isAvailableWithNotifyError:NO];
}

- (NSString *)currentVersion {
    [[self class] registerDouyinShareIDIfNeeded];
    return [BDOpenPlatformApplicationDelegate sharedInstance].currentVersion;
}

+ (void)application:(UIApplication *)application didFinishLaunchingWithOptions:(nullable NSDictionary *)launchOptions
{
    [[BDOpenPlatformApplicationDelegate sharedInstance] application:application didFinishLaunchingWithOptions:launchOptions];
}

+ (BOOL)application:(nullable UIApplication *)application openURL:(nonnull NSURL *)url sourceApplication:(nullable NSString *)sourceApplication annotation:(nonnull id)annotation
{
    [[self class] registerDouyinShareIDIfNeeded];
    return [[BDOpenPlatformApplicationDelegate sharedInstance] application:application openURL:url sourceApplication:sourceApplication annotation:annotation];
}

#pragma mark - valide

- (BOOL)isAvailableWithNotifyError:(BOOL)notifyError {
    [[self class] registerDouyinShareIDIfNeeded];
    
    if(![self appInstalled]) {
        if (notifyError) {
            NSError * error = [BDUGShareError errorWithDomain:BDUGTiktokShareErrorDomain
                                                         code:BDUGShareErrorTypeAppNotInstalled
                                                     userInfo:@{NSLocalizedDescriptionKey: kBDUGTiktokShareErrorDescriptionTiktokNotInstall}];
            [self callbackError:error];
        }
        return NO;
    }
    return YES;
}

- (void)callbackError:(NSError *)error {
    if (_delegate && [_delegate respondsToSelector:@selector(tiktokShare:sharedWithError:)]) {
        [_delegate tiktokShare:self sharedWithError:error];
    }
}

- (BOOL)appInstalled
{
    return [[BDOpenPlatformApplicationDelegate sharedInstance] isAppInstalledWithAppType:BDUGTiktokShareAppType];
}

#pragma mark - send

- (void)sendVideoWithPath:(NSString *)videoPath
{
    if (videoPath.length == 0) {
        NSError * error = [BDUGShareError errorWithDomain:BDUGTiktokShareErrorDomain
                                                     code:BDUGShareErrorTypeNoVideo
                                                 userInfo:@{NSLocalizedDescriptionKey: kBDUGTiktokShareErrorDescriptionContentInvalid}];
        [self callbackError:error];
        return;
    }
    [[self class] registerDouyinShareIDIfNeeded];
    
    BDOpenPlatformShareRequest *req = [[BDOpenPlatformShareRequest alloc] initWithType:BDUGTiktokShareAppType];
    req.mediaType = BDOpenPlatformShareMediaTypeVideo;
    req.localIdentifiers = @[videoPath];
    
    [req sendShareRequestWithCompleteBlock:^(BDOpenPlatformShareResponse * _Nonnull Response) {
        [self didReceiveResponse:Response];
    }];
}

- (void)sendImageWithPath:(NSString *)imagePath
{
    if (imagePath.length == 0) {
        NSError * error = [BDUGShareError errorWithDomain:BDUGTiktokShareErrorDomain
                                                     code:BDUGShareErrorTypeNoImage
                                                 userInfo:@{NSLocalizedDescriptionKey: kBDUGTiktokShareErrorDescriptionContentInvalid}];
        [self callbackError:error];
        return;
    }
    [[self class] registerDouyinShareIDIfNeeded];
    
    BDOpenPlatformShareRequest *req = [[BDOpenPlatformShareRequest alloc] initWithType:BDUGTiktokShareAppType];
    req.mediaType = BDOpenPlatformShareMediaTypeImage;
    
    [req sendShareRequestWithCompleteBlock:^(BDOpenPlatformShareResponse * _Nonnull Response) {
        [self didReceiveResponse:Response];
    }];
}

#pragma mark - handle response

- (void)didReceiveResponse:(BDOpenPlatformBaseResponse *)response {
    switch (response.errCode) {
        case BDOpenPlatformSuccess: {
            [self callbackError:nil];
        }
            break;
        case BDOpenPlatformErrorCodeUnsupported: {
            NSError * error = [BDUGShareError errorWithDomain:BDUGTiktokShareErrorDomain
                                                         code:BDUGShareErrorTypeAppNotSupportAPI
                                                     userInfo:@{NSLocalizedDescriptionKey: kBDUGTiktokShareErrorDescriptionTiktokNotSupportAPI}];
            [self callbackError:error];
        }
            break;
        case BDOpenPlatformErrorCodeUserCanceled: {
            NSError * error = [BDUGShareError errorWithDomain:BDUGTiktokShareErrorDomain
                                                         code:BDUGShareErrorTypeUserCancel
                                                     userInfo:@{NSLocalizedDescriptionKey: kBDUGTiktokShareErrorDescriptionCancel}];
            [self callbackError:error];
        }
            break;
        default: {
            NSError * error = [BDUGShareError errorWithDomain:BDUGTiktokShareErrorDomain
                                                         code:BDUGShareErrorTypeOther
                                                     userInfo:@{NSLocalizedDescriptionKey: @(response.errCode).stringValue}];
            [self callbackError:error];
        }
            break;
    }
    
}

@end
