//
//  TTVideoEnginePool.h
//  Pods
//
//  Created by bytedance on 2022/3/21.
//

#import <Foundation/Foundation.h>
#import "TTVideoEngine.h"
#import "TTVideoEnginePlayerDefine.h"

NS_ASSUME_NONNULL_BEGIN

///MARK: TTVideoEnginePool
@interface TTVideoEnginePool : NSObject
@property(atomic, assign) NSInteger corePoolSizeUpperLimit;  //核心队列最大大小，默认为2

- (instancetype)init NS_UNAVAILABLE;
- (instancetype)new NS_UNAVAILABLE;
+ (instancetype)instance;

- (TTVideoEngine*)getEngine;
- (TTVideoEngine*)getEngineWithOwnPlayer:(BOOL)isOwnPlayer;
- (TTVideoEngine*)getEngineWithType:(TTVideoEnginePlayerType)type;
- (TTVideoEngine*)getEngineWithType:(TTVideoEnginePlayerType)type async:(BOOL)async;
- (void)givebackEngine:(TTVideoEngine*)engine;
- (void)releaseCoreEngines;


- (void)engineAsyncCloseDone:(TTVideoEngine *)engine;
@end


///MARK: TTVideoEngineStateMonitor
/**
 * engine状态监控模块，先放在enginePool里
 */
@interface TTVideoEnginePool (TTVideoEngineStateMonitor)
- (void)startObserve:(NSUInteger)engineHash engine:(TTVideoEngine*)engine;
- (void)stopObserve:(NSUInteger)engineHash;
- (void)engine:(NSUInteger)engineHash stateChange:(TTVideoEnginePlaybackState)state;
- (nullable NSArray<NSDictionary*>*)getExistingEnginesInfos;  //tag,subTag,playbackState,hasLoadingResources
@end

@interface TTVideoEngineStateWrapper : NSObject
@property (nonatomic, weak, nullable) TTVideoEngine *videoEngine;
@property (nonatomic, assign) BOOL hasSet;
- (instancetype)initWithEngine:(TTVideoEngine*)videoEngine;
@end

NS_ASSUME_NONNULL_END
