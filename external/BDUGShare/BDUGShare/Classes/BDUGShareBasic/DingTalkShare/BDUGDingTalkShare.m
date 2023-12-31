//
//  BDUGDingTalkShare.m
//  Article
//
//  Created by 朱斌 on 16/8/22.
//
//

#import "BDUGDingTalkShare.h"
#import "BDUGShareImageUtil.h"
#import "BDUGShareError.h"

NSString * const BDUGDingTalkShareErrorDomain = @"BDUGDingTalkShareErrorDomain";

#define kBDUGDingTalkShareMaxPreviewImageSize    (1024 * 32)
#define kBDUGDingTalkShareMaxImageSize    (1024 * 1024 * 10)
#define kBDUGDingTalkShareMaxTextSize    1024

@interface BDUGDingTalkShare() <DTOpenAPIDelegate>

@property (nonatomic, strong) NSDictionary *callbackUserInfo;

@end

@implementation BDUGDingTalkShare

static BDUGDingTalkShare *shareInstance;

+ (instancetype)sharedDingTalkShare {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        shareInstance = [[BDUGDingTalkShare alloc] init];
    });
    return shareInstance;
}

+ (void)registerWithID:(NSString *)appID {
    [DTOpenAPI registerApp:appID];
}

- (BOOL)isAvailable {
    return [self isAvailableWithNotifyError:NO];
}

+ (BOOL)handleOpenURL:(NSURL *)url {
    return [DTOpenAPI handleOpenURL:url delegate:[BDUGDingTalkShare sharedDingTalkShare]];
}

+ (BOOL)openDingTalk {
    return [DTOpenAPI openDingTalk];
}

- (void)sendTextToScene:(DTScene)scene withText:(NSString *)text customCallbackUserInfo:(NSDictionary *)customCallbackUserInfo {
    self.callbackUserInfo = customCallbackUserInfo;
    
    if (![self isAvailableWithNotifyError:YES]) {
        return;
    }
    if (text.length == 0) {
        NSError * error = [BDUGShareError errorWithDomain:BDUGDingTalkShareErrorDomain
                                                     code:BDUGShareErrorTypeNoTitle
                                                 userInfo:nil];
        [self callbackError:error];
        return;
    }
    
    while ([text dataUsingEncoding:NSUTF8StringEncoding allowLossyConversion:YES].length > kBDUGDingTalkShareMaxTextSize) {
        NSUInteger toIndex = text.length / 2;
        if (toIndex > 0 && toIndex < text.length) {
            text = [text substringToIndex:toIndex];
        }else{
            break;
        }
    }
    
    if ([text dataUsingEncoding:NSUTF8StringEncoding allowLossyConversion:YES].length > kBDUGDingTalkShareMaxTextSize) {
        NSError * error = [BDUGShareError errorWithDomain:BDUGDingTalkShareErrorDomain
                                              code:BDUGShareErrorTypeExceedMaxTitleSize
                                          userInfo:nil];
        [self callbackError:error];
        return;
    }
    
    DTMediaMessage *mediaMessage = [[DTMediaMessage alloc] init];
    DTMediaTextObject *textObject = [[DTMediaTextObject alloc] init];
    textObject.text = text;
    mediaMessage.mediaObject = textObject;
    
    DTSendMessageToDingTalkReq *sendMessageReq = [[DTSendMessageToDingTalkReq alloc] init];
    sendMessageReq.message = mediaMessage;
    sendMessageReq.scene = scene;
    
    [DTOpenAPI sendReq:sendMessageReq];
}

