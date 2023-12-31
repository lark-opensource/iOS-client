//
//  TTVidoEngineFetcherMaker.m
//  ABRInterface
//
//  Created by kun on 2021/1/19.
//

#import "TTVideoEngineFetcherMaker.h"
#import "TTVideoEnginePlayerDefine.h"
#import "TTVideoEngineMDLFetcher.h"
#import <pthread.h>

@interface TTVideoEngineFetcherMaker () {
    pthread_mutex_t _lock;
}
@end

@implementation TTVideoEngineFetcherMaker

+ (instancetype)instance {
    static dispatch_once_t onceToken;
    static TTVideoEngineFetcherMaker *_instance = nil;
    dispatch_once(&onceToken, ^{
        _instance = [[self alloc] init];
    });
    return _instance;
}

- (instancetype)init {
    if (self = [super init]) {
        pthread_mutex_init(&_lock, NULL);
        _fetcherDelegateList = [NSPointerArray weakObjectsPointerArray];
    }
    return self;
}

- (void)dealloc {
    [_fetcherDelegateList addPointer:NULL];
    [_fetcherDelegateList compact];
    for (int i = 0; i < _fetcherDelegateList.count; i++) {
        [_fetcherDelegateList removePointerAtIndex:i];
    }
    _fetcherDelegateList = nil;
    pthread_mutex_destroy(&_lock);
}

- (void)storeDelegate:(id<TTVideoEngineMDLFetcherDelegate>)delegate {
    if (!delegate) {
        TTVideoEngineLog(@"storeDelegate, fetcherDelegate is null");
        return;
    }
    
    TTVideoEngineLog(@"storeDelegate, delegate:%p", delegate);
    pthread_mutex_lock(&_lock);
    [_fetcherDelegateList addPointer:(__bridge void *)delegate];
    pthread_mutex_unlock(&_lock);
}

- (void)removeDelegate:(id<TTVideoEngineMDLFetcherDelegate>)delegate {
    if (!delegate) {
        TTVideoEngineLog(@"removeDelegate, fetcherDelegate is null");
        return;
    }
    
    TTVideoEngineLog(@"removeDelegate, delegate:%p", delegate);
    pthread_mutex_lock(&_lock);
    [_fetcherDelegateList addPointer:NULL];
    [_fetcherDelegateList compact];
    NSUInteger index = 0;
    NSUInteger count = _fetcherDelegateList.count;
    while (index < count) {
        void *pointer = [_fetcherDelegateList pointerAtIndex:index];
        if (pointer && [(__bridge id<TTVideoEngineMDLFetcherDelegate>)pointer isEqual:delegate]) {
            [_fetcherDelegateList removePointerAtIndex:index];
            break;
        }
        index++;
    }
    pthread_mutex_unlock(&_lock);
}

- (id<TTVideoEngineMDLFetcherDelegate>)getMDLFetcherDelegate:(NSString*)engineId {
    id<TTVideoEngineMDLFetcherDelegate> ret = nil;
    pthread_mutex_lock(&_lock);
    for (int i = 0; i < _fetcherDelegateList.count; i++) {
        void *pointer = [_fetcherDelegateList pointerAtIndex:i];
        if (pointer && [engineId isEqualToString:
                        [(__bridge id<TTVideoEngineMDLFetcherDelegate>)pointer getId]]) {
            ret = (__bridge id<TTVideoEngineMDLFetcherDelegate>)pointer;
            break;
        }
    }
    pthread_mutex_unlock(&_lock);
    return ret;
}


- (id<AVMDLiOSURLFetcherInterface>)getFetcher:(NSString *)rawKey
                                      fileKey:(NSString *)fileKey
                                       oldURL:(NSString *)oldURL
                                     engineId:(NSString *)engineId{
    TTVideoEngineLog(@"getFetcher rawKey: %@, fileKey: %@, oldURL: %@, engineId: %@", rawKey, fileKey, oldURL, engineId);
    
    id<TTVideoEngineMDLFetcherDelegate> fetcherDelegate = [self getMDLFetcherDelegate:engineId];
    
    if (!fetcherDelegate) {
        TTVideoEngineLogE(@"getFetcher, fetcherDelegate is null");
        return nil;
    }
    
    TTVideoEngineMDLFetcher *fetcher = [[TTVideoEngineMDLFetcher alloc] initWithMDLFetcherDelegate:fetcherDelegate];
    TTVideoEngineLog(@"mdlFetch return fetcher to mdl %@", fetcher);
    return fetcher;
}
@end
