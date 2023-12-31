//
//  ACCLightningRecordAnimatable.h
//  RecordButton
//
//  Created by shaohua yang on 8/3/20.
//  Copyright © 2020 United Nations. All rights reserved.
//

#import <QuartzCore/QuartzCore.h>
#import <UIKit/UIKit.h>
#import <CreationKitArch/ACCRecordMode.h>

NS_ASSUME_NONNULL_BEGIN

extern const NSTimeInterval kACCRecordAnimateDuration;

typedef NS_ENUM(NSInteger, ACCRecordButtonState) {
    ACCRecordButtonBegin,
    ACCRecordButtonRecording,
    ACCRecordButtonPaused,
    ACCRecordButtonPicture,
};

@protocol ACCLightningRecordAnimatable <NSObject>

@property (nonatomic, assign) ACCRecordButtonState state;
@property (nonatomic, strong) ACCRecordMode *recordMode;

@end

NS_ASSUME_NONNULL_END
