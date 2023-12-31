//
//  ACCRecordFrameSamplingHandlerProvider.m
//  CameraClient
//
//  Created by limeng on 2020/5/11.
//

#import "ACCRecordFrameSamplingHandlerChain.h"
#import "ACCRecordFrameSamplingStickerHandler.h"
#import "ACCRecordFrameSamplingMusicAItHandler.h"
#import "ACCRecordFrameSamplingDuetHandler.h"

@implementation ACCRecordFrameSamplingHandlerChain

+  (NSArray<ACCRecordFrameSamplingHandlerProtocol> *)loadHandlerChain
{
    return (NSArray<ACCRecordFrameSamplingHandlerProtocol> *)@[
        [[ACCRecordFrameSamplingStickerHandler alloc] init],
        [[ACCRecordFrameSamplingMusicAItHandler alloc] init],
        [[ACCRecordFrameSamplingDuetHandler alloc] init]];
}

@end
