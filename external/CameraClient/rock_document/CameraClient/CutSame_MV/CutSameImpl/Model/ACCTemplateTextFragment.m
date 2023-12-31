//
//  ACCTemplateTextFragment.m
//  CameraClient
//
//  Created by long.chen on 2020/3/30.
//

#import "ACCTemplateTextFragment.h"

#import <VideoTemplate/LVTemplateDataManager+Fetcher.h>

@interface ACCTemplateTextFragment () <NSCopying>

@property (nonatomic, copy, readwrite) NSString *payloadID;     // 文字的ID
@property (nonatomic, assign, readwrite) CMTimeRange timeRange; // 时间范围

@end

@implementation ACCTemplateTextFragment

+ (ACCTemplateTextFragment *)convertFromLVTextFragment:(LVTemplateTextFragment *)textFragment
{
    ACCTemplateTextFragment *fragment = [[self class] new];
    fragment.payloadID = textFragment.payloadID;
    fragment.timeRange = textFragment.timeRange;
    fragment.content = textFragment.content;
    fragment.albumImage = textFragment.albumImage;
    return fragment;
}

- (id)copyWithZone:(NSZone *)zone
{
    ACCTemplateTextFragment *copy = [[self class] new];
    copy.payloadID = self.payloadID;
    copy.timeRange = self.timeRange;
    copy.content = self.content;
    copy.albumImage = self.albumImage;
    return copy;
}

@end
