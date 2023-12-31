//
//  BDXAlphaVideoUI.m
//  BDXElement
//
//  Created by li keliang on 2020/11/23.
//

#import "BDXAlphaVideoUI.h"
#import "BDXElementResourceManager.h"
#import <IESLiveVideoGift/IESLiveVideoGiftController.h>
#import <Lynx/LynxUIContext.h>
#import <Lynx/LynxView.h>
#import <Lynx/LynxRootUI.h>
#import <BDWebImage/BDWebImage.h>
#import <Masonry/Masonry.h>
#import <Lynx/LynxLog.h>

// The version of `IESLiveVideoGift` is not specified, so we mock its header
@interface IESLiveVideoGiftMetalConfiguration (Lynx)
@property (nonatomic, assign) BOOL asyncRenderMTKView;
@property (nonatomic, assign) BOOL enableAsyncSetupPipeline;
@end


@interface BDXAlphaVideoUI()<IESLiveVideoGiftControllerDelegate>

@property (nonatomic) IESLiveVideoGiftController *videoController;

@property (nonatomic) BOOL loop;
@property (nonatomic) NSUInteger loopCount;
@property (nonatomic) BOOL autoplay;
@property (nonatomic) BOOL keepVideoLastframe;
@property (nonatomic) BOOL keepPreviousView;

@property (nonatomic) BOOL layoutFinished;
@property (nonatomic) BOOL videoPreparedFinished;

@property (nonatomic) BOOL playSuccessTriggerFlag;

@property (nonatomic) BOOL enableLogInfo;

@property (nonatomic) BOOL enableAsyncRender;

@property (nonatomic) NSURL *unzipURL;
@property (nonatomic) NSURL *videoURL;

@property (nonatomic) UIImageView *firstFrameImageView;
@property (nonatomic) UIImageView *lastFrameImageView;

@property (nonatomic) UIView *containerView;

@property (nonatomic, strong) NSMutableDictionary<NSNumber *, NSNumber *> *subscribedMilliseconds;

@end

@implementation BDXAlphaVideoUI

- (instancetype)init
{
    self = [super init];
    if (self) {
        _loop = NO;
        _loopCount = 0;
        _autoplay = YES;
        _enableLogInfo = YES;
        _keepVideoLastframe = NO;
        _keepPreviousView = NO;
    }
    return self;
}

+ (NSString *)tagName
{
    return @"x-alpha-video";
}

- (UIView *)createView
{
    [self.containerView addSubview:self.videoController.view];
    [self.videoController.view mas_makeConstraints:^(MASConstraintMaker *make) {
        make.edges.equalTo(self.containerView);
    }];
    
    [self.containerView addSubview:self.firstFrameImageView];
    [self.firstFrameImageView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.edges.equalTo(self.containerView);
    }];
    
    [self.containerView addSubview:self.lastFrameImageView];
    [self.lastFrameImageView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.edges.equalTo(self.containerView);
    }];

    [self reportInfoToLynx:@("view created") resourceURL:nil];

    return self.containerView;
}

- (void)layoutDidFinished
{
    [super layoutDidFinished];
    if ([self.context respondsToSelector:@selector(bdx_frame)]) {
        self.videoController.liveRenderSuperViewFame = self.context.bdx_frame;
    }
    
    self.layoutFinished = YES;
    [self reportInfoToLynx:@("layout finished") resourceURL:nil];
    if (_autoplay && _videoPreparedFinished) {
        if (self.keepPreviousView && self.videoController.state == IESLiveVideoGiftPlayStatePlay) {
            // take keepPreviousView as switch
            return;
        }
        [self playVideoIfVideoPrepared];
    }
}

- (void)updateFrameSize
{
    if ([self.context respondsToSelector:@selector(bdx_frame)]) {
        self.videoController.liveRenderSuperViewFame = self.context.bdx_frame;
    }
}