- (void)sendImageToScene:(DTScene)scene withImage:(UIImage *)image customCallbackUserInfo:(NSDictionary *)customCallbackUserInfo {
    self.callbackUserInfo = customCallbackUserInfo;
    
    if (![self isAvailableWithNotifyError:YES]) {
        return;
    }
    if (!image) {
        NSError * error = [BDUGShareError errorWithDomain:BDUGDingTalkShareErrorDomain
                                                     code:BDUGShareErrorTypeNoImage
                                                 userInfo:nil];
        [self callbackError:error];
        return;
    }
    DTMediaMessage *mediaMessage = [[DTMediaMessage alloc] init];
    DTMediaImageObject *imageObject = [[DTMediaImageObject alloc] init];
    imageObject.imageData = [BDUGShareImageUtil compressImage:image withLimitLength:kBDUGDingTalkShareMaxImageSize];
    mediaMessage.mediaObject = imageObject;
    mediaMessage.thumbData = [BDUGShareImageUtil compressImage:image withLimitLength:kBDUGDingTalkShareMaxPreviewImageSize];
    
    DTSendMessageToDingTalkReq *sendMessageReq = [[DTSendMessageToDingTalkReq alloc] init];
    sendMessageReq.message = mediaMessage;
    sendMessageReq.scene = scene;
    
    [DTOpenAPI sendReq:sendMessageReq];
}

- (void)sendImageToScene:(DTScene)scene withImageURL:(NSString *)imageURL customCallbackUserInfo:(NSDictionary *)customCallbackUserInfo {
    self.callbackUserInfo = customCallbackUserInfo;
    
    if (![self isAvailableWithNotifyError:YES]) {
        return;
    }
    
    if ([imageURL dataUsingEncoding:NSUTF8StringEncoding allowLossyConversion:YES].length > 1024 * 10) {
        NSError * error = [BDUGShareError errorWithDomain:BDUGDingTalkShareErrorDomain
                                              code:BDUGShareErrorTypeNoImage
                                          userInfo:nil];
        [self callbackError:error];
        return;
    }
    
    DTMediaMessage *message = [[DTMediaMessage alloc] init];
    DTMediaImageObject *imageObject = [[DTMediaImageObject alloc] init];
    imageObject.imageURL = imageURL;
    message.mediaObject = imageObject;
    
    DTSendMessageToDingTalkReq *sendMessageReq = [[DTSendMessageToDingTalkReq alloc] init];
    sendMessageReq.message = message;
    sendMessageReq.scene = scene;
    
    [DTOpenAPI sendReq:sendMessageReq];
}

