//
//  ACCVideoDataTranslator.h
//  CameraClient-Pods-Aweme
//
//  Created by raomengyun on 2021/4/26.
//

#import <Foundation/Foundation.h>
#import "ACCVEVideoData.h"
#import "ACCNLEEditVideoData.h"

NS_ASSUME_NONNULL_BEGIN

@interface ACCVideoDataTranslator : NSObject

+ (ACCVEVideoData *)translateWithNLEModel:(ACCNLEEditVideoData *)videoData;
+ (ACCNLEEditVideoData *)translateWithVEModel:(ACCVEVideoData *)videoData nle:(NLEInterface_OC *)nle;

@end

NS_ASSUME_NONNULL_END
