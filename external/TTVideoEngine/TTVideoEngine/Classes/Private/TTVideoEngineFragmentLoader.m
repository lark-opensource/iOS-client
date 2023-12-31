//
//  TTVideoEngineFragmentLoader.m
//  TTVideoEngine
//
//  Created by shen chen on 2021/7/8.
//

#import "TTVideoEngineFragmentLoader.h"
#import "TTVideoEngineFragment.h"

@interface TTVideoEngineFragmentLoader()

@property(nonatomic, strong) NSMutableArray<TTVideoEngineFragment> *fragments;

@end

@implementation TTVideoEngineFragmentLoader

- (void)loadFragmentWithList:(NSArray<NSString *> *)fragmentList {
    if (fragmentList == NULL || fragmentList.count == 0) {
        return;
    }
    if (self.fragments == nil) {
        self.fragments = (NSMutableArray<TTVideoEngineFragment> *)[NSMutableArray arrayWithCapacity:1];
    }
    for (NSString *it in fragmentList) {
        Class clz = NSClassFromString([NSString stringWithFormat:@"TTVideoEngine%@Fragment", it]);
        if (!clz) {
            continue;
        }
        SEL selector = @selector(fragmentInstance);
        if (![clz respondsToSelector:selector]) {
            continue;
        }
        NSMethodSignature *signature = [clz methodSignatureForSelector:selector];
        NSInvocation *invocation = [NSInvocation invocationWithMethodSignature:signature];
        [invocation setSelector:selector];
        [invocation setTarget:clz];
        [invocation invoke];
        void *returnValue;
        [invocation getReturnValue:&returnValue];
        id<TTVideoEngineFragment> fragment = (__bridge id<TTVideoEngineFragment>)returnValue;
        [self.fragments addObject:fragment];
    }
}

- (void)unLoadFragment {
    [self.fragments removeAllObjects];
}

- (void)videoEngineDidCallPlay:(TTVideoEngine *)engine {
    [self.fragments enumerateObjectsUsingBlock:^(id  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        id<TTVideoEngineFragment> fragment = obj;
        if ([fragment respondsToSelector:@selector(videoEngineDidCallPlay:)]) {
            [fragment videoEngineDidCallPlay:engine];
        }
    }];
}

- (void)videoEngineDidPrepared:(TTVideoEngine *)engine {
    [self.fragments enumerateObjectsUsingBlock:^(id  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        id<TTVideoEngineFragment> fragment = obj;
        if ([fragment respondsToSelector:@selector(videoEngineDidPrepared:)]) {
            [fragment videoEngineDidPrepared:engine];
        }
    }];
}

- (void)videoEngineDidReset:(TTVideoEngine *)engine {
    [self.fragments enumerateObjectsUsingBlock:^(id  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        id<TTVideoEngineFragment> fragment = obj;
        if ([fragment respondsToSelector:@selector(videoEngineDidReset:)]) {
            [fragment videoEngineDidReset:engine];
        }
    }];
}

- (void)videoEngineDidInit:(TTVideoEngine *)engine {
    [self.fragments enumerateObjectsUsingBlock:^(id  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        id<TTVideoEngineFragment> fragment = obj;
        if ([fragment respondsToSelector:@selector(videoEngineDidInit:)]) {
            [fragment videoEngineDidInit:engine];
        }
    }];
}

@end
