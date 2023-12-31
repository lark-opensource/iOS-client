//
//  TTVideoEngineFragmentLoader.h
//  TTVideoEngine
//
//  Created by shen chen on 2021/7/8.
//

#import <Foundation/Foundation.h>
#import "TTVideoEngine.h"

NS_ASSUME_NONNULL_BEGIN

@interface TTVideoEngineFragmentLoader : NSObject

- (void)loadFragmentWithList:(NSArray <NSString *> *)fragmentList;

- (void)unLoadFragment;

- (void)videoEngineDidCallPlay:(TTVideoEngine *)engine;

- (void)videoEngineDidPrepared:(TTVideoEngine *)engine;

- (void)videoEngineDidReset:(TTVideoEngine *)engine;

- (void)videoEngineDidInit:(TTVideoEngine *)engine;

@end

NS_ASSUME_NONNULL_END
