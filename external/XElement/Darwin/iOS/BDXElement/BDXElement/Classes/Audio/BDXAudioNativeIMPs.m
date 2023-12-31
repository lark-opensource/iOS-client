//
//  BDXAudioManager.m
//  BDXElement-Pods-Aweme
//
//  Created by DylanYang on 2020/10/30.
//

#import "BDXAudioNativeIMPs.h"

static Class s_audioEventClz;

@implementation BDXAudioNativeIMPs
+ (void)setAudioEventClass:(Class)audioEventClass {
    s_audioEventClz = audioEventClass;
}

+ (Class)audioEventClass {
    return  s_audioEventClz;
}

@end
