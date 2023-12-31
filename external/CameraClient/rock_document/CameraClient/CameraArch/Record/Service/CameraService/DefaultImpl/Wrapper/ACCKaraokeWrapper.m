//
//  ACCKaraokeWrapper.m
//  CameraClient-Pods-Aweme
//
//  Created by xiafeiyu on 2021/4/27.
//

#import "ACCKaraokeWrapper.h"

#import <CreativeKit/ACCLogger.h>
#import "ACCCameraFactory.h"
#import <CreationKitRTProtocol/ACCCameraDefine.h>
#import <TTVideoEditor/VERecorder.h>


@interface ACCKaraokeWrapper () <ACCCameraBuildListener>

@property (nonatomic, weak) id<VERecorderPublicProtocol> camera;

@end

@implementation ACCKaraokeWrapper

#pragma mark - ACCCameraWrapper

- (void)setCameraProvider:(id<ACCCameraProvider>)cameraProvider
{
    [cameraProvider addCameraListener:self];
}

#pragma mark - ACCCameraBuildListener

- (void)onCameraInit:(id<VERecorderPublicProtocol>)camera
{
    self.camera = camera;
}

#pragma mark - ACCKaraokeProtocol

- (void)setRecorderAudioMode:(VERecorderAudioMode)mode
{
    if (![self p_verifyCameraContext]) {
        return;
    }
    [self.camera setRecorderAudioMode:mode];
}

- (void)karaokePlay
{
    if (![self p_verifyCameraContext]) {
        return;
    }
    [self.camera karaokePlay];
}

- (void)karaokePause
{
    if (![self p_verifyCameraContext]) {
        return;
    }
    [self.camera karaokePause];
}

- (void)accompanySeekToTime:(NSTimeInterval)time
{
    if (![self p_verifyCameraContext]) {
        return;
    }
    [self.camera accompanySeekToTime:time];
}

- (void)originalSingSeekToTime:(NSTimeInterval)time
{
    if (![self p_verifyCameraContext]) {
        return;
    }
    [self.camera originalSingSeekToTime:time];
}

- (void)setAccompanyMusicFile:(NSURL *_Nonnull)musicURL fromTime:(NSTimeInterval)startTime OriginalSingMusicFile:(NSURL *_Nullable)singURL startTime:(NSTimeInterval)singStartTime
{
    if (![self p_verifyCameraContext]) {
        return;
    }
    [self.camera setAccompanyMusicFile:musicURL fromTime:startTime OriginalSingMusicFile:singURL startTime:singStartTime];
}

- (NSTimeInterval)getAccompanyCurrentTime;
{
    return [self.camera getAccompanyCurrentTime];
}

- (NSTimeInterval)getOriginalSingCurrentTime
{
    return [self.camera getOriginalSingCurrentTime];
}

- (void)mutedOrignalSing:(BOOL)muted
{
    if (![self p_verifyCameraContext]) {
        return;
    }
    [self.camera mutedOrignalSing:muted];
}

- (void)mutedAccompany:(BOOL)muted
{
    if (![self p_verifyCameraContext]) {
        return;
    }
    [self.camera mutedAccompany:muted];
}

- (void)setOriginalSingVolume:(CGFloat)recordVolume
{
    if (![self p_verifyCameraContext]) {
        return;
    }
    [self.camera setOriginalSingVolume:recordVolume];
}

- (CGFloat)originalSingVolume
{
    return [self.camera originalSingVolume];
}

- (void)setAccompanyVolume:(CGFloat)musicVolume
{
    if (![self p_verifyCameraContext]) {
        return;
    }
    [self.camera setAccompanyVolume:musicVolume];
}

- (CGFloat)accompanyVolume
{
    return [self.camera accompanyVolume];
}

- (void)seekToAccompanyTime:(NSTimeInterval)accompanyTime
           accompanyStartWritingTime:(NSTimeInterval)accompanyStartWritingTime
                    originalSingTime:(NSTimeInterval)origianlSingTime
        originalSingStartWritingTime:(NSTimeInterval)originalSingStartWritingTime;
{
    if (![self p_verifyCameraContext]) {
        return;
    }
    [self.camera seekToAccompanyTime:accompanyTime accompanyStartWritingTime:accompanyStartWritingTime originalSingTime:origianlSingTime originalSingStartWritingTime:originalSingStartWritingTime];
}

- (void)routeChanged
{
    if (![self p_verifyCameraContext]) {
        return;
    }
    [self.camera routeChanged];
}

#pragma mark - Utils

- (BOOL)p_verifyCameraContext
{
    if ([self.camera cameraContext]) {
        return YES;
    }
    BOOL result = [self.camera cameraContext] == ACCCameraVideoRecordContext;
    if (!result) {
        ACC_LogError(@"Camera operation error, context not equal to ACCCameraVideoRecordContext point");
    }
    return result;
}


@end

