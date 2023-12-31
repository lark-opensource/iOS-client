//
//  EMAPluginImagePreviewHandler.m
//  EEMicroAppSDK
//
//  Created by lilun.ios on 2021/4/29.
//

#import "EMAPluginImagePreviewHandler.h"
#import <OPFoundation/EMAProtocol.h>
#import <OPFoundation/EMAPhotoScrollViewController.h>
#import <OPFoundation/TMAWebkitResourceManager.h>
#import <OPPluginBiz/OPPluginBiz-Swift.h>
#import <ECOInfra/NSDictionary+BDPExtension.h>
#import <OPFoundation/BDPCommonManager.h>
#import <OPPluginManagerAdapter/BDPJSBridgeUtil.h>
#import <OPPluginManagerAdapter/OPPluginManagerAdapter-Swift.h>
#import <OPFoundation/BDPStorageModuleProtocol.h>
#import <OPFoundation/BDPModuleManager.h>
#import <ECOInfra/BDPUtils.h>
#import <TTMicroApp/TTMicroApp-Swift.h>
#import <TTMicroApp/OPAPIDefine.h>
#import <OPFoundation/OPFoundation-Swift.h>
#import <ECOInfra/ECOInfra-Swift.h>
#import <OPFoundation/EMAPhotoScrollViewController.h>

@interface EMAPluginImagePreviewHandler () <EMAPhotoScrollViewControllerProtocol>

@end

@implementation EMAPluginImagePreviewHandler
- (instancetype)initWithUniqueID:(nonnull BDPUniqueID *)uniqueID
                      controller:(nonnull UIViewController *)controller {
    if(self = [super init]) {
        self.uniqueID = uniqueID;
        self.controller = controller;
    }
    return self;
}

