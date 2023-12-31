//
//  TTVideoEngineAVAIBarrager.h
//  TTVideoEngine
//
//  Created by haocheng on 2021/10/28.
//

#import <Foundation/Foundation.h>
#import "TTVideoEngine+AIBarrage.h"
#import <TTPlayerSDK/TTAVPlayerMaskInfoInterface.h>

NS_ASSUME_NONNULL_BEGIN

@interface TTVideoEngineAVAIBarrager : NSObject<TTAVPlayerMaskInfoInterface>

- (instancetype)initWithVideoEngine:(TTVideoEngine *)engine;

- (void)onMaskInfoCallBack:(NSString*)svg pts:(NSUInteger)pts;

- (void)resetBarrageDelegate:(id<TTVideoEngineAIBarrageDelegate>)delegate;

@end

NS_ASSUME_NONNULL_END
