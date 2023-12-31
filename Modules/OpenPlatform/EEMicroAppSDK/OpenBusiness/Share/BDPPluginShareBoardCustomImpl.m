//
//  BDPPluginShareBoardCustomImpl.m
//  TTMicroApp-Example
//
//  Created by CsoWhy on 2018/8/21.
//

#import "BDPPluginShareBoardCustomImpl.h"
#import <OPFoundation/BDPShareContext+EMA.h>
#import "EERoute.h"
#import "EMAAppEngine.h"
#import "EMAAppLinkModel.h"
#import <OPFoundation/EMADebugUtil.h>
#import "EMAI18n.h"
#import <OPFoundation/EMAMonitorHelper.h>
#import <ECOInfra/EMANetworkManager.h>
#import <OPFoundation/EMARequestUtil.h>
#import <EEMicroAppSDK/EEMicroAppSDK-Swift.h>
#import <ECOInfra/BDPFileSystemHelper.h>
#import <ECOInfra/BDPLogHelper.h>
#import <OPFoundation/BDPModuleManager.h>
#import <OPFoundation/BDPMonitorHelper.h>
#import <TTMicroApp/BDPShareManager.h>
#import <OPFoundation/BDPStorageModuleProtocol.h>
#import <TTMicroApp/BDPTask.h>
#import <TTMicroApp/BDPTimorClient+Business.h>
#import <OPFoundation/BDPTracker.h>
#import <OPFoundation/BDPUtils.h>
#import <ECOInfra/NSDictionary+BDPExtension.h>
#import <ECOInfra/NSString+BDPExtension.h>
#import <OPFoundation/TMASessionManager.h>
#import <TTMicroApp/TTMicroApp-Swift.h>
#import <LarkStorage/LarkStorage-swift.h>
#import <OPSDK/OPSDK-Swift.h>
#import <OPFoundation/OPFoundation-Swift.h>
#import <OPFoundation/EEFeatureGating.h>

NSString * const kMicroApp_AppLink_Mode_Sidebar_Semi = @"sidebar-semi";

@interface BDPPluginShareBoardCustomImpl () <BDPSharePluginDelegate>

@end

@implementation BDPPluginShareBoardCustomImpl


+ (id<BDPSharePluginDelegate>)sharedPlugin
{
    static id instance;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [[self alloc] init];
    });
    return instance;
}

#pragma mark - BDPSharePluginDelegate

