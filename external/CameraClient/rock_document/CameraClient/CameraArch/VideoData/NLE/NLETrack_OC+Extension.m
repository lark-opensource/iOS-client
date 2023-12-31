//
//  NLETrack_OC+Extension.m
//  CameraClient-Pods-Aweme
//
//  Created by geekxing on 2021/1/19.
//

#import "NLETrack_OC+Extension.h"
#import "NLETrackSlot_OC+Extension.h"
#import <CreativeKit/NSArray+ACCAdditions.h>
#import <NLEPlatform/NLETrackMV+iOS.h>

static NSString *const kAudioTrackTag = @"kAudioTrackTag";
static NSString *const kAudioTrackTagBGM = @"kAudioTrackTagBGM";
static NSString *const kAudioTrackTagBGAudio = @"kAudioTrackBGAudio";
static NSString *const kAudioTrackTagKaraoke = @"kAudioTrackTagKaraoke";
static NSString *const kAudioTrackTagTextRead = @"kAudioTrackTagTextRead";

static NSString *const kVideoClipResolveTypeTag = @"kVideoClipResolveTypeTag";

static NSString * const ACCNLEEditLensHDRKey = @"ACCNLEEditLensHDRKey";
static NSString * const ACCNLEEditOneKeyHDRKey = @"ACCNLEEditOneKeyHDRKey";
static NSString * const ACCNLEEditSpecialEffectTrackKey = @"ACCNLEEditSpecialEffectTrackKey";
static NSString * const ACCNLEEditTimeEffectTrackKey = @"ACCNLEEditTimeEffectTrackKey";
static NSString * const ACCNLEEditVideoSubTrackKey = @"ACCNLEEditVideoSubTrackKey";

static NSString *const ACCMarkTrackAsVideoModeOfSmartMovieKey = @"VideoModeOfSmartMovieScene";

@implementation NLETrack_OC (Extension)

- (BOOL)isVideoSubTrack {
    return [[self getExtraForKey:ACCNLEEditVideoSubTrackKey] boolValue];
}

- (void)setIsVideoSubTrack:(BOOL)isVideoSubTrack {
    [self setExtra:@(isVideoSubTrack).stringValue forKey:ACCNLEEditVideoSubTrackKey];
}

- (BOOL)isCutsame
{
    return [[self getExtraForKey:@"business"] isEqualToString:@"cutsame"];
}

- (void)setIsBGMTrack:(BOOL)isBGMTrack
{
    if (isBGMTrack) {
        [self setExtra:kAudioTrackTagBGM forKey:kAudioTrackTag];
    } else {
        [self setExtra:nil forKey:kAudioTrackTag];
    }
}

- (BOOL)isBGMTrack
{
    return [[self getExtraForKey:kAudioTrackTag] isEqualToString:kAudioTrackTagBGM];
}

- (void)setIsTextRead:(BOOL)isTextRead
{
    if (isTextRead) {
        [self setExtra:kAudioTrackTagTextRead forKey:kAudioTrackTag];
    }
}

- (BOOL)isTextRead
{
    return [[self getExtraForKey:kAudioTrackTag] isEqualToString:kAudioTrackTagTextRead];
}

- (void)setIsKaraokeTrack:(BOOL)isKaraokeTrack
{
    if (isKaraokeTrack) {
        [self setExtra:kAudioTrackTagKaraoke forKey:kAudioTrackTag];
    }
}

- (BOOL)isKaraokeTrack
{
    return [[self getExtraForKey:kAudioTrackTag] isEqualToString:kAudioTrackTagKaraoke];
}

- (BOOL)isLensHDRTrack
{
    return [[self getExtraForKey:ACCNLEEditLensHDRKey] boolValue];
}

- (void)setIsLensHDRTrack:(BOOL)isLensHDRTrack
{
    [self setExtra:@(isLensHDRTrack).stringValue forKey:ACCNLEEditLensHDRKey];
}

- (BOOL)isOneKeyHDRTrack
{
    return [[self getExtraForKey:ACCNLEEditOneKeyHDRKey] boolValue];
}

- (void)setIsOneKeyHDRTrack:(BOOL)isOneKeyHDRTrack
{
    [self setExtra:@(isOneKeyHDRTrack).stringValue forKey:ACCNLEEditOneKeyHDRKey];
}

- (BOOL)isSpecialEffectTrack
{
    return [[self getExtraForKey:ACCNLEEditSpecialEffectTrackKey] boolValue];
}