- (void)previewImageWithParam:(nonnull NSDictionary *)param
                     callback:(nonnull BDPJSBridgeCallback)callback {
    BDPLogInfo(@"previewImage call begin");
    OP_API_RESPONSE(OPAPIResponse)
    /// 开发者传下来的urls数组，不确定是否为字符串数组
    NSArray <NSString *> *urls = [param bdp_arrayValueForKey:@"urls"];
    /// 开发者传入的requests字典数组
    NSArray <NSDictionary <NSString *, id> *> *requests = [param bdp_arrayValueForKey:@"requests"];
    /// 如果两个都为空，则失败回调
    BOOL previewImageCondition = BDPIsEmptyArray(urls) && BDPIsEmptyArray(requests);
    if (previewImageCondition) BDPLogWarn(@"previewImage urls and requests is empty.");
    OP_INVOKE_GUARD_NEW(previewImageCondition, [response callback:PreviewImageAPICodeInvalidUrls], @"urls and requests is empty.");

    /// 都不为空也要回调，两个参数互斥
    previewImageCondition = (!BDPIsEmptyArray(urls) && !BDPIsEmptyArray(requests));
    if(previewImageCondition) BDPLogWarn(@"previewImage urls and requests is mutually exclusive.")
    OP_INVOKE_GUARD_NEW(previewImageCondition, [response callback:PreviewImageAPICodeUrlsExclusive], @"urls and requests is mutually exclusive.");
    /// 尝试构造request数组
    NSMutableArray <NSURLRequest *> *urlREquests = [NSMutableArray array];
    /// 用于计算index
    NSMutableArray <NSString *> *tempurls = [NSMutableArray array];
    if (BDPIsEmptyArray(urls)) {
        /// 使用request构造
        BDPLogWarn(@"previewImage request is not empty")
        for (NSDictionary <NSString *, id> *request in requests) {
            NSError *error;
            NSURLRequest *urlRequest = [self buildURLRequestWith:request error:&error];
            if (error) {
                BDPLogWarn(error.localizedDescription)
                if(error.code==PreviewImageAPICodeInvalidHeader){
                    OP_CALLBACK_WITH_ERRMSG([response callback:PreviewImageAPICodeInvalidHeader], error.localizedDescription);
                }else if(error.code==PreviewImageAPICodeInvalidMethod){
                    OP_CALLBACK_WITH_ERRMSG([response callback:PreviewImageAPICodeInvalidMethod], error.localizedDescription);
                }else{
                    OP_CALLBACK_WITH_ERRMSG([response callback:PreviewImageAPICodeInvalidUrls], error.localizedDescription);
                }
                return;
            }
            [tempurls addObject:urlRequest.URL.absoluteString];
            [urlREquests addObject:urlRequest];
        }
    } else {
        /// 使用url构造
        BDPLogWarn(@"previewImage urls is not empty")
        for (NSString *urlstr in urls) {
            /// 先转换URL，urlstr可能为ttfile开头的
            NSString *realurl = [self buildRealUrlFromUrlString:urlstr];
            NSURL *url = [NSURL URLWithString:realurl];
            BOOL urlCondition = BDPIsEmptyString(urlstr);
            if(urlCondition) BDPLogWarn(@"previewImage url is empty.");
            OP_INVOKE_GUARD_NEW(urlCondition, [response callback:PreviewImageAPICodeUrlEmpty], @"url is empty.");
            
            urlCondition = (!url);
            if(urlCondition) BDPLogWarn(@"previewImage Invaild url.")
            OP_INVOKE_GUARD_NEW(urlCondition, [response callback:PreviewImageAPICodeInvalidUrls], @"previewImage Invaild url.");

            NSURLRequest *urlRequest = [NSURLRequest requestWithURL:url];
            [tempurls addObject:urlRequest.URL.absoluteString];
            [urlREquests addObject:urlRequest];
        }
    }

    /// 构造原图，占位图，index（可选）和header
    NSArray <NSString *> *originUrls = [self buildRealUrlsWith:[param bdp_arrayValueForKey:@"originUrls"]] ?: @[];
    NSArray <NSString *> *placeholderUrls = [self buildRealUrlsWith:[param bdp_arrayValueForKey:@"placeholderUrls"]];
    NSString *current = [self buildRealUrlFromUrlString:[param bdp_stringValueForKey:@"current"]] ?: @"";
    /// 老旧逻辑，暂时兼容一下吧，很捞
    NSDictionary <NSString *, NSString *> *header = [param bdp_dictionaryValueForKey:@"header"];
    /// 通过current尝试计算index，当然，也可能开发者愣头，乱传
    NSUInteger tempindex = [tempurls indexOfObject:current];
    NSUInteger index;
    if (tempindex == NSNotFound) {
        BDPLogWarn(@"previewImage current not found")
        index = 0;
    } else {
        index = tempindex;
    }
    BOOL shouldShowSaveOption = YES;
    if ([param objectForKey:@"shouldShowSaveOption"] != nil) {
        shouldShowSaveOption = [param bdp_boolValueForKey2:@"shouldShowSaveOption"];
    }
    BDPLogInfo(@"previewImage shouldShowSaveOption:%d",shouldShowSaveOption);
    EMAPhotoScrollViewController *vc = [[EMAPhotoScrollViewController alloc]
                                        initWithRequests:urlREquests.copy
                                        startWithIndex:index
                                        placeholderImages:nil
                                        placeholderTags:placeholderUrls
                                        originImageURLs:originUrls
                                        delegate:self
                                        success:^{
        [response callback:OPGeneralAPICodeOk];
    }
                                        failure:^(NSString * _Nullable msg) {
        BDPLogWarn(msg)
        OP_CALLBACK_WITH_ERRMSG([response callback:OPGeneralAPICodeUnkonwError], msg);
    }];
    vc.header = header;
    vc.shouldShowSaveOption = shouldShowSaveOption;
    [vc presentPhotoScrollView:self.controller.view.window];
    BDPLogInfo(@"previewImage call end");
}

#pragma mark - build

/// 转换为 realurl
/// @param url 可能为ttfile的URL
/// @return 返回转换后的 realURL
- (nullable NSString *)buildRealUrlFromUrlString:(NSString * _Nullable)url {
    if (BDPIsEmptyString(url)) {
        return nil;
    }
    BDPUniqueID *uniqueID = self.uniqueID;
    if (!uniqueID) {
        return nil;
    }
    OPFileSystemContext *fsContext = [[OPFileSystemContext alloc] initWithUniqueId:uniqueID
                                                                             trace:nil
                                                                               tag:@"previewImage"
                                                                       isAuxiliary:YES];
    OPFileObject *fileObj = [[OPFileObject alloc] initWithRawValue:url];
    /// 如果不能初始化为 fileObj，则说明不是标准的 fileObj, 直接返回原始值 (包括http url)
    if (!fileObj) {
        fsContext.trace.warn(@"invalid fileRawValue, rawValue: %@", [url maskWithExcept:@":/-_."]);
        if ([url hasPrefix:@"http"] || [url hasPrefix:@"https"]) {
            return url;
        } else {
            return nil;
        }
    }

    NSError *error = nil;
    NSString *systemFilePath = [OPFileSystemCompatible getSystemFileFrom:fileObj context:fsContext error:&error];
    BOOL callGetSystemFileFailed = !systemFilePath || error;
    if (callGetSystemFileFailed) {
        fsContext.trace.error(@"call getSystemFile failed, hasSystemFilePath: %@, error: %@", @(systemFilePath != nil), error.description);
        return nil;
    }
    NSURL *fileURL = [[NSURL alloc] initFileURLWithPath:systemFilePath];
    return fileURL.absoluteString;
}

