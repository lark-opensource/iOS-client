//
//  ACCTemplateTextTemplateFragment.h
//  CameraClient-Pods-Aweme
//
//  Created by LeonZou on 2020/12/13.
//

#import "ACCTemplateTextFragment.h"

NS_ASSUME_NONNULL_BEGIN

@class LVTemplateTextTemplateFragment;
@interface ACCTemplateTextTemplateFragment : ACCTemplateTextFragment

@property (nonatomic, assign, readonly) NSInteger idxOfTextPayload; // text payload的下标
@property (nonatomic, copy, readonly) NSString *segmentID;  // 所属segment的ID

+ (ACCTemplateTextTemplateFragment *)convertFromLVTextTemplateFragment:(LVTemplateTextTemplateFragment *)textTemplateFragment;

@end

NS_ASSUME_NONNULL_END
