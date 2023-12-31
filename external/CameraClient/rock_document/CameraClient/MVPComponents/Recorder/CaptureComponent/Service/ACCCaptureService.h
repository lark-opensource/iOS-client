//
//  ACCCaptureService.h
//  CameraClient-Pods-AwemeCore
//
//  Created by qy on 2021/10/21.
//

#import <CreationKitInfra/ACCRACWrapper.h>
#import <CreationKitArch/ACCRecordMode.h>

typedef RACTwoTuple<ACCRecordMode *, ACCRecordMode *> *ACCRecordModeChangePack;

@protocol ACCCaptureService <NSObject>

@property (nonatomic, strong, readonly, nonnull) RACSignal <ACCRecordModeChangePack> *captureReadyForSwitchModeSignal;

@end
