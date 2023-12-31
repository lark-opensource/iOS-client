//
//  TTVideoEngineAVAIBarrager.m
//  TTVideoEngine
//
//  Created by haocheng on 2021/10/28.
//

#import "TTVideoEngineAVAIBarrager.h"
#import "TTVideoEngine+Options.h"
#import "TTVideoEngineUtilPrivate.h"

@interface TTVideoEngineAVAIBarrager()

@property (nonatomic, weak)id<TTVideoEngineAIBarrageDelegate> delegate;
@property (nonatomic, weak)TTVideoEngine *engine;

@end

@implementation TTVideoEngineAVAIBarrager

- (instancetype)initWithVideoEngine:(TTVideoEngine *)engine {
    self = [super init];
    if (self) {
        self.engine = engine;
    }
    return self;
}

- (void)onMaskInfoCallBack:(NSString *)svg pts:(NSUInteger)pts {
    BOOL enable = [[self.engine getOptionBykey:@(VEKKeyPlayerAIBarrageEnabled_BOOL)] boolValue];
    if (!enable)
        return;
    if (self.delegate && [self.delegate respondsToSelector:@selector(videoEngine:onBarrageInfoCallBack:pts:)]) {
        [self.delegate videoEngine:self.engine onBarrageInfoCallBack:svg pts:pts];
    }
}

- (void)resetBarrageDelegate:(id<TTVideoEngineAIBarrageDelegate>)delegate {
    self.delegate = delegate;
}

@end
