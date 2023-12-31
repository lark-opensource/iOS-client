//
//  BDUGRocketShare.m
//  Article
//
//  Created by 蔡伟龙 on 2018/11/14.
//

#import "BDUGRocketShare.h"
#import "BDUGShareError.h"
#import <RocketShareSDK/RSApiInternalObject.h>
#import <RocketShareSDK/RSApi.h>

NSString * const BDUGRocketShareErrorDomain = @"BDUGRocketShareErrorDomain";

#define kBDUGRocketShareMaxTextSize    (1024 * 10)

@interface BDUGRocketShare() <RSApiDelegate>

@end

@implementation BDUGRocketShare

static BDUGRocketShare *shareInstance;
static NSString *rocketShareAppID = nil;

+ (instancetype)sharedRocketShare {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        shareInstance = [[BDUGRocketShare alloc] init];
    });
    return shareInstance;
}

+ (void)registerWithID:(NSString*)appID {
    rocketShareAppID = appID;
}

+ (void)registerRocketShareIDIfNeeded {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        [RSApi registerApp:rocketShareAppID];
    });
}

+ (BOOL)canHandleOpenURL:(NSURL *)url {
    [[self class] registerRocketShareIDIfNeeded];
    return [RSApi canOpenURL:url];
}
 
+ (BOOL)handleOpenURL:(NSURL *)url {
    [[self class] registerRocketShareIDIfNeeded];
    return [RSApi handleOpenURL:url delegate:[BDUGRocketShare sharedRocketShare]];
}

- (BOOL)isAvailable
{
    return [self rocketInstalled] && [self rocketSupportAPI];
}

- (BOOL)rocketInstalled
{
    return [RSApi isRocketAppInstalled];
}

- (BOOL)rocketSupportAPI
{
    return [RSApi isRocketAppSupportApi];
}

- (NSString *)currentVersion {
    [[self class] registerRocketShareIDIfNeeded];
    return [RSApi getApiVersion];
}

#pragma mark - share

- (void)sendTextToScene:(BDUGRocketShareScene)scene withText:(NSString *)text {
    if(![self isAvailableWithNotifyError:YES]) {
        return;
    }
    
    if (text.length == 0) {
        NSError * error = [BDUGShareError errorWithDomain:BDUGRocketShareErrorDomain
                                              code:BDUGShareErrorTypeNoTitle
                                          userInfo:nil];
        [self callbackError:error];
        return;
    }
    
    while([text dataUsingEncoding:NSUTF8StringEncoding allowLossyConversion:YES].length > kBDUGRocketShareMaxTextSize) {
        NSUInteger toIndex = text.length / 2;
        if (toIndex > 0 && toIndex < text.length) {
            text = [text substringToIndex:toIndex];
        }else {
            break;
        }
    }
    
    if ([text dataUsingEncoding:NSUTF8StringEncoding allowLossyConversion:YES].length > kBDUGRocketShareMaxTextSize) {
        NSError * error = [BDUGShareError errorWithDomain:BDUGRocketShareErrorDomain
                                              code:BDUGShareErrorTypeExceedMaxTitleSize
                                          userInfo:nil];
        [self callbackError:error];
        return;
    }

    RSSendMessageToRocketReq * req = [[RSSendMessageToRocketReq alloc] init];
    req.bText = YES;
    req.text = text;
    req.scene = [self RSSceneTransformer:scene];
    
    [self shareWithRequest:req];
}

- (void)sendImageToScene:(BDUGRocketShareScene)scene withImage:(UIImage*)image {
    if(![self isAvailableWithNotifyError:YES]) {
        return;
    }
    if (!image) {
        NSError * error = [BDUGShareError errorWithDomain:BDUGRocketShareErrorDomain
                                              code:BDUGShareErrorTypeNoImage
                                          userInfo:nil];
        [self callbackError:error];
        return;
    }
    RSMediaMessage * message = [[RSMediaMessage alloc] init];
    
    RSImageObject * ext = [RSImageObject new];
    ext.imageData = UIImageJPEGRepresentation(image, 1.0);
    if (ext.imageData.length > 1024 * 1024 * 10) {
        NSError * error = [BDUGShareError errorWithDomain:BDUGRocketShareErrorDomain
                                              code:BDUGShareErrorTypeExceedMaxImageSize
                                          userInfo:nil];
        [self callbackError:error];
        return;
    }
    message.mediaObject = ext;
    
    RSSendMessageToRocketReq * req = [[RSSendMessageToRocketReq alloc] init];
    req.bText = NO;
    req.message = message;
    req.scene = [self RSSceneTransformer:scene];
    [self shareWithRequest:req];
}

