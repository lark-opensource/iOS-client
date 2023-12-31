//
//  IESBlockDisposable.m
//  IESInject-Pods-Aweme
//
//  Created by bytedance on 2021/7/4.
//

#import "IESBlockDisposable.h"
#import "IESContainer+Private.h"

@interface IESBlockDisposable()

@property (atomic, assign, getter = isDisposed, readwrite) BOOL disposed;
@property (nonatomic, copy, readwrite) IESServiceResponeseBlock block;
@property (nonatomic, copy, readwrite) NSString *relatedServiceKey;
@property (nonatomic, weak) IESContainer *serviceContainer;

@end

@implementation IESBlockDisposable

- (void)dealloc
{
    [self dispose];
}

- (instancetype)initWithBlock:(IESServiceResponeseBlock)block serviceKey:(nonnull NSString *)relatedServiceKey serviceContainer:(nonnull IESContainer *)container
{
    if (self = [super init]) {
        _block = [block copy];
        _disposed = NO;
        _relatedServiceKey = relatedServiceKey;
        _serviceContainer = container;
    }
    return self;
}

- (void)dispose
{
    if (!self.disposed) {
        [self.serviceContainer removeBlockNeedServiceResponse:self withRelatedServiceKey:self.relatedServiceKey];
        self.disposed = YES;
    }
}



@end
