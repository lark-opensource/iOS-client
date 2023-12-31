//
//  AWEEditAlgorithmManager.h
//  CameraClient-Pods-Aweme
//
//  Created by HuangHongsen on 2021/8/16.
//

#import <Foundation/Foundation.h>
#import <CreationKitRTProtocol/ACCCameraDefine.h>

typedef NS_ENUM(NSInteger, ACCEditImageAlgorithmType) {
    ACCEditImageAlgorithmTypeSmartSoundTrack = 0,
    ACCEditImageAlgorithmTypeSmartHashtag = 1,
};

typedef NS_OPTIONS(NSUInteger, AWEAIRecommendStrategy) {
    AWEAIRecommendStrategyNone = 0,
    AWEAIRecommendStrategyUploadFrames = 1 << 0,
    AWEAIRecommendStrategyBachVector = 1 << 1,
};

NS_ASSUME_NONNULL_BEGIN

@interface AWEEditAlgorithmManager : NSObject

+ (instancetype)sharedManager;

- (BOOL)useBachToRecommend;

- (BOOL)shouldUploadFramesForRecommendation;


- (AWEAIRecommendStrategy)recommendStrategy;

- (void)runAlgorithmOfType:(ACCEditImageAlgorithmType)type
            withImagePaths:(NSArray<NSString *> *)imagePaths
                completion:(void (^)(NSArray<NSNumber *> *, NSError *))completion;

@end

NS_ASSUME_NONNULL_END
