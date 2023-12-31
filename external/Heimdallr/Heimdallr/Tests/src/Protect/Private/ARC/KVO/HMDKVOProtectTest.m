//
//  HMDProtectUnrecognizedSelectorTest.m
//  HeimdallrDemoTests
//
//  Created by bytedance on 2020/8/4.
//  Copyright © 2020 sunrunwang. All rights reserved.
//

#import <XCTest/XCTest.h>
#import "HMDProtector.h"
#import "HMDDynamicCall.h"
#import "HMDSwizzle.h"
#import "HMDProtect_Private.h"

@interface THIS_IS_Observee_Class : NSObject
@property(nonatomic) NSUInteger value;
@end @implementation THIS_IS_Observee_Class
- (void)observeValueForKeyPath:(NSString *)keyPath
                      ofObject:(id)object
                        change:(NSDictionary<NSKeyValueChangeKey,id> *)change
                       context:(void *)context {} @end

static THIS_IS_Observee_Class *shared_observee;

static BOOL receive_10086 = NO;


@interface THIS_IS_Observer_Class : NSObject
@property(nonatomic) NSUInteger value;
@end @implementation THIS_IS_Observer_Class
- (void)observeValueForKeyPath:(NSString *)keyPath
                      ofObject:(id)object
                        change:(NSDictionary<NSKeyValueChangeKey,id> *)change
                       context:(void *)context {
    if([keyPath isEqualToString:@"value"]) {
        NSUInteger value = DC_IS([change valueForKey:NSKeyValueChangeNewKey], NSNumber).unsignedIntegerValue;
        if(value == 10086) {
            Class thisClass = object_getClass(self);
            XCTAssert(thisClass != THIS_IS_Observer_Class.class);
            XCTAssert(class_getSuperclass(thisClass) == THIS_IS_Observer_Class.class);
            receive_10086 = YES;
        }
    }
}

- (void)dealloc {
    shared_observee.value = 10086;
}

@end

@class YYYObserver;

static int _ObserverKey;

@class YYYObserver;

static int _ObserverKey;

@interface YYYObservee : NSObject

@property (nonatomic, assign) int count;
@property (nonatomic, strong) YYYObserver *observer;

@end

@implementation YYYObservee

- (void)setObserver:(YYYObserver *)observer {
    objc_setAssociatedObject(self, &_ObserverKey, observer, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (void)dealloc {
    NSLog(@"YYYObservee dealloc");
}

@end

@interface YYYObserver : NSObject {
__unsafe_unretained YYYObservee *_observee;
}

@end

@implementation YYYObserver : NSObject

- (instancetype)initWithObservee:(YYYObservee *)observee {
    if (self = [super init]) {
        _observee = observee;
        [_observee addObserver:self forKeyPath:@"count" options:NSKeyValueObservingOptionNew context:nil];
    }
    return self;
}

- (void)dealloc {
    NSLog(@"YYYObserver dealloc");
    if (_observee) {
        [_observee removeObserver:self forKeyPath:@"count"];
    }
    _observee = nil;
}

@end


@interface HMDKVOProtectTest : XCTestCase

@end

@implementation HMDKVOProtectTest

+ (void)setUp {
    HMD_mockClassTreeForClassMethod(HeimdallrUtilities, canFindDebuggerAttached, ^(Class aClass){return NO;});
    HMDProtectTestEnvironment = YES;
    [HMDProtector.sharedProtector turnProtectionsOn:HMDProtectionTypeKVO];
    HMDProtector.sharedProtector.ignoreTryCatch = NO;
}

+ (void)tearDown {
    HMDProtectTestEnvironment = NO;
    [HMDProtector.sharedProtector turnProtectionOff:HMDProtectionTypeAll];
    HMDProtector.sharedProtector.ignoreTryCatch = YES;
    
}

- (void)testRemoveObserverDuringDealloc {
# if __arm64__
    if (@available(iOS 11.3, *)) {
        __block BOOL hasException = NO;
        dispatch_semaphore_t semaphore = dispatch_semaphore_create(0);
        [HMDProtector.sharedProtector registerIdentifier:@"Heimdallr_KVO_Test" withBlock:^(HMDProtectCapture * _Nonnull capture) {
            hasException = YES;
            NSLog(@"hasException");
            dispatch_semaphore_signal(semaphore);
        }];
        XCTestExpectation *expectation = [self expectationWithDescription:@"KVO should not raise a protector exception"];
        @autoreleasepool {
            __autoreleasing YYYObservee *observee = [[YYYObservee alloc] init];
            {
                YYYObserver *observer = [[YYYObserver alloc] initWithObservee:observee];
                observee.observer = observer;
                observer = nil;
            }
        }
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            dispatch_semaphore_wait(semaphore, dispatch_time(DISPATCH_TIME_NOW, (int64_t)(3.0 * NSEC_PER_SEC)));
            XCTAssertTrue(hasException == NO, @"KVOProtector: Shoud not raise a protector exception");
            NSLog(@"fulfill");
            [expectation fulfill];
        });
        [self waitForExpectationsWithTimeout:5 handler:nil];
    }
# endif
}

- (void)wrapObservee:(THIS_IS_Observee_Class *)observee {
    THIS_IS_Observer_Class *observer = THIS_IS_Observer_Class.new;
    
    [observee addObserver:observer
               forKeyPath:@"value"
                  options:NSKeyValueObservingOptionNew
                  context:NULL];
    
    [observer addObserver:self
               forKeyPath:@"value"
                  options:NSKeyValueObservingOptionNew
                  context:NULL];
}

- (void)wrapper {
    THIS_IS_Observee_Class *observee = THIS_IS_Observee_Class.new;
    shared_observee = observee;
    
    receive_10086 = NO;
    [self wrapObservee:observee];
    XCTAssert(receive_10086);
}

- (void)test_observer_isa_hooked {
    #if __arm64__ && __LP64__
    [self wrapper];
    #endif
}

- (void)observeValueForKeyPath:(NSString *)keyPath
                      ofObject:(id)object
                        change:(NSDictionary<NSKeyValueChangeKey,id> *)change
                       context:(void *)context {
}

@end