- (void)sendWebpageToScene:(BDUGRocketShareScene)scene withWebpageURL:(NSString *)webpageURL thumbnailImage:(UIImage *)thumbnailImage title:(NSString*)title description:(NSString*)description style:(NSString *)style {
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
        NSError * error = [BDUGShareError errorWithDomain:BDUGRocketShareErrorDomain
                                              code:BDUGShareErrorTypeExceedMaxTitleSize
                                          userInfo:nil];
        [self callbackError:error];
        return;
    }
    if ([description dataUsingEncoding:NSUTF8StringEncoding allowLossyConversion:YES].length > 1024) {
        NSError * error = [BDUGShareError errorWithDomain:BDUGRocketShareErrorDomain
                                                     code:BDUGShareErrorTypeExceedMaxDescSize
                                                 userInfo:nil];
        [self callbackError:error];
        return;
    }
    if ([webpageURL dataUsingEncoding:NSUTF8StringEncoding allowLossyConversion:YES].length > kBDUGRocketShareMaxTextSize) {
        NSError * error = [BDUGShareError errorWithDomain:BDUGRocketShareErrorDomain
                                                     code:BDUGShareErrorTypeExceedMaxWebPageURLSize
                                                 userInfo:nil];
        [self callbackError:error];
        return;
    }
    RSMediaMessage *message = [RSMediaMessage new];
    message.title = title;
    message.desc = description;
    message.thumbData = UIImageJPEGRepresentation(thumbnailImage, 1.0);
    
    RSWebpageObject *webPageObject = [RSWebpageObject new];
    webPageObject.webpageUrl = webpageURL;
    webPageObject.style = style;
    message.mediaObject = webPageObject;
    
    RSSendMessageToRocketReq* req = [[RSSendMessageToRocketReq alloc] init];
    req.bText = NO;
    req.message = message;
    req.scene = [self RSSceneTransformer:scene];
    
    [self shareWithRequest:req];
}

- (void)sendWebpageToScene:(BDUGRocketShareScene)scene
            withWebpageURL:(NSString *)webpageURL
            thumbnailImage:(UIImage *)thumbnailImage
                     title:(NSString*)title
               description:(NSString*)description {
    [self sendWebpageToScene:scene withWebpageURL:webpageURL thumbnailImage:thumbnailImage title:title description:description style:nil];
}

- (void)sendVideoToScene:(BDUGRocketShareScene)scene
           videoURLString:(NSString *)videoURLString
{
    if (videoURLString.length == 0) {
        NSError * error = [BDUGShareError errorWithDomain:BDUGRocketShareErrorDomain
                                              code:BDUGShareErrorTypeNoWebPageURL
                                          userInfo:nil];
        [self callbackError:error];
        return;
    }
    RSMediaMessage *message = [[RSMediaMessage alloc] init];
    
    RSBDVideoObject *video = [[RSBDVideoObject alloc] init];
    
    RSBDVideoItem *videoItem = [[RSBDVideoItem alloc] init];
    videoItem.url = videoURLString;
    video.videoItems = @[videoItem];
    
    message.mediaObject = video;
    
    RSSendMessageToRocketReq *req = [[RSSendMessageToRocketReq alloc] init];
    req.bText = NO;
    req.message = message;
    req.scene = [self RSSceneTransformer:scene];
    
    [self shareWithRequest:req];
}

- (void)shareWithRequest:(RSBaseReq *)request
{
    [self.class registerRocketShareIDIfNeeded];
    if ([RSApi sendReq:request]) {
        
    } else {
        NSError * error = [BDUGShareError errorWithDomain:BDUGRocketShareErrorDomain
                                              code:BDUGShareErrorTypeSendRequestFail
                                          userInfo:nil];
        [self callbackError:error];
    }
}

#pragma mark - transform

- (enum RSScene)RSSceneTransformer:(BDUGRocketShareScene)scene
{
    enum RSScene rsScene;
    switch (scene) {
        case BDUGRocketShareSceneSession:
            rsScene = RSSceneSession;
            break;
        case BDUGRocketShareSceneTimeline:
            rsScene = RSSceneTimeline;
            break;
        default:
            rsScene = RSSceneSession;
            break;
    }
    return rsScene;
}

#pragma mark - response

-(void)onResp:(RSBaseResp*)resp {
    if ([resp isKindOfClass:[RSSendMessageToRocketResp class]]) {
        if (resp.errCode != 0) {
            if (resp.errCode == RSErrCodeUserCancel) {
                NSError * error = [BDUGShareError errorWithDomain:BDUGRocketShareErrorDomain
                                                      code:BDUGShareErrorTypeUserCancel
                                                  userInfo:nil];
                [self callbackError:error];
            } else {
                NSMutableDictionary * userInfo = [NSMutableDictionary dictionary];
                if (resp.errStr.length > 0) {
                    [userInfo setValue:resp.errStr forKey:NSLocalizedDescriptionKey];
                }
                NSError * error = [BDUGShareError errorWithDomain:BDUGRocketShareErrorDomain
                                                      code:BDUGShareErrorTypeOther
                                                  userInfo:userInfo.copy];
                [self callbackError:error];
            }
        }else {
            if(_delegate && [_delegate respondsToSelector:@selector(rocketShare:sharedWithError:)]) {
                [_delegate rocketShare:self sharedWithError:nil];
            }
        }
    }
}
#pragma mark - Error

- (BOOL)isAvailableWithNotifyError:(BOOL)notifyError {
    [[self class] registerRocketShareIDIfNeeded];
    if(![RSApi isRocketAppInstalled]) {
        if (notifyError) {
            NSError * error = [BDUGShareError errorWithDomain:BDUGRocketShareErrorDomain
                                                  code:BDUGShareErrorTypeAppNotInstalled
                                              userInfo:nil];
            [self callbackError:error];
        }
        return NO;
    }
    else if(![RSApi isRocketAppInstalled]){
        if (notifyError) {
            NSError * error = [BDUGShareError errorWithDomain:BDUGRocketShareErrorDomain
                                                  code:BDUGShareErrorTypeAppNotSupportAPI
                                              userInfo:nil];
            [self callbackError:error];
        }
        return NO;
    }
    return YES;
}

- (void)callbackError:(NSError *)error {
    if (_delegate && [_delegate respondsToSelector:@selector(rocketShare:sharedWithError:)]) {
        [_delegate rocketShare:self sharedWithError:error];
    }
}

@end
