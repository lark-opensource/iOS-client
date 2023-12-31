//
//  BDWebURLSchemeTaskProxy.m
//  BDWebKit
//
//  Created by li keliang on 2020/4/3.
//

#import "BDWebURLSchemeTaskProxy.h"
#import "BDWebURLSchemeTask.h"
#import "BDWebInterceptor+Private.h"
#import "WKWebView+BDPrivate.h"
#import "BDWebResourceMonitorEventType.h"
#import <ByteDanceKit/BTDMacros.h>
#import "BDWebKitMainFrameModel.h"
#import <objc/runtime.h>

@interface BDWebURLSchemeTaskProxy ()

@property (atomic) BOOL stopped;

@end

@implementation BDWebURLSchemeTaskProxy

#pragma mark - MainFrameRecorder
- (void)webView:(WKWebView *)webView willRecordMainFrameModel:(BDWebURLSchemeTask *)task
{
    BDWebKitMainFrameModel *mainFrameModel = webView.bdw_mainFrameModelRecord;
    if (mainFrameModel == nil) {
        mainFrameModel = [[BDWebKitMainFrameModel alloc] init];
        webView.bdw_mainFrameModelRecord = mainFrameModel;
    }
    mainFrameModel.mainFrameStatus = BDWebKitMainFrameStatusUseSchemeHandler;
    mainFrameModel.loadFinishWithLocalData = task.taskFinishWithLocalData;
    mainFrameModel.mainFrameStatModel = [task.bdw_rlProcessInfoRecord copy];
    if (mainFrameModel.mainFramePerformanceTimingModel == nil) {
        mainFrameModel.mainFramePerformanceTimingModel = [[NSMutableDictionary alloc] init];
    }
    [mainFrameModel.mainFramePerformanceTimingModel addEntriesFromDictionary:[task.bdw_ttnetResponseTimingInfoRecord copy]];
}

#pragma mark - BDWebURLSchemeTaskDelegate

- (void)URLSchemeTask:(BDWebURLSchemeTask *)task didReceiveResponse:(NSURLResponse *)response
{
    // process data before send it to webview
    if (task && task.bdw_responseProcessor) {
        response = task.bdw_responseProcessor(task, response);
    }
    
    btd_dispatch_async_on_main_queue(^{
        if (self.stopped) {
            return;
        }
        [self.target didReceiveResponse:response];
        for (NSObject<BDWebInterceptorMonitor> *monitor in BDWebInterceptor.bdw_globalInterceptorMonitors) {
            if ([monitor respondsToSelector:@selector(bdw_URLSchemeTask:didReceiveResponse:)]) {
                [monitor bdw_URLSchemeTask:task didReceiveResponse:response];
            }
        }
    });
}

- (void)URLSchemeTask:(BDWebURLSchemeTask *)task didLoadData:(NSData *)data
{
    // process data before send it to webview
    if (task && task.bdw_dataProcessor) {
        data = task.bdw_dataProcessor(task, data);
    }
    
    btd_dispatch_async_on_main_queue(^{
        if (self.stopped) {
            return;
        }
        [self.target didReceiveData:data];
        for (NSObject<BDWebInterceptorMonitor> *monitor in BDWebInterceptor.bdw_globalInterceptorMonitors) {
            if ([monitor respondsToSelector:@selector(bdw_URLSchemeTask:didLoadData:)]) {
                [monitor bdw_URLSchemeTask:task didLoadData:data];
            }
        }
    });
}

