//
//  BDPStreamingAudioRecorder.m
//  TTMicroApp
//
//  Created by houjihu on 2019/8/15.
//

#import "BDPStreamingAudioRecorder.h"
#import <OPFoundation/BDPNotification.h>
#import <OPFoundation/BDPCommonManager.h>
#import <ECOInfra/BDPFileSystemHelper.h>
#import <OPFoundation/BDPModuleManager.h>
#import "BDPPluginBase.h"
#import "BDPPrivacyAccessNotifier.h"
#import <OPFoundation/BDPStorageModuleProtocol.h>
#import <ECOInfra/NSDictionary+BDPExtension.h>
#import <OPFoundation/TMACustomHelper.h>
#import <AVFoundation/AVFoundation.h>
#import <AudioToolbox/AudioToolbox.h>
#import <CoreAudioKit/CoreAudioKit.h>
#import <TTMicroApp/TTMicroApp-Swift.h>
#import <TTMicroApp/OPAPIDefine.h>
#import <TTMicroApp/BDPAudioControlManager.h>
#import <LarkOpenAPIModel/LarkOpenAPIModel-Swift.h>
#import <LarkStorage/LarkStorage-Swift.h>

#define kWebBrowserInterruptionNotification           @"kWebBrowserInterruptionNotification"

static const int kNumberBuffers = 3;

typedef void (^OnErrorBlock)(NSString *errMsg);

struct BDPRecorderState {
    AudioStreamBasicDescription mDataFormat;
    AudioQueueRef mQueue;
    AudioQueueBufferRef mBuffers[kNumberBuffers];
    AudioFileID mAudioFile;
    UInt32 bufferByteSize;
    SInt64 mCurrentPacket;
    BOOL mIsRunning;
    void (^onFrameRecordedWithAudioDataBlock)(struct BDPRecorderState *recorderState, AudioQueueRef inAQ, AudioQueueBufferRef inBuffer, UInt32 inNumberPacketDescriptions, const AudioStreamPacketDescription *inPacketDescs);
    dispatch_block_t onStopRecorderBlock;
    OnErrorBlock onErrorRecorderBlock;
};

#define VStatusAndShowError(err, msg)     do { \
        if (noErr != err) { \
            NSString *errMsg = [NSString stringWithFormat: @"[ERR:%d]:%@", err, msg]; \
            BDPLogError(errMsg); \
            if (recorderState->onErrorRecorderBlock) { \
                recorderState->onErrorRecorderBlock(msg); \
            } \
            return; \
        } \
} while (0)

static void HandleAudioQueueInputBuffer(void *inUserData, AudioQueueRef inAQ, AudioQueueBufferRef inBuffer, const AudioTimeStamp *inStartTime, UInt32 inNumberPacketDescriptions, const AudioStreamPacketDescription *inPacketDescs)
{
    struct BDPRecorderState *recorderState = (struct BDPRecorderState *)inUserData;

    if (0 == inNumberPacketDescriptions && recorderState->mDataFormat.mBytesPerPacket != 0) { // for CBR
        inNumberPacketDescriptions = recorderState->bufferByteSize / recorderState->mDataFormat.mBytesPerPacket;
    }

    OSStatus stt = noErr;
    if (inNumberPacketDescriptions > 0) {
        stt = AudioFileWritePackets(recorderState->mAudioFile, false, recorderState->bufferByteSize, inPacketDescs, recorderState->mCurrentPacket, &inNumberPacketDescriptions, inBuffer->mAudioData);
        VStatusAndShowError(stt, @"AudioFileWritePackets error");

        if (stt == noErr) {
            recorderState->mCurrentPacket += inNumberPacketDescriptions;
            // BDPLogDebug(@"HandleAudioQueueInputBuffer inNumberPacketDescriptions: %u", (unsigned int)inNumberPacketDescriptions);

            if (recorderState->onFrameRecordedWithAudioDataBlock) {
                recorderState->onFrameRecordedWithAudioDataBlock(recorderState, inAQ, inBuffer, inNumberPacketDescriptions, inPacketDescs);
            }
        }
    }

    if (!recorderState->mIsRunning) {
        BDPLogDebug(@"HandleAudioQueueInputBuffer stop success");
//        NSLog(@"HandleAudioQueueInputBuffer stop success");
        return;
    }

    stt = AudioQueueEnqueueBuffer(recorderState->mQueue, inBuffer, 0, NULL);
    VStatusAndShowError(stt, @"AudioQueueEnqueueBuffer error");
}

