//
//  TTVideoEnginePool.m
//  Pods
//
//  Created by bytedance on 2022/3/21.
//

#import "TTVideoEnginePool.h"
#import <pthread.h>
#import "TTVideoEngine+Options.h"
#import "TTVideoEngine+Private.h"
#import "TTVideoEngineUtilPrivate.h"

///MARK: NSPointerArray + TTVideoEnginePool
@implementation NSPointerArray (TTVideoEnginePool)
- (BOOL)containsEngineOrNot:(TTVideoEngine *)engine {
    for (int i = 0; i < self.count; i++) {
        void *pointer = [self pointerAtIndex:i];
        if (pointer && [(__bridge TTVideoEngine *)pointer isEqual:engine]) {
            return YES;
        }
    }
    return NO;
}
- (void)removeEngine:(TTVideoEngine *)engine {
    for (int i = 0; i < self.count; i++) {
        void *pointer = [self pointerAtIndex:i];
        if (pointer && [(__bridge TTVideoEngine *)pointer isEqual:engine]) {
            [self removePointerAtIndex:i];
            return;
        }
    }
}
- (void)eliminateNullPointers {
    [self addPointer:NULL];
    [self compact];
}

@end


@interface TTVideoEnginePool () {
    pthread_mutex_t _lock;
    NSMutableArray<TTVideoEngine*> *_engineArray; //存放复用的engine
    NSPointerArray *_resetingEngines; //存放正在reset的engine
    dispatch_queue_t  _taskQueue;
    
    //TTVideoEngineStateMonitor
    pthread_mutex_t _monitorLock;
    NSMutableDictionary<NSNumber*, TTVideoEngineStateWrapper*> *_engineDict; //监测模块监测的所有engine
    NSInteger _playingCount;
    
}
@end

@implementation TTVideoEnginePool

+ (instancetype)instance {
    static dispatch_once_t onceToken;
    static TTVideoEnginePool *_instance = nil;
    dispatch_once(&onceToken, ^{
        _instance = [[self alloc] init];
    });
    return _instance;
}

- (instancetype)init {
    if (self = [super init]) {
        pthread_mutex_init(&_lock, NULL);
        _engineArray = [NSMutableArray array];
        _resetingEngines = [NSPointerArray weakObjectsPointerArray];
        _taskQueue = dispatch_queue_create("vcloud.enginepool.task", DISPATCH_QUEUE_SERIAL);
        _corePoolSizeUpperLimit = 2;
    
        pthread_mutex_init(&_monitorLock, NULL);
        _engineDict = [NSMutableDictionary dictionary];
        _playingCount = 0;
    }
    return self;
}

- (void)dealloc {
    [self releaseCoreEngines];
    _engineArray = nil;
    [_resetingEngines eliminateNullPointers];
    for (int i = 0; i < _resetingEngines.count; i++) {
        [_resetingEngines removePointerAtIndex:i];
    }
    _resetingEngines = nil;
    pthread_mutex_destroy(&_lock);
    
    [_engineDict removeAllObjects];
    _engineDict = nil;
    pthread_mutex_destroy(&_monitorLock);
}

- (void)setCorePoolSizeUpperLimit:(NSInteger)corePoolSizeUpperLimit {
    _corePoolSizeUpperLimit = corePoolSizeUpperLimit;
    TTVideoEngineLog(@"set corePoolSizeUpperLimit = %zd", corePoolSizeUpperLimit);
}

- (TTVideoEngine*)getEngine {
    NSInteger corepoolSizeBeforeGetEngine = _engineArray.count;
    TTVideoEngine* ret = [self _popEngineFromPool];
    if (!ret) {
        ret = [[TTVideoEngine alloc] init];
        [ret setOptionForKey:VEKKeyEnginePoolIsFromEnginePool_NSString value:@"new by EnginePool"];
        TTVideoEngineLog(@"create a new engine by enginepool, engine = %p", ret);
    }
    
    [ret setOptionForKey:VEKKeyEnginePoolCorePoolSizeUpperLimit_NSInteger value:@(_corePoolSizeUpperLimit)];
    [ret setOptionForKey:VEKKeyEnginePoolCorePoolSizeBeforeGetEngine value:@(corepoolSizeBeforeGetEngine)];
    [ret setOptionForKey:VEKKeyEnginePoolCountEngineInUse value:@(_engineDict.count)];
    ret.isGetFromEnginePool = YES;
    return ret;
}

