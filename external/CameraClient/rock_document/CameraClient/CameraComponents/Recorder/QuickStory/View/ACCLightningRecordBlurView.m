//
//  ACCLightningRecordBlurView.m
//  RecordButton
//
//  Created by shaohua yang on 8/3/20.
//  Copyright © 2020 United Nations. All rights reserved.
//

#import "ACCLightningRecordBlurView.h"

static const CGFloat kDiameter1 = 64;
static const CGFloat kDiameter2 = 130;
static const CGFloat kDiameter3 = 100;

@implementation ACCLightningRecordBlurView

@synthesize state = _state;
@synthesize recordMode = _recordMode;

- (instancetype)initWithFrame:(CGRect)frame
{
    if (self = [super initWithEffect:[UIBlurEffect effectWithStyle:UIBlurEffectStyleLight]]) {
        self.frame = CGRectMake(0, 0, kDiameter1, kDiameter1);
        self.layer.cornerRadius = kDiameter1 / 2;
        self.layer.masksToBounds = YES;
    }
    return self;
}

- (void)setState:(ACCRecordButtonState)state
{
    self.hidden = NO;
    switch (state) {
        case ACCRecordButtonBegin: {
            [UIView animateWithDuration:kACCRecordAnimateDuration animations:^{
                self.transform = CGAffineTransformIdentity;
            }];
            break;
        }
        case ACCRecordButtonRecording: {
            [UIView animateWithDuration:kACCRecordAnimateDuration animations:^{
                CGFloat scale = kDiameter2 / kDiameter1;
                self.transform = CGAffineTransformScale(CGAffineTransformIdentity, scale, scale);
            }];
            break;
        }
        case ACCRecordButtonPaused: {
            [UIView animateWithDuration:kACCRecordAnimateDuration animations:^{
                CGFloat scale = kDiameter3 / kDiameter1;
                self.transform = CGAffineTransformScale(CGAffineTransformIdentity, scale, scale);
            }];
            break;
        }
        case ACCRecordButtonPicture: {
            self.transform = CGAffineTransformIdentity;
            self.hidden = YES;
        }
        default:
            break;
    }
    _state = state;
}

@end
