//
//  TTVideoEnginePlayerViewWrapper.m
//  TTVideoEngine
//
//  Created by haocheng on 2021/9/22.
//

#import "TTVideoEnginePlayerViewWrapper.h"
#import "TTVideoEngineOwnPlayerVanGuard.h"
#import "TTVideoEngineMoviePlayerLayerView.h"

@implementation TTVideoEnginePlayerViewWrapper

- (instancetype)initWithType:(TTVideoEnginePlayerType)type {
    self = [super init];
    if (self) {
        self.type = type;
        /** system player */
        if (type == TTVideoEnginePlayerTypeSystem) {
            self.playerView = [[TTVideoEngineMoviePlayerLayerView alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
        }
        
        /** own player */
        else {
            id<TTVideoEngineDualCore> dualCore = [[TTPlayerVanGuardFactory alloc] init];
            UIView<TTPlayerViewProtocol> *playerView = [dualCore viewWithFrame:[[UIScreen mainScreen] bounds]];
            playerView.renderType = TTPlayerViewRenderTypeOpenGLES;
            playerView.rotateType = TTPlayerViewRotateTypeNone;
            playerView.memoryOptimizeEnabled = YES;
            [playerView setOptionForKey:TTPlayerViewHandleBackgroundAvView value:@(YES)];
            self.playerView = playerView;
        }
#ifdef DEBUG
        self.debugView = [[TTVideoEngineLogView alloc] initWithFrame:CGRectMake(0, 0, 300, 400)];
#endif
    }
    return self;
}

@end
