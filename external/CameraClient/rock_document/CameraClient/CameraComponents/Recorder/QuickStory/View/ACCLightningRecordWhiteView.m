//
//  ACCLightningRecordWhiteView.m
//  RecordButton
//
//  Created by shaohua yang on 8/3/20.
//  Copyright © 2020 United Nations. All rights reserved.
//

#import "ACCLightningRecordWhiteView.h"

static const CGFloat kDiameter1 = 64; // ACCRecordButtonBegin
static const CGFloat kDiameter2 = 46; // ACCRecordButtonRecording
static const CGFloat kDiameter3 = 56; // ACCRecordButtonPaused

@implementation ACCLightningRecordWhiteView

@synthesize state = _state;
@synthesize recordMode = _recordMode;

- (instancetype)initWithFrame:(CGRect)frame
{
    if (self = [super initWithFrame:CGRectMake(0, 0, kDiameter1, kDiameter1)]) {
        self.backgroundColor = [UIColor whiteColor];
        self.layer.cornerRadius = kDiameter1 / 2;
    }
    return self;
}

- (void)setState:(ACCRecordButtonState)state
{
    self.hidden = NO;
    switch (state) {
        case ACCRecordButtonBegin: {
            [UIView animateWithDuration:kACCRecordAnimateDuration animations:^{
                self.layer.affineTransform = CGAffineTransformIdentity;
            }];
            break;
        }
        case ACCRecordButtonRecording: {
            [UIView animateWithDuration:kACCRecordAnimateDuration animations:^{
                CGFloat scale = kDiameter2 / kDiameter1;
                self.layer.affineTransform = CGAffineTransformScale(CGAffineTransformIdentity, scale, scale);
            }];
            break;
        }
        case ACCRecordButtonPaused: {
            [UIView animateWithDuration:kACCRecordAnimateDuration animations:^{
                CGFloat scale = kDiameter3 / kDiameter1;
                self.layer.affineTransform = CGAffineTransformScale(CGAffineTransformIdentity, scale, scale);
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