- (void)setIsSpecialEffectTrack:(BOOL)isSpecialEffectTrack
{
    [self setExtra:@(isSpecialEffectTrack).stringValue forKey:ACCNLEEditSpecialEffectTrackKey];
}

- (BOOL)isTimeEffectTrack
{
    return [[self getExtraForKey:ACCNLEEditTimeEffectTrackKey] boolValue];
}

- (void)setIsTimeEffectTrack:(BOOL)isTimeEffectTrack
{
    [self setExtra:@(isTimeEffectTrack).stringValue forKey:ACCNLEEditTimeEffectTrackKey];
}

- (void)setVideoClipResolveType:(NSInteger)videoClipResolveType
{
    [self setExtra:@(videoClipResolveType).stringValue forKey:kVideoClipResolveTypeTag];
}

- (ACCSmartMovieSceneMode)smartMovieVideoMode
{
    NSString *tag = [self getExtraForKey:ACCMarkTrackAsVideoModeOfSmartMovieKey];
    if ([tag isEqual:@"1"]) {
        return ACCSmartMovieSceneModeMVVideo;
    }
    if ([tag isEqual:@"2"]) {
        return ACCSmartMovieSceneModeSmartMovie;
    }
    return ACCSmartMovieSceneModeNone;
}

- (void)setSmartMovieVideoMode:(ACCSmartMovieSceneMode)smartMovieVideoMode
{
    NSString *tag = nil;
    if (smartMovieVideoMode == ACCSmartMovieSceneModeMVVideo) {
        tag = @"1";
    } else if (smartMovieVideoMode == ACCSmartMovieSceneModeSmartMovie) {
        tag = @"2";
    }
    [self setExtra:tag forKey:ACCMarkTrackAsVideoModeOfSmartMovieKey];
}

- (NSInteger)videoClipResolveType
{
    return [[self getExtraForKey:kVideoClipResolveTypeTag] integerValue];
}

- (NLETrackSlot_OC *)slotOfID:(UInt64)slotId {
    return [self.slots acc_match:^BOOL(NLETrackSlot_OC * _Nonnull item) {
        return [item getID] == slotId;
    }];
}

- (NLETrackSlot_OC *)slotOfName:(NSString *)slotName {
    return [self.slots acc_match:^BOOL(NLETrackSlot_OC * _Nonnull item) {
        return [[item getName] isEqualToString: slotName];
    }];
}

- (void)adjustTargetStartTime {
    if (self.getTrackType != NLETrackVIDEO || !self.isMainTrack) {
        return;
    }
    [self timeSort];
}

- (void)updateAndOrderSlots:(NSArray<NLETrackSlot_OC *> *)slots
{
    CMTime cursotTime = kCMTimeZero;
    for (NLETrackSlot_OC *cur in slots) {
        cur.startTime = cursotTime;
        cursotTime = CMTimeAdd(cursotTime, cur.duration);
    }
    
    // 移除历史 slot
    [self.slots acc_forEach:^(NLETrackSlot_OC * _Nonnull obj) {
        [self removeSlot:obj];
    }];
    
    // 添加新增 slot
    [slots acc_forEach:^(NLETrackSlot_OC * _Nonnull obj) {
        [self addSlotAtEnd:obj];
    }];
    
    [self timeSort];
}

- (void)acc_replaceSlot:(NLETrackSlot_OC *)slot atIndex:(NSUInteger)index
{
    if (index >= self.slots.count) {
        [self addSlotAtEnd:slot];
        return;
    }
    
    NLETrackSlot_OC *removeSlot = self.slots[index];
    [self removeSlot:removeSlot];
    [self addSlot:slot atIndex:(int)index];
}

- (void)updateAudioSubType:(NLEResourceType)audioSubType {    
    if (self.getTrackType != NLETrackAUDIO) return;
    
    NSAssert(audioSubType == NLEResourceTypeAudio ||
             audioSubType == NLEResourceTypeAlgorithmMVAudio ||
             audioSubType == NLEResourceTypeMusicMVAudio ||
             audioSubType == NLEResourceTypeNormalMVAudio, @"audioType is inavailable");
    
    [self.slots acc_forEach:^(NLETrackSlot_OC * _Nonnull obj) {
        if (obj.segment && obj.segment.getResNode) {
            obj.segment.getResNode.resourceType = audioSubType;
        }
    }];
}

@end