- (TTVideoEngine*)getEngineWithOwnPlayer:(BOOL)isOwnPlayer {
    TTVideoEngine *ret = nil;
    if (!isOwnPlayer) {
        ret = [[TTVideoEngine alloc] initWithOwnPlayer:NO];
    }
    
    NSInteger corepoolSizeBeforeGetEngine = _engineArray.count;
    ret = ret ? : [self _popEngineFromPool];
    if (!ret) {
        ret = [[TTVideoEngine alloc] initWithOwnPlayer:YES];
        [ret setOptionForKey:VEKKeyEnginePoolIsFromEnginePool_NSString value:@"new by EnginePool"];
        TTVideoEngineLog(@"create a new engine by enginepool, engine = %p", ret);
    }
    
    [ret setOptionForKey:VEKKeyEnginePoolCorePoolSizeUpperLimit_NSInteger value:@(_corePoolSizeUpperLimit)];
    [ret setOptionForKey:VEKKeyEnginePoolCorePoolSizeBeforeGetEngine value:@(corepoolSizeBeforeGetEngine)];
    [ret setOptionForKey:VEKKeyEnginePoolCountEngineInUse value:@(_engineDict.count)];
    ret.isGetFromEnginePool = YES;
    return ret;
}

- (TTVideoEngine*)getEngineWithType:(TTVideoEnginePlayerType)type {
    TTVideoEngine *ret = nil;
    if (type == TTVideoEnginePlayerTypeSystem) {
        ret = [[TTVideoEngine alloc] initWithType:TTVideoEnginePlayerTypeSystem];
    }
    
    NSInteger corepoolSizeBeforeGetEngine = _engineArray.count;
    ret = ret ? : [self _popEngineFromPool];
    if (!ret) {
        ret = [[TTVideoEngine alloc] initWithType:type];
        [ret setOptionForKey:VEKKeyEnginePoolIsFromEnginePool_NSString value:@"new by EnginePool"];
        TTVideoEngineLog(@"create a new engine by enginepool, engine = %p", ret);
    }
    
    [ret setOptionForKey:VEKKeyEnginePoolCorePoolSizeUpperLimit_NSInteger value:@(_corePoolSizeUpperLimit)];
    [ret setOptionForKey:VEKKeyEnginePoolCorePoolSizeBeforeGetEngine value:@(corepoolSizeBeforeGetEngine)];
    [ret setOptionForKey:VEKKeyEnginePoolCountEngineInUse value:@(_engineDict.count)];
    ret.isGetFromEnginePool = YES;
    return ret;
}

- (TTVideoEngine*)getEngineWithType:(TTVideoEnginePlayerType)type async:(BOOL)async {
    TTVideoEngine *ret = nil;
    if (type == TTVideoEnginePlayerTypeSystem) {
        ret = [[TTVideoEngine alloc] initWithType:TTVideoEnginePlayerTypeSystem async:async];
    }
    
    NSInteger corepoolSizeBeforeGetEngine = _engineArray.count;
    ret = ret ? : [self _popEngineFromPool];
    if (!ret) {
        ret = [[TTVideoEngine alloc] initWithType:type async:async];
        [ret setOptionForKey:VEKKeyEnginePoolIsFromEnginePool_NSString value:@"new by EnginePool"];
        TTVideoEngineLog(@"create a new engine by enginepool, engine = %p", ret);
    }
    
    [ret setOptionForKey:VEKKeyEnginePoolCorePoolSizeUpperLimit_NSInteger value:@(_corePoolSizeUpperLimit)];
    [ret setOptionForKey:VEKKeyEnginePoolCorePoolSizeBeforeGetEngine value:@(corepoolSizeBeforeGetEngine)];
    [ret setOptionForKey:VEKKeyEnginePoolCountEngineInUse value:@(_engineDict.count)];
    ret.isGetFromEnginePool = YES;
    return ret;
}

