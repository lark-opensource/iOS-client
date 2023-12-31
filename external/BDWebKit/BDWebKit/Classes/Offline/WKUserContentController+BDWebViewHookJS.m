//
//  WKUserContentController+BDWebViewHookJS.m
//  BDWebKit
//
//  Created by wealong on 2019/12/15.
//

#import "WKUserContentController+BDWebViewHookJS.h"
#import <objc/runtime.h>
#import <TTNetworkManager/TTNetworkManager.h>
#import <TTNetworkManager/NSURLRequest+WebviewInfo.h>
#import <ByteDanceKit/ByteDanceKit.h>
#import <BDWebCore/IWKUtils.h>
#import "NSObject+BDWRuntime.h"
#import "BDWebViewResourceManager.h"
#import <BDWebKit/IESFalconManager.h>
#import <BDWebKit/IESFalconWebURLProtocolTask.h>
#import <BDWebKit/BDWebResourceMonitorEventType.h>
#import <BDWebKit/BDWebKitSettingsManger.h>

static NSString *const kBDWHookAjaxHandleName = @"IMYXHR";

// 用于falcon对齐RL埋点规范,增加版本信息
static NSString *const kFalconHookAjaxResLoaderVersion = @"1.1.1";

static const void *kBDWHookAjaxKey = &kBDWHookAjaxKey;
static const void *kBDWHookAjaxSourceKey = &kBDWHookAjaxSourceKey;
static const void *kBDWHookAjaxMonitorKey = &kBDWHookAjaxMonitorKey;

