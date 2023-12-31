//
//  ACCLightningRecordRedView.m
//  RecordButton
//
//  Created by shaohua yang on 8/3/20.
//  Copyright © 2020 United Nations. All rights reserved.
//

#import <CreativeKit/UIColor+CameraClientResource.h>

#import "ACCLightningRecordRedView.h"

#import "ACCConfigKeyDefines.h"
#import <CameraClient/ACCRecordMode+LiteTheme.h>

static const CGFloat kDiameter1 = 64; // ACCRecordButtonBegin
static const CGFloat kDiameter2 = 18; // ACCRecordButtonRecording

@implementation ACCLightningRecordRedView

@synthesize state = _state;
@synthesize recordMode = _recordMode;

- (instancetype)initWithFrame:(CGRect)frame
{
    if (self = [super initWithFrame:CGRectMake(0, 0, kDiameter1, kDiameter1)]) {
        self.backgroundColor = ACCResourceColor(ACCUIColorConstPrimary);
        self.layer.cornerRadius = kDiameter1 / 2;
        self.userInteractionEnabled = NO;
    }
    return self;
}

- (void)setState:(ACCRecordButtonState)state
{
    self.backgroundColor = (self.idleColor ?: ACCResourceColor(ACCUIColorConstPrimary));
    self.hidden = (self.recordMode.modeId == ACCRecordModeLivePhoto);
    self.alpha = 1;

    switch (state) {
        case ACCRecordButtonBegin: {
            if (self.recordMode.isStoryStyleMode && ACCConfigBool(kConfigBool_white_lightning_shoot_button)) {
                self.backgroundColor = [UIColor whiteColor];
            }
            self.layer.affineTransform = CGAffineTransformIdentity;
            self.layer.bounds = CGRectMake(0, 0, kDiameter1, kDiameter1);
            self.layer.cornerRadius = kDiameter1 / 2;
            break;
        }
        case ACCRecordButtonRecording: {
            if (self.hideWhenRecording) {
                self.hidden = YES;
                break;
            }

            [CATransaction begin];
            [CATransaction setAnimationDuration:kACCRecordAnimateDuration];

            // _centerLayer 64x64 circle -> 18x18 rect, cornerRadius=4
            self.layer.affineTransform = CGAffineTransformIdentity;
            CABasicAnimation *cornerRadius = [CABasicAnimation animationWithKeyPath:@"cornerRadius"];
            cornerRadius.fromValue = @(self.layer.cornerRadius);
            self.layer.cornerRadius = 4;
            cornerRadius.toValue = @(self.layer.cornerRadius);
            [self.layer addAnimation:cornerRadius forKey:@"cornerRadius"];

            CABasicAnimation *bounds = [CABasicAnimation animationWithKeyPath:@"bounds"];
            bounds.fromValue = [NSValue valueWithCGRect:self.layer.bounds];
            self.layer.bounds = CGRectMake(0, 0, kDiameter2, kDiameter2);
            bounds.toValue = [NSValue valueWithCGRect:self.layer.bounds];
            [self.layer addAnimation:bounds forKey:@"bounds"];

            [CATransaction commit];
            break;
        }
        case ACCRecordButtonPaused: {
            self.layer.affineTransform = CGAffineTransformIdentity;
            self.hidden = YES;
            break;
        }
        case ACCRecordButtonPicture: {
            self.backgroundColor = [UIColor whiteColor];
            break;
        }
        default:
            break;
    }
    _state = state;
}

- (void)setIdleColor:(UIColor *)idleColor
{
    _idleColor = idleColor;
    self.backgroundColor = idleColor;
}

@end