- (void)URLSchemeTaskDidFinishLoading:(BDWebURLSchemeTask *)task
{
    NSTimeInterval resLoadFinish = [[NSDate date] timeIntervalSince1970];
    task.bdw_rlProcessInfoRecord[kBDWebviewResLoadFinishKey] = @(resLoadFinish * 1000);
    task.bdw_rlProcessInfoRecord[kBDWebviewResStateKey] = @"success";
    
    btd_dispatch_async_on_main_queue(^{
        self.stopped = YES;
        
        if (task.willRecordForMainFrameModel) {
            [self webView:task.bdw_webView willRecordMainFrameModel:task];
        }
        
        [self.target didFinish];
        for (NSObject<BDWebInterceptorMonitor> *monitor in BDWebInterceptor.bdw_globalInterceptorMonitors) {
            if ([monitor respondsToSelector:@selector(bdw_URLSchemeTaskDidFinishLoading:)]) {
                [monitor bdw_URLSchemeTaskDidFinishLoading:task];
            }
        }
    });
}

- (void)URLSchemeTask:(BDWebURLSchemeTask *)task didFailWithError:(NSError *)error
{
    NSTimeInterval resLoadFinish = [[NSDate date] timeIntervalSince1970];
    task.bdw_rlProcessInfoRecord[kBDWebviewResLoadFinishKey] = @(resLoadFinish * 1000);
    task.bdw_rlProcessInfoRecord[kBDWebviewResStateKey] = @"failed";
    task.bdw_rlProcessInfoRecord[kBDWebviewResErrorMsgKey] = error ? error.localizedDescription : @"";
    
    btd_dispatch_async_on_main_queue(^{
        self.stopped = YES;
        
        if (task.willRecordForMainFrameModel) {
            [self webView:task.bdw_webView willRecordMainFrameModel:task];
        }
        
        [self.target didFailWithError:error];
        for (NSObject<BDWebInterceptorMonitor> *monitor in BDWebInterceptor.bdw_globalInterceptorMonitors) {
            if ([monitor respondsToSelector:@selector(bdw_URLSchemeTask:didFailWithError:)]) {
                [monitor bdw_URLSchemeTask:task didFailWithError:error];
            }
        }
    });
}

- (void)URLSchemeTask:(BDWebURLSchemeTask *)task didPerformRedirection:(NSURLResponse *)response newRequest:(NSURLRequest *)request {
    btd_dispatch_async_on_main_queue(^{
        if (self.stopped) {
            return;
        }
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Warc-performSelector-leaks"
        SEL sel = [self.class schemeTaskRedirectionSelector];
        if ([self.target respondsToSelector:sel]) {
            [self.target performSelector:sel withObject:response withObject:request];
        }
#pragma clang diagnostic pop
        for (NSObject<BDWebInterceptorMonitor> *monitor in BDWebInterceptor.bdw_globalInterceptorMonitors) {
            if ([monitor respondsToSelector:@selector(bdw_URLSchemeTask:didPerformRedirection:newRequest:)]) {
                [monitor bdw_URLSchemeTask:task didPerformRedirection:response newRequest:request];
            }
        }
    });
}

+ (SEL)schemeTaskRedirectionSelector {
    // _didPerformRedirection:newRequest:
    NSString *sel = @"_didPerformRedirection:newRequest:";
    return NSSelectorFromString(sel);
}

#pragma mark - Message Forwarding

- (BOOL)respondsToSelector:(SEL)aSelector
{
    if ([_target respondsToSelector:aSelector]) {
        return YES;
    }
    
    return [super respondsToSelector:aSelector];
}

- (id)forwardingTargetForSelector:(SEL)selector {
    return _target;
}

- (void)forwardInvocation:(NSInvocation *)invocation {
    SEL sel = invocation.selector;
    if ([_target respondsToSelector:sel]) {
        [invocation invokeWithTarget:_target];
    }
}

- (NSMethodSignature *)methodSignatureForSelector:(SEL)aSelector {
    __block NSMethodSignature *methodSignature = [NSMethodSignature signatureWithObjCTypes:"@^v^c"];

    if ([_target respondsToSelector:aSelector] && [_target respondsToSelector:@selector(methodSignatureForSelector:)]) {
        methodSignature = [(NSObject *)_target methodSignatureForSelector:aSelector];
    }

    return methodSignature;
}

@end