- (void)bdp_showShareBoardWithContext:(BDPShareContext *)context
                          didComplete:(BDPShareCompletion)complete
{
    BDPLogTagInfo(BDPTag.gadgetShare, @"bdp_showShareBoard app=%@, imageUrl=%@", context.appCommon.uniqueID, [BDPLogHelper safeURLString: context.imageUrl]);
    /// 应用分享埋点
    [BDPTracker event:@"app_share" attributes:@{@"app_capability_type":@"MiniProgram"} uniqueID:nil];

    NSString *title = context.title;
    BDPUniqueID *uniqueID = context.appCommon.uniqueID;
    id<BDPSandboxProtocol> sandbox = context.appCommon.sandbox;
    NSString *path = context.query;
    NSString *PCPath = context.PCPath;
    NSString *PCMode = context.PCMode;
    NSString *imageUrl = context.imageUrl;
    NSString *content = nil;
    UIView *superview = context.controller.view;
    if ([path isKindOfClass:[NSString class]]) {
        path = [path stringByRemovingPercentEncoding];
    }
    if ([PCPath isKindOfClass:[NSString class]]) {
        PCPath = [PCPath stringByRemovingPercentEncoding];
    }

    /// 在配置中心进行了分享裸链的apps配制，但是还是不希望分享裸链，这样过于愚蠢，还是倾向于同一分享卡片
    BOOL shouldShareOnlyLinkSpecially = [EMAAppEngine.currentEngine.onlineConfig shouldShareOnlyLinkSpeciallyWithUniqueID:uniqueID];
    if (shouldShareOnlyLinkSpecially) {
        id<EMAProtocol> delegate = [EMARouteProvider getEMADelegate];
        if (![delegate respondsToSelector:@selector(shareWebUrl:title:content:)]){
            [self shareFailToastWithComplete:complete onView:superview];
            BDPLogError(@"should share only link but route has no impl, app=%@", context.appCommon.uniqueID);
            return;
        }
        BDPMonitorWithCode(EPMClientOpenPlatformShareCode.share_entry_start, context.appCommon.uniqueID)
            .kv(@"op_tracking", @"opshare_ttq_api")
            .flush();
        [delegate shareWebUrl:path title:title content:content];
        !complete?:complete(BDPSharePluginResultSuccess,nil,nil,nil);
        return;
    } else {
        BDPMonitorWithCode(EPMClientOpenPlatformShareCode.share_entry_start, context.appCommon.uniqueID)
            .kv(@"op_tracking", @"opshare_gadget_pageshare")
            .flush();
    }

    /// 没有title则设置为小程序名字
    if (title.length == 0) {
        title = context.appCommon.model.name;
        BDPLogTagInfo(BDPTag.gadgetShare, @"share title is nil, use mini program name");
    }
    /// path不存在就设置为空字符串，下面会自己处理用默认页面
    if (!path) path = @"";

    EMAAppLinkModel *finalURL = [[EMAAppLinkModel alloc] initWithType:EMAAppLinkTypeOpen];
    EMAShareOptions options = EMAShareOptionsNone;
    finalURL.addQuery(kAppLink_appId, uniqueID.appID);
    finalURL.addQuery(kAppLink_op_tracking, @"opshare_gadget_pageshare");
    if (!BDPIsEmptyString(path)) {
        finalURL.addQuery(kAppLink_path, path);
        options |= EMAShareOptionsIOS;
        options |= EMAShareOptionsAndroid;
    }
    if (!BDPIsEmptyString(PCPath) && !BDPIsEmptyString(PCMode)) {
        finalURL.addQuery(kAppLink_path_pc, PCPath).addQuery(kAppLink_mode, PCMode);
        options |= EMAShareOptionsPC;
    }

    /// 兜底链接
    NSString *cardLinkURL = finalURL.generateURL.absoluteString;
    /// 平台链接
    NSString *appLinkHref = finalURL.generateURL.absoluteString;
    
    NSData *pathData = [cardLinkURL dataUsingEncoding:NSUTF8StringEncoding];
    NSString *base64Path = [pathData base64EncodedStringWithOptions:kNilOptions];
    BDPLogTagInfo(BDPTag.gadgetShare, @"share path: %@", base64Path)

    /// 兜底 case，开发者没有填PC参数，兜底链接需要补充
    if (BDPIsEmptyString(PCPath) || BDPIsEmptyString(PCMode)) {
        /// 手动添加PCMode为sidebar-semi
        finalURL.addQuery(kAppLink_mode, kMicroApp_AppLink_Mode_Sidebar_Semi);
        cardLinkURL = finalURL.generateURL.absoluteString;
    }

    if (imageUrl.length != 0) {
        BDPLogTagInfo(BDPTag.gadgetShare, @"imageUrl is not empty,url:%@", imageUrl);
        /// 如果开发者设置了URL则用开发者的URL处理
        if ([imageUrl hasPrefix:@"ttfile"]) {
            /// 取出图片
            BOOL fgDisable = [EEFeatureGating boolValueForKey:@"openplatform.api.shareboard.file.disable"];
            NSString *absPath = nil;
            if(fgDisable) {
                absPath = [[BDPGetResolvedModule(BDPStorageModuleProtocol, context.appCommon.uniqueID.appType) sharedLocalFileManager] fileInfoWithRelativePath:imageUrl uniqueID:context.appCommon.model.uniqueID pkgName:context.appCommon.model.pkgName useFileScheme:YES].path;
            }else {
                OPFileObject *fileObj = [[OPFileObject alloc] initWithRawValue:imageUrl];
                OPFileSystemContext *fsContext = [[OPFileSystemContext alloc] initWithUniqueId:context.appCommon.uniqueID
                                                                                         trace:nil
                                                                                           tag:@"share"
                                                                                   isAuxiliary:YES];
                if (!fileObj) {
                    fsContext.trace.error(@"resolve fileobj failed");
                }
                NSError *fsError = nil;
                NSString *fileSystemPath = [OPFileSystemCompatible getSystemFileFrom:fileObj context:fsContext error:&fsError];
                if (fsError) {
                    fsContext.trace.error(@"getSystemFilePath failed, error: %@", fsError.description);
                } else {
                    absPath = [NSURL fileURLWithPath:fileSystemPath].absoluteString;
                }
            }
            if (!absPath) {
                /// 绝对路径为空
                BDPLogTagError(BDPTag.gadgetShare, @"share ttfile error because absPath is empty! app=%@, imageUrl=%@", context.appCommon.uniqueID, [BDPLogHelper safeURLString: imageUrl]);
                return [self shareFailToastWithComplete:complete onView:superview];
            }
            NSError *error;
            NSData *fileData = [NSData lss_dataWithContentsOfURL:[NSURL URLWithString:absPath] error: &error];
            if (!fileData) {
                /// 未取到数据
                BDPLogTagError(BDPTag.gadgetShare, @"share ttfile error because file data is nil! app=%@, imageUrl=%@, absPath=%@, error:%@", context.appCommon.uniqueID, [BDPLogHelper safeURLString: imageUrl], absPath, error);
                return [self shareFailToastWithComplete:complete onView:superview];
            }
            /// 消息卡片形式分享小程序
            [self shareCardWithTitle:title
                            uniqueID:uniqueID
                             sandbox:sandbox
                           imageData:fileData
                                 url:cardLinkURL
                         appLinkHref:appLinkHref
                             options:options
                            complete:complete
                              onView:superview];
        } else if ([imageUrl hasPrefix:@"file://"]) {
            NSError *error;
            NSData *fileData = [NSData lss_dataWithContentsOfURL:[NSURL URLWithString:imageUrl] error:&error];
            if (!fileData) {
                /// 未取到数据
                BDPLogTagError(BDPTag.gadgetShare, @"share ttfile error because file data is nil! app=%@, imageUrl=%@, error=%@", context.appCommon.uniqueID, [BDPLogHelper safeURLString: imageUrl], error);
                return [self shareFailToastWithComplete:complete onView:superview];
            }
            /// 消息卡片形式分享小程序
            [self shareCardWithTitle:title
                            uniqueID:uniqueID
                             sandbox:sandbox
                           imageData:fileData
                                 url:cardLinkURL
                         appLinkHref:appLinkHref
                             options:options
                            complete:complete
                              onView:superview];
        } else {
            [EMAHUD showLoading:EMAI18n.please_wait on:superview window:uniqueID.window delay:0 disableUserInteraction:NO];
            /// 下载图片
            if (![context.appCommon.auth checkAuthorizationURL:imageUrl authType:BDPAuthorizationURLDomainTypeDownload]) {
                BDPLogTagWarn(BDPTag.gadgetShare, @"share imageUrl auth denied! app=%@, imageURL=%@", context.appCommon.uniqueID, [BDPLogHelper safeURLString: imageUrl]);
                [self shareFailToastWithComplete:complete onView:superview];
                return;
            }
            NSURL *url = [NSURL URLWithString:imageUrl];
            NSURLSession *session = EMANetworkManager.shared.urlSession;
            NSURLSessionDataTask *task = [session dataTaskWithURL:url completionHandler:^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    if (error) {
                        BDPLogTagError(BDPTag.gadgetShare, @"share imageUrl download error! app=%@, url=%@, error=%@", context.appCommon.uniqueID, [BDPLogHelper safeURL: url], error);
                        [self shareFailToastWithComplete:complete onView:superview];
                        return;
                    }
                    BDPLogTagInfo(BDPTag.gadgetShare, @"share imageUrl download completed. app=%@, url=%@, dataLength=%@", context.appCommon.uniqueID, [BDPLogHelper safeURL: url], @(data.length));
                    [EMAHUD removeHUDOn:superview window:uniqueID.window];
                    [self shareCardWithTitle:title
                                    uniqueID:uniqueID
                                     sandbox:sandbox
                                   imageData:data
                                         url:cardLinkURL
                                 appLinkHref:appLinkHref
                                     options:options
                                    complete:complete
                                      onView:superview];
                });
            }];
            BDPLogTagInfo(BDPTag.gadgetShare, @"share imageUrl download start, app=%@", context.appCommon.uniqueID);
            [task resume];
        }
    } else {
        /// 开发者没有设置URL则默认使用当前页面的截图
        BDPLogTagInfo(BDPTag.gadgetShare, @"share screenshort, app=%@", context.appCommon.uniqueID);
        /// 进行截图（注意 iPad 多 Scene 适配，不能随意选择一个默认window截图，不然可能泄漏用户隐私）
        UIView *view = context.controller.view ?: uniqueID.window;
        if (!view) {
            BDPLogTagError(BDPTag.gadgetShare, @"view to screenshort is nil, app=%@", context.appCommon.uniqueID);
            [self shareFailToastWithComplete:complete onView:superview];
            return;
        }

        UIGraphicsBeginImageContextWithOptions(view.frame.size, NO, [UIScreen mainScreen].scale);
        [view drawViewHierarchyInRect:view.bounds afterScreenUpdates:YES];
        UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
        UIGraphicsEndImageContext();

        if (!image) {
            BDPLogTagError(BDPTag.gadgetShare, @"screenshort image nil, app=%@", context.appCommon.uniqueID);
            [self shareFailToastWithComplete:complete onView:superview];
            return;
        }

        /// 处理图片尺寸 符合要求
        CGFloat width = image.size.width * image.scale;
        CGFloat height = width / 211 * 132; // 截图宽高比 211*132
        if (height > image.size.height * image.scale) {
            height = image.size.height * image.scale;
        }

        CGImageRef imageRef = CGImageCreateWithImageInRect(image.CGImage, CGRectMake(0, 0, width, height));
        if (imageRef == NULL) {
            BDPLogTagError(BDPTag.gadgetShare, @"screenshort imageRef nil, app=%@", context.appCommon.uniqueID);
            [self shareFailToastWithComplete:complete onView:superview];
            return;
        }

        image = [UIImage imageWithCGImage:imageRef scale:image.scale orientation:image.imageOrientation];
        CGImageRelease(imageRef);

        NSData *imageData = UIImagePNGRepresentation(image);
        if (!imageData) {
            BDPLogTagError(BDPTag.gadgetShare, @"screenshort imageData nil, app=%@", context.appCommon.uniqueID);
            [self shareFailToastWithComplete:complete onView:superview];
            return;
        }
        [self shareCardWithTitle:title
                        uniqueID:uniqueID
                         sandbox:sandbox
                       imageData:imageData
                             url:cardLinkURL
                     appLinkHref:appLinkHref
                         options:options
                        complete:complete
                          onView:superview];
    }
}