/// 构造真实URL字符串数组
/// @param urls 可能有ttfile的url数组
/// @return 返回转换后的 realURL
- (nullable NSArray <NSString *> *)buildRealUrlsWith:(NSArray <NSString *> * _Nullable)urls {
    if (!urls) {
        return nil;
    }
    NSMutableArray <NSString *> *array = [NSMutableArray array];
    for (NSString *url in urls) {
        if (![url isKindOfClass:NSString.class]) {
            return nil;
        }
        NSString *realurl = [self buildRealUrlFromUrlString:url];
        if (!realurl) {
            return nil;
        }
        [array addObject:realurl];
    }
    return array.copy;
}

/// 构造图片请求
/// @param requestDictionary 请求字典
/// @param error 错误指针，该参数不允许传nil，传了nil导致的crash，本方法概不负责，并且如果传了nil，本方法不保证正常运行
- (nullable NSURLRequest *)buildURLRequestWith:(NSDictionary <NSString *, id> * _Nonnull)requestDictionary
                                         error:(NSError * _Nonnull *)error {
    if (!error) {
        NSAssert(error, @"error不允许传递nil");
        return nil;
    }
    NSMutableURLRequest *mutableRequest = NSMutableURLRequest.new;
    NSString *urlstr = [requestDictionary bdp_stringValueForKey:@"url"];
    /// url必填参数
    if (BDPIsEmptyString(urlstr)) {
        *error = [NSError errorWithDomain:@"previewImageError" code:-1 userInfo:@{NSLocalizedDescriptionKey: @"url is empty."}];
        return nil;
    }
    /// 先转换URL，urlstr可能为ttfile开头的
    NSString *realurl = [self buildRealUrlFromUrlString:urlstr];
    NSURL *url = [NSURL URLWithString:realurl];
    /// 判断URL是否合法
    if (!url) {
        *error = [NSError errorWithDomain:@"previewImageError" code:-1 userInfo:@{NSLocalizedDescriptionKey: @"Invaild url."}];
        return nil;
    }
    mutableRequest.URL = url;
    NSDictionary <NSString *, NSString *> *header = [requestDictionary bdp_dictionaryValueForKey:@"header"];
    /// header是选填参数
    if (!BDPIsEmptyDictionary(header)) {
        /// 写了header就需要检查开发者传入的是否是<NSString *, NSString *>类型，不合法需要返回错误
        NSError *headerError = [self checkHTTPHeaderWith:header];
        if (headerError) {
            *error = headerError;
            return nil;
        }
        mutableRequest.allHTTPHeaderFields = header;
    }
    NSString *method = [requestDictionary bdp_stringValueForKey:@"method"].uppercaseString;
    /// method选填参数，HTTPMethod默认是GET
    if (!BDPIsEmptyString(method)) {
        /// 写了就需要检查是否合法
        NSError *methodError = [self checkHTTPMethodWith:method];
        if (methodError) {
            *error = methodError;
            return nil;
        }
        mutableRequest.HTTPMethod = method;
    }
    /// body是可选参数
    NSDictionary <NSString *, id> *body = [requestDictionary bdp_dictionaryValueForKey:@"body"];
    if (!BDPIsEmptyDictionary(body) && [NSJSONSerialization isValidJSONObject:body]) {
        /// 先判断是否合法
        if (![NSJSONSerialization isValidJSONObject:body]) {
            *error = [NSError errorWithDomain:@"HTTPBody error" code:-1 userInfo:@{NSLocalizedDescriptionKey: @"Invaild body."}];
            return nil;
        }
        NSError *jsonToDataError;
        NSData *httpbody = [NSJSONSerialization dataWithJSONObject:body options:0 error:&jsonToDataError];
        /// 在判断转换的时候是否error
        if (jsonToDataError) {
            *error = jsonToDataError;
            return nil;
        }
        mutableRequest.HTTPBody = httpbody;
    }
    return mutableRequest.copy;
}

#pragma mark - check param vaild

/// 检查HTTP header是否合法
/// @param header 请求头字典
- (nullable NSError *)checkHTTPHeaderWith:(NSDictionary <NSString *, NSString *> *)header {
    __block NSError *error;
    [header enumerateKeysAndObjectsUsingBlock:^(NSString * _Nonnull key, NSString * _Nonnull obj, BOOL * _Nonnull stop) {
        /// oc的字典，需要判断是否可以作为HTTP的请求头，满足<NSString *, NSString *>才可以
        if (![obj isKindOfClass:NSString.class] || ![key isKindOfClass:NSString.class]) {
            *stop = YES;
            error = [NSError errorWithDomain:@"HTTP Header error" code:PreviewImageAPICodeInvalidHeader userInfo:@{NSLocalizedDescriptionKey: @"Invaild header."}];
        }
    }];
    return error;
}