- (void)playVideoIfVideoPrepared
{
    if (!self.unzipURL && self.videoURL) {
        [self prepareVideoWithURL:self.videoURL];
    }
    if (!self.unzipURL || !self.videoURL) {
        [self reportErrorMessage:BDXAlphaVideoErrorCodeResourcesNotFound resourceURL:self.videoURL message:@("Resource URL not found or unzip resource failed")];
        return;
    }

    if (!self.layoutFinished) {
        [self reportErrorMessage:BDXAlphaVideoErrorCodeVideoUnknownException resourceURL:self.videoURL message:@("Layout didn't finish")];
        return;
    }
 
    if (!self.keepPreviousView && self.videoController.state == IESLiveVideoGiftPlayStatePlay) {
        // take keepPreviousView as switch
        return;
    }
    
    IESLiveVideoGiftMetalConfiguration *configuration = [[IESLiveVideoGiftMetalConfiguration alloc] init];
    configuration.loop = self.loop;
    if ([self.context respondsToSelector:@selector(bdx_frame)]) {
        configuration.liveRenderSuperViewFame = self.context.bdx_frame;
    }
    configuration.directory = self.unzipURL.path;
    configuration.removedOnCompletion = !self.keepVideoLastframe;
    // some resource did not set fps info correctly, and a default fps will be applied
    // if set useDrawTimer = YES, the video will be set to 30fps by default; otherwise, it will be 60-120fps, then the video may be accelerated
    configuration.useDrawTimer = YES;
  
    if (self.enableAsyncRender) {
      if ([configuration respondsToSelector:@selector(setAsyncRenderMTKView:)]) {
        configuration.asyncRenderMTKView = YES;
      }
    
      if ([configuration respondsToSelector:@selector(setEnableAsyncSetupPipeline:)]) {
        configuration.enableAsyncSetupPipeline = YES;
      }
    }
  
  
    if ([configuration respondsToSelector:@selector(setKeepPreviousView:)]) {
        // IESLiveVideoGift provide keepPreviousView at 1.3.24
        BOOL keepPreviousView = self.keepPreviousView;
        NSMethodSignature *signature = [[configuration class] instanceMethodSignatureForSelector:@selector(setKeepPreviousView:)];
        NSInvocation *invocation = [NSInvocation invocationWithMethodSignature:signature];
        [invocation setTarget:configuration];
        [invocation setSelector:@selector(setKeepPreviousView:)];
        [invocation setArgument:&keepPreviousView atIndex:2];
        [invocation invoke];
    }
    [self.videoController playWithConfiguration:configuration];
    [self reportInfoToLynx:@("play") resourceURL: self.videoURL];
}

- (void)stopVideo
{
    self.playSuccessTriggerFlag = NO;
    self.loopCount = 0;
    [self resetSubscribedMillisecondsTrigger];
    [self.videoController stop];
    [self reportInfoToLynx:@("stop") resourceURL: self.videoURL];
}

- (void)pauseVideo
{
    self.playSuccessTriggerFlag = NO;
    [self.videoController pause];
    [self reportInfoToLynx:@("pause") resourceURL: self.videoURL];
}

- (void)resumeVideo
{
    [self.videoController resume];
    [self reportInfoToLynx:@("resume") resourceURL: self.videoURL];
}

/**
 * Seeks to a specific time in the video player.
 *
 * @param second The time in seconds to seek to.
 */
- (void)seekToVideo:(NSTimeInterval) second
{
  [self.videoController seekToTime: second];
  [self reportInfoToLynx:@("seek") resourceURL: self.videoURL];
}

- (void)releaseVideo
{
    [self reportInfoToLynx:@("release") resourceURL: self.videoURL];
}

- (void)prepareVideoWithZipURL:(NSURL *)URL
{
  __weak __typeof(self) weakSelf = self;
  if ([self.uiDelegate loadZipFromResourceFetcher:URL completion:^(NSURL *URL, NSURL *unzipURL, NSError * _Nullable error) {
    if (![URL.absoluteString isEqualToString:weakSelf.videoURL.absoluteString]) {
      return;
    }
    
    weakSelf.unzipURL = unzipURL;
    if (error) {
      weakSelf.unzipURL = NULL;
      weakSelf.videoPreparedFinished = NO;
      [weakSelf reportErrorMessage:BDXAlphaVideoErrorCodeResourcesNotFound resourceURL:self.videoURL message:@("Resource URL not found or unzip resource failed")];
    } else {
      weakSelf.videoPreparedFinished = YES;
      [weakSelf.eventDispatcher sendCustomEvent:@"ready" params:nil];
      [weakSelf reportInfoToLynx:@("ready") resourceURL: self.videoURL];
    }
  }]) {
    return;
  }
  
    NSURL *baseURL = nil;
    if ([self.context respondsToSelector:@selector(bdx_containerURL)]) {
        baseURL = [self.context bdx_containerURL];
    }
    NSMutableDictionary *context = [NSMutableDictionary dictionary];
    if ([self.context respondsToSelector:@selector(bdx_context)]) {
        LynxUIContext *lynxContext = self.context.bdx_context;
        context[BDXElementContextContainerKey] = lynxContext.rootUI.lynxView;
    }

    [[BDXElementResourceManager sharedInstance] resourceZipFileWithURL:URL baseURL:baseURL context:context completionHandler:^(NSURL * _Nonnull URL, NSURL * _Nonnull unzipURL, NSError * _Nullable error) {
        __strong __typeof(weakSelf) self = weakSelf;
        if (![URL.absoluteString isEqualToString:weakSelf.videoURL.absoluteString]) {
            return;
        }

        self.unzipURL = unzipURL;
        if (error) {
            self.unzipURL = NULL;
            self.videoPreparedFinished = NO;
            [self reportErrorMessage:BDXAlphaVideoErrorCodeResourcesNotFound resourceURL:self.videoURL message:@("Resource URL not found or unzip resource failed")];
        } else {
            self.videoPreparedFinished = YES;
            [self.eventDispatcher sendCustomEvent:@"ready" params:nil];
            [self reportInfoToLynx:@("ready") resourceURL: self.videoURL];
        }
    }];
}

