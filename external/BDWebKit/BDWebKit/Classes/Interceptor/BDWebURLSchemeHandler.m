//
//  BDWebURLSchemeHandler.m
//  BDWebKit
//
//  Created by caiweilong on 2020/3/19.
//

#import "BDWebURLSchemeHandler.h"
#import "BDWebInterceptor+Private.h"
#import "BDWebURLSchemeTaskProxy.h"
#import "BDWebURLSchemeTask.h"
#import "BDWebKitUtil.h"
#import "WKWebView+BDInterceptor.h"
#import "WKWebView+BDPrivate.h"
#import "BDWebResourceMonitorEventType.h"
#import "BDWebKitMainFrameModel.h"
#import <objc/runtime.h>

static char const kBDWebSchemaHandlerSchemeTaskKey;
static char const kBDWebSchemaHandlerSchemeHandlerKey;

@implementation BDWebURLSchemeHandler

#pragma mark - MainFrameRecorder

- (BOOL)webview:(nonnull WKWebView *)webView recordForMainFrame:(NSURLRequest *)request {
    // reset bdw_mainFrameModelRecord when received main frame request at BDWebInterceptorPluginObject
    if (webView.bdw_mainFrameModelRecord) {
        BDWebKitMainFrameStatus status = webView.bdw_mainFrameModelRecord.mainFrameStatus;
        if (status != BDWebKitMainFrameStatusNone) {
            return NO;
        }
    }
    NSString *webURL = webView.URL.absoluteString;
    if ([webURL isEqualToString:request.URL.absoluteString]) {
        return YES;
    }
    return NO;
}


#pragma mark - URLSchemeHandler

- (void)webView:(nonnull WKWebView *)webView startURLSchemeTask:(nonnull id<WKURLSchemeTask>)urlSchemeTask API_AVAILABLE(ios(11.0)) {
    id<BDWebURLSchemeTaskHandler> handler = objc_getAssociatedObject(urlSchemeTask, &kBDWebSchemaHandlerSchemeHandlerKey);
    __block NSURLRequest *request = urlSchemeTask.request;
    
    // if will block request, just send nil response
    BOOL willBlock = [BDWebInterceptor willBlockRequest:request];
    if (willBlock) {
        // make response headers
        NSMutableDictionary *headerFields = [@{@"ETag":@"0000000000000000", @"Access-Control-Allow-Origin" : @"*"} mutableCopy];
        NSString *extension = [request.URL pathExtension];
        NSString *contentType = [BDWebKitUtil contentTypeOfExtension:extension];
        if (contentType) {
            headerFields[@"Content-Type"] = contentType;
        }
        // make data
        NSData *data = [@"0000000000000000" dataUsingEncoding:NSUTF8StringEncoding];

        NSURLResponse *response = [[NSHTTPURLResponse alloc] initWithURL:request.URL statusCode:200 HTTPVersion:nil headerFields:headerFields];

        [urlSchemeTask didReceiveResponse:response];
        [urlSchemeTask didReceiveData:data];
        [urlSchemeTask didFinish];
        return;
    }

    NSTimeInterval resLoadStart = [[NSDate date] timeIntervalSince1970];
    if (!handler) {
        // 增加从WebView获取class的逻辑, 优先级最高
        Class handlerClass = [[BDWebInterceptor sharedInstance] schemaHandlerClassWithURLRequest:urlSchemeTask.request
                                                                                         webview:webView];
        
        BDWebURLSchemeTaskProxy *taskProxy = [BDWebURLSchemeTaskProxy alloc];
        taskProxy.target = urlSchemeTask;
        
        NSArray<Class<BDWebRequestDecorator>> *decorators = [[BDWebInterceptor sharedInstance] bdw_requestDecorators];
        if (decorators.count > 0) {
            [decorators enumerateObjectsUsingBlock:^(Class _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
                id<BDWebRequestDecorator> decorator = (id<BDWebRequestDecorator>)[[obj alloc] init];
                request = [decorator bdw_decorateRequest:request];
            }];
        }
        
        BDWebURLSchemeTask *task = [[BDWebURLSchemeTask alloc] init];
        task.bdw_request = request;
        task.bdw_webView = webView;
        task.delegate = taskProxy;
        task.willRecordForMainFrameModel = [self webview:webView recordForMainFrame:request];
        task.bdw_rlProcessInfoRecord = [[NSMutableDictionary alloc] init];
        task.bdw_rlProcessInfoRecord[kBDWebviewResLoadStartKey] = @(resLoadStart * 1000);
        task.bdw_rlProcessInfoRecord[kBDWebviewResSrcKey] = request.URL.absoluteString;
        task.bdw_rlProcessInfoRecord[kBDWebviewResSceneKey] = task.willRecordForMainFrameModel ? @"web_main_document" : @"web_child_resource";
        if (@available(iOS 12.0, *)) {
            if ([task.bdw_webView.bdw_interceptorHandler respondsToSelector:@selector(canHandleRequest:)]) {
                task.canHandle = [task.bdw_webView.bdw_interceptorHandler canHandleRequest:task];
            }
        }
        task.taskFinishWithLocalData = NO;
        task.taskFinishWithTTNet = NO;
        task.ttnetEnableCustomizedCookie = NO;
        
        if (decorators.count > 0) {
            [decorators enumerateObjectsUsingBlock:^(Class _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
                id<BDWebRequestDecorator> decorator = (id<BDWebRequestDecorator>)[[obj alloc] init];
                SEL selector = @selector(bdw_decorateSchemeTask:);
                if ([decorator respondsToSelector:(selector)]) {
                    [decorator bdw_decorateSchemeTask:task];
                }
            }];
        }
        
        handler = [[handlerClass alloc] initWithWebView:webView schemeTask:task];

        objc_setAssociatedObject(urlSchemeTask, &kBDWebSchemaHandlerSchemeHandlerKey, handler, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
        objc_setAssociatedObject(task, &kBDWebSchemaHandlerSchemeTaskKey, taskProxy, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
        
    }
    [handler bdw_startURLSchemeTask];
}

- (void)webView:(nonnull WKWebView *)webView stopURLSchemeTask:(nonnull id<WKURLSchemeTask>)urlSchemeTask API_AVAILABLE(ios(11.0)){
    id<BDWebURLSchemeTaskHandler> handler = objc_getAssociatedObject(urlSchemeTask, &kBDWebSchemaHandlerSchemeHandlerKey);
    
    [handler bdw_stopURLSchemeTask];
}

@end
