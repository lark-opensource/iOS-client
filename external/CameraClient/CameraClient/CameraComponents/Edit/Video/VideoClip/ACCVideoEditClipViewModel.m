//
//  ACCVideoEditClipViewModel.m
//  CameraClient-Pods-DouYin
//
//  Created by chengfei xiao on 2020/8/7.
//

#import "ACCVideoEditClipViewModel.h"
#import <CreativeKit/ACCMacros.h>
#import <CreativeKit/NSArray+ACCAdditions.h>

@interface ACCVideoEditClipViewModel()

@property (nonatomic, strong, readwrite) RACSignal *didFinishClipEditSignal;
@property (nonatomic, strong, readwrite) RACSubject *didFinishClipEditSubject;

@property (nonatomic, strong, readwrite) RACSignal *willRemoveAllEditsSignal;
@property (nonatomic, strong, readwrite) RACSubject *willRemoveAllEditsSubject;

@property (nonatomic, strong, readwrite) RACSignal *didRemoveAllEditsSignal;
@property (nonatomic, strong, readwrite) RACSubject *didRemoveAllEditsSubject;

@property (nonatomic, strong, readwrite) RACSignal *removeAllEditsSignal;
@property (nonatomic, strong, readwrite) RACSubject *removeAllEditsSubject;

@property (nonatomic, strong) NSMutableArray<id<ACCEditClipServiceSubscriber>> *subscribers;

@end


@implementation ACCVideoEditClipViewModel

- (void)dealloc
{
    ACCLog(@"%@ dealloc",NSStringFromSelector(_cmd));
    [_didFinishClipEditSubject sendCompleted];
    [_willRemoveAllEditsSubject sendCompleted];
    [_didRemoveAllEditsSubject sendCompleted];
    [_removeAllEditsSubject sendCompleted];
}

#pragma mark - getter

- (RACSignal *)didFinishClipEditSignal
{
    return self.didFinishClipEditSubject;
}

- (RACSubject *)didFinishClipEditSubject
{
    if (!_didFinishClipEditSubject) {
        _didFinishClipEditSubject = [RACSubject subject];
    }
    return _didFinishClipEditSubject;
}

- (RACSignal *)willRemoveAllEditsSignal
{
    return self.didRemoveAllEditsSubject;
}

- (RACSignal *)didRemoveAllEditsSignal
{
    return self.didRemoveAllEditsSubject;
}

- (RACSubject *)willRemoveAllEditsSubject
{
    if (!_willRemoveAllEditsSubject) {
        _willRemoveAllEditsSubject = [RACSubject subject];
    }
    return _willRemoveAllEditsSubject;
}

- (RACSubject *)didRemoveAllEditsSubject
{
    if (!_didRemoveAllEditsSubject) {
        _didRemoveAllEditsSubject = [RACSubject subject];
    }
    return _didRemoveAllEditsSubject;
}

- (RACSignal *)removeAllEditsSignal
{
    return self.removeAllEditsSubject;
}

- (RACSubject *)removeAllEditsSubject
{
    if (!_removeAllEditsSubject) {
        _removeAllEditsSubject = [RACSubject subject];
    }
    return _removeAllEditsSubject;
}

- (NSMutableArray<id<ACCEditClipServiceSubscriber>> *)subscribers
{
    if (!_subscribers) {
        _subscribers = [NSMutableArray array];
    }
    return _subscribers;
}

#pragma mark -

- (void)sendDidFinishClipEditSignal
{
    [self.didFinishClipEditSubject sendNext:nil];
}

- (void)sendWillRemoveAllEditsSignal
{
    [self.subscribers enumerateObjectsUsingBlock:^(id<ACCEditClipServiceSubscriber>  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        [obj willRemoveAllEdits];
    }];
    [self.willRemoveAllEditsSubject sendNext:nil];
}

- (void)sendDidRemoveAllEditsSignal
{
    [self.subscribers enumerateObjectsUsingBlock:^(id<ACCEditClipServiceSubscriber>  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        [obj didRemoveAllEdits];
    }];
    [self.didRemoveAllEditsSubject sendNext:nil];
}

- (void)sendRemoveAllEditsSignal
{
    [self.removeAllEditsSubject sendNext:nil];
}

- (void)addSubscriber:(id<ACCEditClipServiceSubscriber>)subscriber
{
    [self.subscribers acc_addObject:subscriber];
}

@end
