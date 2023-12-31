//
//  ACCDisposable.h
//  CameraClient
//
//  Created by leo on 2019/12/12.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@class ACCScopedDisposable;
@interface ACCDisposable : NSObject
@property (atomic, assign, getter = isDisposed, readonly) BOOL disposed;

+ (instancetype)disposableWithBlock:(void (^)(void))block;
- (void)dispose;

- (ACCScopedDisposable *)asScopedDisposable;
@end

@interface ACCScopedDisposable : ACCDisposable
+ (instancetype)scopedDisposableWithDisposable:(ACCDisposable *)disposable;
@end

NS_ASSUME_NONNULL_END