/// 在开启与关闭录制时都需要做一次写magic cookie操作，开始时做是为了使文件具备magic cookie可用，结束时调用是为了更新与校正magic cookie信息
static OSStatus SetMagicCookieForFile(
                                      AudioQueueRef inQueue,
                                      AudioFileID   inFile
                                      )
{
    OSStatus result = noErr;
    UInt32 cookieSize;

    result = AudioQueueGetPropertySize(
                                       inQueue,
                                       kAudioQueueProperty_MagicCookie,
                                       &cookieSize
                                       );
    if (result == noErr && cookieSize > 0) {
        char *magicCookie =
        (char *)malloc(cookieSize);
        if (magicCookie == NULL) {
            BDPLogError(@"SetMagicCookieForFile malloc error");
            return -1;
        }
        result = AudioQueueGetProperty(
                                       inQueue,
                                       kAudioQueueProperty_MagicCookie,
                                       magicCookie,
                                       &cookieSize
                                       );
        if (result == noErr) {
            result = AudioFileSetProperty(
                                          inFile,
                                          kAudioFilePropertyMagicCookieData,
                                          cookieSize,
                                          magicCookie
                                          );
        }
        free(magicCookie);
    }
    if (result == noErr) {
        BDPLogDebug(@"SetMagicCookieForFile success");
    } else {
        BDPLogError(@"SetMagicCookieForFile error: [ERR:%d]", result);
    }
    return result;
}

static void PropertyListenerCallback(void *inUserData, AudioQueueRef inAQ, AudioQueuePropertyID inID)
{
    struct BDPRecorderState *recorderState = (struct BDPRecorderState *)inUserData;

    UInt32 running = 0;
    UInt32 size = 0;
    OSStatus stts = AudioQueueGetProperty(inAQ, kAudioQueueProperty_IsRunning, &running, &size);
    BDPLogDebug(@"get kAudioQueueProperty_IsRunning error: [ERR:%d]", stts);
    recorderState->mIsRunning = running;
//    NSLog(@"recording running: %d", running);

    if (!recorderState->mIsRunning) {
        AudioQueueStop(inAQ, YES);

        // a codec may update its cookie at the end of an encoding session, so reapply it to the file now
        // linear PCM, as used in this app, doesn't have magic cookies. this is included in case you
        // want to change to a format that does use magic cookies.
        OSStatus stts = noErr;
        stts = SetMagicCookieForFile(recorderState->mQueue, recorderState->mAudioFile);
        BDPLogDebug(@"SetMagicCookieForFile error: [ERR:%d]", stts);

        if (recorderState->onStopRecorderBlock) {
            recorderState->onStopRecorderBlock();
        }
    }
}

@interface BDPStreamingAudioRecorder () <AVAudioRecorderDelegate, OPMediaResourceInterruptionObserver>

@property (nonatomic, assign) struct BDPRecorderState recorderState;
@property (nonatomic, copy) dispatch_block_t durationBlock;
@property (nonatomic, copy) NSString *recorderURLPath;
@property (nonatomic, copy) NSString *fileExtension;

@property (nonatomic, strong) BDPScenarioObj *scenarioObj;

@end

@implementation BDPStreamingAudioRecorder
@synthesize wrapper = _wrapper;

+ (instancetype)shareInstance
{
    static dispatch_once_t onceToken;
    static BDPStreamingAudioRecorder *streamRecorder = nil;
    dispatch_once(&onceToken, ^{
        streamRecorder = [[BDPStreamingAudioRecorder alloc] init];
    });
    return streamRecorder;
}
#pragma mark - life cycle

- (instancetype)init {
    if(self = [super init]) {
        // 添加后台监听
        [self observerInit];
        // 初始化音频管理对象
        [self setupScenario];
    }
    return self;
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [self disposeAudioRecorderWithStopAction:NO];
}

#pragma mark - Audio Recorder

- (void)observerInit {
    // kBDPAudioInterruptionNotification
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(handleInterruption:)
                                                 name:kBDPAudioInterruptionNotification
                                               object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(webViewInterrupt:)
                                                 name:kWebBrowserInterruptionNotification
                                               object:nil];

    //UIApplicationDidEnterBackgroundNotification
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(applicationDidEnterBackground)
                                                 name:UIApplicationDidEnterBackgroundNotification
                                               object:nil];
    //UIApplicationWillResignActiveNotification
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(applicationWillResignActive)
                                                 name:UIApplicationWillResignActiveNotification
                                               object:nil];

}

- (void)setupScenario {
    NSString *name = [NSString stringWithFormat:@"com.recorder.gadget-%p", self];
    AVAudioSessionCategoryOptions options = AVAudioSessionCategoryOptionMixWithOthers;
    options |= AVAudioSessionCategoryOptionDefaultToSpeaker;
    options |= AVAudioSessionCategoryOptionAllowBluetooth;
    _scenarioObj = [[BDPScenarioObj alloc] initWithName:name
                                               category:AVAudioSessionCategoryPlayAndRecord
                                                   mode:AVAudioSessionModeDefault
                                                options:options];
}

