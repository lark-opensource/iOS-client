//
//  BDUGAwemeShare.m
//  NewsLite
//
//  Created by 杨阳 on 2019/4/24.
//

#import "BDUGAwemeShare.h"
#import "BDUGShareError.h"
#import <TikTokOpenPlatformSDK/BDOpenPlatformShare.h>
#import <TikTokOpenPlatformSDK/BDOpenPlatformApplicationDelegate+Inner.h>

NSString * const BDUGAwemeShareErrorDomain = @"BDUGAwemeShareErrorDomain";
static TikTokOpenPlatformAppType const BDUGAwemeShareAppType = TikTokOpenPlatformAppTypeChina;

@interface BDUGAwemeShare ()

@end

@implementation BDUGAwemeShare

static BDUGAwemeShare *shareInstance;
static NSString *douyinShareAppID = nil;

+ (instancetype)sharedDouyinShare {
    static dispatch_once_t onceToken;
    static BDUGAwemeShare *shareInstance;
    dispatch_once(&onceToken, ^{
        shareInstance = [[BDUGAwemeShare alloc] init];
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
        //注册抖音
        [[BDOpenPlatformApplicationDelegate sharedInstance] registerAppId:douyinShareAppID appType:BDUGAwemeShareAppType];
    });
}

- (BOOL)isAvailable {
    return [self isAvailableWithNotifyError:NO];
}

- (NSString *)currentVersion {
    [[self class] registerDouyinShareIDIfNeeded];
    return [BDOpenPlatformApplicationDelegate sharedInstance].currentVersion;
}

+ (void)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    [[BDOpenPlatformApplicationDelegate sharedInstance] application:application didFinishLaunchingWithOptions:launchOptions];
}

+ (BOOL)application:(UIApplication *)application openURL:(NSURL *)url sourceApplication:(NSString *)sourceApplication annotation:(id)annotation
{
    [[self class] registerDouyinShareIDIfNeeded];
    return [[BDOpenPlatformApplicationDelegate sharedInstance] application:application openURL:url sourceApplication:sourceApplication annotation:annotation];
}

#pragma mark - valide

- (BOOL)isAvailableWithNotifyError:(BOOL)notifyError {
    [[self class] registerDouyinShareIDIfNeeded];
    
    if(![self appInstalled]) {
        if (notifyError) {
            NSError * error = [BDUGShareError errorWithDomain:BDUGAwemeShareErrorDomain
                                                  code:BDUGShareErrorTypeAppNotInstalled
                                              userInfo:nil];
            [self callbackError:error];
        }
        return NO;
    }
    return YES;
}

- (void)callbackError:(NSError *)error {
    if (_delegate && [_delegate respondsToSelector:@selector(awemeShare:sharedWithError:)]) {
        [_delegate awemeShare:self sharedWithError:error];
    }
}

- (BOOL)appInstalled
{
    return [[BDOpenPlatformApplicationDelegate sharedInstance] isAppInstalledWithAppType:BDUGAwemeShareAppType];
}

+ (BOOL)openAweme {
    NSURL *schema = [NSURL URLWithString:@"snssdk1128://"];
    if (@available(iOS 10.0, *)) {
        [[UIApplication sharedApplication] openURL:schema options:@{} completionHandler:nil];
        return YES;
    } else {
        return [[UIApplication sharedApplication] openURL:schema];
    }
}

#pragma mark - send
    
- (void)sendVideoWithPath:(NSString *)videoPath extraInfo:(NSDictionary *)extraInfo state:(NSString *)state hashtag:(NSString *)hashtag
{
    if (videoPath.length == 0) {
        NSError * error = [BDUGShareError errorWithDomain:BDUGAwemeShareErrorDomain
                                              code:BDUGShareErrorTypeNoVideo
                                          userInfo:nil];
        [self callbackError:error];
        return;
    }
    [[self class] registerDouyinShareIDIfNeeded];
    
    BDOpenPlatformShareRequest *req = [[BDOpenPlatformShareRequest alloc] initWithType:BDUGAwemeShareAppType];
    req.mediaType = BDOpenPlatformShareMediaTypeVideo;
    req.localIdentifiers = @[videoPath];
    req.state = state;
    req.extraInfo = extraInfo;
    req.hashtag = hashtag;
    
    [req sendShareRequestWithCompleteBlock:^(BDOpenPlatformShareResponse * _Nonnull Response) {
        [self didReceiveResponse:Response];
    }];
}

- (void)sendImageWithPath:(NSString *)imagePath extraInfo:(NSDictionary *)extraInfo state:(NSString *)state hashtag:(NSString *)hashtag
{
    if (imagePath.length == 0) {
        NSError * error = [BDUGShareError errorWithDomain:BDUGAwemeShareErrorDomain
                                              code:BDUGShareErrorTypeNoImage
                                          userInfo:nil];
        [self callbackError:error];
        return;
    }
    [[self class] registerDouyinShareIDIfNeeded];
    
    BDOpenPlatformShareRequest *req = [[BDOpenPlatformShareRequest alloc] initWithType:BDUGAwemeShareAppType];
    req.mediaType = BDOpenPlatformShareMediaTypeImage;
    req.localIdentifiers = @[imagePath];
    req.state = state;
    req.extraInfo = extraInfo;
    req.hashtag = hashtag;
    [req sendShareRequestWithCompleteBlock:^(BDOpenPlatformShareResponse * _Nonnull Response) {
        [self didReceiveResponse:Response];
    }];
}

#pragma mark - handle response

- (void)didReceiveResponse:(BDOpenPlatformShareResponse * _Nonnull)response {
    NSError *error;
    switch (response.errCode) {
        case BDOpenPlatformSuccess: {
            error = nil;
        }
            break;
        case BDOpenPlatformErrorCodeUserCanceled: {
            error = [BDUGShareError errorWithDomain:BDUGAwemeShareErrorDomain code:BDUGShareErrorTypeUserCancel userInfo:nil];
        }
            break;
        case BDOpenPlatformErrorCodeUnsupported: {
            error = [BDUGShareError errorWithDomain:BDUGAwemeShareErrorDomain code:BDUGShareErrorTypeAppNotSupportAPI userInfo:nil];
        }
            break;
        default: {
            error = [BDUGShareError errorWithDomain:BDUGAwemeShareErrorDomain code:BDUGShareErrorTypeOther userInfo:@{NSLocalizedDescriptionKey: @(response.shareState).stringValue}];
        }
            break;
    }
    [self callbackError:error];
}

@end
