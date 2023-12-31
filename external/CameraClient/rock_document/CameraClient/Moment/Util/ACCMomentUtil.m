//
//  ACCMomentUtil.m
//  Pods
//
//  Created by Pinka on 2020/6/8.
//

#import "ACCMomentUtil.h"

@implementation ACCMomentUtil

+ (NSUInteger)degressFromAsset:(AVAsset *)asset
{
    NSUInteger degress = 0;
    NSArray *tracks = [asset tracksWithMediaType:AVMediaTypeVideo];
    if([tracks count] > 0) {
        AVAssetTrack *videoTrack = [tracks objectAtIndex:0];
        CGAffineTransform t = videoTrack.preferredTransform;
        
       if (t.a == 0 && t.b == 1.0 && t.c == -1.0 && t.d == 0){
            // Portrait
            degress = 90;
        } else if(t.a == 0 && t.b == -1.0 && t.c == 1.0 && t.d == 0){
            // PortraitUpsideDown
            degress = 270;
        } else if(t.a == 1.0 && t.b == 0 && t.c == 0 && t.d == 1.0){
            // LandscapeRight
            degress = 0;
        } else if(t.a == -1.0 && t.b == 0 && t.c == 0 && t.d == -1.0){
            // LandscapeLeft
            degress = 180;
        }
   }
    
   return degress;
}

+ (NSUInteger)degressFromImage:(UIImage *)image
{
    if (image.imageOrientation == UIImageOrientationUp) {
        return 0;
    } else if (image.imageOrientation == UIImageOrientationDown) {
        return 180;
    } else if (image.imageOrientation == UIImageOrientationLeft) {
        return 90;
    } else if (image.imageOrientation == UIImageOrientationRight) {
        return 270;
    }
    
    return 0;
}

+ (NSUInteger)aiOrientationFromDegress:(NSUInteger)degress
{
    return degress/90;
}

@end