- (void)setupAudioSession {
    [BDPAudioSessionProxy entryWithObj:self.scenarioObj scene:OPMediaMutexSceneAudioRecord observer:self];
}

- (void)applicationDidEnterBackground
{
    // 小程序进入后台或音频被打断时，暂停录音（录音不做恢复处理）
    if (_recorderState.mIsRunning && ([BDPPrivacyAccessNotifier sharedNotifier].currentStatus & BDPPrivacyAccessStatusMicrophone)) {
        [self pause:nil completion:nil];
    }
}

- (void)applicationWillResignActive
{
    // 小程序进入后台或音频被打断时，暂停录音（录音不做恢复处理）
    if (_recorderState.mIsRunning && ([BDPPrivacyAccessNotifier sharedNotifier].currentStatus & BDPPrivacyAccessStatusMicrophone)) {
        [self pause:nil completion:nil];
    }
}

- (void)webViewInterrupt:(NSNotification *)notification
{
    BOOL isActive = [notification.userInfo bdp_boolValueForKey:@"kViewActive"];
    if (!isActive) {
        // 小程序进入后台或音频被打断时，暂停录音（录音不做恢复处理）
        if (_recorderState.mIsRunning && ([BDPPrivacyAccessNotifier sharedNotifier].currentStatus & BDPPrivacyAccessStatusMicrophone)) {
            [self pause:nil completion:nil];
        }
    }
}

- (void)handleInterruption:(NSNotification *)notification {
    BDPAudioInterruptionOperationType type = [notification.userInfo bdp_integerValueForKey:kBDPAudioInterruptionOperationUserInfoKey];
    if (type == BDPAudioInterruptionOperationTypeBackground || type == BDPAudioInterruptionOperationTypeSystemBegan) {
        // 小程序进入后台或音频被打断时，暂停录音（录音不做恢复处理）
        if (_recorderState.mIsRunning) {
            // 退后台时暂停音频录制
            [self pause:nil completion:nil];
        }
    }
}

