//
//  ACCVEVideoData.h
//  CameraClient-Pods-Aweme
//
//  Created by raomengyun on 2021/4/26.
//

#import <Foundation/Foundation.h>
#import "ACCEditVideoData.h"

NS_ASSUME_NONNULL_BEGIN

@class HTSVideoData;

@interface ACCVEVideoData : NSObject<ACCEditVideoDataProtocol>

@property (nonatomic, strong, readonly) HTSVideoData *videoData;

+ (instancetype)videoDataWithDraftFolder:(NSString *)draftFolder;
+ (nullable instancetype)videoDataWithVideoAsset:(AVAsset *)videoAsset draftFolder:(NSString *)draftFolder;
+ (nullable instancetype)videoDataWithVideoData:(HTSVideoData *)videoData draftFolder:(NSString *)draftFolder;
- (nullable instancetype)initWithVideoData:(HTSVideoData *)videoData draftFolder:(NSString *)draftFolder;

- (instancetype)init NS_UNAVAILABLE;

@end

NS_ASSUME_NONNULL_END
