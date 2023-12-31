//
//  ACCDisposable.m
//  CameraClient
//
//  Created by leo on 2019/12/12.
//

#import "ACCDisposable.h"
#import <libkern/OSAtomic.h>

// Copied from  https://github.com/ReactiveCocoa/ReactiveObjC/blob/master/ReactiveObjC/RACDisposable.m

@interface ACCDisposable () {
    void * volatile _disposeBlock;
}

@end

@implementation ACCDisposable
#pragma mark Properties

- (BOOL)isDisposed {
    return _disposeBlock == NULL;
}

#pragma mark Lifecycle

- (instancetype)init {
    self = [super init];

    _disposeBlock = (__bridge void *)self;
    OSMemoryBarrier();

    return self;
}

- (instancetype)initWithBlock:(void (^)(void))block {
    NSCParameterAssert(block != nil);

    self = [super init];

    _disposeBlock = (void *)CFBridgingRetain([block copy]);
    OSMemoryBarrier();

    return self;
}

+ (instancetype)disposableWithBlock:(void (^)(void))block {
    return [(ACCDisposable *)[self alloc] initWithBlock:block];
}

- (void)dealloc {
    if (_disposeBlock == NULL || _disposeBlock == (__bridge void *)self) return;

    CFRelease(_disposeBlock);
    _disposeBlock = NULL;
}

#pragma mark Disposal

- (void)dispose {
    void (^disposeBlock)(void) = NULL;

    while (YES) {
        void *blockPtr = _disposeBlock;
        if (OSAtomicCompareAndSwapPtrBarrier(blockPtr, NULL, &_disposeBlock)) {
            if (blockPtr != (__bridge void *)self) {
                disposeBlock = CFBridgingRelease(blockPtr);
            }

            break;
        }
    }

    if (disposeBlock != nil) disposeBlock();
}


- (ACCScopedDisposable *)asScopedDisposable {
    return [ACCScopedDisposable scopedDisposableWithDisposable:self];
}
@end

@implementation ACCScopedDisposable

+ (instancetype)scopedDisposableWithDisposable:(ACCDisposable *)disposable {
    return [self disposableWithBlock:^{
        [disposable dispose];
    }];
}

- (void)dealloc
{
    [self dispose];
}

#pragma mark ACCDisposable

- (ACCScopedDisposable *)asScopedDisposable {
    // totally already are
    return self;
}
@end