- (BOOL)prepareAudioRecorderWithAudioFormatID:(AudioFormatID)audioFormatID sampleRate:(Float64)sampleRate channelsPerFrame:(UInt32)channelsPerFrame frameSize:(UInt32)frameSize filePath:(NSString *)filePath completion:(void(^)(BDPAudioRecorderErrorType type, NSString * _Nullable errMsg))completion {
    [self setupAudioSession];

    OSStatus stts = noErr;
    // step 1: set up the format of recording
    // 未经过数据压缩，直接量化进行传输则被称为PCM（脉冲编码调制）。 要算一个PCM音频流的码率是一件很轻松的事情，采样率值×采样大小值×声道数bps。 一个采样率为44.1KHz，采样大小为16bit，双声道的PCM编码的WAV文件，它的数据速率则为44.1K×16×2=1411.2 Kbps。
    _recorderState.mDataFormat.mFormatID = audioFormatID; // [kAudioFormatMPEGLayer3, kAudioFormatMPEG4AAC]
    _recorderState.mDataFormat.mSampleRate = sampleRate; // 采样率, eg. 44100
    _recorderState.mDataFormat.mChannelsPerFrame = channelsPerFrame; // 1:单声道；2:立体声, eg. 1
    _recorderState.mDataFormat.mBitsPerChannel = 0;  // 语音每采样点占用位数[8/16/24/32], eg. 16
    _recorderState.mDataFormat.mFramesPerPacket = 1024; // 每个Packet的帧数量, eg. 1
    _recorderState.mDataFormat.mBytesPerFrame = _recorderState.mDataFormat.mChannelsPerFrame * _recorderState.mDataFormat.mBitsPerChannel / 8; //  (mBitsPerChannel / 8 * mChannelsPerFrame) 每帧的Byte数, eg. 2
    _recorderState.mDataFormat.mBytesPerPacket = _recorderState.mDataFormat.mBytesPerFrame * _recorderState.mDataFormat.mFramesPerPacket; // 每个Packet的Bytes数量, eg. 2
    _recorderState.mDataFormat.mFormatFlags = kAudioFormatFlagIsSignedInteger | kAudioFormatFlagIsPacked; // kLinearPCMFormatFlagIsPacked | kLinearPCMFormatFlagIsSignedInteger | kAudioFormatFlagIsBigEndian; // 标签格式, eg. kAudioFormatFlagIsSignedInteger | kAudioFormatFlagIsPacked

    // step 2: create audio intpu queue
    stts = AudioQueueNewInput(&_recorderState.mDataFormat, HandleAudioQueueInputBuffer, &_recorderState, CFRunLoopGetMain(), kCFRunLoopCommonModes, 0, &_recorderState.mQueue);
    
    if ([self needExitWith:stts msg:@"create recording audio queue error" errCode:BDPAudioRecorderErrorTypeCreateQueueFail completion:completion]) {
        return NO;
    }

    // step 3: get the detail format
    UInt32 dataFormatSize = sizeof(_recorderState.mDataFormat);
    stts = AudioQueueGetProperty(_recorderState.mQueue, kAudioQueueProperty_StreamDescription, &_recorderState.mDataFormat, &dataFormatSize);
    if ([self needExitWith:stts msg:@"get audio queue property error" errCode:BDPAudioRecorderErrorTypeGetQueuePropertyFail completion:completion]) {
        return NO;
    }

    stts = AudioQueueAddPropertyListener(
                                         _recorderState.mQueue,
                                         kAudioQueueProperty_IsRunning,
                                         PropertyListenerCallback,
                                         &_recorderState
                                         );
    if ([self needExitWith:stts msg:@"add audio isRunning listener error" errCode:BDPAudioRecorderErrorTypeAddListenerFail completion:completion]) {
        return NO;
    }

    // step 4: create audio file
    NSURL *tmpURL = [NSURL URLWithString: filePath];
    CFURLRef url = (__bridge CFURLRef)tmpURL;
    stts = AudioFileCreateWithURL(url, kAudioFileM4AType, &_recorderState.mDataFormat, kAudioFileFlags_EraseFile, &_recorderState.mAudioFile); // kAudioFileAIFFType(pcm), kAudioFileM4AType(aac), kAudioFileMP3Type(mp3)
    if ([self needExitWith:stts msg:@"create audio file error" errCode:BDPAudioRecorderErrorTypeCreateFileFail completion:completion]) {
        return NO;
    }
    BDPLogDebug(@"open file %@ success!", url);

    // step 5: prepare buffers and buffer queue
    _recorderState.bufferByteSize = frameSize > 0 ? frameSize : 50000;//kNumberPackages * recorderStat_.mDataFormat.mBytesPerPacket;
    for (int i = 0; i < kNumberBuffers; i++) {
        stts = AudioQueueAllocateBuffer(_recorderState.mQueue, _recorderState.bufferByteSize, &_recorderState.mBuffers[i]);
        if ([self needExitWith:stts msg:@"allocate audio queue buffer error" errCode:BDPAudioRecorderErrorTypeAllocateBufferFail completion:completion]) {
            return NO;
        }
        stts = AudioQueueEnqueueBuffer(_recorderState.mQueue, _recorderState.mBuffers[i], 0, NULL);
        if ([self needExitWith:stts msg:@"enqueue audio queue buffer error" errCode:BDPAudioRecorderErrorTypeEnqueueBufferFail completion:completion]) {
            return NO;
        }
    }

    WeakSelf;
    // frameSize: 指定帧大小，单位 KB。
    // 传入 frameSize 后，每录制指定帧大小的内容后，会回调录制的文件内容，不指定则不会回调
    if (frameSize > 0) {
        _recorderState.onFrameRecordedWithAudioDataBlock = ^(struct BDPRecorderState *recorderState, AudioQueueRef inAQ, AudioQueueBufferRef inBuffer, UInt32 inNumberPacketDescriptions, const AudioStreamPacketDescription *inPacketDescs) {
            StrongSelfIfNilReturn;
            [self onFrameRecordedWithRecorderState:recorderState inAQ:inAQ inBuffer:inBuffer inNumberPacketDescriptions:inNumberPacketDescriptions inPacketDescs:inPacketDescs];
        };;
    }

    _recorderState.onStopRecorderBlock = ^{
        StrongSelfIfNilReturn
        [self disposeAudioRecorderWithStopAction:YES];
    };
    _recorderState.onErrorRecorderBlock = ^(NSString *errMsg){
        StrongSelfIfNilReturn
        [self audioRecorderEncodeErrorWithMessage:errMsg];
    };

    SetMagicCookieForFile(_recorderState.mQueue, _recorderState.mAudioFile);

    return YES;
}