- (TTVideoEngine*)_popEngineFromPool {
    TTVideoEngine* ret = nil;
    pthread_mutex_lock(&_lock);
    if (_engineArray.count > 0) {
        ret = [_engineArray lastObject];
        [_engineArray removeObject:ret];
    }
    pthread_mutex_unlock(&_lock);
    
    if (ret) {
        TTVideoEngineLog(@"get an engine from corePool, engine = %p", ret);
        [ret refreshEnginePara];
        [ret setOptionForKey:VEKKeyEnginePoolIsFromEnginePool_NSString value:@"get existing from EnginePool"];
    }
    return ret;
}

- (void)givebackEngine:(TTVideoEngine *)engine {
    if (!engine) {
        TTVideoEngineLog(@"giveback engine return directly because engine is nil");
        return;
    }
    
    pthread_mutex_lock(&_lock);
    if ([_engineArray containsObject:engine] || [_resetingEngines containsEngineOrNot:engine]) {
        //give back same engine return directly
        pthread_mutex_unlock(&_lock);
        TTVideoEngineLog(@"giveback engine return directly because engine has given back before, engine = %p", engine);
        return;
    }
    
    NSInteger count = _engineArray.count;
    pthread_mutex_unlock(&_lock);
    TTVideoEngineLog(@"giveback engine begin, engine = %p", engine);
    if (!engine.isOwnPlayer) {
        if (engine.lastUserAction != TTVideoEngineUserActionStop && engine.lastUserAction != TTVideoEngineUserActionClose) {
            [engine closeAysnc];
        }
        TTVideoEngineLog(@"giveback engine end, ownPlayer close directly, engine = %p", engine);
    } else if (count >= _corePoolSizeUpperLimit) {
        if (engine.lastUserAction != TTVideoEngineUserActionStop && engine.lastUserAction != TTVideoEngineUserActionClose) {
            [engine closeAysnc];
        }
        TTVideoEngineLog(@"giveback engine end, not core engine, close by enginepool, engine = %p", engine);
    } else {
        if (engine.lastUserAction != TTVideoEngineUserActionStop && engine.lastUserAction != TTVideoEngineUserActionClose) {
            [engine stop];
        }
        pthread_mutex_lock(&_lock);
        [_resetingEngines addPointer:(__bridge void* _Nullable)engine];
        pthread_mutex_unlock(&_lock);
        if (engine.lastUserAction != TTVideoEngineUserActionClose || engine.engineCloseIsDone) {
            [self _resetAndGivebackToPoolAsync:engine];
        }
        
    }
}

- (void)_resetAndGivebackToPoolAsync:(TTVideoEngine *)engine {
    dispatch_async(_taskQueue, ^{
        if (!engine) {
            TTVideoEngineLog(@"giveback engine end with nil engine, return");
            return;
        }
        
        [engine resetAllOptions];
        pthread_mutex_lock(&self->_lock);
        [self->_resetingEngines eliminateNullPointers];
        [self->_resetingEngines removeEngine:engine];
        NSInteger count = self->_engineArray.count;
        if (count < self->_corePoolSizeUpperLimit) {
            [self->_engineArray insertObject:engine atIndex:0];
            TTVideoEngineLog(@"giveback engine end, back to corepool, engine = %p", engine);
        } else {
            TTVideoEngineLog(@"giveback engine end, not core engine, return, engine = %p", engine);
        }
        pthread_mutex_unlock(&self->_lock);
    });
}

- (void)engineAsyncCloseDone:(TTVideoEngine *)engine {
    if (!engine) {
        TTVideoEngineLog(@"engineAsyncCloseDone return because engine is nil");
        return;
    }
    pthread_mutex_lock(&_lock);
    if ([self->_resetingEngines containsEngineOrNot:engine]) {
        [self _resetAndGivebackToPoolAsync:engine];
    } else {
        engine.engineCloseIsDone = YES;
        TTVideoEngineLog(@"engineAsyncCloseDone before add engine to core pool, engine = %p", engine);
    }
    pthread_mutex_unlock(&_lock);
}