- (void)prepareVideoWithURL:(NSURL *)URL
{
    if (self.videoController.state == IESLiveVideoGiftPlayStateStop) {
        self.firstFrameImageView.hidden = NO;
        self.lastFrameImageView.hidden = YES;
    }
    self.videoURL = URL;
    NSString *directory = self.videoURL.absoluteString;
    if ([[directory pathExtension] isEqualToString:@"zip"]){
        [self prepareVideoWithZipURL: self.videoURL];
    } else {
        self.videoPreparedFinished = YES;
        [self reportInfoToLynx:@("Resource type is not a zip file. Try to use this URL directly") resourceURL: self.videoURL];
        self.unzipURL = self.videoURL;
    }
    if (_autoplay && _layoutFinished && _videoPreparedFinished) {
        [self playVideoIfVideoPrepared];
    }
}

- (BOOL)isVideoPlaying {
    return ([self.videoController isPlaying]);
}

- (NSNumber*) getVideoDuration {
    return [NSNumber numberWithFloat: self.videoController.totalDurationOfPlayingEffect * 1000];
}

- (void)resetSubscribedMillisecondsTrigger
{
    [self.subscribedMilliseconds.copy enumerateKeysAndObjectsUsingBlock:^(NSNumber * _Nonnull key, NSNumber * _Nonnull obj, BOOL * _Nonnull stop) {
        self.subscribedMilliseconds[key] = @(NO);
    }];
}


- (void)reportInfoToLynx:(NSString *)message resourceURL:(NSURL *)resourceURL
{
    if (self.enableLogInfo) {
        LLogInfo(@"BDXAlphaVideoUI.m report info: message: %@, resourceURL: %@", message, resourceURL.absoluteString ?: @"");
    }
}

#pragma mark - Error Message Handler

- (void)sendErrorEventWithCode:(BDXAlphaVideoErrorCode)code resourceURL:(NSURL *)resourceURL message:(NSString *)message
{
    [self.eventDispatcher sendCustomEvent:@"error" params:@{@"code": @(code),
                                                            @"message": message ?: @"Unknown error.",
                                                            @"resourceURL":resourceURL.absoluteString ?: @""}];
}

- (void)reportErrorToLynxAndElementMonitor:(BDXAlphaVideoErrorCode)code resourceURL:(NSURL *)resourceURL message:(NSString *)message
{
    if (self.enableLogInfo) {
        LLogError(@"BDXAlphaVideoUI.m reportErrorCode: code: %@, message: %@, resourceURL: %@", @(code), message ?: @"Unknown error.", resourceURL.absoluteString ?: @"");
    }
}

- (void)reportErrorMessage:(BDXAlphaVideoErrorCode)code resourceURL:(NSURL *)resourceURL message:(NSString *)message
{
    [self reportErrorToLynxAndElementMonitor:code resourceURL:resourceURL message:message];
    [self sendErrorEventWithCode:code resourceURL:resourceURL message:message];
}



#pragma mark - Prop setter

BDX_PROP_SETTER(src, NSString *) {
    
    if (!value || ![value isKindOfClass:[NSString class]]) {
        self.videoURL = nil;
        [self reportErrorMessage:BDXAlphaVideoErrorCodeResourcesNotFound resourceURL:nil message:@("Resource URL not found")];
        return;
    }
    
    if ([value isEqualToString:self.videoURL.absoluteString]) {
        return;
    }
    
    [self.subscribedMilliseconds removeAllObjects];


    NSURL *baseURL = nil;
    if ([self.context respondsToSelector:@selector(bdx_containerURL)]) {
        baseURL = [self.context bdx_containerURL];
    }
    
    NSURL *URL = [NSURL URLWithString:value relativeToURL:baseURL];
    [self prepareVideoWithURL:URL];
}

