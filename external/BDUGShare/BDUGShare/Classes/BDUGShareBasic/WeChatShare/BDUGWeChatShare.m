//
//  BDUGWeChatShare.m
//  Article
//
//  Created by 王霖 on 15/9/21.
//
//

#import "BDUGWeChatShare.h"
#import "BDUGShareImageUtil.h"
#import "BDUGShareBaseUtil.h"
#import "BDUGShareError.h"
#import <WechatSDK/WXApi.h>

//static NSString * const SSCommonWxxcxID = @"SSCommonWxxcxID";
//static NSString * const SSCommonWxxcxPathTemplate = @"SSCommonWxxcxPathTemplate";

NSString * const BDUGWechatShareErrorDomain = @"BDUGWechatShareErrorDomain";

#define kBDUGWechatShareMaxPreviewImageSize    (1024 * 32)
#define kBDUGWechatShareMaxImageSize   (1024 * 1024 * 10)
#define kBDUGWechatShareMaxFileSize    (1024 * 1024 * 10)
#define kBDUGWechatShareMaxTextSize    (1024 * 10)

@interface BDUGWeChatShare()<WXApiDelegate>

@property (nonatomic, strong)NSDictionary *callbackUserInfo;

@end

@implementation BDUGWeChatShare

static BDUGWeChatShare *shareInstance;
static NSString *wechatShareAppID = nil;
static NSString *wecahtUniversalLink = nil;

+ (instancetype)sharedWeChatShare {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        shareInstance = [[BDUGWeChatShare alloc] init];
    });
    return shareInstance;
}

+ (void)registerWithID:(NSString*)appID universalLink:(NSString *)universalLink {
    wechatShareAppID = appID;
    wecahtUniversalLink = universalLink;
}

//+ (void)registerWxxcxID:(NSString *)wxxcxID {
//    [NSUserDefaults.standardUserDefaults setObject:wxxcxID forKey:SSCommonWxxcxID];
//}
//
//+ (void)registerWxxcxPath:(NSString *)wxxcxPath {
//    [NSUserDefaults.standardUserDefaults setObject:wxxcxPath forKey:SSCommonWxxcxPathTemplate];
//}

+ (void)registerWechatShareIDIfNeeded {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        [WXApi registerApp:wechatShareAppID universalLink:wecahtUniversalLink];
    });
}

- (BOOL)isAvailable {
    return [self isAvailableWithNotifyError:NO];
}

- (NSString *)currentVersion {
    [[self class] registerWechatShareIDIfNeeded];
    return [WXApi getApiVersion];
}

/**
 *  打开微信
 *
 *  @return 是否成功打开
 */
+ (BOOL)openWechat {
    [[self class] registerWechatShareIDIfNeeded];
    if (@available(iOS 16.0, *)) {
        NSURL *weixinUrl = [NSURL URLWithString:@"weixin://"];
        BOOL canOpen = [[UIApplication sharedApplication] canOpenURL:weixinUrl];
        if (canOpen) {
            [[UIApplication sharedApplication] openURL:weixinUrl options:@{} completionHandler:nil];
        }
        return canOpen;
    }
    return [WXApi openWXApp];
}

+ (BOOL)handleOpenURL:(NSURL *)url {
    [[self class] registerWechatShareIDIfNeeded];
    return [WXApi handleOpenURL:url delegate:[BDUGWeChatShare sharedWeChatShare]];
}

+ (BOOL)handleOpenUniversalLink:(NSUserActivity *)userActivity {
    [[self class] registerWechatShareIDIfNeeded];
    return [WXApi handleOpenUniversalLink:userActivity delegate:[BDUGWeChatShare sharedWeChatShare]];
}