/// audio recorder 终止逻辑
///
/// audio recorder 在 listenerCallback 的终止分为两部分，在老逻辑上是分开的，现在合并在一个方法。
///     1. stop，主要是处理结果文件并返回 js stop 事件。
///     2. dispose，主要是处理相关对象及监听的销毁。
/// 老逻辑是在 PropertyListenerCallback 同步处理并先 1 后 2 同步调用的。
///
/// 老逻辑存在的问题:
///     1. stop 使用的是 AudioQueueFlush + AudioQueueStop(immediately) 的方式停止，但是根据官方文档描述，
///        并不能保证立即同步终止（还会继续写入 queue 中的 buffer），而老逻辑在 listenerCallback 的回调中是
///        同步调用，此时还在写文件，加解密场景下会导致文件加密后仍持续写入录音数据而不可读。原逻辑之所以没问题是因
///        为 js 回调也是异步，且没有加密逻辑，不会改变文件路径，前端恰好拿到原始文件路径后还能正常操作。
///     2. 按照官方文档，如果将 stop 逻辑改为 AudioQueueFlush + AudioQueueStop(非 immediately) 方式停止，
///        理论上可以保证结果的一致性，即 listenerCallback 回调时 queue 中的 buffer 已经写入完成，可以正常对
///        完整的文件结果做加密。但实际测试下来回调发生时还是会写入 buffer 数据，而且就算有一致性，在前端表现上也会
///        变为点击 stop 后需要等待一段时间（主要是等待 queue 中的剩余 buffer 写入，用户可感知）才能回调并在 UI
///        上显示停止。
///
/// 综上，在「文件操作收敛」 + 「加解密」场景下我们需要调整这里的逻辑顺序:
///     1. 将原有的 stop 和 dispose 同步调用逻辑合并在一个方法。并且保证在处理文件之前已经完整处理了「移除事件监听」、
///        「销毁 recorder queue」、「close 文件」操作，后续文件操作状态的一致性。
///     2. 原单独调用 dispose 逻辑的地方通过添加 handleStopAction 参数控制。
///
/// 上述改造完成后，既保证了文件操作的一致性，也解决了历史实现上的潜在问题，还保持了 UI 体验与之前一致。
///
/// 后续演进方向:
///     1. 目前终止逻辑都是主线程同步调用，相关文件操作也是同步调用，后续引入加解密可能会产生耗时操作，合并后的逻辑需要考虑异步。
///     2. 这个类是个单例，uniqueId，engine 之类的都是 API 调用时候设置的，如果有异步改造，需要将 fireEvent 相关调用改为无状态。
///
/// @param handleStopAction 是否处理 recorder 结果文件，并发出 stop 事件。
- (BOOL)disposeAudioRecorderWithStopAction:(BOOL)handleStopAction {
    OSStatus stts = noErr;
    if (_recorderState.mIsRunning) {
        [self updateMicrophoneAccessStatus:NO];
        [OPMediaMutex unlockWithScene:OPMediaMutexSceneAudioRecord wrapper:self.wrapper];
    }
    if (_recorderState.mQueue) {
        stts = AudioQueueRemovePropertyListener(_recorderState.mQueue,
                                                kAudioQueueProperty_IsRunning,
                                                PropertyListenerCallback,
                                                &_recorderState);
        if (stts == noErr) {
            BDPLogDebug(@"AudioQueueRemovePropertyListener success");
        } else {
            BDPLogError(@"AudioQueueRemovePropertyListener error");
        }
        stts = AudioQueueDispose(_recorderState.mQueue, true);
        if (stts == noErr) {
            BDPLogDebug(@"AudioQueueDispose success");
        } else {
            BDPLogError(@"AudioQueueDispose error");
        }
        _recorderState.mQueue = NULL;
    }

    if (_recorderState.mAudioFile) {
        stts = AudioFileClose(_recorderState.mAudioFile);
        if (stts == noErr) {
            BDPLogDebug(@"AudioFileClose success");
        } else {
            BDPLogError(@"AudioFileClose error");
        }
        _recorderState.mAudioFile = NULL;
    }

    _recorderState.onFrameRecordedWithAudioDataBlock = nil;
    _recorderState.onStopRecorderBlock = nil;
    _recorderState.onErrorRecorderBlock = nil;
    _recorderState.mCurrentPacket = 0;
    
    [BDPAudioSessionProxy leaveWithObj:self.scenarioObj scene:OPMediaMutexSceneAudioRecord wrapper:self.wrapper];
    [self stopTimer];

    if (handleStopAction) {
        OPFileObject *fileObj = [OPFileObject generateRandomTTFile:BDPFolderPathTypeTemp fileExtension:self.fileExtension];
        OPFileSystemContext *fsContext = [[OPFileSystemContext alloc] initWithUniqueId:self.uniqueID trace:nil tag:@"operateRecorder"];
        NSError *error = nil;
        BOOL result = [OPFileSystemCompatible moveSystemFile:self.recorderURLPath to:fileObj context:fsContext error:&error];
        NSString *tempFilePath = fileObj.rawValue;
        if (!result || error) {
            fsContext.trace.error(@"move system file failed, result: %@, error: %@", @(result), error.description);
            tempFilePath = @""; // 与原逻辑等价
        }
        [self stateChange:@"stop" data:@{ @"tempFilePath": tempFilePath ?: @"" }];
        [self updateMicrophoneAccessStatus:NO];
        [OPMediaMutex unlockWithScene:OPMediaMutexSceneAudioRecord wrapper:self.wrapper];
    }

    return YES;
}

