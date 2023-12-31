//
//  BDUGQQShare.m
//  Article
//
//  Created by 王霖 on 15/9/21.
//
//

#import "BDUGQQShare.h"
#import "BDUGShareImageUtil.h"
#import "BDUGShareBaseUtil.h"
#import <TencentOpenAPI/QQApiInterface.h>
#import <TencentOpenAPI/QQApiInterface.h>
#import <TencentOpenAPI/TencentOAuth.h>
#import <TencentOpenAPI/QQApiInterfaceObject.h>
#import "BDUGShareError.h"

NSString * const BDUGQQShareErrorDomain = @"BDUGQQShareErrorDomain";

#define kBDUGQQShareMaxImageSize   (1024 * 1024 * 5)
#define kBDUGQQShareMaxPreviewImageSize   (1024 * 1024 * 1)

@interface BDUGQQShare()<QQApiInterfaceDelegate, TencentSessionDelegate>

@property(nonatomic, strong)TencentOAuth *tencentOauth;
@property(nonatomic, strong)NSArray *permissions;
@property(nonatomic, copy)NSDictionary *callbackUserInfo;

@end

@implementation BDUGQQShare

static BDUGQQShare *shareInstance;
static NSString *qqShareAppID = nil;
static NSString *qqUniversalLink = nil;

+ (instancetype)sharedQQShare {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        shareInstance = [[BDUGQQShare alloc] init];
    });
    return shareInstance;
}

+ (void)registerWithID:(NSString *)appID {
    [self registerWithID:appID universalLink:@""];
}

+ (void)registerWithID:(NSString *)appID universalLink:(NSString *)universalLink {
    qqShareAppID = appID;
    qqUniversalLink = universalLink;
}

+ (void)registerQQShareIfNeeded {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        BDUGQQShare *qqShare = [BDUGQQShare sharedQQShare];
        if (qqUniversalLink) {
            qqShare.tencentOauth = [[TencentOAuth alloc] initWithAppId:qqShareAppID andUniversalLink:qqUniversalLink andDelegate:qqShare];
        } else {
            qqShare.tencentOauth = [[TencentOAuth alloc] initWithAppId:qqShareAppID andDelegate:qqShare];
        }
        
    });
}

- (BOOL)isAvailable {
    [[self class] registerQQShareIfNeeded];
    return [self isAvailableWithNotifyError:NO];
}

- (NSString *)currentVersion {
    return [TencentOAuth sdkVersion];
}

+ (BOOL)handleOpenURL:(NSURL *)url {
    [self registerQQShareIfNeeded];
    return [QQApiInterface handleOpenURL:url delegate:[BDUGQQShare sharedQQShare]];
}

+ (BOOL)handleOpenUniversallink:(NSURL *)universallink {
    [self registerQQShareIfNeeded];
    if ([TencentOAuth CanHandleUniversalLink:universallink]) {
        [QQApiInterface handleOpenUniversallink:universallink delegate:[BDUGQQShare sharedQQShare]];
        return [TencentOAuth HandleUniversalLink:universallink];
    } else {
        return NO;
    }
}

+ (BOOL)openQQ {
    [[self class] registerQQShareIfNeeded];
    return [QQApiInterface openQQ];
}

#pragma mark - 分享到QQ好友

- (void)sendText:(NSString *)text withCustomCallbackUserInfo:(NSDictionary *)customCallbackUserInfo {
    [[self class] registerQQShareIfNeeded];
    
    self.callbackUserInfo = customCallbackUserInfo;
    if (![self isAvailableWithNotifyError:YES]) {
        return;
    }
    
    if (text.length == 0) {
        NSError * error = [BDUGShareError errorWithDomain:BDUGQQShareErrorDomain
                                              code:BDUGShareErrorTypeNoTitle
                                          userInfo:nil];
        [self callbackError:error];
        return;
    }
    
    if (text.length > 1536) {
        text = [text substringToIndex:1536];
    }
    
    QQApiTextObject * textObject = [QQApiTextObject objectWithText:text];
    SendMessageToQQReq * req = [SendMessageToQQReq reqWithContent:textObject];
    
    QQApiSendResultCode sent = [QQApiInterface sendReq:req];
    [self handleSendResult:sent];
}

