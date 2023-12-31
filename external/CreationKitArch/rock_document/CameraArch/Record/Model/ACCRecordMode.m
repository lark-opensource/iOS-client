//
//  ACCRecordMode.m
//  CameraClient-Pods-Aweme
//
//  Created by yangying on 2020/11/26.
//

#import "ACCRecordMode.h"

// Don't take the number 0
ACCRecordModeIdentifier const ACCRecordModeTakePicture = 1;
ACCRecordModeIdentifier const ACCRecordModeLive = 2;
ACCRecordModeIdentifier const ACCRecordModeMixHoldTapRecord = 3; // Take a video
ACCRecordModeIdentifier const ACCRecordModeMV = 4;
ACCRecordModeIdentifier const ACCRecordModeMixHoldTap15SecondsRecord = 5; // Multi shot - 15s
ACCRecordModeIdentifier const ACCRecordModeMixHoldTapLongVideoRecord = 6; // Multi shot - 60s
ACCRecordModeIdentifier const ACCRecordModeStory = 7; // Quick shot
ACCRecordModeIdentifier const ACCRecordModeCombined = 8; // Multi shot
ACCRecordModeIdentifier const ACCRecordModeText = 9;
ACCRecordModeIdentifier const ACCRecordModeMixHoldTap60SecondsRecord = 10;
ACCRecordModeIdentifier const ACCRecordModeMixHoldTap3MinutesRecord = 11;
ACCRecordModeIdentifier const ACCRecordModeStoryCombined = 12; // Snapshot with sub modes
ACCRecordModeIdentifier const ACCRecordModeMiniGame = 13; // Games
ACCRecordModeIdentifier const ACCRecordModeKaraoke = 14; // Karaoke
ACCRecordModeIdentifier const ACCRecordModeCreatorPreview = 15;
ACCRecordModeIdentifier const ACCRecordModeLivePhoto = 16;
ACCRecordModeIdentifier const ACCRecordModeTheme = 17; // lite theme mode
ACCRecordModeIdentifier const ACCRecordModeDuet = 18; //duet and sing tab
ACCRecordModeIdentifier const ACCRecordModeAudio = 19;

@implementation ACCRecordMode

- (NSUInteger)hash
{
    return self.modeId;
}

- (BOOL)isEqual:(id)object
{
    if (object == nil || ![object isKindOfClass:[ACCRecordMode class]]) {
        return NO;
    }
    
   ACCRecordMode *otherMode = (ACCRecordMode *)object;
    return self.modeId == otherMode.modeId;
}

- (void)setIsExclusive:(BOOL)isExclusive
{
    _isExclusive = isExclusive;
    self.isInitial = YES;
}

@end
