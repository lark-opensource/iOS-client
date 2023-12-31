//
//  ACCTemplateDetailModel.m
//  CameraClient-Pods-Aweme
//
//  Created by Lemonior on 2020/11/20.
//

#import "ACCTemplateDetailModel.h"

@implementation ACCTemplateDetailModel

+ (NSDictionary *)JSONKeyPathsByPropertyKey
{
    return @{
        @"templateID": @"template_id",
        @"type": @"template_type",
        @"cutsameTemplate": @"ulike_info",
        @"classicalTemplate": @"mv_info",
        @"urlPrefix": @"url_prefix",
    };
}

- (id)copyWithZone:(nullable NSZone *)zone
{
    ACCTemplateDetailModel *copy = [[ACCTemplateDetailModel alloc] init];
    copy.templateID = self.templateID;
    copy.type = self.type;
    copy.cutsameTemplate = [self.cutsameTemplate copy];
    copy.classicalTemplate = [self.classicalTemplate copy];
    copy.urlPrefix = [self.urlPrefix copy];
    return copy;
}

@end

@implementation ACCTemplateRecommendModel

+ (NSDictionary *)JSONKeyPathsByPropertyKey
{
    return @{
        @"recommendTemplates": @"template_list",
        @"logPb": @"log_pb",
    };
}

+ (NSValueTransformer *)recommendTemplatesJSONTransformer
{
    return [MTLJSONAdapter arrayTransformerWithModelClass:ACCRecommendTemplateInfo.class];
}

+ (NSValueTransformer *)logPbJSONTransformer
{
    return [MTLJSONAdapter dictionaryTransformerWithModelClass:ACCLogPbInfo.class];
}

- (id)copyWithZone:(nullable NSZone *)zone
{
    ACCTemplateRecommendModel *copy = [[ACCTemplateRecommendModel alloc] init];
    copy.recommendTemplates = [self.recommendTemplates copy];
    return copy;
}

@end

@implementation ACCRecommendTemplateInfo

+ (NSDictionary *)JSONKeyPathsByPropertyKey
{
    return @{
        @"templateBaseInfo": @"base_info",
        @"musicEditInfo": @"music_edit_info",
        @"segmentInfos": @"segment_infos",
        @"meta": @"meta",
    };
}

+ (NSValueTransformer *)segmentInfosJSONTransformer
{
    return [MTLJSONAdapter arrayTransformerWithModelClass:ACCRecommendSegmentInfo.class];
}

+ (NSValueTransformer *)musicEditInfoJSONTransformer
{
    return [MTLJSONAdapter dictionaryTransformerWithModelClass:ACCMusicEditInfo.class];
}

+ (NSValueTransformer *)templateBaseInfoJSONTransformer
{
    return [MTLJSONAdapter dictionaryTransformerWithModelClass:ACCTemplateDetailModel.class];
}

- (id)copyWithZone:(nullable NSZone *)zone
{
    ACCRecommendTemplateInfo *copy = [[ACCRecommendTemplateInfo alloc] init];
    copy.templateBaseInfo = [self.templateBaseInfo copy];
    copy.musicEditInfo = [self.musicEditInfo copy];
    copy.segmentInfos = [self.segmentInfos copy];
    copy.meta = [self.meta copy];
    return copy;
}

@end

@implementation ACCRecommendSegmentInfo

+ (NSDictionary *)JSONKeyPathsByPropertyKey
{
    return @{
        @"materialID": @"material_id",
        @"startTime": @"start_time",
        @"endTime": @"end_time",
        @"segmentID": @"segment_id",
        @"cropCxy": @"crop_cxy"
    };
}

- (id)copyWithZone:(nullable NSZone *)zone
{
    ACCRecommendSegmentInfo *copy = [[ACCRecommendSegmentInfo alloc] init];
    copy.materialID = [self.materialID copy];
    copy.startTime = self.startTime;
    copy.endTime = self.endTime;
    copy.segmentID = [self.segmentID copy];
    return copy;
}

+ (NSValueTransformer *)bboxJSONTransformer
{
    return [MTLJSONAdapter dictionaryTransformerWithModelClass:ACCMVReframe.class];
}

- (NSArray<NSValue *> *)cropPoints {
    ACCMVReframe *mvReframe = self.cropCxy;
    NSValue *leftTop = [NSValue valueWithCGPoint:CGPointMake(mvReframe.centerX - mvReframe.width / 2, mvReframe.centerY - mvReframe.height / 2)];
    NSValue *rightTop = [NSValue valueWithCGPoint:CGPointMake(mvReframe.centerX + mvReframe.width / 2, mvReframe.centerY - mvReframe.height / 2)];
    NSValue *leftBottom = [NSValue valueWithCGPoint:CGPointMake(mvReframe.centerX - mvReframe.width / 2, mvReframe.centerY + mvReframe.height / 2)];
    NSValue *rightBottom = [NSValue valueWithCGPoint:CGPointMake(mvReframe.centerX + mvReframe.width / 2, mvReframe.centerY + mvReframe.height / 2)];
    NSArray<NSValue *> * points = @[leftTop, rightTop, leftBottom, rightBottom];
    return points;
}

@end

@implementation ACCMVReframe

+ (NSDictionary *)JSONKeyPathsByPropertyKey {
    return @{
        @"centerX": @"center_x",
        @"centerY": @"center_y",
        @"width": @"width",
        @"height": @"height",
        @"rotateAngle": @"rotate_angle",
    };
}

@end

@implementation ACCLogPbInfo

+ (NSDictionary *)JSONKeyPathsByPropertyKey {
    return @{
        @"imprID": @"impr_id",
    };
}

@end
