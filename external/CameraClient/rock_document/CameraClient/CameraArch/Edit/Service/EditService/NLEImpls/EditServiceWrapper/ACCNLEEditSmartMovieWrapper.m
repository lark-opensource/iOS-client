//
//  ACCNLEEditSmartMovieWrapper.m
//  CameraClient-Pods-Aweme
//
//  Created by LeonZou on 2021/8/3.
//

#import "ACCNLEEditSmartMovieWrapper.h"
#import "ACCSmartMovieManagerProtocol.h"
#import "ACCEditVideoDataProtocol.h"
#import "ACCNLEEditVideoData.h"
#import "ACCEditVideoDataDowngrading.h"

#import <CreativeKit/ACCMacros.h>

#import <NLEPlatform/NLEInterface.h>
#import <CameraClient/NLETrack_OC+Extension.h>
#import <CameraClient/NLEEditor_OC+Extension.h>
#import <CameraClient/NLETrackSlot_OC+Extension.h>

#import <CreationKitInfra/ACCRACWrapper.h>
#import <CreationKitRTProtocol/ACCEditSessionBuilderProtocol.h>


@interface ACCNLEEditSmartMovieWrapper () <ACCEditBuildListener>

@property (nonatomic, weak) NLEInterface_OC *nle;

@property (nonatomic, weak) id<ACCSmartMovieManagerProtocol> smartMovieManager;
@property (nonatomic, strong) RACSubject *recoverySubject;
@property (nonatomic, strong) RACSubject<NSNumber *> *didSwitchMusicSubject;
@property (nonatomic, strong) RACSubject<id<ACCEditSmartMovieMusicTupleProtocol>> *willSwitchMusicSubject;
@property (nonatomic, assign) BOOL isSmartMovieBubbleAllowed;

@end

@implementation ACCNLEEditSmartMovieWrapper

- (instancetype)init {
    if (self = [super init]) {
        _recoverySubject = [RACSubject subject];
        _didSwitchMusicSubject = [RACSubject subject];
        _willSwitchMusicSubject = [RACSubject subject];
    }
    return self;
}

- (void)dealloc
{
    [self onCleared];
}

- (void)setEditSessionProvider:(nonnull id<ACCEditSessionProvider>)editSessionProvider
{
    [editSessionProvider addEditSessionListener:self];
}

- (void)triggerSignalForRecovery
{
    [self.recoverySubject sendNext:nil];
}

- (void)triggerSignalForDidSwitchMusic
{
    [self.didSwitchMusicSubject sendNext:nil];
}
 
- (void)triggerSignalForWillSwitchMusic:(id<ACCEditSmartMovieMusicTupleProtocol> _Nonnull)musicTuple
{
    [self.willSwitchMusicSubject sendNext:musicTuple];
}

- (BOOL)isSmartMovieMode
{
    return [self.smartMovieManager isSmartMovieMode];
}

- (void)showUploadRemindToastIfNeeded
{
    [self.smartMovieManager showRemindUploadToastIfNeeded];
}

- (nullable NLETrack_OC *)getBGMTrack
{
    for (NLETrack_OC *track in [[self.nle.editor getModel] getTracks]) {
        if ([track getTrackType] == NLETrackAUDIO && track.isBGMTrack) {
            return track;
        }
    }
    return nil;
}

- (nullable NLETrack_OC *)removeBGMTrack
{
    NLETrack_OC *track = [self getBGMTrack];
    if (track) {
        [[self.nle.editor getModel] removeTrack:track];
    }
    return track;
}

- (BOOL)replaceBGMTrack:(NLETrack_OC *)track
{
    [self removeBGMTrack];
    [[self.nle.editor getModel] addTrack:track];
    return YES;
}

- (void)useLocalMusic:(nonnull id<ACCMusicModelProtocol>)localMusicModel withTotalVideoDuration:(CGFloat)totalVideoDuration
{
    NSURL *url = localMusicModel.loaclAssetUrl;
    NSString *filePath = url.path;
    if (!localMusicModel.isLocalScannedMedia || ACC_isEmptyString(filePath)) {
        NSAssert(NO, @"SmartMovie: invalid music model found when use local music");
        return;
    }
    
    if (![NSFileManager.defaultManager fileExistsAtPath:filePath]) {
        NSAssert(NO, @"SmartMovie: local music not exist");
        return;
    }
    
    NSInteger repeatCount = [self p_calculateRepeatCountForMusic:url
                                          withTotalVideoDuration:totalVideoDuration];
    [self p_replaceMusic:url
               startTime:0.0
                duration:[localMusicModel.duration floatValue]
             repeatCount:repeatCount
            forVideoData:nil];
}