- (void)sendTextToScene:(BDUGWechatShareScene)scene withText:(NSString *)text customCallbackUserInfo:(NSDictionary *)customCallbackUserInfo {
    [[self class] registerWechatShareIDIfNeeded];
    
    self.callbackUserInfo = customCallbackUserInfo;
    
    if(![self isAvailableWithNotifyError:YES]) {
        return;
    }
    
    if (text.length == 0) {
        [self callBackWithErrorType:BDUGShareErrorTypeNoTitle errorInfo:nil];
        return;
    }
    
    while([text dataUsingEncoding:NSUTF8StringEncoding allowLossyConversion:YES].length > kBDUGWechatShareMaxTextSize) {
        NSUInteger toIndex = text.length / 2;
        if (toIndex > 0 && toIndex < text.length) {
            text = [text substringToIndex:toIndex];
        }else {
            break;
        }
    }
    
    if ([text dataUsingEncoding:NSUTF8StringEncoding allowLossyConversion:YES].length > kBDUGWechatShareMaxTextSize) {
        [self callBackWithErrorType:BDUGShareErrorTypeExceedMaxTitleSize errorInfo:nil];

        return;
    }
    
    SendMessageToWXReq * req = [[SendMessageToWXReq alloc] init];
    req.bText = YES;
    req.text = text;
    req.scene = [self WXSceneTransformer:scene];
    
    [WXApi sendReq:req completion:^(BOOL success) {
        if (!success) {
            NSError *error = [BDUGShareError errorWithDomain:BDUGWechatShareErrorDomain code:BDUGShareErrorTypeSendRequestFail userInfo:nil];
            [self callbackError:error];
        }
    }];
}

- (void)sendImageToScene:(BDUGWechatShareScene)scene withImage:(UIImage *)image customCallbackUserInfo:(NSDictionary *)customCallbackUserInfo {
    [[self class] registerWechatShareIDIfNeeded];
    
    self.callbackUserInfo = customCallbackUserInfo;
    
    if(![self isAvailableWithNotifyError:YES]) {
        return;
    }
    if (!image) {
        [self callBackWithErrorType:BDUGShareErrorTypeNoImage errorInfo:nil];
        return;
    }
    
    WXMediaMessage * message = [WXMediaMessage message];
    message.thumbData = [BDUGShareImageUtil compressImage:image withLimitLength:kBDUGWechatShareMaxPreviewImageSize];
    
    WXImageObject * ext = [WXImageObject object];
    ext.imageData = [BDUGShareImageUtil compressImage:image withLimitLength:kBDUGWechatShareMaxImageSize];

    message.mediaObject = ext;
    
    SendMessageToWXReq * req = [[SendMessageToWXReq alloc] init];
    req.bText = NO;
    req.message = message;
    req.scene = [self WXSceneTransformer:scene];;
    [WXApi sendReq:req completion:^(BOOL success) {
        if (!success) {
            NSError *error = [BDUGShareError errorWithDomain:BDUGWechatShareErrorDomain code:BDUGShareErrorTypeSendRequestFail userInfo:nil];
            [self callbackError:error];
        }
    }];
}

- (void)sendWebpageToScene:(BDUGWechatShareScene)scene withWebpageURL:(NSString *)webpageURL thumbnailImage:(UIImage *)thumbnailImage title:(NSString *)title description:(NSString *)description customCallbackUserInfo:(NSDictionary *)customCallbackUserInfo {
    [self sendWebpageToScene:scene withWebpageURL:webpageURL thumbnailImage:thumbnailImage imageURL:nil title:title description:description customCallbackUserInfo:customCallbackUserInfo];
}

