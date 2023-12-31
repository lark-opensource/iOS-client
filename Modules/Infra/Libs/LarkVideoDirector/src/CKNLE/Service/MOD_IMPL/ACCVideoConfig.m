//
//  ACCVideoConfig.m
//  Modeo
//
//  Created by 马超 on 2020/12/28.
//

#import "ACCVideoConfig.h"

#import <AWEBaseLib/UIDevice+AWEAdditions.h>
#import <HTSServiceKit/HTSServiceCenter.h>
#import <CameraClient/ACCConfigKeyDefines.h>

static const NSUInteger kAWEStudioMaxVideoDuration = 180; // shoot 3 minutes
const CGFloat kAWEClipVideoInitLimitMaxDuration = 60.0;

@interface ACCVideoConfig ()
@property (nonatomic, assign) ACCRecordLengthMode videoLenthMode;

@property (nonatomic, assign) HTSBeautifyType beautifyType;
@property (nonatomic, assign) NSInteger faceDetectInterval;

@property (nonatomic, assign) double reshapeLevelMax;
@property (nonatomic, assign) double reshapeLevelDefault;

@property (nonatomic, assign) double smoothLevelMax;
@property (nonatomic, assign) double smoothLevelDefault;

@property (nonatomic, assign) double faceLiftValueMax;
@property (nonatomic, assign) double faceLiftValueDefault;

@property (nonatomic, assign) double bigEyeValueMax;
@property (nonatomic, assign) double bigEyeValueDefault;

@property (nonatomic, assign) double lipstickValueMax;
@property (nonatomic, assign) double lipstickValueDefault;

@property (nonatomic, assign) double blusherValueMax;
@property (nonatomic, assign) double blusherValueDefault;

@property (nonatomic, assign) double sharpenValueMax;
@property (nonatomic, assign) double sharpenValueDefault;

@property (nonatomic, assign) NSInteger videoMinSeconds;
@property (nonatomic, assign) NSInteger videoMaxSeconds;
@property (nonatomic, assign) NSInteger longVideoMaxSeconds;
@property (nonatomic, assign) NSInteger standardVideoMaxSeconds;
@property (nonatomic, assign) NSInteger videoSelectableMaxSeconds;
@property (nonatomic, assign) NSInteger videoUploadMaxSeconds;
@property (nonatomic, assign) NSInteger videoFromLvUploadMaxSeconds;
@property (nonatomic, assign) NSInteger musicMaxSeconds;
@property (nonatomic, assign) double longVideoDurationLowerLimit;
@property (nonatomic, assign) BOOL isReshoot;


@end

@implementation ACCVideoConfig

- (instancetype)init
{
    self = [super init];
    if (self) {
        //低端机型没有美颜
        if ([self supportNewBeautify]) {
            self.beautifyType = HTSBeautify612;
        } else {
            self.beautifyType = HTSBeautifyNature;
        }
        
        self.faceDetectInterval = 30;
        self.videoMinSeconds = 1;
        self.videoMaxSeconds = 15;
        self.standardVideoMaxSeconds = 15;
        self.videoSelectableMaxSeconds = 3600;
        self.longVideoDurationLowerLimit = 61.0;

        _smoothLevelMax = 1.0;
        _smoothLevelDefault = 0.5;
        
        _faceLiftValueMax = 1.0;
        _faceLiftValueDefault = 0.5;
        
        _bigEyeValueMax = 1.0;
        _bigEyeValueDefault = 0.3;
        
        _lipstickValueMax = 1.0;
        _lipstickValueDefault = 0.3;
        
        _blusherValueMax = 1.0;
        _blusherValueDefault = 0.2;
        
        _sharpenValueMax = 1.0;
        _sharpenValueDefault = 0.7;
        _isReshoot = NO;
    }
    return self;
}

#pragma mark - private

- (BOOL)supportNewBeautify
{
    static BOOL iOS10To11;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        iOS10To11 = [[[UIDevice currentDevice] systemVersion] compare:@"10.0" options:NSNumericSearch] != NSOrderedAscending;
    });
    
    if (!iOS10To11) {
        return NO;
    }
    
    return ![UIDevice awe_isPoorThanIPhone6S];
}

- (NSInteger)videoUploadMaxSeconds
{
    return 60;
}