#pragma mark - helpers

/// 消息卡片形式分享小程序
- (void)shareCardWithTitle:(nullable NSString *)title
                  uniqueID:(nullable BDPUniqueID *)uniqueID
                   sandbox:(id<BDPSandboxProtocol> )sandbox
                 imageData:(nullable NSData *)imageData
                       url:(nullable NSString *)url
               appLinkHref:(nullable NSString *)appLinkHref
                   options:(EMAShareOptions)options
                  complete:(BDPShareCompletion)complete
                    onView:(UIView *)superview {
    BDPLogInfo(@"shareCard appID=%@, imageData.length=%@, url=%@", uniqueID, @(imageData.length), [BDPLogHelper safeURLString: url]);
    /// 消息卡片形式分享小程序
    id<EMAProtocol> delegate = [EMARouteProvider getEMADelegate];
    if (![delegate respondsToSelector:@selector(shareCardWithTitle:uniqueID:imageData:url:appLinkHref:options:callback:)]) {
        BDPLogTagError(BDPTag.gadgetShare, @"client not impl the shareCard interface");
        [self shareFailToastWithComplete:complete onView:superview];
        return;
    }
    [delegate shareCardWithTitle:title
                                              uniqueID:uniqueID
                                             imageData:imageData
                                                   url:url
                                           appLinkHref:appLinkHref
                                               options:options
                                              callback:^(NSDictionary<NSString *,id> *dict, BOOL isCancel) {
        if (isCancel) {
            !complete?:complete(BDPSharePluginResultCancel, nil, nil, nil);
            return;
        }
        if (BDPIsEmptyDictionary(dict)) {
            !complete?:complete(BDPSharePluginResultFailed, nil, nil, nil);
            return;
        }
        [BDPPluginShareBoardCustomImpl getShareCardInfoWithItemsDict:dict uniqueID:uniqueID sandbox:sandbox callback:^(NSArray *infoList, NSError *error) {
            NSArray *retArr = BDPIsEmptyArray(infoList) ? nil : infoList;
            !complete?:complete(BDPSharePluginResultSuccess, nil, nil, retArr ? @{@"data": retArr} : nil);
        }];
    }];
}

