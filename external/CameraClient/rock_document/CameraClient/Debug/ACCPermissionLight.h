//
//  ACCPermissionMonitor.h
//  CameraClientTikTok
//
//  Created by wishes on 2020/8/9.
//

#if DEBUG || INHOUSE_TARGET

#import <Foundation/Foundation.h>
#import <AVFoundation/AVFoundation.h>

NS_ASSUME_NONNULL_BEGIN

struct RECORD_AU {
    intptr_t AU;
    BOOL isRecording;
};

@interface AVCaptureSession (ACCPermissionLight)

+ (void)acc_load;

@end


@interface ACCPermissionLight : NSObject

@property (nonatomic,assign) BOOL isRecordingVideo;

@property (nonatomic,assign) struct RECORD_AU recordAU;

+ (instancetype)shareInstance;

+ (void)acc_load;

- (void)startRecordAU:(intptr_t)AU;

- (void)stopRecordAU:(intptr_t)AU;

@end

NS_ASSUME_NONNULL_END

#endif