- (void)startTimerWithCallback:(dispatch_block_t)callback duration:(NSTimeInterval)duration {
    if (!callback) {
        return;
    }
    WeakSelf;
    dispatch_block_t newBlock = dispatch_block_create(0, ^{
        StrongSelfIfNilReturn;
        if (callback) {
            callback();
        }
        self.durationBlock = nil;
    });
    self.durationBlock = newBlock;
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(duration * NSEC_PER_SEC)), dispatch_get_main_queue(), newBlock);
}

- (void)stopTimer {
    dispatch_block_t block = self.durationBlock;
    if (!block) {
        return;
    }
    dispatch_block_cancel(block);
    self.durationBlock = nil;
}

#pragma mark - Actions

- (void)operateState:(NSDictionary * _Nullable)action completion:(void(^)(BDPAudioRecorderErrorType type, NSString * _Nullable errMsg))completion {
    NSString *state = [action bdp_stringValueForKey:@"operationType"];
    if ([state isEqualToString:@"start"]) {
        [self start:action completion:completion];
        return;
    } else if ([state isEqualToString:@"pause"]) {
        [self pause:action completion:completion];
        return;
    } else if ([state isEqualToString:@"resume"]) {
        [self resume:action completion:completion];
        return;
    } else if ([state isEqualToString:@"stop"]) {
        [self stop:action completion:completion];
        return;
    }
    !completion ?: completion(BDPAudioRecorderErrorTypeOperationTypeInvalid, nil);
}

- (void)forceStopRecorder // 强制停止录音，在退出小程序或者关闭音频权限时调用 by zhangquan
{
    if (_recorderState.mIsRunning) {
        [self stop:nil completion:nil];
    }
}

/*-----------------------------------------------*/
//          Recorder Operate - 录音操作
/*-----------------------------------------------*/
- (void)start:(NSDictionary *)action completion:(void(^)(BDPAudioRecorderErrorType type, NSString * _Nullable errMsg))completion {
    NSInteger sampleRate = [action integerValueForKey:@"sampleRate" defaultValue:16000];
    NSInteger encodeBitRate = [action integerValueForKey:@"encodeBitRate" defaultValue:0];
    NSInteger numberOfChannels = [action integerValueForKey:@"numberOfChannels" defaultValue:1];
    NSInteger duration = [action integerValueForKey:@"duration" defaultValue:60000];
    duration = MAX(0, duration / 1000);
    NSString *format = [action stringValueForKey:@"format" defaultValue:@"mp3"];
    // 目前只支持录制aac格式，因为苹果没有录制mp3的专利授权
    format = @"aac";
    sampleRate = MAX(8000, MIN(44100, sampleRate));
    if (sampleRate != 8000 && sampleRate != 44100) {
        sampleRate = 16000;
    }

    if (sampleRate == 8000) {
        encodeBitRate = MAX(16000, MIN(48000, encodeBitRate));
    } else if (sampleRate == 16000) {
        encodeBitRate = MAX(24000, MIN(96000, encodeBitRate));
    } else if (sampleRate == 44100) {
        encodeBitRate = MAX(64000, MIN(320000, encodeBitRate));
    }

    AudioFormatID audioFormatID = [format isEqualToString:@"aac"] ? kAudioFormatMPEG4AAC : kAudioFormatMPEGLayer3;
    UInt32 channelsPerFrame = (numberOfChannels == 2) ? 2 : 1;
    UInt32 frameSize = [action integerValueForKey:@"frameSize" defaultValue:0] * 1000; // KB -> byte
    // encodeBitRate暂时没用

    if (_recorderState.mIsRunning) {
//        BDP_CALLBACK_WITH_ERRMSG(BDPJSBridgeCallBackTypeFailed, @"It is already recording")
        //如果正在录制，先停止掉上次的录制
        [self stop:nil completion:nil];
    }
    
    NSString *errorInfo = [OPMediaMutex tryLockAndUnmuteSyncWithScene:OPMediaMutexSceneAudioRecord observer:self];
    if (!BDPIsEmptyString(errorInfo)) {
        !completion ?: completion(BDPAudioRecorderErrorTypeStartLockMutexFail, errorInfo);
        return;
    }
    
    [self setupAudioSession];

    NSString *fileExtension = [format isEqualToString:@"aac"] ? @"m4a" : @"mp3";
    self.fileExtension = fileExtension;
    BDPResolveModule(storageModule, BDPStorageModuleProtocol, self.uniqueID.appType);
    id<BDPMinimalSandboxProtocol> sandbox = [storageModule minimalSandboxWithUniqueID:self.uniqueID];

    // 标准化文件操作，内部业务逻辑产生的中间文件应当放入到 privateTmpPath，而不是用户可见的 tmp 目录。
    // 等到真正的 recorder 完成时再将文件产物移动到 tmp 目录返回给用户。
        NSString *randomPrivateTmpPath = [OPFileSystemUtils generateRandomPrivateTmpPathWith:sandbox
                                                                               pathExtension:fileExtension];
        self.recorderURLPath = randomPrivateTmpPath;
        BOOL prepareResult = [self prepareAudioRecorderWithAudioFormatID:audioFormatID
                                                              sampleRate:sampleRate
                                                        channelsPerFrame:channelsPerFrame
                                                               frameSize:frameSize
                                                                filePath:randomPrivateTmpPath
                                                              completion:completion];
        if (!prepareResult) {
            [self disposeAudioRecorderWithStopAction:NO];
            return;
        }
    
    OSStatus stts = AudioQueueStart(_recorderState.mQueue, NULL);
    if ([self needExitWith:stts msg:@"start recording audio error" errCode:BDPAudioRecorderErrorTypeStartFail completion:completion]) {
        return;
    }
//    _recorderState.mIsRunning = YES;
    [self stateChange:@"start" data:nil];
    [self updateMicrophoneAccessStatus:YES];
    WeakSelf;
    [self startTimerWithCallback:^{
        StrongSelfIfNilReturn;
        [self stop:nil completion:nil];
    } duration:duration];
    !completion ?: completion(BDPAudioRecorderErrorTypeSuccess, nil);
}

