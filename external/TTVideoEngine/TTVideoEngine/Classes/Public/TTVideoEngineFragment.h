//
//  TTVideoEngineFragment.h
//  TTVideoEngine
//
//  Created by shen chen on 2021/7/7.
//

#import <Foundation/Foundation.h>
#import "TTVideoEngine.h"

NS_ASSUME_NONNULL_BEGIN

@protocol TTVideoEngineFragment <NSObject>

- (void)videoEngineDidInit:(TTVideoEngine *)engine;

- (void)videoEngineDidCallPlay:(TTVideoEngine *)engine;

- (void)videoEngineDidPrepared:(TTVideoEngine *)engine;

- (void)videoEngineDidReset:(TTVideoEngine *)engine;

@end

NS_ASSUME_NONNULL_END