BDX_PROP_SETTER(loop, id) {
    self.loop = [value boolValue];
}

BDX_PROP_SETTER(iosAsyncRender, id) {
  self.enableAsyncRender = [value boolValue];
}

BDX_PROP_SETTER(autoplay, id) {
    self.autoplay = [value boolValue];
}

BDX_PROP_SETTER(play, id) {
    [self playVideoIfVideoPrepared];
}

BDX_PROP_SETTER(stop, id) {
    [self stopVideo];
}

BDX_PROP_SETTER(pause, id) {
    [self pauseVideo];
}

BDX_PROP_SETTER(resume, id) {
    [self resumeVideo];
}

/**
 * A prop that seeks the video to the specified millisecond value and reports the seek event to Lynx.
 *
 * @param seek The name of the property being set.
 * @param id The value to set the property to.
 */
BDX_PROP_SETTER(seek, id) {
  // If the value is nil or NSNull, do nothing.
  if (!value || [value isEqual:[NSNull null]]) {
      return;
  }
  NSNumber *millisecond = value[@"ms"];
  if (millisecond != nil && [millisecond isKindOfClass:[NSNumber class]]) {
    // Convert the milliseconds to seconds
      NSTimeInterval time = [millisecond doubleValue] / 1000.0;
    // Seek the video to the given time
      [self seekToVideo:time];
    // Report the seek event to Lynx, passing the video URL as a parameter
      [self reportInfoToLynx:@"seek" resourceURL:self.videoURL];
  }
}

BDX_PROP_SETTER(release, id) {
    [self releaseVideo];
}

BDX_PROP_SETTER(poster, NSString *) {
    if (![value isKindOfClass:[NSString class]] || value.length == 0) {
        [self reportErrorMessage:BDXAlphaVideoErrorCodeVideoPosterSetFail resourceURL:nil message:@("Set video poster failed.")];
        self.firstFrameImageView.image = nil;
        return;
    }
    NSURL *baseURL = nil;
    if ([self.context respondsToSelector:@selector(bdx_containerURL)]) {
        baseURL = [self.context bdx_containerURL];
    }
    NSURL *URL = [NSURL URLWithString:value relativeToURL:baseURL];
    __weak __typeof(self) weakSelf = self;
    [self.firstFrameImageView bd_setImageWithURL:URL placeholder:nil options:BDImageRequestDefaultOptions completion:(BDImageRequestCompletedBlock)^(BDWebImageRequest *request, UIImage *image, NSData *data, NSError *error, BDWebImageResultFrom from) {
        if (error) {
            NSString *message = [NSString stringWithFormat:@"poster_errorcode:%ld;description:%@",(long)error.code,error.localizedDescription ?: @"Set video poster failed."];
            [weakSelf reportErrorMessage:BDXAlphaVideoErrorCodeVideoPosterSetFail resourceURL:nil message:message];
        }
        else {
            [weakSelf reportInfoToLynx:@("poster set") resourceURL: self.videoURL];
        }
    }];
}

BDX_PROP_SETTER(lastframe, NSString *) {
    if (![value isKindOfClass:[NSString class]] || value.length == 0) {
        [self reportErrorMessage:BDXAlphaVideoErrorCodeVideoLastframeSetFail resourceURL:nil message:@("Set video lastframe failed.")];
        self.lastFrameImageView.image = nil;
        return;
    }
    NSURL *baseURL = nil;
    if ([self.context respondsToSelector:@selector(bdx_containerURL)]) {
        baseURL = [self.context bdx_containerURL];
    }
    NSURL *URL = [NSURL URLWithString:value relativeToURL:baseURL];
    __weak __typeof(self) weakSelf = self;
    [self.lastFrameImageView bd_setImageWithURL:URL placeholder:nil options:BDImageRequestDefaultOptions completion:(BDImageRequestCompletedBlock)^(BDWebImageRequest *request, UIImage *image, NSData *data, NSError *error, BDWebImageResultFrom from) {
        if (error) {
            NSString *message = [NSString stringWithFormat:@"lastframe_errorcode:%ld;description:%@",(long)error.code,error.localizedDescription ?: @"Set video lastframe failed."];
            [weakSelf sendErrorEventWithCode:BDXAlphaVideoErrorCodeVideoPosterSetFail resourceURL:nil message:message];
        }
        else {
            self.keepVideoLastframe = NO;
            [weakSelf reportInfoToLynx:@("lastframe set") resourceURL: self.videoURL];
        }
    }];
}