- (void)sendImageWithImageData:(NSData *)imageData
            thumbnailImageData:(NSData *)thumbnailImageData
                         title:(NSString *)title
                   description:(NSString *)description
        customCallbackUserInfo:(NSDictionary *)customCallbackUserInfo {
    [[self class] registerQQShareIfNeeded];
    
    self.callbackUserInfo = customCallbackUserInfo;
    
    if (![self isAvailableWithNotifyError:YES]) {
        return;
    }
    
    if (imageData.length > kBDUGQQShareMaxImageSize || thumbnailImageData.length > kBDUGQQShareMaxPreviewImageSize) {
        NSError * error = [BDUGShareError errorWithDomain:BDUGQQShareErrorDomain
                                              code:BDUGShareErrorTypeExceedMaxImageSize
                                          userInfo:nil];
        [self callbackError:error];
        return;
    }
    
    if (title.length > 128) {
        title = [title substringToIndex:128];
    }
    
    if (description.length > 512) {
        description = [description substringToIndex:512];
    }
    
    if (imageData == nil) {
        NSError * error = [BDUGShareError errorWithDomain:BDUGQQShareErrorDomain
                                              code:BDUGShareErrorTypeNoImage
                                          userInfo:nil];
        [self callbackError:error];
        return;
    }
    
    QQApiImageObject *imageObject = [QQApiImageObject objectWithData:imageData
                                                    previewImageData:thumbnailImageData
                                                               title:title
                                                         description:description];
    SendMessageToQQReq *req = [SendMessageToQQReq reqWithContent:imageObject];
    QQApiSendResultCode sent = [QQApiInterface sendReq:req];
    [self handleSendResult:sent];
}

- (void)sendImage:(UIImage *)image
        withTitle:(NSString *)title
      description:(NSString *)description
customCallbackUserInfo:(NSDictionary *)customCallbackUserInfo {
    NSData *imageData = [BDUGShareImageUtil compressImage:image withLimitLength:kBDUGQQShareMaxImageSize];
    NSData *previewImageData = [BDUGShareImageUtil compressImage:image withLimitLength:kBDUGQQShareMaxPreviewImageSize];
    [self sendImageWithImageData:imageData
              thumbnailImageData:previewImageData
                           title:title
                     description:description
          customCallbackUserInfo:customCallbackUserInfo];
    
}

- (void)sendNewsWithURL:(NSString *)url
         thumbnailImage:(UIImage *)thumbnailImage
      thumbnailImageURL:(NSString *)thumbnailImageURL
                  title:(NSString *)title
            description:(NSString *)description
 customCallbackUserInfo:(NSDictionary *)customCallbackUserInfo {
    [[self class] registerQQShareIfNeeded];
    
    self.callbackUserInfo = customCallbackUserInfo;
    
    if (![self isAvailableWithNotifyError:YES]) {
        return;
    }
    
    if (title.length > 128) {
        title = [title substringToIndex:128];
    }
    
    if (description.length > 512) {
        description = [description substringToIndex:512];
    }
    
    NSURL * nUrl = [BDUGShareBaseUtil URLWithURLString:url];
    NSURL * pImageUrl = [BDUGShareBaseUtil URLWithURLString:thumbnailImageURL];
    
    if (nUrl == nil) {
        NSError * error = [BDUGShareError errorWithDomain:BDUGQQShareErrorDomain
                                              code:BDUGShareErrorTypeInvalidContent
                                          userInfo:nil];
        [self callbackError:error];
        return;
    }
    
   
    if (pImageUrl != nil) {
        [BDUGShareImageUtil downloadImageDataWithURL:pImageUrl limitLength:kBDUGQQShareMaxPreviewImageSize completion:^(NSData *imageData, NSError *error) {
            QQApiNewsObject *newsObj = [QQApiNewsObject objectWithURL:nUrl
                                                                title:title
                                                          description:description
                                                     previewImageData:imageData];
            SendMessageToQQReq *req = [SendMessageToQQReq reqWithContent:newsObj];
            QQApiSendResultCode sent = [QQApiInterface sendReq:req];
            [self handleSendResult:sent];
        }];
    }else {
         QQApiNewsObject *newsObj = [QQApiNewsObject objectWithURL:nUrl
                                           title:title
                                     description:description
                                previewImageData:[BDUGShareImageUtil compressImage:thumbnailImage withLimitLength:kBDUGQQShareMaxPreviewImageSize]];
        SendMessageToQQReq *req = [SendMessageToQQReq reqWithContent:newsObj];
        QQApiSendResultCode sent = [QQApiInterface sendReq:req];
        [self handleSendResult:sent];
    }
}

#pragma mark - 分享到QQ空间

