//
//  BDUGMayaShare.m
//  TTShare
//
//  Created by chenjianneng on 2019/3/15.
//

#import "BDUGMayaShare.h"
#import "BDUGShareError.h"

NSString * const BDUGMayaShareErrorDomain = @"BDUGMayaShareErrorDomain";

#define kTTMYShareMaxTextSize    (1024 * 10)

@interface BDUGMayaShare() <MYApiDelegate>

@end

@implementation BDUGMayaShare

static BDUGMayaShare *shareInstance;
static NSString *mayaShareAppID = nil;

+ (instancetype)sharedMYShare {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        shareInstance = [[BDUGMayaShare alloc] init];
    });
    return shareInstance;
}

+ (void)registerMYShareIDIfNeeded {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        [MYApi registerApp:mayaShareAppID];
    });
}

+ (void)registerWithID:(NSString*)appID {
    mayaShareAppID = appID;
}


+ (BOOL)handleOpenURL:(NSURL *)url {
    [[self class] registerMYShareIDIfNeeded];
    return [MYApi handleOpenURL:url delegate:[BDUGMayaShare sharedMYShare]];
}

- (BOOL)isAvailable {
    return [self isAvailableWithNotifyError:NO];
}

- (NSString *)currentVersion {
    [[self class] registerMYShareIDIfNeeded];
    return [MYApi getApiVersion];
}

- (void)sendWebpageToScene:(MYScene)scene
            withWebpageURL:(NSString *)webpageURL
            thumbnailImage:(UIImage *)thumbnailImage
                     title:(NSString*)title
               description:(NSString*)description {
    [self sendWebpageToScene:scene withWebpageURL:webpageURL thumbnailImage:thumbnailImage title:title description:description style:nil];
}

- (void)sendWebpageToScene:(MYScene)scene withWebpageURL:(NSString *)webpageURL thumbnailImage:(UIImage *)thumbnailImage title:(NSString*)title description:(NSString*)description style:(NSString *)style {
    [[self class] registerMYShareIDIfNeeded];

    if(![self isAvailableWithNotifyError:YES]) {
        return;
    }

    while ([title dataUsingEncoding:NSUTF8StringEncoding allowLossyConversion:YES].length > 512) {
        NSUInteger toIndex = title.length / 2;
        if (toIndex > 0 && toIndex < title.length) {
            title = [title substringToIndex:toIndex];
        }else {
            break;
        }
    }

    while ([description dataUsingEncoding:NSUTF8StringEncoding allowLossyConversion:YES].length > 1024) {
        NSUInteger toIndex = description.length / 2;
        if (toIndex > 0 && toIndex < description.length) {
            description = [description substringToIndex:toIndex];
        }else {
            break;
        }
    }

    if ([title dataUsingEncoding:NSUTF8StringEncoding allowLossyConversion:YES].length > 512) {
        NSError * error = [BDUGShareError errorWithDomain:BDUGMayaShareErrorDomain
                                              code:BDUGShareErrorTypeExceedMaxTitleSize
                                          userInfo:nil];
        [self callbackError:error];
        return;
    }
    if ([description dataUsingEncoding:NSUTF8StringEncoding allowLossyConversion:YES].length > 1024) {
        NSError * error = [BDUGShareError errorWithDomain:BDUGMayaShareErrorDomain
                                              code:BDUGShareErrorTypeExceedMaxDescSize
                                          userInfo:nil];
        [self callbackError:error];
        return;
    }
    if ([webpageURL dataUsingEncoding:NSUTF8StringEncoding allowLossyConversion:YES].length > kTTMYShareMaxTextSize) {
        NSError * error = [BDUGShareError errorWithDomain:BDUGMayaShareErrorDomain
                                              code:BDUGShareErrorTypeExceedMaxWebPageURLSize
                                          userInfo:nil];
        [self callbackError:error];
        return;
    }

    MYWebpageMessage *webPageObject = [MYWebpageMessage new];
    webPageObject.webpageUrl = webpageURL;
    webPageObject.thumbImage = thumbnailImage;
    webPageObject.title = title;
    webPageObject.desc = description;

    MYSendMessageReq* req = [[MYSendMessageReq alloc] init];
    req.message = webPageObject;
    req.scene = scene;

    [MYApi sendReq:req];
}


#pragma makr - MYApiDelegate

- (void)onResp:(MYBaseResp *)resp {
    if([resp isKindOfClass:[MYSendMessageResp class]]) {
        if(resp.code != 0) {
            if(resp.code == MYRespCodeCancelled) {
                NSError * error = [BDUGShareError errorWithDomain:BDUGMayaShareErrorDomain
                                                      code:BDUGShareErrorTypeUserCancel
                                                  userInfo:nil];
                [self callbackError:error];
            }else {
                NSError * error = [BDUGShareError errorWithDomain:BDUGMayaShareErrorDomain
                                                             code:BDUGShareErrorTypeOther
                                                         userInfo:@{NSLocalizedDescriptionKey: @(resp.code).stringValue}];
                [self callbackError:error];
            }
        }else {
            if(_delegate && [_delegate respondsToSelector:@selector(mayaShare:sharedWithError:)]) {
                [_delegate mayaShare:self sharedWithError:nil];
            }
        }
    }
}

#pragma mark - Error

- (BOOL)isAvailableWithNotifyError:(BOOL)notifyError {
    [[self class] registerMYShareIDIfNeeded];
    if(![MYApi isAppInstalled]) {
        if (notifyError) {
            NSError * error = [BDUGShareError errorWithDomain:BDUGMayaShareErrorDomain
                                                  code:BDUGShareErrorTypeAppNotInstalled
                                              userInfo:nil];
            [self callbackError:error];
        }
        return NO;
    }
    else if(![MYApi isAppSupportApi]){
        if (notifyError) {
            NSError * error = [BDUGShareError errorWithDomain:BDUGMayaShareErrorDomain
                                                  code:BDUGShareErrorTypeAppNotSupportAPI
                                              userInfo:nil];
            [self callbackError:error];
        }
        return NO;
    }
    return YES;
}

- (void)callbackError:(NSError *)error {
    if (_delegate && [_delegate respondsToSelector:@selector(mayaShare:sharedWithError:)]) {
        [_delegate mayaShare:self sharedWithError:error];
    }
}


@end
