//
//  NLETrackMV_OC+Extension.h
//  CameraClient-Pods-Aweme
//
//  Created by raomengyun on 2021/5/21.
//

#import <NLEPlatform/NLETrackMV+iOS.h>

NS_ASSUME_NONNULL_BEGIN

@class IESMMMVResource;

@interface NLETrackMV_OC (Extension)

- (void)updateWithModelPath:(NSString *)modelPath
              userResources:(NSArray<IESMMMVResource *> *)resources
          resourcesDuration:(nullable NSArray *)resourcesDuration
                draftFolder:(NSString *)draftFolder;

- (void)configAlgorithmPath:(NSString *)algorithmPath;

@end

NS_ASSUME_NONNULL_END