- (void)sendImageToQZoneWithImage:(UIImage *)image title:(NSString *)title customCallbackUserInfo:(NSDictionary *)customCallbackUserInfo {
    [[self class] registerQQShareIfNeeded];
    
    NSData *imageData = [BDUGShareImageUtil compressImage:image withLimitLength:kBDUGQQShareMaxImageSize];
    NSData *previewImageData = [BDUGShareImageUtil compressImage:image withLimitLength:kBDUGQQShareMaxPreviewImageSize];
    [self sendImageToQZoneWithImageData:imageData thumbnailImageData:previewImageData title:title customCallbackUserInfo:customCallbackUserInfo];;
}

- (void)sendImageToQZoneWithImageData:(NSData *)imageData thumbnailImageData:(NSData *)thumbnailImageData title:(NSString *)title customCallbackUserInfo:(NSDictionary *)customCallbackUserInfo {
    [[self class] registerQQShareIfNeeded];
    
    self.callbackUserInfo = customCallbackUserInfo;
    
    if (![self isAvailableWithNotifyError:YES]) {
        return;
    }
    
    if (imageData.length > kBDUGQQShareMaxImageSize || thumbnailImageData.length > kBDUGQQShareMaxPreviewImageSize) {
        NSError * error = [BDUGShareError errorWithDomain:BDUGQQShareErrorDomain
                                              code:BDUGShareErrorTypeExceedMaxImageSize
                                          userInfo:nil];
        [self callbackError:error];
        return;
    }
    
    if (title.length > 128) {
        title = [title substringToIndex:128]; 
    }
    
    if (imageData == nil) {
        NSError * error = [BDUGShareError errorWithDomain:BDUGQQShareErrorDomain
                                              code:BDUGShareErrorTypeNoImage
                                          userInfo:nil];
        [self callbackError:error];
        return;
    }
    
    QQApiImageArrayForQZoneObject *imgObj = [QQApiImageArrayForQZoneObject objectWithimageDataArray:@[imageData] title:title extMap:nil];
    SendMessageToQQReq* req = [SendMessageToQQReq reqWithContent:imgObj];
    QQApiSendResultCode sent = [QQApiInterface SendReqToQZone:req];
    [self handleSendResult:sent];
}

- (void)sendNewsToQZoneWithURL:(NSString *)url
                thumbnailImage:(UIImage *)thumbnailImage
             thumbnailImageURL:(NSString *)thumbnailImageURL
                         title:(NSString *)title
                   description:(NSString *)description
        customCallbackUserInfo:(NSDictionary *)customCallbackUserInfo {
    [[self class] registerQQShareIfNeeded];
    
    self.callbackUserInfo = customCallbackUserInfo;
    
    if (![self isAvailableWithNotifyError:YES]) {
        return;
    }
    
    if (title.length > 128) {
        title = [title substringToIndex:128];
    }
    
    if (description.length > 512) {
        description = [description substringToIndex:512];
    }
    
    NSURL * nUrl = [BDUGShareBaseUtil URLWithURLString:url];
    NSURL * pImageUrl = [BDUGShareBaseUtil URLWithURLString:thumbnailImageURL];
    
    if (nUrl == nil) {
        NSError * error = [BDUGShareError errorWithDomain:BDUGQQShareErrorDomain
                                              code:BDUGShareErrorTypeNoWebPageURL
                                          userInfo:nil];
        [self callbackError:error];
        return;
    }
    
    if (pImageUrl != nil) {
        [BDUGShareImageUtil downloadImageDataWithURL:pImageUrl limitLength:kBDUGQQShareMaxPreviewImageSize completion:^(NSData *imageData, NSError *error) {
            QQApiNewsObject *newsObj = [QQApiNewsObject objectWithURL:nUrl
                                                                title:title
                                                          description:description
                                                     previewImageData:imageData];
            SendMessageToQQReq *req = [SendMessageToQQReq reqWithContent:newsObj];
            QQApiSendResultCode sent = [QQApiInterface SendReqToQZone:req];
            [self handleSendResult:sent];
        }];
    }else {
        QQApiNewsObject *newsObj = [QQApiNewsObject objectWithURL:nUrl
                                           title:title
                                     description:description
                                previewImageData:[BDUGShareImageUtil compressImage:thumbnailImage withLimitLength:kBDUGQQShareMaxPreviewImageSize]];
        SendMessageToQQReq *req = [SendMessageToQQReq reqWithContent:newsObj];
        QQApiSendResultCode sent = [QQApiInterface SendReqToQZone:req];
        [self handleSendResult:sent];
    }
}

