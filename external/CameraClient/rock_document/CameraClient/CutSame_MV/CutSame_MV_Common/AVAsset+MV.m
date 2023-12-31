//
//  AVAsset+LV.m
//  CameraClient
//
//  Created by xulei on 2020/6/1.
//

#import "AVAsset+MV.h"
#import "CGSize+MV.h"

@implementation AVAsset (MV)

- (AVCaptureVideoOrientation)mv_fixedOrientation {
    NSArray *tracks = [self tracksWithMediaType:AVMediaTypeVideo];
    AVAssetTrack *track = tracks.firstObject;
    if(!track) {
        return AVCaptureVideoOrientationPortrait;
    }
    CGAffineTransform t = track.preferredTransform;
    if(t.a == 0 && t.b == 1.0 && t.c == -1.0 && t.d == 0) {
        // Portrait
        return AVCaptureVideoOrientationLandscapeRight;
    } else if(t.a == 0 && t.b == -1.0 && t.c == 1.0 && t.d == 0) {
        // PortraitUpsideDown
        return AVCaptureVideoOrientationLandscapeLeft;
    } else if(t.a == -1.0 && t.b == 0 && t.c == 0 && t.d == -1.0) {
        // LandscapeLeft
        return AVCaptureVideoOrientationPortraitUpsideDown;
    } else {
        return AVCaptureVideoOrientationPortrait;
    }
}

- (CGSize)mv_videoSize {
    CGSize size = CGSizeZero;
    for (AVAssetTrack *track in self.tracks) {
        if ([track.mediaType isEqualToString:AVMediaTypeVideo]) {
            size = track.naturalSize;
            AVCaptureVideoOrientation orientation = [self mv_fixedOrientation];
            if (orientation != AVCaptureVideoOrientationPortrait && orientation != AVCaptureVideoOrientationPortraitUpsideDown) {
                size = CGSizeMake(size.height, size.width);
            }
            
            break;
        }
    }
    return mv_CGSizeSafeValue(size);
}

@end
