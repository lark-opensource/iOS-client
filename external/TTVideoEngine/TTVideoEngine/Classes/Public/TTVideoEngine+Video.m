//
//  TTVideoEngine+Video.m
//  TTVideoEngine
//
//  Created by liujiangnan.south on 2020/12/9.
//

#import "TTVideoEngine+Video.h"
#import "TTVideoEngine+Private.h"
#import <TTPlayerSDK/TTPlayerDef.h>

@implementation TTVideoEngine (Video)

- (void)setVideoWrapper:(EngineVideoWrapper *)wrapper {
    [self.player setValueVoidPTR:wrapper forKey:KeyIsVideoWrapperPTR];
}

@end
