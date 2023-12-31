//
//  WKProcessPoolHook.m
//  LarkRustHTTP
//
//  Created by SolaWing on 2019/3/5.
//

#import <Foundation/Foundation.h>
#import <WebKit/WebKit.h>
#import <objc/runtime.h>

static WKProcessPool* __weak shared;
typedef OS_OBJECT_RETURNS_RETAINED WKProcessPool*(*PoolInit)(WKProcessPool* OS_OBJECT_CONSUMED, SEL);
static PoolInit originInit;

static OS_OBJECT_RETURNS_RETAINED
WKProcessPool* poolSingletonInit(WKProcessPool* OS_OBJECT_CONSUMED self, SEL sel) {
    id v = shared;
    self = originInit(self, sel);
    if (v) {
        //if not call super init, will crash
        return v;
    }
    shared = self;
    return self;
}

void makeWKProcessPoolSingleton(void) {
    // 应该只在主线程上调用，所以没做线程保护
    assert( originInit == nil );
    if (originInit) { return; }

    SEL sel = @selector(init);
    Class cls = objc_getClass("WKProcessPool");
    Method method = class_getInstanceMethod(cls, sel);
    originInit = (void*)method_getImplementation(method);
    class_replaceMethod(cls, sel, (void*)poolSingletonInit, method_getTypeEncoding(method));
}

void resetSharedWKProcessPool(void) {
    shared = NULL;
}

NSError* _Nullable http_objc_catch(void(NS_NOESCAPE ^ _Nonnull action)(void)) {
    @try {
        action();
        return nil;
    }
    @catch (NSException *exception) {
        return [[NSError alloc] initWithDomain: exception.name code:0 userInfo:exception.userInfo];
    }
}
