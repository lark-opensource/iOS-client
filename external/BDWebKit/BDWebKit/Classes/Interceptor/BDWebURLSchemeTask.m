//
//  BDWebURLSchemeTask.m
//  BDWebKit
//
//  Created by li keliang on 2020/3/13.
//

#import "BDWebURLSchemeTask.h"
#import <objc/runtime.h>
#import <objc/message.h>

@implementation BDWebURLSchemeTask

@synthesize taskFinishWithLocalData;
@synthesize taskFinishWithTTNet;
@synthesize useTTNetCommonParams;
@synthesize ttnetEnableCustomizedCookie;
@synthesize willRecordForMainFrameModel;
@synthesize taskHttpCachePolicy;
@synthesize bdw_shouldUseNetReuse;

- (WKWebView *)bdw_webView
{
    id(^blk)(void) = objc_getAssociatedObject(self, _cmd);
    return blk ? blk() : nil;
}

- (void)setBdw_webView:(WKWebView *)bdw_webView
{
    BOOL (*allowsWeakReference)(id, SEL) =
        (BOOL(*)(id, SEL))
        class_getMethodImplementation([bdw_webView class],
                                       @selector(allowsWeakReference));
    __unsafe_unretained WKWebView *tmpWebView = bdw_webView;
    if (allowsWeakReference && (IMP)allowsWeakReference != _objc_msgForward) {
        BOOL deallocating =
            ! (*allowsWeakReference)(bdw_webView, @selector(allowsWeakReference));
        // 尝试修复webView在deallocating中被赋值给weak指针的问题
        if (deallocating) {
            tmpWebView = nil;
        }
    }
    __weak WKWebView *weakWebView = tmpWebView;
    objc_setAssociatedObject(self, @selector(bdw_webView), (id)^(void){ return weakWebView; } , OBJC_ASSOCIATION_COPY_NONATOMIC);
}

- (void)bdw_didReceiveResponse:(NSURLResponse *)response
{
    // notify lifecycle delegate
    if ([self.bdw_lifecycleDelegate respondsToSelector:@selector(URLSchemeTask:didReceiveResponse:)]) {
        [self.bdw_lifecycleDelegate URLSchemeTask:self didReceiveResponse:response];
    }
    
    if (!self.taskHasFinishOrFail && [_delegate respondsToSelector:@selector(URLSchemeTask:didReceiveResponse:)]) {
        [_delegate URLSchemeTask:self didReceiveResponse:response];
    }
    
    if (@available(iOS 12.0, *)) {
        if (!self.taskHasFinishOrFail && [self.bdw_webView.bdw_interceptorMonitor respondsToSelector:@selector(bdw_URLSchemeTask:didReceiveResponse:)]) {
            [self.bdw_webView.bdw_interceptorMonitor bdw_URLSchemeTask:self didReceiveResponse:response];
        }
    }
}

- (void)bdw_didLoadData:(NSData *)data
{
    // notify lifecycle delegate
    if ([self.bdw_lifecycleDelegate respondsToSelector:@selector(URLSchemeTask:didLoadData:)]) {
        [self.bdw_lifecycleDelegate URLSchemeTask:self didLoadData:data];
    }
    
    if (!self.taskHasFinishOrFail && [_delegate respondsToSelector:@selector(URLSchemeTask:didLoadData:)]) {
        if (@available(iOS 12.0, *)) {
            if (self.canHandle) {
                [self.bdw_webView.bdw_interceptorHandler bdw_URLSchemeTask:self didLoadData:data];
            } else {
                [_delegate URLSchemeTask:self didLoadData:data];
            }
        } else {
            [_delegate URLSchemeTask:self didLoadData:data];
        }
    }
    
    if (@available(iOS 12.0, *)) {
        if (!self.taskHasFinishOrFail && [self.bdw_webView.bdw_interceptorMonitor respondsToSelector:@selector(bdw_URLSchemeTask:didLoadData:)]) {
            [self.bdw_webView.bdw_interceptorMonitor bdw_URLSchemeTask:self didLoadData:data];
        }
    }
}

- (void)bdw_didFinishLoading
{
    // notify lifecycle delegate
    if ([self.bdw_lifecycleDelegate respondsToSelector:@selector(URLSchemeTaskDidFinishLoading:)]) {
        [self.bdw_lifecycleDelegate URLSchemeTaskDidFinishLoading:self];
    }
    
    if(!self.taskHasFinishOrFail) {
        if (@available(iOS 12.0, *)) {
            if (self.canHandle) {
                [self.bdw_webView.bdw_interceptorHandler bdw_URLSchemeTaskDidFinishLoading:self];
            } else {
                if ([_delegate respondsToSelector:@selector(URLSchemeTaskDidFinishLoading:)]) {
                    [_delegate URLSchemeTaskDidFinishLoading:self];
                }
            }
        } else {
            if ([_delegate respondsToSelector:@selector(URLSchemeTaskDidFinishLoading:)]) {
                [_delegate URLSchemeTaskDidFinishLoading:self];
            }
        }
        
        if (@available(iOS 12.0, *)) {
            if (!self.taskHasFinishOrFail && [self.bdw_webView.bdw_interceptorMonitor respondsToSelector:@selector(bdw_URLSchemeTaskDidFinishLoading:)]) {
                [self.bdw_webView.bdw_interceptorMonitor bdw_URLSchemeTaskDidFinishLoading:self];
            }
        }
        
        self.taskHasFinishOrFail = YES;
    }
}

- (void)bdw_didFailWithError:(NSError *)error
{
    // notify lifecycle delegate
    if ([self.bdw_lifecycleDelegate respondsToSelector:@selector(URLSchemeTask:didFailWithError:)]) {
        [self.bdw_lifecycleDelegate URLSchemeTask:self didFailWithError:error];
    }
    
    if(!self.taskHasFinishOrFail) {
        if (@available(iOS 12.0, *)) {
            if ([self.bdw_webView.bdw_interceptorMonitor respondsToSelector:@selector(bdw_URLSchemeTask:didFailWithError:)]) {
                [self.bdw_webView.bdw_interceptorMonitor bdw_URLSchemeTask:self didFailWithError:error];
            }
        }
        
        if ([_delegate respondsToSelector:@selector(URLSchemeTask:didFailWithError:)]) {
            [_delegate URLSchemeTask:self didFailWithError:error];
        }
        self.taskHasFinishOrFail = YES;
    }
}

- (void)bdw_didPerformRedirection:(NSURLResponse *)response newRequest:(NSURLRequest *)request
{
    // notify lifecycle delegate
    if ([self.bdw_lifecycleDelegate respondsToSelector:@selector(URLSchemeTask:didPerformRedirection:newRequest:)]) {
        [self.bdw_lifecycleDelegate URLSchemeTask:self didPerformRedirection:response newRequest:request];
    }
    
    if (!self.taskHasFinishOrFail && [_delegate respondsToSelector:@selector(URLSchemeTask:didPerformRedirection:newRequest:)]) {
        [_delegate URLSchemeTask:self didPerformRedirection:response newRequest:request];
    }
    
    if (@available(iOS 12.0, *)) {
        if (!self.taskHasFinishOrFail && [self.bdw_webView.bdw_interceptorMonitor respondsToSelector:@selector(bdw_URLSchemeTask:didPerformRedirection:newRequest:)]) {
            [self.bdw_webView.bdw_interceptorMonitor bdw_URLSchemeTask:self didPerformRedirection:response newRequest:request];
        }
    }
}

@end
