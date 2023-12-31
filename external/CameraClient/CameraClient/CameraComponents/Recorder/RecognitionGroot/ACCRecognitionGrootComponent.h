//
//  ACCRecognitionGrootComponent.h
//  CameraClient-Pods-Aweme
//
//  Created by Bytedance on 2021/8/23.
//

#import <CreativeKit/ACCFeatureComponent.h>

@class SSRecognizeResult;

@interface ACCRecognitionGrootComponent : ACCFeatureComponent

- (void)updateCheckGrootResearch:(BOOL)allowResearch;

- (void)updateStickerState:(BOOL)show;
@end