- (void)useMusic:(id<ACCMusicModelProtocol> _Nonnull)musicModel ForVideoData:(id<ACCEditVideoDataProtocol> _Nonnull)videoData
{
    NSURL *url = musicModel.loaclAssetUrl;
    if (ACC_isEmptyString([url absoluteString])) {
        NSAssert(NO, @"SmartMovie: empty music model found when replace music");
        return;
    }
    
    NSString *filePath = url.path;
    if (![NSFileManager.defaultManager fileExistsAtPath:filePath]) {
        NSAssert(NO, @"SmartMovie: music not exist");
        return;
    }
    
    NSInteger repeatCount = [self p_calculateRepeatCountForMusic:url
                                          withTotalVideoDuration:videoData.totalVideoDuration];
    
    ACCNLEEditVideoData *nleVideoData = acc_videodata_take_nle(videoData);
    [self p_replaceMusic:url
               startTime:0.0
                duration:[musicModel.duration floatValue]
             repeatCount:repeatCount
            forVideoData:nleVideoData];
}

- (void)dismissMusicForVideoData:(id<ACCEditVideoDataProtocol> _Nonnull)videoData
{
    ACCNLEEditVideoData *nleVideoData = acc_videodata_take_nle(videoData);
    if (!nleVideoData) {
        return;
    }
    
    for (NLETrack_OC *track in [nleVideoData.nle.editor.model getTracks]) {
        if (track.isBGMTrack && track.getTrackType == NLETrackAUDIO) {
            [track clearSlots];
            break;
        }
    }
}

#pragma mark - ACCEditBuildListener

- (void)onEditSessionInit:(nonnull ACCEditSessionWrapper *)editSession {}

- (void)onNLEEditorInit:(NLEInterface_OC *)editor
{
    self.nle = editor;
}

#pragma mark - getter & setter

- (RACSignal *)willSwitchMusicSignal
{
    return self.willSwitchMusicSubject;
}

- (RACSignal *)didSwitchMusicSignal
{
    return self.didSwitchMusicSubject;
}

- (RACSignal *)recoverySignal
{
    return self.recoverySubject;
}

- (id<ACCSmartMovieManagerProtocol>)smartMovieManager
{
    if (!_smartMovieManager) {
        _smartMovieManager = acc_sharedSmartMovieManager();
    }
    return _smartMovieManager;
}

- (void)updateSmartMovieBubbleAllowed:(BOOL)allowed
{
    self.isSmartMovieBubbleAllowed = allowed;
}

#pragma mark - private
- (NSInteger)p_calculateRepeatCountForMusic:(nonnull NSURL *)url withTotalVideoDuration:(CGFloat)totalVideoDuration
{
    if (ACC_FLOAT_EQUAL_ZERO(totalVideoDuration)) {
        NSAssert(NO, @"SmartMovie: invalid totalVideoDuration found when culculate repeatCount for music");
        return 1;
    }
    
    AVURLAsset *audioAsset = [AVURLAsset URLAssetWithURL:url
                                                 options:@{
                                                           AVURLAssetPreferPreciseDurationAndTimingKey: @(YES)
                                                           }];
    NSTimeInterval clipDuration = audioAsset.duration.value;
    NSInteger repeatCount = 1;
    
    if (audioAsset.duration.timescale > 0) {
        clipDuration /= audioAsset.duration.timescale;
    }
    if (totalVideoDuration > clipDuration && clipDuration > 0) {
        repeatCount = (totalVideoDuration / clipDuration) + 1;
    }
    
    return repeatCount;
}

- (void)p_replaceMusic:(nonnull NSURL *)url
             startTime:(CGFloat)startTime
              duration:(CGFloat)duration
           repeatCount:(NSInteger)repeatCount
          forVideoData:(nullable ACCNLEEditVideoData *)videoData
{
    AVAsset *asset = [AVAsset assetWithURL:url];
    NLETrackSlot_OC *slot = nil;
    
    NSArray<NLETrack_OC *> *tracks = @[];
    if (videoData) {
        tracks = [videoData.nle.editor.model getTracks].copy;
        slot = [NLETrackSlot_OC audioTrackSlotWithAsset:asset nle:videoData.nle];
    } else {
         slot = [NLETrackSlot_OC audioTrackSlotWithAsset:asset nle:self.nle];
         tracks = [self.nle.editor.model getTracks].copy;
    }
    
    for (NLETrack_OC *track in tracks) {
        if (track.isBGMTrack && track.getTrackType == NLETrackAUDIO) {
            [track clearSlots];
            [track addSlot:slot];
            break;
        }
    }
    
    // 非本地音乐
    if (videoData == nil) {
        [self.nle.editor acc_commitAndRender:nil];
    }
}

- (void)onCleared
{
    [_recoverySubject sendCompleted];
    [_didSwitchMusicSubject sendCompleted];
    [_willSwitchMusicSubject sendCompleted];
}

@end
