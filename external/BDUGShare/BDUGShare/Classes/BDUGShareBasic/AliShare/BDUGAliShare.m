//
//  BDUGAliShare.m
//  Article
//
//  Created by Huaqing Luo on 27/8/15.
//
//

#import "BDUGAliShare.h"
#import "BDUGShareError.h"

NSString * const BDUGAliShareErrorDomain = @"BDUGAliShareErrorDomain";

static NSString * const kTTAliShareErrorDescriptionZhifubaoNotInstall = @"Zhifubao is not installed.";
static NSString * const kTTAliShareErrorDescriptionZhifubaoNotSupportAPI = @"Zhifubao do not support api.";
static NSString * const kTTAliShareErrorDescriptionExceedMaxImageSize = @"(Image/Preview image) excced max size.";
static NSString * const kTTAliShareErrorDescriptionExceedMaxTextSize = @"Text excced max length.";
static NSString * const kTTAliShareErrorDescriptionContentInvalid = @"Content is invalid.";
static NSString * const kTTAliShareErrorDescriptionCancel = @"User cancel.";
static NSString * const kTTAliShareErrorDescriptionOther = @"Some error occurs.";


@interface BDUGAliShare ()<APOpenAPIDelegate>

@property (nonatomic, strong)NSDictionary *callbackUserInfo;

@end

@implementation BDUGAliShare

static BDUGAliShare * shareInstance;
static NSString *aliPayAppID;

+ (instancetype)sharedAliShare {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        shareInstance = [[BDUGAliShare alloc] init];
    });
    return shareInstance;
}

+ (void)registerWithID:(NSString*)appID {
    aliPayAppID = appID;
}

+ (void)registerAliPayAppIDIfNeed {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        [APOpenAPI registerApp:aliPayAppID];
    });
}

- (BOOL)isAvailable {
    [[self class] registerAliPayAppIDIfNeed];
    return [self isAvailableWithNotifyError:NO];
}

- (BOOL)isSupportShareTimeLine {
    [[self class] registerAliPayAppIDIfNeed];
    return ([APOpenAPI isAPAppInstalled] && [APOpenAPI isAPAppSupportShareTimeLine]);
}

- (NSString *)currentVersion {
    [[self class] registerAliPayAppIDIfNeed];
    return [APOpenAPI getApiVersion];
}

+ (BOOL)handleOpenURL:(NSURL *)url {
    [self registerAliPayAppIDIfNeed];
    return [APOpenAPI handleOpenURL:url delegate:[BDUGAliShare sharedAliShare]];
}


- (void)sendTextToScene:(APScene)scene withText:(NSString *)text customCallbackUserInfo:(NSDictionary *)customCallbackUserInfo {
    [[self class] registerAliPayAppIDIfNeed];
    
    self.callbackUserInfo = customCallbackUserInfo;
    
    if (![self isAvailableWithNotifyError:YES]) {
        return;
    }
    
    APMediaMessage * message = [[APMediaMessage alloc] init];
    APShareTextObject * textObj = [[APShareTextObject alloc] init];
    textObj.text = text;
    message.mediaObject = textObj;
    
    APSendMessageToAPReq * request = [[APSendMessageToAPReq alloc] init];
    request.message = message;
    request.scene = scene;
    [APOpenAPI sendReq:request];
}

- (void)sendImageToScene:(APScene)scene withImage:(UIImage*)image customCallbackUserInfo:(NSDictionary *)customCallbackUserInfo {
    [[self class] registerAliPayAppIDIfNeed];
    
    self.callbackUserInfo = customCallbackUserInfo;
    
    if (![self isAvailableWithNotifyError:YES]) {
        return;
    }
    
    APMediaMessage * message = [[APMediaMessage alloc] init];
    APShareImageObject * imgObj = [[APShareImageObject alloc] init];
    imgObj.imageData = UIImageJPEGRepresentation(image, 1.0);
    message.mediaObject = imgObj;
    
    APSendMessageToAPReq * request = [[APSendMessageToAPReq alloc] init];
    request.message = message;
    request.scene = scene;
    [APOpenAPI sendReq:request];
}

- (void)sendImageToScene:(APScene)scene withImageURL:(NSString*)imageURL customCallbackUserInfo:(NSDictionary *)customCallbackUserInfo {
    [[self class] registerAliPayAppIDIfNeed];
    
    self.callbackUserInfo = customCallbackUserInfo;
    
    if (![self isAvailableWithNotifyError:YES]) {
        return;
    }
    
    APMediaMessage * message = [[APMediaMessage alloc] init];
    APShareImageObject * imgObj = [[APShareImageObject alloc] init];
    imgObj.imageUrl = imageURL;
    message.mediaObject = imgObj;
    
    APSendMessageToAPReq * request = [[APSendMessageToAPReq alloc] init];
    request.message = message;
    request.scene = scene;
    [APOpenAPI sendReq:request];
}

