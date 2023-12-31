//
//  BDTTNetAdapter.m
//  ByteWebView
//
//  Created by Lin Yong on 2019/2/18.
//

#import "BDTTNetAdapter.h"
#import <BDWebCore/IWKUtils.h>
#import <WebKit/WebKit.h>
#import "BDWebViewSchemeTaskHandler.h"
#import <objc/runtime.h>
#import <BDTrackerProtocol/BDTrackerProtocol.h>
#import <BDAlogProtocol/BDAlogProtocol.h>
#import "BDWebViewDebugKit.h"

#define isEmptyString(str) (!str || ![str isKindOfClass:[NSString class]] || str.length == 0)

static NSString * const TAG = @"BDWebView.SchemeHandler";

@interface BDTTNetAdapter ()
@end

@implementation BDTTNetAdapter

- (void)dealloc
{
    
}

static BOOL sIsAsyncWhenHandleSchemeTask = NO;
+ (BOOL)isAsyncWhenHandleSchemeTask {
    return sIsAsyncWhenHandleSchemeTask;
}

+ (void)setIsAsyncWhenHandleSchemeTask:(BOOL)isAsyncWhenHandleSchemeTask {
    sIsAsyncWhenHandleSchemeTask = isAsyncWhenHandleSchemeTask;
}

static NSArray<NSString *> *sSafeHostList;
+ (NSArray<NSString *> *)safeHostList {
    return sSafeHostList;
}

+ (void)setSafeHostList:(NSArray<NSString *> *)safeHostList {
    sSafeHostList = safeHostList;
}

@end
