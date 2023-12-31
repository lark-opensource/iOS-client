//
//  TTVideoEngine+AIBarrage.h
//  TTVideoEngine
//
//  Created by haocheng on 2021/10/28.
//

#import "TTVideoEngine.h"

NS_ASSUME_NONNULL_BEGIN

@protocol TTVideoEngineAIBarrageDelegate <NSObject>

- (void)videoEngine:(TTVideoEngine *)videoEngine onBarrageInfoCallBack:(NSString *)content pts:(NSUInteger)pts;

@end

@interface TTVideoEngine()
/* mask info interface*/
@property (nonatomic, weak, nullable) id<TTVideoEngineAIBarrageDelegate> aiBarrageInfoDelegate;

@end


NS_ASSUME_NONNULL_END