- (void)sendWebpageToScene:(APScene)scene withWebpageURL:(NSString *)webpageURL thumbnailImage:(UIImage*)thumbnailImage thumbnailImageURL:(NSString *)thumbnailImageURL title:(NSString*)title description:(NSString*)description customCallbackUserInfo:(NSDictionary *)customCallbackUserInfo {
    [[self class] registerAliPayAppIDIfNeed];
    
    self.callbackUserInfo = customCallbackUserInfo;
    
    if (![self isAvailableWithNotifyError:YES]) {
        return;
    }
    
    APMediaMessage * message = [[APMediaMessage alloc] init];
    message.title = [title copy];
    message.desc = [description copy];
    if (thumbnailImage) {
        message.thumbData = UIImageJPEGRepresentation(thumbnailImage, 1.0);
    } else if (thumbnailImageURL.length > 0) {
        message.thumbUrl = thumbnailImageURL;
    }
    APShareWebObject * webObj = [[APShareWebObject alloc] init];
    webObj.wepageUrl = webpageURL;
    message.mediaObject = webObj;
    
    APSendMessageToAPReq * request = [[APSendMessageToAPReq alloc] init];
    request.message = message;
    request.scene = scene;
    [APOpenAPI sendReq:request];
}

#pragma mark -- APOpenAPIDelegate

- (void)onResp:(APBaseResp *)resp {
    if (resp.errCode == APSuccess) {
        if (_delegate && [_delegate respondsToSelector:@selector(aliShare:sharedWithError:customCallbackUserInfo:)]) {
            [_delegate aliShare:self sharedWithError:nil customCallbackUserInfo:_callbackUserInfo];
        }
    }else if (resp.errCode == APErrCodeUserCancel) {
        NSError * error = [BDUGShareError errorWithDomain:BDUGAliShareErrorDomain
                                              code:BDUGShareErrorTypeUserCancel
                                          userInfo:@{NSLocalizedDescriptionKey:kTTAliShareErrorDescriptionCancel}];
        if (_delegate && [_delegate respondsToSelector:@selector(aliShare:sharedWithError:customCallbackUserInfo:)]) {
            [_delegate aliShare:self sharedWithError:error customCallbackUserInfo:_callbackUserInfo];
        }
    }else {
        NSMutableDictionary * userInfo = [NSMutableDictionary dictionary];
        if (resp.errStr.length > 0) {
            [userInfo setValue:resp.errStr forKey:NSLocalizedDescriptionKey];
        }else {
            [userInfo setValue:kTTAliShareErrorDescriptionOther forKey:NSLocalizedDescriptionKey];
        }
        NSError * error = [BDUGShareError errorWithDomain:BDUGAliShareErrorDomain
                                              code:BDUGShareErrorTypeOther
                                          userInfo:userInfo.copy];
        if (_delegate && [_delegate respondsToSelector:@selector(aliShare:sharedWithError:customCallbackUserInfo:)]) {
            [_delegate aliShare:self sharedWithError:error customCallbackUserInfo:_callbackUserInfo];
        }
    }
}

- (void)onReq:(APBaseReq *)req {
    if (_requestDelegate && [_requestDelegate respondsToSelector:@selector(aliShare:receiveRequest:)]) {
        [_requestDelegate aliShare:self receiveRequest:req];
    }
}

#pragma mark - Error

- (BOOL)isAvailableWithNotifyError:(BOOL)notifyError {
    [[self class] registerAliPayAppIDIfNeed];
    if(![APOpenAPI isAPAppInstalled]) {
        if (notifyError) {
            NSError * error = [BDUGShareError errorWithDomain:BDUGAliShareErrorDomain
                                                  code:BDUGShareErrorTypeAppNotInstalled
                                              userInfo:@{NSLocalizedDescriptionKey: kTTAliShareErrorDescriptionZhifubaoNotInstall}];
            [self callbackError:error];
        }
        return NO;
    }else if(![APOpenAPI isAPAppSupportOpenApi]){
        if (notifyError) {
            NSError * error = [BDUGShareError errorWithDomain:BDUGAliShareErrorDomain
                                                  code:BDUGShareErrorTypeAppNotSupportAPI
                                              userInfo:@{NSLocalizedDescriptionKey: kTTAliShareErrorDescriptionZhifubaoNotSupportAPI}];
            [self callbackError:error];
        }
        return NO;
    }
    return YES;
}

- (void)callbackError:(NSError *)error {
    if (_delegate && [_delegate respondsToSelector:@selector(aliShare:sharedWithError:customCallbackUserInfo:)]) {
        [_delegate aliShare:self sharedWithError:error customCallbackUserInfo:_callbackUserInfo];
    }
}

#pragma mark - Util

@end
