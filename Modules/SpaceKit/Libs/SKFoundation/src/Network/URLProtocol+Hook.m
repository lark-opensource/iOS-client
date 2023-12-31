//
//  URLProtocol+Hook.m
//  SKFoundation
//
//  Created by huangzhikai on 2023/3/30.
//

#import "URLProtocol+Hook.h"
#import <objc/runtime.h>
#import <objc/message.h>
#import "SKFoundation-Swift.h"
#import <HTTProtocol/HTTProtocol-Swift.h>


#pragma mark -- BaseHTTProtocol

@interface BaseHTTProtocol(hook)

+ (void)beginHook;

@end

@implementation BaseHTTProtocol(hook)

//+ (BOOL)canInitWithRequest:(NSURLRequest *)request;
//+ (BOOL)canInitWithTask:(NSURLSessionTask *)task

+ (void)beginHook {
    
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        
        //类方法
        [URLProtocolHook doc_swizzleClass: object_getClass([BaseHTTProtocol class])
                                 selector: @selector(canInitWithRequest:)
                            swizzledClass: object_getClass([self class])
                         swizzledSelector: @selector(docsCanInitWithRequest:)];
        
        [URLProtocolHook doc_swizzleClass: object_getClass([BaseHTTProtocol class])
                                 selector: @selector(canInitWithTask:)
                            swizzledClass: object_getClass([self class])
                         swizzledSelector: @selector(docsCanInitWithTask:)];
        
        //对象方法
        [URLProtocolHook doc_swizzleClass: [BaseHTTProtocol class]
                                 selector: @selector(startLoading)
                            swizzledClass: [self class]
                         swizzledSelector: @selector(docsStartLoading)];
        
        [URLProtocolHook doc_swizzleClass: [BaseHTTProtocol class]
                                 selector: @selector(stopLoading)
                            swizzledClass: [self class]
                         swizzledSelector: @selector(docsStopLoading)];
    });
}

+ (BOOL)docsCanInitWithRequest:(NSURLRequest *)request {
    BOOL result = [self docsCanInitWithRequest: request];
    NSString *info = [NSString stringWithFormat:@"URLProtocolHook ===> %@ canInitWithRequest: %d, currentThread: %@",[self class], result, [NSThread currentThread]];
    [DocsLogger info:info extraInfo:nil error:nil component:nil
             traceId:nil fileName:@"" funcName:@"" funcLine:0];
    return result;
}

+ (BOOL)docsCanInitWithTask:(NSURLSessionTask *)task {
    BOOL result = [self docsCanInitWithTask: task];
    NSString *info = [NSString stringWithFormat:@"URLProtocolHook ===> %@ canInitWithTask: %d, currentThread: %@",[self class], result, [NSThread currentThread]];
    [DocsLogger info:info extraInfo:nil error:nil component:nil
             traceId:nil fileName:@"" funcName:@"" funcLine:0];
    return result;
}

- (void)docsStartLoading {
    NSString *info = [NSString stringWithFormat:@"URLProtocolHook ===> %@ startLoading, currentThread: %@",[self class], [NSThread currentThread]];
    [DocsLogger info:info extraInfo:nil error:nil component:nil
             traceId:nil fileName:@"" funcName:@"" funcLine:0];
    [self docsStartLoading];
}

- (void)docsStopLoading {
    NSString *info = [NSString stringWithFormat:@"URLProtocolHook ===> %@ stopLoading, currentThread: %@",[self class], [NSThread currentThread]];
    [DocsLogger info:info extraInfo:nil error:nil component:nil
             traceId:nil fileName:@"" funcName:@"" funcLine:0];
    [self docsStopLoading];
}


@end

#pragma mark -- NSURLProtocol

@interface NSURLProtocol(hook)

+ (void)beginHook;

@end

@implementation NSURLProtocol(hook)

//- (instancetype)initWithRequest:(NSURLRequest *)request cachedResponse:(nullable NSCachedURLResponse *)cachedResponse client:(nullable id <NSURLProtocolClient>)client NS_DESIGNATED_INITIALIZER;

+ (void)beginHook {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        [URLProtocolHook doc_swizzleClass: [NSURLProtocol class]
                                 selector: @selector(initWithRequest:cachedResponse:client:)
                            swizzledClass: [self class]
                         swizzledSelector: @selector(docsInitWithRequest:cachedResponse:client:)];
    });
}

- (instancetype)docsInitWithRequest:(NSURLRequest *)request
                     cachedResponse:(nullable NSCachedURLResponse *)cachedResponse
                             client:(nullable id <NSURLProtocolClient>)client {
    NSString *info = [NSString stringWithFormat:@"URLProtocolHook ===> %@ docsInitWithRequest, currentThread: %@",[self class], [NSThread currentThread]];
    [DocsLogger info:info extraInfo:nil error:nil component:nil
             traceId:nil fileName:@"" funcName:@"" funcLine:0];
    return [self docsInitWithRequest:request cachedResponse:cachedResponse client:client];
}


@end


#pragma mark -- URLProtocolHook

@implementation URLProtocolHook : NSObject

+ (void)beginHook {
    [BaseHTTProtocol beginHook];
    [NSURLProtocol beginHook];
    
}
+ (BOOL)doc_swizzleClass:(Class)originClass
                selector:(SEL)originSelector
           swizzledClass:(Class)swizzledClass
        swizzledSelector:(SEL)swizzledSelector {
    Method originalMethod = class_getInstanceMethod(originClass, originSelector);
    
    if (!originalMethod) {
        return NO;
    }
    Method swizzledMethod = class_getInstanceMethod(swizzledClass, swizzledSelector);
    if (!swizzledMethod) {
        return NO;
    }

    BOOL didAddMethod = class_addMethod(originClass,
                                        originSelector,
                                        method_getImplementation(swizzledMethod),
                                        method_getTypeEncoding(swizzledMethod));

    if (didAddMethod) {
        class_replaceMethod(originClass,
                            swizzledSelector,
                            method_getImplementation(originalMethod),
                            method_getTypeEncoding(originalMethod));
    } else {
        method_exchangeImplementations(originalMethod, swizzledMethod);
    }

    return YES;
}

@end