- (void)sendWebpageToScene:(DTScene)scene withWebpageURL:(NSString *)webpageURL thumbnailImage:(UIImage *)thumbnailImage thumbnailImageURL:(NSString *)thumbnailImageURL title:(NSString *)title description:(NSString *)description customCallbackUserInfo:(NSDictionary *)customCallbackUserInfo {
    self.callbackUserInfo = customCallbackUserInfo;
    
    if (![self isAvailableWithNotifyError:YES]) {
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
    
    NSUInteger webpageURLLength = [webpageURL dataUsingEncoding:NSUTF8StringEncoding allowLossyConversion:YES].length;
    NSUInteger thumbnailImageURLLength = [thumbnailImageURL dataUsingEncoding:NSUTF8StringEncoding allowLossyConversion:YES].length;
    NSUInteger titleLength = [title dataUsingEncoding:NSUTF8StringEncoding allowLossyConversion:YES].length;
    NSUInteger descriptionLength = [description dataUsingEncoding:NSUTF8StringEncoding allowLossyConversion:YES].length;
    
    if (webpageURLLength > 10 * 1024) {
        NSError * error = [BDUGShareError errorWithDomain:BDUGDingTalkShareErrorDomain
                                              code:BDUGShareErrorTypeExceedMaxWebPageURLSize
                                          userInfo:nil];
        [self callbackError:error];
        return;
    }
    if (thumbnailImageURLLength > 32 * 1024) {
        NSError * error = [BDUGShareError errorWithDomain:BDUGDingTalkShareErrorDomain
                                                     code:BDUGShareErrorTypeExceedMaxImageSize
                                                 userInfo:nil];
        [self callbackError:error];
        return;
    }
    if (titleLength > 512) {
        NSError * error = [BDUGShareError errorWithDomain:BDUGDingTalkShareErrorDomain
                                                     code:BDUGShareErrorTypeExceedMaxTitleSize
                                                 userInfo:nil];
        [self callbackError:error];
        return;
    }
    if (descriptionLength > 1024) {
        NSError * error = [BDUGShareError errorWithDomain:BDUGDingTalkShareErrorDomain
                                                     code:BDUGShareErrorTypeExceedMaxDescSize
                                                 userInfo:nil];
        [self callbackError:error];
        return;
    }
    
    DTMediaMessage *message = [[DTMediaMessage alloc] init];
    message.title = title;
    message.messageDescription = description;
    message.thumbURL = thumbnailImageURL;
    if (thumbnailImageURL.length == 0) {
        message.thumbData = [BDUGShareImageUtil compressImage:thumbnailImage withLimitLength:kBDUGDingTalkShareMaxPreviewImageSize];
    }
    DTMediaWebObject *webObject = [[DTMediaWebObject alloc] init];
    webObject.pageURL = webpageURL;
    message.mediaObject = webObject;
    
    DTSendMessageToDingTalkReq *sendMessageReq = [[DTSendMessageToDingTalkReq alloc] init];
    sendMessageReq.message = message;
    sendMessageReq.scene = scene;
    
    [DTOpenAPI sendReq:sendMessageReq];
}

- (void)onResp:(DTBaseResp *)resp {
    if (resp.errorCode == DTOpenAPISuccess) {
        if (_delegate && [_delegate respondsToSelector:@selector(dingTalkShare:sharedWithError:customCallbackUserInfo:)]) {
            [_delegate dingTalkShare:self sharedWithError:nil customCallbackUserInfo:_callbackUserInfo];
        }
    }else if (resp.errorCode == DTOpenAPIErrorCodeUserCancel) {
        NSError * error = [BDUGShareError errorWithDomain:BDUGDingTalkShareErrorDomain
                                              code:BDUGShareErrorTypeUserCancel
                                          userInfo:nil];
        [_delegate dingTalkShare:self sharedWithError:error customCallbackUserInfo:_callbackUserInfo];
    }else {
        NSMutableDictionary * userInfo = [NSMutableDictionary dictionary];
        if (resp.errorMessage.length > 0) {
            [userInfo setValue:resp.errorMessage forKey:NSLocalizedDescriptionKey];
        }
        NSError * error = [BDUGShareError errorWithDomain:BDUGDingTalkShareErrorDomain
                                              code:BDUGShareErrorTypeOther
                                          userInfo:userInfo.copy];
        [_delegate dingTalkShare:self sharedWithError:error customCallbackUserInfo:_callbackUserInfo];
    }
}

- (void)onReq:(DTBaseReq *)req {
    if (_requestDelegate && [_requestDelegate respondsToSelector:@selector(dingTalkShare:receiveRequest:)]) {
        [_requestDelegate dingTalkShare:self receiveRequest:req];
    }
}

#pragma mark - Error

- (BOOL)isAvailableWithNotifyError:(BOOL)notifyError {
    if(![DTOpenAPI isDingTalkInstalled]) {
        if (notifyError) {
            NSError * error = [BDUGShareError errorWithDomain:BDUGDingTalkShareErrorDomain
                                                  code:BDUGShareErrorTypeAppNotInstalled
                                              userInfo:nil];
            [self callbackError:error];
        }
        return NO;
    }
    else if(![DTOpenAPI isDingTalkSupportOpenAPI]){
        if (notifyError) {
            NSError * error = [BDUGShareError errorWithDomain:BDUGDingTalkShareErrorDomain
                                                  code:BDUGShareErrorTypeAppNotSupportAPI
                                              userInfo:nil];
            [self callbackError:error];
        }
        return NO;
    }
    return YES;
}

- (void)callbackError:(NSError *)error {
    if (_delegate && [_delegate respondsToSelector:@selector(dingTalkShare:sharedWithError:customCallbackUserInfo:)]) {
        [_delegate dingTalkShare:self sharedWithError:error customCallbackUserInfo:_callbackUserInfo];
    }
}

#pragma mark - Util

@end
