//
//  ACCTemplateDetailModel.h
//  CameraClient-Pods-Aweme
//
//  Created by Lemonior on 2020/11/20.
//

#import <Foundation/Foundation.h>
#import <CreationKitArch/ACCMVTemplateModelProtocol.h>
#import "ACCMusicEditInfo.h"
#import <CreationKitInfra/ACCBaseApiModel.h>

#import <Mantle/Mantle.h>

@interface ACCLogPbInfo : MTLModel <MTLJSONSerializing>

@property (nonatomic, copy) NSString *imprID;

@end

@interface ACCMVReframe : MTLModel <MTLJSONSerializing>

@property (assign, nonatomic) CGFloat centerX;
@property (assign, nonatomic) CGFloat centerY;
@property (assign, nonatomic) CGFloat width;
@property (assign, nonatomic) CGFloat height;
@property (assign, nonatomic) CGFloat rotateAngle;

@end

@interface ACCTemplateDetailModel : MTLModel <MTLJSONSerializing, NSCopying>

@property (nonatomic, assign) int64_t templateID;
@property (nonatomic, assign) ACCMVTemplateType type;
@property (nonatomic, strong) NSDictionary *cutsameTemplate; // cutsameModel
@property (nonatomic, strong) NSDictionary *classicalTemplate; // mvModel
@property (nonatomic, strong) NSString *urlPrefix;

@end

@interface ACCRecommendSegmentInfo : MTLModel <MTLJSONSerializing, NSCopying>

@property (nonatomic, copy) NSString *materialID;
@property (nonatomic, assign) NSInteger startTime;
@property (nonatomic, assign) NSInteger endTime;
@property (nonatomic, copy) NSString *segmentID;
@property (nonatomic, strong) ACCMVReframe *cropCxy;

- (NSArray<NSValue *> *)cropPoints;

@end

@interface ACCRecommendTemplateInfo : MTLModel <MTLJSONSerializing, NSCopying>

@property (nonatomic, strong) ACCTemplateDetailModel *templateBaseInfo; // base info for template
@property (nonatomic, strong) ACCMusicEditInfo *musicEditInfo; // musicModel
@property (nonatomic, strong) NSArray<ACCRecommendSegmentInfo *> *segmentInfos;
@property (nonatomic, copy) NSString *meta;

@end

@interface ACCTemplateRecommendModel : MTLModel <MTLJSONSerializing, NSCopying>

@property (nonatomic, strong) NSArray<ACCRecommendTemplateInfo *> *recommendTemplates;
@property (nonatomic, strong) ACCLogPbInfo *logPb; // query log

@end
