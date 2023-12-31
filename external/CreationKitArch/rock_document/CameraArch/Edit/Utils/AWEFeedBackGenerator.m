//
//  AWEFeedBackGenerator.m
//  AWEStudio
//
//  Created by hanxu on 2018/11/25.
//  Copyright © 2018 bytedance. All rights reserved.
//

#import "AWEFeedBackGenerator.h"
#import <AVFoundation/AVFoundation.h>
#import <CreativeKit/UIDevice+ACCHardware.h>

@interface AWEFeedBackGenerator ()

@property (nonatomic, strong) id feedBackGenertor;

@end

@implementation AWEFeedBackGenerator

+ (AWEFeedBackGenerator *)sharedInstance
{
    static dispatch_once_t onceToken;
    static AWEFeedBackGenerator *instance;
    dispatch_once(&onceToken, ^{
        instance = [[AWEFeedBackGenerator alloc] init];
    });
    return instance;
}

- (void)doFeedback
{
    [self doFeedback:UIImpactFeedbackStyleLight];
}

- (void)doFeedback:(UIImpactFeedbackStyle)style
{
    if (@available(iOS 10.0, *)) {
        if ([UIDevice acc_isBetterThanIPhone7]) {
            if (!self.feedBackGenertor) {
                self.feedBackGenertor = [[UIImpactFeedbackGenerator alloc] initWithStyle:style];
            }
            [self.feedBackGenertor impactOccurred];
            return;
        }
    }
    
    AudioServicesPlaySystemSound(kSystemSoundID_Vibrate);
}

@end
