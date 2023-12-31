//
//  ACCRatioActionData.h
//  CameraClient
//
//  Created by ZhangYuanming on 2020/2/2.
//

#import <Foundation/Foundation.h>
#import <AVFoundation/AVFoundation.h>
#import <TTVideoEditor/IESMMBaseDefine.h>

NS_ASSUME_NONNULL_BEGIN

@interface ACCRatioActionData : NSObject

@property (nonatomic, nullable) AVCaptureSessionPreset preferPreset;
@property (nonatomic) IESMMCaptureRatio captureRatio;
@property (nonatomic) CGFloat previewHeight;
@property (nonatomic) CGFloat outputHeight;

@end

NS_ASSUME_NONNULL_END
