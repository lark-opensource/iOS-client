//
//  ACCMusicTemplateModelTransformer.m
//  CameraClient-Pods-Aweme
//
//  Created by zhangyuanming on 2020/11/27.
//

#import "ACCMusicTemplateModelTransformer.h"

@implementation ACCMusicTemplateModelTransformer

+ (VEAlgorithmMVTemplate *)transformToVETemplate:(id<ACCMusicMVTemplateInfoProtocol>)templateInfo
{
    VEAlgorithmMVTemplate *result = [[VEAlgorithmMVTemplate alloc] init];
    result.templateId = templateInfo.templateID;
    result.tag = templateInfo.tag;
    result.style = templateInfo.style;
    result.expr = templateInfo.expr;
    result.zipUrl = templateInfo.zipURL;
    result.source = VEAlgorithmMVTemplateTypeCutSame;

    NSMutableArray<VEAlgorithmMVVideoSegInfo *> *segments = [NSMutableArray array];
    for (id<ACCMusicMVVideoSegInfoProtocol> segmentInfo in templateInfo.videoSegs) {
        [segments addObject:[self transformToVESegment:segmentInfo]];
    }
    result.videoSegs = [segments copy];

    return result;
}

+ (VEAlgorithmMVVideoSegInfo *)transformToVESegment:(id<ACCMusicMVVideoSegInfoProtocol>)segmentInfo
{
    VEAlgorithmMVVideoSegInfo *result = [[VEAlgorithmMVVideoSegInfo alloc] init];
    result.startTime = segmentInfo.startTime;
    result.endTime = segmentInfo.endTime;
    result.fragmentId = segmentInfo.fragmentID;
    result.cropRatio = segmentInfo.cropRatio;
    result.materialType = segmentInfo.materialType;
    result.sourceDuration = segmentInfo.sourceDuration;
    result.groupId = segmentInfo.groupID;

    return result;
}

+ (VEAIMomentMoment *)transformToVEMoment:(ACCMomentAIMomentModel *)moment
{
    VEAIMomentMoment *aiMoment = [[VEAIMomentMoment alloc] init];
    aiMoment.coverId = moment.coverUid;
    aiMoment.effectId = moment.effectId;
    aiMoment.extra = moment.extra;
    aiMoment.identity = moment.identity;
    aiMoment.materialIds = moment.uids;
    aiMoment.version = moment.version;
    aiMoment.type = moment.type;
    aiMoment.title = moment.title;
    aiMoment.templateId = moment.templateId;
    aiMoment.momentSource = moment.momentSource;
    
    return aiMoment;
}

+ (NSArray<VEAIMomentMoment *> *)transformToVEMoments:(NSArray<ACCMomentAIMomentModel *> *)moments
{
    NSMutableArray *result = [NSMutableArray array];
    
    for (ACCMomentAIMomentModel *model in moments) {
        [result addObject:[self transformToVEMoment:model]];
    }
    
    return [result copy];
}

+ (NSArray<VEAlgorithmMVTemplate *> *)transformToVETemplates:(NSArray<id<ACCMusicMVTemplateInfoProtocol>> *)templateInfos
{
    NSMutableArray *result = [NSMutableArray array];
    
    for (id<ACCMusicMVTemplateInfoProtocol> model in templateInfos) {
        [result addObject:[self transformToVETemplate:model]];
    }
    
    return [result copy];
}

@end