- (void)releaseCoreEngines {
    pthread_mutex_lock(&_lock);
    NSInteger count = [_engineArray count];
    for (NSInteger i = 0; i < count; i++) {
        TTVideoEngine* engine = _engineArray[i];
        [engine closeAysnc];
    }
    [_engineArray removeAllObjects];
    pthread_mutex_unlock(&_lock);
}

@end


///MARK: TTVideoEngineStateMonitor
@implementation TTVideoEngineStateWrapper
- (instancetype)initWithEngine:(TTVideoEngine *)videoEngine {
    if (self = [super init]) {
        _videoEngine = videoEngine;
        _hasSet = FALSE;
    }
    return self;
}
@end


@implementation TTVideoEnginePool (TTVideoEngineStateMonitor)

- (void)startObserve:(NSUInteger)engineHash engine:(TTVideoEngine *)engine {
    if (!engine) {
        return;
    }
    TTVideoEngineStateWrapper *wrapper = [[TTVideoEngineStateWrapper alloc] initWithEngine:engine];
    
    pthread_mutex_lock(&_monitorLock);
    [_engineDict setObject:wrapper forKey:@(engineHash)];
    pthread_mutex_unlock(&_monitorLock);
}

- (void)stopObserve:(NSUInteger)engineHash {
    pthread_mutex_lock(&_monitorLock);
    [_engineDict removeObjectForKey:@(engineHash)];
    pthread_mutex_unlock(&_monitorLock);
}

- (void)engine:(NSUInteger)engineHash stateChange:(TTVideoEnginePlaybackState)state {
    pthread_mutex_lock(&_monitorLock);
    TTVideoEngineStateWrapper *wrapper = [_engineDict objectForKey:@(engineHash)];
    NSMutableArray *crosstalkEngines = nil;
    if (wrapper) {
        switch (state) {
            case TTVideoEnginePlaybackStatePlaying: {
                if (!wrapper.hasSet) {
                    wrapper.hasSet = TRUE;
                    if (++_playingCount >= 2) {
                        //is crosstalk
                        crosstalkEngines = [NSMutableArray array];
                        NSMutableArray *willRemoveKeys = [NSMutableArray array];
                        [_engineDict enumerateKeysAndObjectsUsingBlock:^(NSNumber *key, TTVideoEngineStateWrapper *obj, BOOL *stop) {
                            //wrapper中的videoEngine是弱引用，需做判空处理
                            if (obj.videoEngine) {
                                if (obj.hasSet) [crosstalkEngines addObject:obj.videoEngine];
                            } else {
                                [willRemoveKeys addObject:key];
                            }
                        }];
                        [_engineDict removeObjectsForKeys:willRemoveKeys];
                    }
                }
                break;
            }
            case TTVideoEnginePlaybackStateStopped:
            case TTVideoEnginePlaybackStatePaused:
            case TTVideoEnginePlaybackStateError: {
                if (wrapper.hasSet) {
                    wrapper.hasSet = FALSE;
                    --_playingCount;
                }
                break;
            }
            default: {
                break;
            }
        }
    }
    pthread_mutex_unlock(&_monitorLock);
    if (crosstalkEngines) {
        for (TTVideoEngine *engine in crosstalkEngines) {
            [engine crosstalkHappen:crosstalkEngines];
        }
    }
}

- (NSArray *)getExistingEnginesInfos {
    NSMutableArray<NSDictionary*> *retInfos = [NSMutableArray array];
    NSDictionary *engineDictCopy = nil;
    pthread_mutex_lock(&_monitorLock);
    engineDictCopy = [_engineDict copy];
    pthread_mutex_unlock(&_monitorLock);
    if ([engineDictCopy count] > 0) {
        [engineDictCopy enumerateKeysAndObjectsUsingBlock:^(NSNumber *key, TTVideoEngineStateWrapper *obj, BOOL *stop) {
            NSDictionary *enginePlayInfo = [obj.videoEngine getEnginePlayInfo];
            if ([enginePlayInfo isKindOfClass:[NSDictionary class]]) {
                [retInfos addObject:enginePlayInfo];
            }
        }];
    }
    return retInfos;
}

@end
