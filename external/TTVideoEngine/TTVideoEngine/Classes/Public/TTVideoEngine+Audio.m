//
//  TTVideoEngine+Audio.m
//  Pods
//
//  Created by guikunzhi on 2019/11/1.
//

#import "TTVideoEngine+Audio.h"
#import "TTVideoEngine+Private.h"
#import <TTPlayerSDK/TTPlayerDef.h>
#import "TTVideoEngineUtilPrivate.h"

@implementation TTVideoEngine (Audio)

- (nullable UIImage *)getCoverImage {
    return [self.player attachedPic];
}

- (void)setAudioProcessor:(EngineAudioWrapper *)wrapper {
    TTVideoEngineLog(@"set audio processor, %p",wrapper);
    [self.player setValueVoidPTR:wrapper forKey:KeyIsAudioProcessWrapperPTR];
}

@end
