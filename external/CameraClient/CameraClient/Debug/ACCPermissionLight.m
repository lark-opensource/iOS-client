//
//  ACCPermissionMonitor.m
//  CameraClientTikTok
//
//  Created by wishes on 2020/8/9.
//

#if DEBUG || INHOUSE_TARGET


#import "ACCPermissionLight.h"
#import <CreativeKit/NSObject+ACCAdditions.h>
#import <BDFishhook/BDFishhook.h>
#import <AudioToolbox/AUGraph.h>

@interface AVCaptureSession (ACCPermissionLight)

@end

@implementation AVCaptureSession (ACCPermissionLight)

+ (void)acc_load {
    [self acc_swizzleInstanceMethod:@selector(startRunning) with:@selector(acc_startRunning)];
    [self acc_swizzleInstanceMethod:@selector(stopRunning) with:@selector(acc_stopRunning)];
}

- (void)acc_startRunning {
    [ACCPermissionLight shareInstance].isRecordingVideo = YES;
    [self acc_startRunning];
}

- (void)acc_stopRunning {
    [ACCPermissionLight shareInstance].isRecordingVideo = NO;
    [self acc_stopRunning];
}

@end


OSStatus (*ORIG_AudioOutputUnitStart)(AudioUnit);
OSStatus (*ORIG_AudioOutputUnitStop)(AudioUnit);

OSStatus (*ORIG_AUGraphStart)(AUGraph);
OSStatus (*ORIG_AUGraphStop)(AUGraph);

static inline BOOL IsRecorderAudioUnit(AudioUnit au) {
    UInt32 flag;
    UInt32 size = sizeof(UInt32);
    AudioUnitGetProperty(au, kAudioOutputUnitProperty_EnableIO, kAudioUnitScope_Input, 1, &flag, &size);
    if (flag != 1) {
        return NO;
    }
    AudioComponent component = AudioComponentInstanceGetComponent(au);
    AudioComponentDescription description;
    AudioComponentGetDescription(component, &description);
    if (description.componentType != kAudioUnitType_Output) {
       return NO;
    }
    return YES;
}

static inline BOOL IsRecordAudioGraph(AUGraph ag) {
    UInt32 count;
    AUNode node;
    AudioUnit audioUnit;
    AUGraphGetNodeCount(ag, &count);
    for (int i = 0; i < count; i++) {
        AUGraphGetIndNode(ag, i, &node);
        if (!node) continue;
        AUGraphNodeInfo(ag, node, NULL, &audioUnit);
        if (!audioUnit) continue;
        if (IsRecorderAudioUnit(audioUnit)) {
            return YES;
        }
    }
    
    return NO;
}

OSStatus ACCAudioOutputUnitStart(AudioUnit au) {
    if (IsRecorderAudioUnit(au)) {
        [[ACCPermissionLight shareInstance] startRecordAU:(intptr_t)au];
    }
    return ORIG_AudioOutputUnitStart(au);
}

OSStatus ACCAudioOutputUnitStop(AudioUnit au) {
    if (IsRecorderAudioUnit(au)) {
        [[ACCPermissionLight shareInstance] stopRecordAU:(intptr_t)au];
    }
    return ORIG_AudioOutputUnitStop(au);
}

OSStatus ACCAUGraphStart(AUGraph ag) {
    if (IsRecordAudioGraph(ag)) {
        [[ACCPermissionLight shareInstance] startRecordAU:(intptr_t)ag];
    }
    return ORIG_AUGraphStart(ag);
}

OSStatus ACCAUGraphStop(AUGraph ag) {
    if (IsRecordAudioGraph(ag)) {
        [[ACCPermissionLight shareInstance] stopRecordAU:(intptr_t)ag];
    }
    return ORIG_AUGraphStop(ag);
}

@implementation ACCPermissionLight


+ (void)acc_load {
    open_bdfishhook();
    // hook same function multi times(functions below also hooked by TSPrivacyKit) are not safe, use local fishhook to workaround
    bd_rebind_symbols((struct bd_rebinding[2]){
        {"AudioOutputUnitStart", ACCAudioOutputUnitStart, (void *)&ORIG_AudioOutputUnitStart},
        {"AUGraphStart", ACCAUGraphStart, (void *)&ORIG_AUGraphStart}
    }, 2);
    bd_rebind_symbols((struct bd_rebinding[2]){
        {"AudioOutputUnitStop", ACCAudioOutputUnitStop, (void *)&ORIG_AudioOutputUnitStop},
        {"AUGraphStop", ACCAUGraphStop, (void *)&ORIG_AUGraphStop}
    }, 2);
}

+ (instancetype)shareInstance {
    static dispatch_once_t onceToken;
    static ACCPermissionLight* light;
    dispatch_once(&onceToken, ^{
        light = [ACCPermissionLight new];
    });
    return light;
}

- (void)startRecordAU:(intptr_t)pointer {
    self.recordAU = (struct RECORD_AU){
       .AU = pointer,
       .isRecording = YES
    };
}

- (void)stopRecordAU:(intptr_t)pointer {
    self.recordAU = (struct RECORD_AU){
       .AU = pointer,
       .isRecording = NO
    };
}

@end

#endif
