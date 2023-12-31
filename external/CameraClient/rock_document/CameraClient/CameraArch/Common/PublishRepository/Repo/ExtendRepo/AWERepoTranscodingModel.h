//
//  AWERepoTranscodingModel.h
//  CameraClient-Pods-Aweme
//
//  Created by yangying on 2020/10/14.
//

#import <CreationKitArch/ACCRepoTranscodingModel.h>


NS_ASSUME_NONNULL_BEGIN

@interface AWERepoTranscodingModel : ACCRepoTranscodingModel

@property (nonatomic, assign) NSTimeInterval exportVideoDuration;

@property (nonatomic, assign) int encodeBitsType; // encode bits type
@property (nonatomic, assign) int encodeHdrType; // encode hdr type

@property (nonatomic, strong, nullable) NSNumber* uploadSpeedIndex;

@end

@interface AWEVideoPublishViewModel (AWERepoTranscoding)
 
@property (nonatomic, strong, readonly) AWERepoTranscodingModel *repoTranscoding;
 
@end

NS_ASSUME_NONNULL_END
