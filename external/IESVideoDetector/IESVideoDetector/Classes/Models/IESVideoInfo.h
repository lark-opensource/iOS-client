//
//  IESVideoInfo.h
//  CameraClient
//
//  Created by geekxing on 2020/4/3.
//

#import <Foundation/Foundation.h>
#import <CoreMedia/CoreMedia.h>

NS_ASSUME_NONNULL_BEGIN

@interface IESVideoInfo : NSObject


/// An invalid video info represents asset which async loads failed
+ (instancetype)invalidVideoInfo;

@property (nonatomic, assign) CMTime duration;
@property (nonatomic, assign) CMTime videoDuration;
@property (nonatomic, assign) float frameRate;
@property (nonatomic, assign) float bitrate;
@property (nonatomic, assign) CGSize videoSize;

@end

NS_ASSUME_NONNULL_END