/// 分享失败提示
- (void)shareFailToastWithComplete:(BDPShareCompletion)complete onView:(UIView *)superview {
    BDPLogTagWarn(BDPTag.gadgetShare, @"shareFail");
    [EMAHUD removeHUDOn:superview window:superview.window];
    [EMAHUD showFailure:EMAI18n.share_fail on:superview window:superview.window delay:1.5 disableUserInteraction:NO];
    !complete?:complete(BDPSharePluginResultFailed,nil,nil,nil);
}

+ (void)getShareCardInfoWithItemsDict:(NSDictionary<NSString *,id> *)itemsDict
                 uniqueID:(BDPUniqueID *)uniqueID
                              sandbox:(id<BDPSandboxProtocol> )sandbox
                             callback:(void (^)(NSArray *, NSError *))callback
{
    NSArray *items = [itemsDict bdp_arrayValueForKey:@"items"];
    if (!BDPIsEmptyArray(items)) {
        BOOL enableApiUniteOpt = [EEFeatureGating boolValueForKey:@"openplatform.open.interface.api.unite.opt"];
        if (enableApiUniteOpt) {
            OpenChatIDsByChatIDsModel *model = [[OpenChatIDsByChatIDsModel alloc] initWithAppType:uniqueID.appType appID:uniqueID.appID chats:nil session:[[TMASessionManager sharedManager] getSession:sandbox] ?: @"" chatsArray:items];
            [FetchIDUtils fetchOpenChatIDsByChatIDsWithUniqueID:uniqueID model:model header:@{} completionHandler:^(NSDictionary<NSString *,id> *openChatIdDict, NSError *error) {
                if (BDPIsEmptyDictionary(openChatIdDict)) {
                    !callback ?: callback(nil, error);
                    BDPLogTagWarn(BDPTag.gadgetShare, @"empty callback params:%@", error.localizedDescription)
                    return;
                }
                NSMutableArray *d = @[].mutableCopy;
                for (NSDictionary *item in items) {
                    NSInteger chatId = [item bdp_integerValueForKey:@"chatid"];
                    if (chatId > 0) {
                        NSDictionary *openChatItem = [openChatIdDict bdp_objectForKey:@(chatId).stringValue];
                        NSMutableDictionary *newItem = @{}.mutableCopy;
                        [newItem setValue:[openChatItem valueForKey:@"open_chat_id"] forKey:@"id"];
                        [newItem setValue:[openChatItem valueForKey:@"chat_name"] forKey:@"name"];
                        NSDictionary *i18nNames = [openChatItem valueForKey:@"chat_i18n_names"];
                        if (!BDPIsEmptyDictionary(i18nNames)) {
                            [newItem setValue:i18nNames forKey:@"i18nNames"];
                        }
                        [newItem setValue:[openChatItem valueForKey:@"chat_avatar_urls"] forKey:@"avatarUrls"];
                        NSInteger type = [item bdp_integerValueForKey:@"type"];
                        if (type == 0) {
                            [newItem setValue:@(type) forKey:@"chatType"];
                            [newItem setValue:@(type) forKey:@"userType"];
                        } else if (type == 1) {
                            [newItem setValue:@(type) forKey:@"chatType"];
                        } else if (type == 2) {
                            [newItem setValue:@(0) forKey:@"chatType"];
                            [newItem setValue:@(1) forKey:@"userType"];
                        }
                        if (!BDPIsEmptyDictionary(newItem)) {
                            [d addObject:newItem];
                        }
                    }
                }
                if (!BDPIsEmptyArray(d)) {
                    !callback ?: callback(d, nil);
                } else {
                    !callback ?: callback(nil, nil);
                    BDPLogTagWarn(BDPTag.gadgetShare, @"empty callback params");
                }
            }];
        } else {
            [EMARequestUtil fetchOpenChatIDsByChatIDs:items
                                              sandbox:sandbox
                                              orContext:nil
                                    completionHandler:^(NSDictionary<NSString *,NSString *> *openChatIdDict, NSError *error) {
                if (BDPIsEmptyDictionary(openChatIdDict)) {
                    !callback ?: callback(nil, error);
                    BDPLogTagWarn(BDPTag.gadgetShare, @"empty callback params:%@", error.localizedDescription)
                    return;
                }
                NSMutableArray *d = @[].mutableCopy;
                for (NSDictionary *item in items) {
                    NSInteger chatId = [item bdp_integerValueForKey:@"chatid"];
                    if (chatId > 0) {
                        NSDictionary *openChatItem = [openChatIdDict bdp_objectForKey:@(chatId).stringValue];
                        NSMutableDictionary *newItem = @{}.mutableCopy;
                        [newItem setValue:[openChatItem valueForKey:@"open_chat_id"] forKey:@"id"];
                        [newItem setValue:[openChatItem valueForKey:@"chat_name"] forKey:@"name"];
                        NSDictionary *i18nNames = [openChatItem valueForKey:@"chat_i18n_names"];
                        if (!BDPIsEmptyDictionary(i18nNames)) {
                            [newItem setValue:i18nNames forKey:@"i18nNames"];
                        }
                        [newItem setValue:[openChatItem valueForKey:@"chat_avatar_urls"] forKey:@"avatarUrls"];
                        NSInteger type = [item bdp_integerValueForKey:@"type"];
                        if (type == 0) {
                            [newItem setValue:@(type) forKey:@"chatType"];
                            [newItem setValue:@(type) forKey:@"userType"];
                        } else if (type == 1) {
                            [newItem setValue:@(type) forKey:@"chatType"];
                        } else if (type == 2) {
                            [newItem setValue:@(0) forKey:@"chatType"];
                            [newItem setValue:@(1) forKey:@"userType"];
                        }
                        if (!BDPIsEmptyDictionary(newItem)) {
                            [d addObject:newItem];
                        }
                    }
                }
                if (!BDPIsEmptyArray(d)) {
                    !callback ?: callback(d, nil);
                } else {
                    !callback ?: callback(nil, nil);
                    BDPLogTagWarn(BDPTag.gadgetShare, @"empty callback params");
                }
            }];
        }
    } else {
        !callback ?: callback(nil, nil);
    }
}

@end


