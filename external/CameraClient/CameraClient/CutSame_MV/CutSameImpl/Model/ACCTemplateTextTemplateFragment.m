//
//  ACCTemplateTextTemplateFragment.m
//  CameraClient-Pods-Aweme
//
//  Created by LeonZou on 2020/12/13.
//

#import "ACCTemplateTextTemplateFragment.h"
#import <VideoTemplate/LVTemplateDataManager+Fetcher.h>

@interface ACCTemplateTextTemplateFragment () <NSCopying>

@property (nonatomic, assign, readwrite) NSInteger idxOfTextPayload;
@property (nonatomic, copy, readwrite) NSString *segmentID;

@end

@implementation ACCTemplateTextTemplateFragment

+ (ACCTemplateTextTemplateFragment *)convertFromLVTextTemplateFragment:(LVTemplateTextTemplateFragment *)textTemplateFragment {
    ACCTemplateTextTemplateFragment *fragment = (ACCTemplateTextTemplateFragment *)[super convertFromLVTextFragment:textTemplateFragment];
    fragment.idxOfTextPayload = textTemplateFragment.idxOfTextPayload;
    fragment.segmentID = textTemplateFragment.textTemplateSegmentID;
    return fragment;
}

- (id)copyWithZone:(NSZone *)zone {
    ACCTemplateTextTemplateFragment *copy = [super copyWithZone:zone];
    copy.idxOfTextPayload = self.idxOfTextPayload;
    copy.segmentID = self.segmentID;
    return copy;
}

@end