- (void)handleSendResult:(QQApiSendResultCode)sendResult {
    switch (sendResult) {
        case EQQAPISENDSUCESS:
        case EQQAPIAPPSHAREASYNC: {
            //QQ请求发送成功，等待onResp返回结果。
        }
            break;
        case EQQAPIQQNOTINSTALLED: {
            NSError * error = [BDUGShareError errorWithDomain:BDUGQQShareErrorDomain
                                                         code:BDUGShareErrorTypeAppNotInstalled
                                                     userInfo:nil];
            [self callbackError:error];
        }
            break;
        case EQQAPIQQNOTSUPPORTAPI: {
            NSError * error = [BDUGShareError errorWithDomain:BDUGQQShareErrorDomain
                                                         code:BDUGShareErrorTypeAppNotSupportAPI
                                                     userInfo:nil];
            [self callbackError:error];
        }
            break;
        case EQQAPIMESSAGETYPEINVALID:
        case EQQAPIMESSAGECONTENTNULL:
        case EQQAPIMESSAGECONTENTINVALID: {
            NSError * error = [BDUGShareError errorWithDomain:BDUGQQShareErrorDomain
                                                         code:BDUGShareErrorTypeInvalidContent
                                                     userInfo:nil];
            [self callbackError:error];
        }
            break;
        case EQQAPIQZONENOTSUPPORTTEXT:
        case EQQAPIQZONENOTSUPPORTIMAGE: {
            //qzone分享不支持text类型分享
            NSError * error = [BDUGShareError errorWithDomain:BDUGQQShareErrorDomain
                                                         code:BDUGShareErrorTypeAppNotSupportShareType
                                                     userInfo:nil];
            [self callbackError:error];
        }
            break;
        case EQQAPIAPPNOTREGISTED:
        case EQQAPIQQNOTSUPPORTAPI_WITH_ERRORSHOW:
        case EQQAPISENDFAILD:
        default: {
            NSError * error = [BDUGShareError errorWithDomain:BDUGQQShareErrorDomain
                                                         code:BDUGShareErrorTypeOther
                                                     userInfo:@{NSLocalizedDescriptionKey: @(sendResult).stringValue}];
            [self callbackError:error];
        }
            break;
    }
}

#pragma mark -- QQApiInterfaceDelegate

- (void)onReq:(QQBaseReq *)req {
    if (_requestDelegate && [_requestDelegate respondsToSelector:@selector(qqShare:receiveRequest:)]) {
        [_requestDelegate qqShare:self receiveRequest:req];
    }
}

- (void)onResp:(QQBaseResp *)resp {
    switch (resp.type) {
        case ESENDMESSAGETOQQRESPTYPE: {
            SendMessageToQQResp* sendResp = (SendMessageToQQResp*)resp;
            if ([_delegate respondsToSelector:@selector(qqShare:sharedWithError:customCallbackUserInfo:)]) {
                NSError * error = nil;
                if (![resp.result isEqualToString:@"0"]) {
                    NSMutableDictionary * userInfo = [NSMutableDictionary dictionary];
                    if (sendResp.errorDescription.length > 0) {
                        [userInfo setValue:[sendResp errorDescription] forKey:NSLocalizedDescriptionKey];
                    }
                    error = [BDUGShareError errorWithDomain:BDUGQQShareErrorDomain
                                                code:BDUGShareErrorTypeOther
                                            userInfo:userInfo.copy];
                }
                [_delegate qqShare:self sharedWithError:error customCallbackUserInfo:_callbackUserInfo];
            }
        }
            break;
        default:
            break;
    }
}

- (void)isOnlineResponse:(NSDictionary *)response {}

#pragma mark - Error

- (BOOL)isAvailableWithNotifyError:(BOOL)notifyError {
    if(![QQApiInterface isQQInstalled]) {
        if (notifyError) {
            NSError * error = [BDUGShareError errorWithDomain:BDUGQQShareErrorDomain
                                                  code:BDUGShareErrorTypeAppNotInstalled
                                              userInfo:nil];
            [self callbackError:error];
        }
        return NO;
    }
    
    if(![QQApiInterface isQQSupportApi]) {
        if (notifyError) {
            NSError * error = [BDUGShareError errorWithDomain:BDUGQQShareErrorDomain
                                                  code:BDUGShareErrorTypeAppNotSupportAPI
                                              userInfo:nil];
            [self callbackError:error];
        }
        return NO;
    }
    return YES;
}

- (void)callbackError:(NSError *)error {
    if (_delegate && [_delegate respondsToSelector:@selector(qqShare:sharedWithError:customCallbackUserInfo:)]) {
        [_delegate qqShare:self sharedWithError:error customCallbackUserInfo:_callbackUserInfo];
    }
}

#pragma mark - TencentLoginDelegate

- (void)tencentDidLogin {
    
}

- (void)tencentDidNotLogin:(BOOL)cancelled {
    
}

- (void)tencentDidNotNetWork {
    
}

@end