- (void)sendWebpageToScene:(BDUGWechatShareScene)scene withWebpageURL:(NSString *)webpageURL thumbnailImage:(UIImage *)thumbnailImage imageURL:(NSString *)imageURLString title:(NSString *)title description:(NSString *)description customCallbackUserInfo:(NSDictionary *)customCallbackUserInfo {
    [[self class] registerWechatShareIDIfNeeded];
    
    self.callbackUserInfo = customCallbackUserInfo;
    
    if(![self isAvailableWithNotifyError:YES]) {
        return;
    }
    if (webpageURL.length == 0) {
        [self callBackWithErrorType:BDUGShareErrorTypeNoWebPageURL errorInfo:nil];
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
    
    if ([title dataUsingEncoding:NSUTF8StringEncoding allowLossyConversion:YES].length > 512 || [description dataUsingEncoding:NSUTF8StringEncoding allowLossyConversion:YES].length > 1024 || [webpageURL dataUsingEncoding:NSUTF8StringEncoding allowLossyConversion:YES].length > kBDUGWechatShareMaxTextSize) {
        NSError * error = [BDUGShareError errorWithDomain:BDUGWechatShareErrorDomain
                                              code:BDUGShareErrorTypeExceedMaxTitleSize
                                          userInfo:nil];
        [self callbackError:error];
        return;
    }
    
    void (^shareBlock)(NSData *) = ^(NSData *thumbImageData) {
        WXMediaMessage *message = [WXMediaMessage message];
        message.title = title;
        message.description = description;
        message.thumbData = thumbImageData;
        
        WXWebpageObject *webPageObject = [WXWebpageObject object];
        webPageObject.webpageUrl = webpageURL;
        message.mediaObject = webPageObject;
        
        SendMessageToWXReq* req = [[SendMessageToWXReq alloc] init];
        req.bText = NO;
        req.message = message;
        req.scene = [self WXSceneTransformer:scene];;
        
        [WXApi sendReq:req completion:^(BOOL success) {
            if (!success) {
                NSError *error = [BDUGShareError errorWithDomain:BDUGWechatShareErrorDomain code:BDUGShareErrorTypeSendRequestFail userInfo:nil];
                [self callbackError:error];
            }
        }];
    };
    
    NSURL * pImageUrl = [BDUGShareBaseUtil URLWithURLString:imageURLString];
    if (pImageUrl) {
        [BDUGShareImageUtil downloadImageDataWithURL:pImageUrl limitLength:kBDUGWechatShareMaxPreviewImageSize completion:^(NSData *imageData, NSError *error) {
            if (imageData) {
                shareBlock(imageData);
            } else {
                shareBlock([BDUGShareImageUtil compressImage:thumbnailImage withLimitLength:kBDUGWechatShareMaxPreviewImageSize]);
            }
        }];
    } else {
        shareBlock([BDUGShareImageUtil compressImage:thumbnailImage withLimitLength:kBDUGWechatShareMaxPreviewImageSize]);
    }
}

- (void)sendVideoToScene:(BDUGWechatShareScene)scene withVideoURL:(NSString *)videoURL thumbnailImage:(UIImage*)thumbnailImage title:(NSString*)title description:(NSString*)description customCallbackUserInfo:(NSDictionary *)customCallbackUserInfo {
    [[self class] registerWechatShareIDIfNeeded];
    
    self.callbackUserInfo = customCallbackUserInfo;
    
    if(![self isAvailableWithNotifyError:YES]) {
        return;
    }
    if (videoURL.length == 0) {
        [self callBackWithErrorType:BDUGShareErrorTypeNoVideo errorInfo:nil];
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
    
    if ([title dataUsingEncoding:NSUTF8StringEncoding allowLossyConversion:YES].length > 512 || [description dataUsingEncoding:NSUTF8StringEncoding allowLossyConversion:YES].length > 1024 || [videoURL dataUsingEncoding:NSUTF8StringEncoding allowLossyConversion:YES].length > kBDUGWechatShareMaxTextSize) {
        NSError * error = [BDUGShareError errorWithDomain:BDUGWechatShareErrorDomain
                                              code:BDUGShareErrorTypeExceedMaxTitleSize
                                          userInfo:nil];
        [self callbackError:error];
        return;
    }
    
    WXMediaMessage *message = [WXMediaMessage message];
    message.title = title;
    message.description = description;
    message.thumbData = [BDUGShareImageUtil compressImage:thumbnailImage withLimitLength:kBDUGWechatShareMaxPreviewImageSize];
    
    WXVideoObject *ext = [WXVideoObject object];
    ext.videoUrl = videoURL;
    message.mediaObject = ext;
    
    SendMessageToWXReq* req = [[SendMessageToWXReq alloc] init];
    req.bText = NO;
    req.message = message;
    req.scene = [self WXSceneTransformer:scene];;
    
    [WXApi sendReq:req completion:^(BOOL success) {
        if (!success) {
            NSError *error = [BDUGShareError errorWithDomain:BDUGWechatShareErrorDomain code:BDUGShareErrorTypeSendRequestFail userInfo:nil];
            [self callbackError:error];
        }
    }];
}

- (void)sendMiniProgramToScene:(BDUGWechatShareScene)scene thumbnailImage:(UIImage*)thumbnailImage title:(NSString*)title description:(NSString*)description miniProgramUserName:(NSString *)miniProgramUserName miniProgramPath:(NSString *)path webPageURLString:(NSString *)webPageURLString launchMiniProgram:(BOOL)launchMiniProgram {
    [[self class] registerWechatShareIDIfNeeded];
    
    if(![self isAvailableWithNotifyError:YES]) {
        return;
    }
    if (miniProgramUserName.length == 0) {
        [self callBackWithErrorType:BDUGShareErrorTypeInvalidContent errorInfo:@"There is no mini program user name"];
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
        NSError * error = [BDUGShareError errorWithDomain:BDUGWechatShareErrorDomain
                                                     code:BDUGShareErrorTypeExceedMaxTitleSize
                                                 userInfo:nil];
        [self callbackError:error];
        return;
    }
    if ([description dataUsingEncoding:NSUTF8StringEncoding allowLossyConversion:YES].length > 1024) {
        NSError * error = [BDUGShareError errorWithDomain:BDUGWechatShareErrorDomain
                                                     code:BDUGShareErrorTypeExceedMaxDescSize
                                                 userInfo:nil];
        [self callbackError:error];
        return;
    }
    
    BaseReq *req;
    if (launchMiniProgram) {
        WXLaunchMiniProgramReq *miniReq = [[WXLaunchMiniProgramReq alloc] init];
        miniReq.userName = miniProgramUserName;
        miniReq.path = path;
        miniReq.miniProgramType = WXMiniProgramTypeRelease;
        
        req = miniReq;
    } else {
        WXMiniProgramObject *object = [WXMiniProgramObject object];
        object.webpageUrl = webPageURLString;
        object.userName = miniProgramUserName;
        object.path = path;
        object.hdImageData = [BDUGShareImageUtil compressImage:thumbnailImage withLimitLength:1024 * 128];
        object.withShareTicket = YES;
        object.miniProgramType = WXMiniProgramTypeRelease;
        
        WXMediaMessage *message = [WXMediaMessage message];
        message.title = title;
        message.description = description;
        message.thumbData = [BDUGShareImageUtil compressImage:thumbnailImage withLimitLength:kBDUGWechatShareMaxPreviewImageSize];  //兼容旧版本节点的图片，小于32KB，新版本优先
        message.mediaObject = object;
        
        SendMessageToWXReq *msgReq = [[SendMessageToWXReq alloc] init];
        msgReq.bText = NO;
        msgReq.message = message;
        msgReq.scene = WXSceneSession;
        
        req = msgReq;
    }
    
    [WXApi sendReq:req completion:^(BOOL success) {
        if (!success) {
            NSError *error = [BDUGShareError errorWithDomain:BDUGWechatShareErrorDomain code:BDUGShareErrorTypeSendRequestFail userInfo:nil];
            [self callbackError:error];
        }
    }];
}

- (void)sendFileWithFileName:(NSString *)fileName fileURL:(NSURL *)fileURL thumbImage:(UIImage *)thumbImage
{
    [[self class] registerWechatShareIDIfNeeded];
    if(![self isAvailableWithNotifyError:YES]) {
        return;
    }
    if (!fileURL || ![[NSFileManager defaultManager] fileExistsAtPath:fileURL.path]) {
        [self callBackWithErrorType:BDUGShareErrorTypeInvalidContent errorInfo:@"File does not exist"];
        return;
    }
    NSData *fileData = [NSData dataWithContentsOfURL:fileURL];
    if (fileData.length > kBDUGWechatShareMaxFileSize) {
        //文件数据大。
        [self callBackWithErrorType:BDUGShareErrorTypeExceedMaxFileSize errorInfo:nil];
        return;
    }
    
    //文件数据
    WXFileObject *fileObj = [WXFileObject object];
    fileObj.fileData = fileData;
    
    WXMediaMessage *wxMediaMessage = [WXMediaMessage message];
    wxMediaMessage.title = fileName;
    wxMediaMessage.thumbData = [BDUGShareImageUtil compressImage:thumbImage withLimitLength:kBDUGWechatShareMaxPreviewImageSize];
    wxMediaMessage.mediaObject = fileObj;
    
    SendMessageToWXReq *req = [[SendMessageToWXReq alloc] init];
    req.message = wxMediaMessage;
    req.bText = NO;
    req.scene = WXSceneSession;
    
    [WXApi sendReq:req completion:^(BOOL success) {
        if (!success) {
            NSError *error = [BDUGShareError errorWithDomain:BDUGWechatShareErrorDomain code:BDUGShareErrorTypeSendRequestFail userInfo:nil];
            [self callbackError:error];
        }
    }];
}

#pragma mark - transform scene

- (enum WXScene)WXSceneTransformer:(BDUGWechatShareScene)scene
{
    enum WXScene wxScene;
    switch (scene) {
        case BDUGWechatShareSceneSession:
            wxScene = WXSceneSession;
            break;
        case BDUGWechatShareSceneFavorite:
            wxScene = WXSceneFavorite;
            break;
        case BDUGWechatShareSceneTimeline:
            wxScene = WXSceneTimeline;
            break;
        case BDUGWechatShareSceneSpecifiedSession:
            wxScene = WXSceneSpecifiedSession;
            break;
        default:
            wxScene = WXSceneSession;
            break;
    }
    return wxScene;
}

#pragma mark - delegate

-(void)onResp:(BaseResp*)resp {
    if([resp isKindOfClass:[SendMessageToWXResp class]] ||
       [resp isKindOfClass:[WXLaunchMiniProgramResp class]]) {
        if(resp.errCode != 0) {
            if(resp.errCode == WXErrCodeUserCancel) {
                NSError * error = [BDUGShareError errorWithDomain:BDUGWechatShareErrorDomain
                                                      code:BDUGShareErrorTypeUserCancel
                                                  userInfo:nil];
                [self callbackError:error];
            } else {
                NSMutableDictionary * userInfo = [NSMutableDictionary dictionary];
                if (resp.errStr.length > 0) {
                    [userInfo setValue:resp.errStr forKey:NSLocalizedDescriptionKey];
                }
                NSError * error = [BDUGShareError errorWithDomain:BDUGWechatShareErrorDomain
                                                      code:BDUGShareErrorTypeOther
                                                  userInfo:userInfo.copy];
                [self callbackError:error];
            }
        }else {
            if(_delegate && [_delegate respondsToSelector:@selector(weChatShare:sharedWithError:customCallbackUserInfo:)]) {
                [_delegate weChatShare:self sharedWithError:nil customCallbackUserInfo:_callbackUserInfo];
            }
        }
    } else if ([resp isKindOfClass:NSClassFromString(@"PayResp")]) {
        if (_payDelegate && [_payDelegate respondsToSelector:@selector(weChatShare:payResponse:)]) {
            [_payDelegate weChatShare:self payResponse:(PayResp *)resp];
        }
    }
}

-(void)onReq:(BaseReq*)req {
    if (_requestDelegate && [_requestDelegate respondsToSelector:@selector(weChatShare:receiveRequest:)]) {
        [_requestDelegate weChatShare:self receiveRequest:req];
    }
}

#pragma mark - Error

- (BOOL)isAvailableWithNotifyError:(BOOL)notifyError {
    [[self class] registerWechatShareIDIfNeeded];
    
    if(![WXApi isWXAppInstalled]) {
        if (notifyError) {
            NSError * error = [BDUGShareError errorWithDomain:BDUGWechatShareErrorDomain
                                                  code:BDUGShareErrorTypeAppNotInstalled
                                              userInfo:nil];
            [self callbackError:error];
        }
        return NO;
    }
    else if(![WXApi isWXAppSupportApi]){
        if (notifyError) {
            NSError * error = [BDUGShareError errorWithDomain:BDUGWechatShareErrorDomain
                                                  code:BDUGShareErrorTypeAppNotSupportAPI
                                              userInfo:nil];
            [self callbackError:error];
        }
        return NO;
    }
    return YES;
}

- (void)callBackWithErrorType:(BDUGShareErrorType)errorType errorInfo:(NSString *)errorInfo
{
    NSDictionary *dic;
    if (errorInfo) {
        dic = @{NSLocalizedDescriptionKey: errorInfo};
    }
    NSError *error = [BDUGShareError errorWithDomain:BDUGWechatShareErrorDomain code:errorType userInfo:dic];
    [self callbackError:error];
}

- (void)callbackError:(NSError *)error {
    if (_delegate && [_delegate respondsToSelector:@selector(weChatShare:sharedWithError:customCallbackUserInfo:)]) {
        [_delegate weChatShare:self sharedWithError:error customCallbackUserInfo:_callbackUserInfo];
    }
}

#pragma mark - Util

@end
