//
//  category.m
//  AudioSessionTesting
//
//  Created by lvdaqian on 2019/7/16.
//  Copyright © 2019 cn.lvdaqian. All rights reserved.
//
#import <AVFoundation/AVFoundation.h>
@implementation AVAudioSession(debuging)

+ (void)load {
    SEL selector = NSSelectorFromString(@"swizzled");
    if ([self respondsToSelector: selector]) {
        [self performSelector:selector];
    }
}

@end
