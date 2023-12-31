//
//  TTVideoEngine+AsyncInit.h
//  TTVideoEngine
//
//  Created by haocheng on 2021/9/22.
//

#import "TTVideoEngine.h"

NS_ASSUME_NONNULL_BEGIN

@class TTVideoEnginePlayerViewWrapper;

@interface TTVideoEngine (AsyncInit)

/**
 * create player view wrapper instance for TTVideoEngine asynchronously initialize;
 */
+ (TTVideoEnginePlayerViewWrapper *)viewWrapperWithType:(TTVideoEnginePlayerType)type;

/**
 * set up a player view wrapper ins into TTVideoEngine,
 * if you initialize TTVideoEngine with async parameter is YES,
 * must invoked it before anything using.
 */
- (void)setUpPlayerViewWrapper:(TTVideoEnginePlayerViewWrapper *)wrapper;

@end

NS_ASSUME_NONNULL_END
