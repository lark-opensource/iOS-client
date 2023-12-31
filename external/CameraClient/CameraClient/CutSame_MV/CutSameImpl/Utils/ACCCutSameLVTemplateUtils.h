//
//  ACCCutSameLVTemplateUtils.h
//  CameraClient-Pods-Aweme
//
//  Created by Pinka on 2020/3/24.
//

#import <CreationKitArch/ACCCutSameFragmentModelProtocol.h>
#import <VideoTemplate/LVTemplateProcessor.h>

NS_ASSUME_NONNULL_BEGIN

@interface ACCCutSameLVTemplateUtils : NSObject

+ (id<LVTemplateFragment>)createTemplateWithFragment:(id<ACCCutSameFragmentModelProtocol>)fragment;
+ (id<LVTemplateVideoFragment>)createVideoTemplateWithFragment:(id<ACCCutSameFragmentModelProtocol>)fragment;
+ (id<LVTemplateImageFragment>)createImageTemplateWithFragment:(id<ACCCutSameFragmentModelProtocol>)fragment;

@end

@interface NSArray (ACCCutSameFragmentModelLVTemplate)

- (NSArray<id<LVTemplateFragment>> *)createTemplateFragmentArray;

@end

NS_ASSUME_NONNULL_END