- (void)pause:(NSDictionary * _Nullable)action completion:(void(^ _Nullable)(BDPAudioRecorderErrorType type, NSString * _Nullable errMsg))completion {
    OSStatus stts = AudioQueuePause(_recorderState.mQueue);
    if ([self needExitWith:stts msg:@"pause recording error" errCode:BDPAudioRecorderErrorTypePauseFail completion:completion]) {
        return;
    }
    [self stateChange:@"pause" data:nil];
    [self updateMicrophoneAccessStatus:NO];
    !completion ?: completion(BDPAudioRecorderErrorTypeSuccess, nil);
}

- (void)stop:(NSDictionary * _Nullable)action completion:(void(^ _Nullable)(BDPAudioRecorderErrorType type, NSString * _Nullable errMsg))completion {
    _recorderState.mIsRunning = NO;
    [self stopTimer];
    OSStatus stts;
    stts = AudioQueueFlush(_recorderState.mQueue);
    BDPLogError(@"AudioQueueFlush error: [ERR:%d]", stts);
    stts = AudioQueueStop(_recorderState.mQueue, true);
    if ([self needExitWith:stts msg:@"stop recording error" errCode:BDPAudioRecorderErrorTypeStopFail completion:completion]) {
        return;
    }
    [self updateMicrophoneAccessStatus:NO];
    [OPMediaMutex unlockWithScene:OPMediaMutexSceneAudioRecord wrapper:self.wrapper];
    !completion ?: completion(BDPAudioRecorderErrorTypeSuccess, nil);
}

- (void)resume:(NSDictionary * _Nullable)action completion:(void(^ _Nullable)(BDPAudioRecorderErrorType type, NSString * _Nullable errMsg))completion {
    OSStatus stts = AudioQueueStart(_recorderState.mQueue, NULL);
    if ([self needExitWith:stts msg:@"resume recording error" errCode:BDPAudioRecorderErrorTypeResumeFail completion:completion]) {
        return;
    }
    [self stateChange:@"resume" data:nil];
    [self updateMicrophoneAccessStatus:YES];
    !completion ?: completion(BDPAudioRecorderErrorTypeSuccess, nil);
}

- (void)audioRecorderEncodeErrorWithMessage:(NSString *)message {
    [self stateChange:@"error" data:@{@"errMsg": message ?: @""}];
    [self updateMicrophoneAccessStatus:NO];
    [OPMediaMutex unlockWithScene:OPMediaMutexSceneAudioRecord wrapper:self.wrapper];
}

/*-----------------------------------------------*/
//           Recorder State - 录音状态
/*-----------------------------------------------*/
- (void)stateChange:(NSString *)state data:(NSDictionary *)data {
    if (BDPIsEmptyString(state)) {
        return;
    }

    NSMutableDictionary *mutableData = [[NSMutableDictionary alloc] initWithDictionary:data ? : @{}];
    [mutableData setValue:state forKey:@"state"];
    if (self.stateChangeBlock) {
        self.stateChangeBlock([mutableData copy]);
    }
}

