//
//  ACCAudioPortServiceImpl.m
//  CameraClient-Pods-Aweme
//
//  Created by bytedance on 2021/6/3.
//

#import "ACCAudioPortServiceImpl.h"

#import <AVFoundation/AVFoundation.h>
#import <ReactiveObjC/RACSubject.h>
#import <ReactiveObjC/RACTuple.h>

@interface ACCAudioPortServiceImpl ()

@property (nonatomic, strong) RACSubject<RACTwoTuple *> *IOPortChangeSubject;

#pragma mark - ACCAudioPortService
@property (nonatomic, assign, readwrite) ACCAudioIOPort inputPort;
@property (nonatomic, assign, readwrite) ACCAudioIOPort outputPort;

@end

@implementation ACCAudioPortServiceImpl

- (instancetype)init
{
    self = [super init];
    if (self) {
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(updateIOPort) name:AVAudioSessionRouteChangeNotification object:nil];
        [self updateIOPort];
    }
    return self;
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [_IOPortChangeSubject sendCompleted];
}

- (void)updateIOPort
{
    AVAudioSessionRouteDescription *description = [AVAudioSession sharedInstance].currentRoute;
    AVAudioSessionPort inputPort = description.inputs.firstObject.portType;
    self.inputPort = ACCAudioIOPortBuiltin;
    if ([inputPort isEqualToString:AVAudioSessionPortBluetoothHFP]) {
        self.inputPort = ACCAudioIOPortBluetooth;
    } else if ([inputPort isEqualToString:AVAudioSessionPortHeadsetMic]) {
        self.inputPort = ACCAudioIOPortWiredHeadset;
    }
    AVAudioSessionPort outputPort = description.outputs.firstObject.portType;
    self.outputPort = ACCAudioIOPortBuiltin;
    if ([outputPort isEqualToString:AVAudioSessionPortBluetoothA2DP] || [outputPort isEqualToString:AVAudioSessionPortBluetoothLE] || [outputPort isEqualToString:AVAudioSessionPortBluetoothHFP]) {
        self.outputPort = ACCAudioIOPortBluetooth;
    } else if ([outputPort isEqualToString:AVAudioSessionPortHeadphones]) {
        self.outputPort = ACCAudioIOPortWiredHeadset;
    }
    [self.IOPortChangeSubject sendNext:[RACTwoTuple pack:@(self.inputPort) :@(self.outputPort)]];
}

#pragma mark - ACCAudioPortService

- (RACSignal<RACTwoTuple *> *)IOPortChangeSignal
{
    return self.IOPortChangeSubject;
}

- (RACSubject<RACTwoTuple *> *)IOPortChangeSubject
{
    if (!_IOPortChangeSubject) {
        _IOPortChangeSubject = [RACSubject subject];
    }
    return _IOPortChangeSubject;
}

@end
