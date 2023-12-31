//
//  ACCAudioExport.h
//  CameraClient-Pods-Aweme
//
//  Created by raomengyun on 2021/4/15.
//

#import <Foundation/Foundation.h>
#import "ACCEditVideoData.h"

NS_ASSUME_NONNULL_BEGIN

@interface ACCAudioExport : NSObject

- (void)exportAllAudioSoundInVideoData:(ACCEditVideoData *)videoData
                            completion:(void (^)(NSURL *_Nullable, NSError *_Nullable))completion;

- (void)cancelAudioExport;

@end

NS_ASSUME_NONNULL_END