BDX_PROP_SETTER(keepLastframe, id) {
    self.keepVideoLastframe = [value boolValue];
}

BDX_PROP_SETTER(keepPreviousView, id) {
    self.keepPreviousView = [value boolValue];
}

BDX_PROP_SETTER(subscribeUpdateEvent, id) {
    if (!value || [value isEqual:[NSNull null]]) {
        return;
    }
    [self reportInfoToLynx:@("subscribed") resourceURL: self.videoURL];
    NSNumber *millisecond = value[@"ms"];
    if ([millisecond isKindOfClass:NSNumber.class]) {
        if (!self.subscribedMilliseconds[millisecond]) {
            self.subscribedMilliseconds[millisecond] = @(NO);
        }
    }
}

BDX_PROP_SETTER(unsubscribeUpdateEvent, id) {
    if (!value || [value isEqual:[NSNull null]]) {
        return;
    }
    [self reportInfoToLynx:@("unsubscribed") resourceURL: self.videoURL];
    NSNumber *millisecond = value[@"ms"];
    if ([millisecond isKindOfClass:NSNumber.class]) {
        self.subscribedMilliseconds[millisecond] = nil;
    }
}

BDX_PROP_SETTER(isPlaying, id) {
}

BDX_PROP_SETTER(getDuration, id) {
}

#pragma mark - IESLiveVideoGiftControllerDelegate

- (void)didFinishPlayingWithError:(NSError *)error
{
    self.playSuccessTriggerFlag = NO;
    [self resetSubscribedMillisecondsTrigger];
    _loopCount = 0;
    if (error) {
        NSString *message = [NSString stringWithFormat:@"player_errorcode:%ld;description:%@",(long)error.code,error.localizedDescription ?: @"Abnormal play end"];
        [self reportErrorMessage:BDXAlphaVideoErrorCodeAbnormalPlayEnd resourceURL:self.videoURL message:message];
        self.lastFrameImageView.hidden = NO;
    } else {
        [self.eventDispatcher sendCustomEvent:@"completion" params:nil];
        [self reportInfoToLynx:@("completion") resourceURL: self.videoURL];
        self.lastFrameImageView.hidden = NO;
    }
}

- (void)videoGiftController:(IESLiveVideoGiftController *)controller didEndPlayingFrame:(IESLiveFrameInfo *)frame
{
    if (frame.loopCount > _loopCount) {
        _loopCount = frame.loopCount;
        [self resetSubscribedMillisecondsTrigger];
    }
}

- (void)frameCallBack:(Float64)duration
{
    if (duration >= 0.05) {
        if (!self.playSuccessTriggerFlag) {
            [self.eventDispatcher sendCustomEvent:@"start" params:nil];
            self.playSuccessTriggerFlag = !self.playSuccessTriggerFlag;
        }

        self.firstFrameImageView.hidden = YES;
        self.lastFrameImageView.hidden = YES;
    }

    [self.subscribedMilliseconds.copy enumerateKeysAndObjectsUsingBlock:^(NSNumber * _Nonnull key, NSNumber * _Nonnull obj, BOOL * _Nonnull stop) {
        if ([key floatValue] <= duration * 1000 && [obj boolValue] == NO) {
            self.subscribedMilliseconds[key] = @(YES);
            [self.eventDispatcher sendCustomEvent:@"update" params:@{@"subscribedMillisecond" : key}];
        }
    }];

}

#pragma mark - Accessors

- (IESLiveVideoGiftController *)videoController
{
    if (!_videoController) {
        _videoController = [[IESLiveVideoGiftController alloc] initWithDelegate:self];
    }
    return _videoController;
}

- (UIImageView *)firstFrameImageView
{
    if (!_firstFrameImageView) {
        _firstFrameImageView = [[UIImageView alloc] init];
    }
    return _firstFrameImageView;
}

- (UIImageView *)lastFrameImageView
{
    if (!_lastFrameImageView) {
        _lastFrameImageView = [[UIImageView alloc] init];
    }
    return _lastFrameImageView;
}

- (UIView *)containerView
{
    if (!_containerView) {
        _containerView = [[UIView alloc] init];
    }
    return _containerView;
}

- (NSMutableDictionary<NSNumber *,NSNumber *> *)subscribedMilliseconds
{
    if (!_subscribedMilliseconds) {
        _subscribedMilliseconds = [NSMutableDictionary new];
    }
    return _subscribedMilliseconds;
}

- (NSUInteger)getState {
  return self.videoController.state;
}

- (BOOL)isPrepared {
  return self.videoPreparedFinished;
}

@end