/// 检查HTTP method是否是previewImage的合法方法
/// @param method 开发者参数
- (nullable NSError *)checkHTTPMethodWith:(NSString *)method {
    /// 目前只支持GET和POST
    NSArray <NSString *> *methodSet = @[@"GET", @"POST"];
    return [methodSet containsObject:method] ? nil : [NSError errorWithDomain:@"HTTP method error" code:PreviewImageAPICodeInvalidMethod userInfo:@{NSLocalizedDescriptionKey: @"Invaild method."}];
}


#pragma mark - EMAPhotoScrollViewControllerProtocol

- (UIImage *)placeholderImageForTag:(NSString *)tag {
    /*
    BDPType appType = self.context.engine.uniqueID.appType;
     */
    BDPType appType = self.uniqueID.appType;
    if (appType != BDPTypeNativeApp) {
        //  非小程序无需走代理
        return nil;
    }
    NSString *placeholderURL = tag;
    if (BDPIsEmptyString(placeholderURL)) {
        return nil;
    }
    UIImage *image = [TMAWebkitResourceManager.defaultManager imageResourceForURL:[NSURL URLWithString:placeholderURL] pageURL:[NSURL URLWithString:@""]];
    return image;
}

- (void)handelQRCode:(NSString *)qrCode fromController:(EMAPhotoScrollViewController *)controller {
    [self.class handelQRCode:qrCode fromController:controller uniqueID:self.uniqueID];
}

+ (void)handelQRCode:(NSString *)qrCode fromController:(UIViewController *)controller uniqueID:(BDPUniqueID*)uniqueID{
    BDPType appType = uniqueID.appType;
    if (appType != BDPTypeNativeApp) {
        //  非小程序无需走代理
        return;
    }
    /*
    BDPJSBridgeEngine gadgetEngine = (BDPJSBridgeEngine)self.context.engine;
     */
    BDPLogInfo(@"handelQRCode, qrCode=%@, controller=%@", qrCode, controller);
    BOOL openURL = NO;
    NSURL *url = [NSURL URLWithString:qrCode];
    if (url) {
        NSString *failErrMsg;
        BDPCommon *common = [[BDPCommonManager sharedManager] getCommonWithUniqueID:uniqueID];
        if ([url.scheme.lowercaseString isEqualToString:@"http"] || [url.scheme.lowercaseString isEqualToString:@"https"]) {
            if ([common.auth checkAuthorizationURL:url.absoluteString authType:BDPAuthorizationURLDomainTypeWebView]) {
                openURL = YES;  // 打开HTTP
            }
        } else if([common.auth checkSchema:&url uniqueID:uniqueID errorMsg:&failErrMsg]) {
            openURL = YES;      // 打开Schema
        }
        if (!BDPIsEmptyString(failErrMsg)) {
            BDPLogInfo(@"failErrMsg: %@", failErrMsg);
        }
    }
    //兼容老API
    if([controller isKindOfClass:EMAPhotoScrollViewController.class]) {
        EMAPhotoScrollViewController *vc = (EMAPhotoScrollViewController *)controller;
        [vc dismissAnimated:YES completion:^{
           if (openURL && [[EMAProtocolProvider getEMADelegate] handleQRCode:qrCode uniqueID:uniqueID fromController:controller]) {
               BDPLogInfo(@"handleQRCode %@", BDPParamStr(qrCode, @(openURL)));
               return;
           }

            // 展示普通文本
            UIViewController *viewController = [EMAControllerOCBridge textViewControllerWith:qrCode];
            [OPNavigatorHelper push:viewController window:controller.view.window animated:YES];

            BDPLogInfo(@"show text %@", BDPParamStr(qrCode, @(openURL)));
        }];
    }else {
        [controller dismissViewControllerAnimated:NO completion:^{
           if (openURL && [[EMAProtocolProvider getEMADelegate] handleQRCode:qrCode uniqueID:uniqueID fromController:controller]) {
               BDPLogInfo(@"handleQRCode %@", BDPParamStr(qrCode, @(openURL)));
               return;
           }

            // 展示普通文本
            UIViewController *viewController = [EMAControllerOCBridge textViewControllerWith:qrCode];
            [OPNavigatorHelper push:viewController window:controller.view.window animated:YES];

            BDPLogInfo(@"show text %@", BDPParamStr(qrCode, @(openURL)));
        }];
    }

}

@end
