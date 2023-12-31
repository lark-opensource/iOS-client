//
//  ACCEditVideoDataFactory.h
//  CameraClient-Pods-Aweme
//
//  Created by raomengyun on 2021/4/14.
//

#import <Foundation/Foundation.h>
#import <AVFoundation/AVFoundation.h>
#import "ACCEditVideoData.h"
#import "ACCVEVideoData.h"

NS_ASSUME_NONNULL_BEGIN

@class ACCNLEEditVideoData;
@interface ACCEditVideoDataFactory : NSObject

+ (ACCEditVideoData *)videoDataWithCacheDirPath:(NSString *)cacheDirPath;

+ (ACCEditVideoData *)videoDataWithVideoAsset:(AVAsset *)asset cacheDirPath:(NSString *)cacheDirPath;

+ (ACCNLEEditVideoData *)tempNLEVideoDataWithDraftFolder:(nullable NSString *)draftFolder;

@end

NS_ASSUME_NONNULL_END