#pragma mark - 创建分段录音文件

- (void)onFrameRecordedWithRecorderState:(struct BDPRecorderState *)recorderState inAQ:(AudioQueueRef)inAQ inBuffer:(AudioQueueBufferRef)inBuffer inNumberPacketDescriptions:(UInt32)inNumberPacketDescriptions inPacketDescs:(const AudioStreamPacketDescription *)inPacketDescs {
    // 1: 创建音频文件
    NSString *fileExtension = self.fileExtension;
    BDPResolveModule(storageModule, BDPStorageModuleProtocol, self.uniqueID.appType);
    id<BDPMinimalSandboxProtocol> sandbox = [storageModule minimalSandboxWithUniqueID:self.uniqueID];
    NSString *filePath = [storageModule generateRandomFilePathWithType:BDPFolderPathTypeTemp sandbox:sandbox extension:fileExtension addFileScheme:NO];
    NSURL *tmpURL = [NSURL fileURLWithPath:filePath];
    CFURLRef url = (__bridge CFURLRef)tmpURL;
    AudioFileID frameRecordedAudioFile;
    OSStatus stts = AudioFileCreateWithURL(url, kAudioFileM4AType, &recorderState->mDataFormat, kAudioFileFlags_EraseFile, &frameRecordedAudioFile); // kAudioFileAIFFType(pcm), kAudioFileM4AType(aac), kAudioFileMP3Type(mp3)
    VStatusAndShowError(stts, @"FrameRecorded: create audio file error");
    BDPLogDebug(@"FrameRecorded: open file %@ success!", tmpURL);

    // 2. 写入Magic Cookie
    SetMagicCookieForFile(recorderState->mQueue, frameRecordedAudioFile);

    // 3. 写入分片数据
    SInt16 currentPacket = 0;
    if (inNumberPacketDescriptions > 0) {
        stts = AudioFileWritePackets(frameRecordedAudioFile, false, recorderState->bufferByteSize, inPacketDescs, currentPacket, &inNumberPacketDescriptions, inBuffer->mAudioData);
        VStatusAndShowError(stts, @"AudioFileWritePackets error");


        // 4. 写入文件
        stts = AudioFileClose(frameRecordedAudioFile);
        if (stts == noErr) {
            BDPLogDebug(@"AudioFileClose success");
        } else {
            BDPLogError(@"AudioFileClose error");
        }

        // 5. 发送音频数据
        if (stts == noErr) {
            NSData *audioData = [NSData lss_dataWithContentsOfURL:tmpURL error:nil];
            NSString *base64AudioString = [audioData base64EncodedStringWithOptions:0];
            // BDPLogDebug(@"data: %@", audioData);
            BOOL isLastFrame = (!recorderState->mIsRunning);
//            NSLog(@"onFrameRecorded isLastFrame: %@", isLastFrame ? @"YES" : @"NO");
            [self stateChange:@"frameRecorded" data:@{@"frameBuffer": base64AudioString ?: @"",
                                                      @"isLastFrame": @(isLastFrame)
                                                      }];
        }

        // 6. 删除临时文件
        [[LSFileSystem main] removeItemAtPath:tmpURL.path error:nil];
    }
}

- (BOOL)needExitWith:(OSStatus)err msg:(NSString * _Nullable)msg  errCode:(BDPAudioRecorderErrorType)errCode completion:(void(^ _Nullable)(BDPAudioRecorderErrorType type, NSString * _Nullable errMsg))completion {
    if (noErr != err) {
        NSString *errMsg = [NSString stringWithFormat: @"[ERR:%d]:%@", err, msg];
        BDPLogError(errMsg);
        !completion ?: completion(errCode, msg);
        return YES;
    }
    return NO;
}

#pragma mark - Utils
/*-----------------------------------------------*/
//                  Utils - 工具
/*-----------------------------------------------*/
- (void)updateMicrophoneAccessStatus:(BOOL)isUsing
{
    [[BDPPrivacyAccessNotifier sharedNotifier] setPrivacyAccessStatus:BDPPrivacyAccessStatusMicrophone isUsing:isUsing];
}

#pragma mark - OPMediaResourceInterruptionObserver

- (void)mediaResourceWasInterruptedBy:(NSString *)scene msg:(NSString * _Nullable)msg {
    BDPLogInfo(@"BDPStreamingAudioRecorder %@ mediaResourceWasInterruptedBy scene: %@, msg: %@", self, scene, msg ?: @"");
    [self pause:nil completion:nil];
}

- (void)mediaResourceInterruptionEndFrom:(NSString *)scene {
    BDPLogInfo(@"mediaResourceInterruptionEndFrom: %@", scene);
}

@end