- (NSInteger)videoFromLvUploadMaxSeconds
{
    return 60;
}

- (NSInteger)clipVideoInitialMaxSeconds
{
    return kAWEClipVideoInitLimitMaxDuration;
}

- (NSInteger)clipVideoFromLvInitialMaxSeconds
{
    return kAWEClipVideoInitLimitMaxDuration;
}

- (BOOL)isLimitInitialMaxSeconds
{
    return NO;
}

- (BOOL)allowUploadLongVideo
{
    return NO;
}

- (BOOL)needIsLongVideoParameter
{
    return NO;
}

- (BOOL)limitMusicAccordingLongVideo
{
    return NO;
}

- (BOOL)allowUploadSinglePhoto
{
    return YES;
}

- (NSInteger)longVideoMaxSeconds
{
    if (ACCConfigBool(kConfigBool_enable_record_3min_optimize)) {
        return kAWEStudioMaxVideoDuration;
    }

    return 60;
}

- (NSInteger)videoMaxSeconds
{
    if (ACCConfigBool(kConfigBool_enable_record_3min_optimize)) {
        return [self currentVideoMaxSeconds];
    }

    return [self longVideoMaxSeconds];
}

- (NSInteger)currentVideoMaxSeconds
{
    NSInteger maxVideoDurationFromServer = 60;
    NSInteger oneMinutes = maxVideoDurationFromServer > 0 ? maxVideoDurationFromServer : 60;
    NSInteger threeMinutes = 180;
    NSInteger currentMaxSeconds = self.standardVideoMaxSeconds;
    switch ([self currentVideoLenthMode]) {
        case ACCRecordLengthModeStandard:
            currentMaxSeconds = self.isReshoot ? threeMinutes : self.standardVideoMaxSeconds;
            break;
        case ACCRecordLengthMode60Seconds:
            currentMaxSeconds = oneMinutes;
            break;
        case ACCRecordLengthMode3Minutes:
            currentMaxSeconds = threeMinutes;
            break;
        case ACCRecordLengthModeLong:
            currentMaxSeconds = oneMinutes;
            break;

        default:
            break;
    }
    return currentMaxSeconds;
}

#pragma mark - protocol methods

- (ACCRecordLengthMode)currentVideoLenthMode
{
     if (self.videoLenthMode == ACCRecordLengthModeUnknown) {
        self.videoLenthMode = ACCRecordLengthModeStandard;
    }
    return self.videoLenthMode;
}

- (void)updateCurrentVideoLenthMode:(ACCRecordLengthMode)videoLenthMode
{
    //重拍的时候会写死videoLenthMode为ACCRecordLengthModeStandard，这和被重拍的真实值不一致，这里需要做区分，一遍后面返回
    //最大值的时候能够保证是正确的
    //When the remake will write dead video LentMode ACC Record Length Mode Standard, which is not consistent with the real
    //value of the remake, here need to make a distinction, again after the return of the maximum value can be guaranteed to be correct
//    self.isReshoot = isReshoot;
    if (videoLenthMode == ACCRecordLengthModeUnknown) {
        self.videoLenthMode = ACCRecordLengthModeStandard;
    } else {
        self.videoLenthMode = videoLenthMode;
    }
}

- (void)updateCurrentVideoLenthMode:(ACCRecordLengthMode)videoLenthMode isReshoot:(BOOL)isReshoot
{
    //重拍的时候会写死videoLenthMode为ACCRecordLengthModeStandard，这和被重拍的真实值不一致，这里需要做区分，一遍后面返回
    //最大值的时候能够保证是正确的
    //When the remake will write dead video LentMode ACC Record Length Mode Standard, which is not consistent with the real
    //value of the remake, here need to make a distinction, again after the return of the maximum value can be guaranteed to be correct
    self.isReshoot = isReshoot;
    if (videoLenthMode == ACCRecordLengthModeUnknown) {
        self.videoLenthMode = ACCRecordLengthModeStandard;
    } else {
        self.videoLenthMode = videoLenthMode;
    }
}

- (BOOL)enableUploadClientBOE
{
    return false;
}

- (BOOL)showTitleInVideoCameraBottomView
{
    return YES;
}

- (NSInteger)publishMaxTitleLength
{
    return 55;
}

@end
