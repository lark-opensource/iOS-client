//
//  IESAssetFormatterFunctions.h
//  CameraClient
//
//  Created by geekxing on 2020/4/13.
//

#ifndef IESAssetFormatterFunctions_h
#define IESAssetFormatterFunctions_h
#import <AVFoundation/AVFoundation.h>

static NSString *const IESAssetMonitorKeyDuration = @"duration";
static NSString *const IESAssetMonitorKeyVideoDuration = @"v_duration";
static NSString *const IESAssetMonitorKeyFrameRate = @"frameRate";
static NSString *const IESAssetMonitorKeyVideoBitrate = @"v_bitrate";
static NSString *const IESAssetMonitorKeyVideoResolution = @"resolution";
static NSString *const IESAssetMonitorKeyIncompleted = @"incompleted";

NS_INLINE NSString *stringFromCMTime(CMTime time) {
    NSString *formattedTime;
    if (CMTIME_IS_NUMERIC(time)) {
        formattedTime = [NSString stringWithFormat:@"%.2f", CMTimeGetSeconds(time)];
    } else {
        formattedTime = [NSString stringWithFormat:@"%@", [NSValue valueWithCMTime:time]];
    }
    return formattedTime;
}

CG_INLINE CGSize displayVideoSize(CGSize naturalSize, CGAffineTransform t) {
    CGSize dimensions = CGSizeApplyAffineTransform(naturalSize,t);
    return CGSizeMake(fabs(dimensions.width), fabs(dimensions.height));
}

NS_INLINE NSNumber *bitrateWithEstimatedDataRate(float estimatedDataRate) {
    return @((NSInteger)(roundf(estimatedDataRate/1000.f))); //kbps
}


#endif /* IESAssetFormatterFunctions_h */
