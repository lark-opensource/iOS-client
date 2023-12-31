//
//  BDImageExceptionHandler.m
//  BDWebImage
//
//  Created by 陈奕 on 2020/5/6.
//

#import "BDImageExceptionHandler.h"

@interface BDImageExceptionHandler ()

@property(nonatomic, strong) NSPointerArray *records;
@property (nonatomic, strong, nonnull) dispatch_semaphore_t recordsLock;

@end

@implementation BDImageExceptionHandler

+ (instancetype)sharedHandler {
    static dispatch_once_t onceToken;
    static BDImageExceptionHandler *handler;
    dispatch_once(&onceToken, ^{
        handler = [[BDImageExceptionHandler alloc] init];
    });
    return handler;
}

- (instancetype)init
{
    self = [super init];
    if (self) {
        _records = [NSPointerArray weakObjectsPointerArray];
        _recordsLock = dispatch_semaphore_create(1);
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(applicationDidEnterBackground:) name:UIApplicationDidEnterBackgroundNotification object:nil];
    }
    return self;
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIApplicationDidEnterBackgroundNotification object:nil];
}

- (void)registerRecord:(BDImagePerformanceRecoder *)record {
    if (record != nil) {
        if([self isWeakNet]) {
            record.exceptionType = BDImageExceptionFGWeaknet;
        }
        dispatch_semaphore_wait(_recordsLock, DISPATCH_TIME_FOREVER);
        [_records addPointer:NULL];
        [_records compact];
        [_records addPointer:(__bridge void *)record];
        dispatch_semaphore_signal(_recordsLock);
    }
}

- (BOOL)isWeakNet {
    static Class cls = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        cls = NSClassFromString(@"BDImageNetIndicator");
    });
    if ([cls respondsToSelector:@selector(isWeakNet)]) {
        return [cls performSelector:@selector(isWeakNet)];
    }
    return NO;
}

#pragma mark - UIApplicationDidEnterBackgroundNotification
-(void)applicationDidEnterBackground:(NSNotification *)notification {
    dispatch_semaphore_wait(_recordsLock, DISPATCH_TIME_FOREVER);
    [_records addPointer:NULL];
    [_records compact];
    for (NSUInteger i = 0; i < _records.count; i++) {
        BDImagePerformanceRecoder *record = [_records pointerAtIndex:i];
        if (record.exceptionType == BDImageExceptionFGWeaknet||record.exceptionType == BDImageExceptionBGWeaknet) {
            record.exceptionType = BDImageExceptionBGWeaknet;
        } else {
            record.exceptionType = BDImageExceptionBackground;
        }
    }
    dispatch_semaphore_signal(_recordsLock);
}

@end