@implementation WKUserContentController (BDWebViewHookJS)
- (void)bdw_installHookAjax {
    BOOL installed = [objc_getAssociatedObject(self, kBDWHookAjaxKey) boolValue];
    if (installed) {
        return;
    }
    objc_setAssociatedObject(self, kBDWHookAjaxKey, @YES, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
   
    __weak typeof(self) wself = self;
    [self bdw_register:kBDWHookAjaxHandleName handle:^(WKScriptMessage * _Nonnull msg) {
        [wself bdw_interceptionRequest:msg.webView messageBody:msg.body];
    }];
    
    //add hook script
    NSString * jsScript = [self bdw_hookAjaxJS];
    if (jsScript.length > 0) {
        if ([self.bdw_hookjsMonitor respondsToSelector:@selector(bypassSetting)]) {
            if ([self.bdw_hookjsMonitor bypassSetting]) {
                NSString *jsonString = nil;
                NSError *err = nil;
                NSData *jsonData = [NSJSONSerialization dataWithJSONObject:[self.bdw_hookjsMonitor bypassSetting] options:NSJSONWritingPrettyPrinted error:&err];
                if (jsonData.length > 0) {
                    jsonString = [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
                    NSMutableString *temp = [NSMutableString stringWithString:jsScript];
                    [temp appendString:[NSString stringWithFormat:@"(function () {window.__tiktokwebview_hook_whitelist_setting__ = %@;})();",jsonString]];
                    jsScript = temp;
                }
            }
        }
        
        WKUserScript *userScript = [[WKUserScript alloc] initWithSource:jsScript injectionTime:WKUserScriptInjectionTimeAtDocumentStart forMainFrameOnly:NO];
        [self addUserScript:userScript];
        objc_setAssociatedObject(self, kBDWHookAjaxSourceKey, userScript, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    }
}

- (void)uninstallHookAjax {
    if (objc_getAssociatedObject(self, kBDWHookAjaxSourceKey) == nil)
        return;

    NSArray<WKUserScript*> *scripts = [self userScripts];
    BOOL need_uninstall = NO;
    for (WKUserScript* script in scripts) {
        if (script == objc_getAssociatedObject(self, kBDWHookAjaxSourceKey)) {
            need_uninstall = YES;
            break;
        }
    }
    
    if (!need_uninstall) {
        return;
    }

    [self removeAllUserScripts];
    for (WKUserScript* script in scripts) {
        if (script != objc_getAssociatedObject(self, kBDWHookAjaxSourceKey)) {
            [self addUserScript:script];
        }
    }
    
    objc_setAssociatedObject(self, kBDWHookAjaxKey, @NO, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    objc_setAssociatedObject(self, kBDWHookAjaxSourceKey, nil, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (id<BDWebViewHookJSMonitor>)bdw_hookjsMonitor {
    return objc_getAssociatedObject(self, kBDWHookAjaxMonitorKey);
}

- (void)bdw_installHookAjaxWithMonitor:(id<BDWebViewHookJSMonitor>)monitor {
    objc_setAssociatedObject(self, kBDWHookAjaxMonitorKey, monitor, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    [self bdw_installHookAjax];
}

- (void)bdw_installNativeDomReady {
    NSString *jsScript = [self bdw_fetchNativeDomReadyJS];
    
    if (jsScript.length > 0) {
        WKUserScript *userScript = [[WKUserScript alloc] initWithSource:jsScript injectionTime:WKUserScriptInjectionTimeAtDocumentStart forMainFrameOnly:NO];
        [self addUserScript:userScript];
    }
}

#pragma mark - RecordHTTPResponse

+ (NSSet *)falconHookAjaxMonitorResponseHeaders
{
    static NSSet *headers = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        headers = [NSSet setWithArray: @[
            @"content-type", @"content-length", @"content-encoding", @"x-gecko-proxy-logid", @"x-gecko-proxy-pkgid",
            @"x-gecko-proxy-tvid", @"x-tos-version-id", @"x-bdcdn-cache-status", @"x-cache", @"x-response-cache",
            @"x-tt-trace-host", @"via"
        ]];
    });
    return headers;
}

+ (NSDictionary *)hookAjaxTTNetResponseTimingInfo:(TTHttpResponse *)ttResponse
{
    TTHttpResponseTimingInfo *timingInfo = ttResponse.timinginfo;
    return @{
        @"ttnet_start" : @([timingInfo.start timeIntervalSince1970] * 1000),
        @"ttnet_proxy" : @(timingInfo.proxy),
        @"ttnet_dns" : @(timingInfo.dns),
        @"ttnet_connect" : @(timingInfo.connect),
        @"ttnet_ssl" : @(timingInfo.ssl),
        @"ttnet_send" : @(timingInfo.send),
        @"ttnet_wait" : @(timingInfo.wait),
        @"ttnet_receive" : @(timingInfo.receive),
        @"ttnet_total" : @(timingInfo.total),
        @"ttnet_receivedResponseContentLength" : @(timingInfo.receivedResponseContentLength),
        @"ttnet_totalReceivedBytes" : @(timingInfo.totalReceivedBytes),
        @"ttnet_isSocketReused" : @(timingInfo.isSocketReused),
        @"ttnet_isCached" : @(timingInfo.isCached),
        @"ttnet_isFromProxy" : @(timingInfo.isFromProxy)
    };
    return [[NSDictionary alloc] init];
}

+ (NSDictionary *)hookAjaxTTNetResponseHeaders:(TTHttpResponse *)ttResponse
{
    NSDictionary *dict = [ttResponse.allHeaderFields btd_filter:^BOOL(id _Nonnull key, id  _Nonnull obj) {
        return [[[self class] falconHookAjaxMonitorResponseHeaders] containsObject: key];
    }];
    return [dict copy];
}

+ (NSString *)hookAjaxResponseHeaderStringFromDic:(NSDictionary *)dict
{
    if (![NSJSONSerialization isValidJSONObject:dict]) {
        return [NSString stringWithFormat:@"%@", dict];
    }

    NSData *data = [NSJSONSerialization dataWithJSONObject:dict options:kNilOptions error:nil];
    return [[NSString alloc]initWithData:data encoding:NSUTF8StringEncoding];
}

#pragma mark - Interception Request

- (void)bdw_interceptionRequest:(WKWebView *)webView messageBody:(id)messageBody {
    NSDictionary *dict = messageBody;
    if (dict.count <= 0) {
        return;
    }
    id requestID = [dict objectForKey:@"id"];
    NSString *method = [dict btd_stringValueForKey:@"method"];
    id body = [dict objectForKey:@"data"];
    NSDictionary *requestHeaders = [dict btd_dictionaryValueForKey:@"headers"];
    if (![requestHeaders isKindOfClass:[NSDictionary class]]) {
        requestHeaders = nil;
    }
    NSString *urlString = [dict btd_stringValueForKey:@"url"];
    NSURL *URL = [[self class] bdw_URLWithString:urlString baseURL:webView.URL];
    NSString *urlContentType = requestHeaders[@"Content-Type"];
    
    if ([self.bdw_hookjsMonitor respondsToSelector:@selector(didRecieveJSMessage:baseURL:withContentTyp:)]) {
        [self.bdw_hookjsMonitor didRecieveJSMessage:URL baseURL:webView.URL withContentTyp:(urlContentType ?: @"empty-type")];
    } else if ([self.bdw_hookjsMonitor respondsToSelector:@selector(didRecieveJSMessage:baseURL:)]) {
        [self.bdw_hookjsMonitor didRecieveJSMessage:URL baseURL:webView.URL];
    }
    
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:URL cachePolicy:NSURLRequestReloadIgnoringCacheData timeoutInterval:60];
    
    //加个保护，requestHeaders里的value必须是string
    NSMutableDictionary *tmpHeaders = [NSMutableDictionary dictionaryWithCapacity:requestHeaders.count];
    for (NSString *tmpKey in requestHeaders.allKeys) {
        NSString *tmpValue = requestHeaders[tmpKey];
        if ([tmpValue isKindOfClass:[NSString class]]) {
            [tmpHeaders setValue:tmpValue forKey:tmpKey];
        } else {
            [tmpHeaders setValue:[NSString stringWithFormat:@"%@",tmpValue] forKey:tmpKey];
        }
    }
    if ([tmpHeaders valueForKey:@"User-Agent"] == nil && webView.customUserAgent) {
        [tmpHeaders setValue:webView.customUserAgent forKey:@"User-Agent"];
    }
    [tmpHeaders setValue:@"TTNet" forKey:@"X-TT-Web-Proxy"];
    [request setAllHTTPHeaderFields:tmpHeaders];
    /*
     *  Multipart 处理暂时不合入国内,国内没有复杂结构体的body
     *    if([requestHeaders[@"Content-Type"] isEqualToString:@"multipart/form-data"]){
     *        mutipartData = [self bdw_buildMultipartRequest:request withData:[body dataUsingEncoding:NSUTF8StringEncoding] error:err];
     *    }
     */
    request.HTTPMethod = method.uppercaseString;
    NSError *err = nil;
    if ([body isKindOfClass:[NSString class]]) {
        request.HTTPBody = [body dataUsingEncoding:NSUTF8StringEncoding];
    } else if ([body isKindOfClass:[NSData class]]) {
        request.HTTPBody = body;
    } else if ([NSJSONSerialization isValidJSONObject:body]) {
        request.HTTPBody = [NSJSONSerialization dataWithJSONObject:body options:0 error:&err];
    }

    if ([self.bdw_hookjsMonitor respondsToSelector:@selector(didHandleXHRMessage:baseURL: headers: multipartData: error:)]) {
        [self.bdw_hookjsMonitor didHandleXHRMessage:URL baseURL:webView.URL headers:requestHeaders multipartData:nil error:err];
    }
    
    if (@available(iOS 13.0, *) ) {
        // iOS 13 HTTP GET 请求禁止携带Body
        if ([request.HTTPMethod isEqualToString:@"GET"] && request.HTTPBody.length > 0) {
            NSAssert(NO, @"HTTP GET request don't allow carrying the body.");
            request.HTTPMethod = @"POST";
        }
    }
    
    // decorate request before sent to ttnet
    NSURLRequest *finalRequest = [IESFalconManager willDecorateRequest:request];
    
    __block IESFalconWebURLProtocolTask *hookAjaxTask = [[IESFalconWebURLProtocolTask alloc] init];
    hookAjaxTask.bdw_request = finalRequest;
    hookAjaxTask.bdw_webView = webView;
    hookAjaxTask.taskFinishWithLocalData = NO;
    hookAjaxTask.taskFinishWithTTNet = YES;
    hookAjaxTask.taskFromHookAjax = YES;
    hookAjaxTask.ttnetEnableCustomizedCookie = NO;
    
    NSMutableDictionary *falconProcessInfoDic = [[NSMutableDictionary alloc] init];
    
    falconProcessInfoDic[kBDWebviewResLoaderNameKey] = @"falconHookAjax";
    falconProcessInfoDic[kBDWebviewResLoaderVersionKey] = kFalconHookAjaxResLoaderVersion;
    falconProcessInfoDic[kBDWebviewResSrcKey] = finalRequest.URL.absoluteString;
    falconProcessInfoDic[kBDWebviewGeckoSyncUpdateKey] = @(NO);
    falconProcessInfoDic[kBDWebviewCDNCacheEnableKey] = @(NO);
    falconProcessInfoDic[kBDWebviewResSceneKey] = @"web_child_resource";
    
    NSString *dataRequestType = [finalRequest.URL.path.pathExtension lowercaseString];
    falconProcessInfoDic[kBDWebviewResTypeKey] = BTD_isEmptyString(dataRequestType) ? @"hook_ajax_post_api" : dataRequestType;
    
    falconProcessInfoDic[kBDWebviewResFromKey] = @"cdn";
    falconProcessInfoDic[kBDWebviewIsMemoryKey] = @(NO);
    falconProcessInfoDic[kBDWebviewResStateKey] = @"failed";
    falconProcessInfoDic[kBDWebviewGeckoConfigFromKey] = @"custom_config";
    falconProcessInfoDic[kBDWebviewFetcherListKey] = @"[BDWebViewHookJS]";
    
    NSTimeInterval ajaxHttpTaskStartTime = [NSDate date].timeIntervalSince1970 * 1000;
    falconProcessInfoDic[kBDWebviewResLoadStartKey] = @(ajaxHttpTaskStartTime);
    falconProcessInfoDic[kBDWebviewCDNStartKey] = @(ajaxHttpTaskStartTime);
    
    hookAjaxTask.bdw_falconProcessInfoRecord = falconProcessInfoDic;
    
    [IESFalconManager willDecorateURLProtocolTask:hookAjaxTask];
    
    // add associated object for webview info
    finalRequest.webviewInfo = [hookAjaxTask.bdw_additionalInfo copy];
    finalRequest.needCommonParams = hookAjaxTask.useTTNetCommonParams;
    
    BOOL willEnableTTNetCacheControl = NO;
    if (hookAjaxTask.taskHttpCachePolicy != BDWebHTTPCachePolicyUseAppSetting) {
        willEnableTTNetCacheControl = hookAjaxTask.taskHttpCachePolicy == BDWebHTTPCachePolicyEnableCache ? YES : NO;
    }
    
    TTHttpTask *ttnetTask = [[TTNetworkManager shareInstance] requestForWebview:finalRequest
                                                                     autoResume:NO
                                                                enableHttpCache:willEnableTTNetCacheControl
                                                                 headerCallback:nil
                                                                   dataCallback:nil
                                                           callbackWithResponse:^(NSError *error, id obj, TTHttpResponse *response) {
        NSString *responseString = nil;
        if ([obj isKindOfClass:[NSData class]]) {
            responseString = [[NSString alloc] initWithData:((NSData *)obj) encoding:NSUTF8StringEncoding];
        }
        
        NSTimeInterval ajaxHttpTaskFinishTime = [NSDate date].timeIntervalSince1970 * 1000;
        hookAjaxTask.bdw_falconProcessInfoRecord[kBDWebviewCDNFinishKey] = @(ajaxHttpTaskFinishTime);
        hookAjaxTask.bdw_falconProcessInfoRecord[kBDWebviewResLoadFinishKey] = @(ajaxHttpTaskFinishTime);
        hookAjaxTask.bdw_falconProcessInfoRecord[kBDWebviewResSizeKey] = @(response.timinginfo.totalReceivedBytes);
        hookAjaxTask.bdw_falconProcessInfoRecord[kBDWebviewResStateKey] = @"success";
        hookAjaxTask.bdw_falconProcessInfoRecord[kBDWebviewResVersionKey] = @([response.allHeaderFields btd_integerValueForKey:@"x-gecko-proxy-pkgid"]);
        
        if (!hookAjaxTask.bdw_falconProcessInfoRecord[kBDWebviewExtraKey] || [hookAjaxTask.bdw_falconProcessInfoRecord[kBDWebviewExtraKey] isKindOfClass:[NSDictionary class]]) {
            hookAjaxTask.bdw_falconProcessInfoRecord[kBDWebviewExtraKey] = [[NSMutableDictionary alloc] init];
        }
        NSDictionary *headerDict = [[self class] hookAjaxTTNetResponseHeaders:response];
        hookAjaxTask.bdw_falconProcessInfoRecord[kBDWebviewExtraKey][kBDWebviewExtraHTTPResponseHeadersKey] = [[self class] hookAjaxResponseHeaderStringFromDic:headerDict];
        
        hookAjaxTask.bdw_ttnetResponseTimingInfoRecord = [[self class] hookAjaxTTNetResponseTimingInfo:response];
        
        if (error) {
            NSString *errorDescription = error.localizedDescription ? : @"unknown";
            NSString *oldErrorMsg = hookAjaxTask.bdw_falconProcessInfoRecord[kBDWebviewResErrorMsgKey];
            if (BTD_isEmptyString(oldErrorMsg)) {
                hookAjaxTask.bdw_falconProcessInfoRecord[kBDWebviewResErrorMsgKey] = errorDescription;
            } else {
                hookAjaxTask.bdw_falconProcessInfoRecord[kBDWebviewResErrorMsgKey] = [NSString stringWithFormat:@"%@  {%@}", oldErrorMsg, errorDescription];
            }
            
            hookAjaxTask.bdw_falconProcessInfoRecord[kBDWebviewResStateKey] = @"failed";
            [IESFalconManager bdw_URLProtocolTask:hookAjaxTask didFailWithError:error];
        } else {
            NSHTTPURLResponse *nsResponse = [[NSHTTPURLResponse alloc] initWithURL:response.URL statusCode:response.statusCode HTTPVersion:@"HTTP/1.1" headerFields:response.allHeaderFields];
            [IESFalconManager bdw_URLProtocolTask:hookAjaxTask didReceiveResponse:nsResponse];
            
            [IESFalconManager bdw_URLProtocolTask:hookAjaxTask didLoadData:(NSData *)obj];
            [IESFalconManager bdw_URLProtocolTaskDidFinishLoading:hookAjaxTask];
        }
        
        if ([self.bdw_hookjsMonitor respondsToSelector:@selector(didRecieveResponseCode: forURL:baseURL: error:)]) {
            [self.bdw_hookjsMonitor didRecieveResponseCode:response.statusCode forURL:URL baseURL:webView.URL error:error];
        }
        [self bdw_requestCallback:requestID request:finalRequest httpCode:response.statusCode headers:response.allHeaderFields data:responseString webView:webView];
    }
                                                               redirectCallback:nil];
    ttnetTask.enableCustomizedCookie = hookAjaxTask.ttnetEnableCustomizedCookie;
    ttnetTask.timeoutInterval = [BDWebKitSettingsManger bdFixTTNetTimeout];
    [ttnetTask resume];
    
    /*
    NSURLSessionTask *task = [[NSURLSession sharedSession] dataTaskWithRequest:request completionHandler:^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error) {
        NSHTTPURLResponse *httpResponse = nil;
        if ([response isKindOfClass:[NSHTTPURLResponse class]]) {
            httpResponse = (id)response;
        }
        NSDictionary *allHeaderFields = httpResponse.allHeaderFields;
        NSString *responseString = nil;
        if (data.length > 0) {
            responseString = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
        }
        
        if ([self.bdw_hookjsMonitor respondsToSelector:@selector(didRecieveResponseCode: forURL: error:)]) {
            [self.bdw_hookjsMonitor didRecieveResponseCode:httpResponse.statusCode forURL:URL error:error];
        }
        
        [self bdw_requestCallback:requestID request:request httpCode:httpResponse.statusCode headers:allHeaderFields data:responseString webView:webView];
    }];
    [task resume];
    */
    if ([self.bdw_hookjsMonitor respondsToSelector:@selector(didSendRequest:baseURL:)]) {
        [self.bdw_hookjsMonitor didSendRequest:URL baseURL:webView.URL];
    }
}

- (void)bdw_requestCallback:(id)requestId
                    request:(NSURLRequest*)request
                   httpCode:(NSInteger)httpCode
                    headers:(NSDictionary *)headers
                       data:(NSString *)data
                    webView:(WKWebView *)webView {
    NSMutableDictionary *dict = [NSMutableDictionary dictionary];
    [dict setValue:@(httpCode) forKey:@"status"];
    [dict setValue:headers forKey:@"headers"];
    if (data.length > 0) {
        [dict setValue:data forKey:@"data"];
    }
    NSString *jsonString = nil;
    NSError *err = nil;
    NSData *jsonData = [NSJSONSerialization dataWithJSONObject:dict options:NSJSONWritingPrettyPrinted error:&err];
    if (jsonData.length > 0) {
        jsonString = [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
    }
    NSString *jsScript = [NSString stringWithFormat:@";window.imy_realxhr_callback && window.imy_realxhr_callback(%@, %@);", requestId, jsonString?:@"{}"];
    dispatch_async(dispatch_get_main_queue(), ^{
        [webView evaluateJavaScript:jsScript completionHandler:^(id result, NSError *error) {
                if ([self.bdw_hookjsMonitor respondsToSelector:@selector(didInvokeJSCallback:forURL:)]) {
                    [self.bdw_hookjsMonitor didInvokeJSCallback:error forURL:request.URL];
                }
                    
//                NSLog(@"window.imy_realxhr_callback error: %@ \n js = %@",error, jsScript);
        }];
    });
}

+ (NSURL *)bdw_URLWithString:(NSString *)urlString baseURL:(NSURL *)baseURL
{
    if (!urlString.length) {
        return nil;
    }
    if (![urlString containsString:@"://"]) {
        if ([urlString hasPrefix:@"//"]) {
            urlString = [NSString stringWithFormat:@"%@:%@", baseURL.scheme?:@"http", urlString];
        }
        else if ([urlString hasPrefix:@"/"]) {
            urlString = [NSString stringWithFormat:@"%@://%@%@", baseURL.scheme?:@"http", baseURL.host, urlString];
        }
        else {
            urlString = [NSString stringWithFormat:@"%@://%@", baseURL.scheme?:@"http", urlString];
        }
    }
    return [NSURL btd_URLWithString:urlString];
}

- (NSString *)bdw_hookAjaxJS {
    return [BDWebViewResourceManager sharedInstance].fetchAjaxHookJS;
}

- (NSString *)bdw_fetchNativeDomReadyJS {
    return @"var readyRE = /complete|loaded|interactive/;"
    @"if (readyRE.test(document.readyState) && document.body) {"
    @"console.log('bytedance://domReady');"
    @"} else {"
    @"document.addEventListener('DOMContentLoaded', function(){"
    @"console.log('bytedance://domReady');"
    @"}, false)"
    @"}";
}

//build multipart request
-(NSArray*)bdw_buildMultipartRequest:(NSMutableURLRequest*)request withData:(NSData*)data error:(NSError*)err {
    
    NSString*boundary = [[NSUUID UUID]UUIDString];//随机字符串，用作分割符
    request.HTTPMethod = @"POST";
    
    //拼接请求体数据(0-6步)
    NSMutableData *requestMutableData=[NSMutableData data];
    
    id body = [NSJSONSerialization JSONObjectWithData:data
                                                        options:NSJSONReadingMutableContainers
                                                          error:&err];
    NSMutableArray *result = nil;
    if(!err && [body isKindOfClass:[NSArray class]])
    {
        result = [[NSMutableArray alloc] init];
        for (NSDictionary *paramWrapper in (NSArray*)body) {
            NSMutableDictionary* wrapper = paramWrapper.mutableCopy;
            [wrapper removeObjectForKey:@"value"];
            [result addObject:wrapper];

            if ([paramWrapper[@"type"] isEqualToString:@"[object Blob]"]) {
                NSString *contentName = paramWrapper[@"name"];
                NSString *fileName = paramWrapper[@"filename"]?:@"";
                NSString *contentType = paramWrapper[@"contentType"]?:@"";
                /*--------------------------------------------------------------------------*/
                //1.\r\n--Boundary+72D4CD655314C423\r\n   // 分割符，以“--”开头，后面的字随便写，只要不写中文即可
                NSMutableString *myString=[NSMutableString stringWithFormat:@"\r\n--%@\r\n",boundary];
                
                //2. Content-Disposition: form-data; name="image"; filename="001.png"\r\n  // 这里注明服务器接收图片的参数（类似于接收用户名的userName）及服务器上保存图片的文件名
                [myString appendString:[NSString stringWithFormat:@"Content-Disposition: form-data; name=\"%@\"; filename=\"%@\"\r\n",contentName,fileName]];
                
                //3. Content-Type:image/png \r\n  // 图片类型为png
                [myString appendString:[NSString stringWithFormat:@"Content-Type:%@\r\n", contentType]];
                
                //4. Content-Transfer-Encoding: binary\r\n\r\n  // 编码方式
                [myString appendString:@"Content-Transfer-Encoding: binary\r\n\r\n"];
                
                //转换成为二进制数据
                [requestMutableData appendData:[myString dataUsingEncoding:NSUTF8StringEncoding]];
                
                //5.文件数据部分
                NSData *fileData=[paramWrapper[@"value"] dataUsingEncoding:NSUTF8StringEncoding];
                
                //转换成为二进制数据
                [requestMutableData appendData:fileData];
                
                //6. \r\n--Boundary+72D4CD655314C423--\r\n  // 分隔符后面以"--"结尾，表明结束
                [requestMutableData appendData:[[NSString stringWithFormat:@"\r\n--%@--\r\n",boundary] dataUsingEncoding:NSUTF8StringEncoding]];
                /*--------------------------------------------------------------------------*/
                
            
            }else {
                NSString* key = paramWrapper[@"name"];
                NSString *pair = [NSString stringWithFormat:@"--%@\r\nContent-Disposition: form-data; name=\"%@\"\r\n\r\n",boundary,key];
                [requestMutableData appendData:[pair dataUsingEncoding:NSUTF8StringEncoding]];
                id value = paramWrapper[@"value"];;
                if ([value isKindOfClass:[NSString class]]) {
                    [requestMutableData appendData:[value dataUsingEncoding:NSUTF8StringEncoding]];
                }else if ([value isKindOfClass:[NSData class]]){
                    [requestMutableData appendData:value];
                }
                [requestMutableData appendData:[@"\r\n" dataUsingEncoding:NSUTF8StringEncoding]];
        
            }
        }
    }
    //设置请求体
    request.HTTPBody=requestMutableData;
    
    //设置请求头
    NSString *headStr=[NSString stringWithFormat:@"multipart/form-data; boundary=%@",boundary];
    [request setValue:headStr forHTTPHeaderField:@"Content-Type"];

    return result;
    
}

@end
