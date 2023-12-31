//
//  ACCMomentBIMResult+VEAIMomentMaterialInfo.m
//  Pods
//
//  Created by Pinka on 2020/6/9.
//

#import "ACCMomentBIMResult+VEAIMomentMaterialInfo.h"
#import "VEAIMomentScoreInfo+WCTColumnCoding.h"
#import "VEAIMomentFaceFeature+WCTColumnCoding.h"
#import "VEAIMomentTag+WCTColumnCoding.h"
#import <CreativeKit/NSArray+ACCAdditions.h>

@implementation ACCMomentBIMResult (VEAIMomentMaterialInfo)

+ (NSDateFormatter *)exifDateFormatter
{
    static NSDateFormatter *formatter = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        formatter = [[NSDateFormatter alloc] init];
        [formatter setDateFormat:@"yyyy:MM:dd HH:mm:ss Z"];
    });
    
    return formatter;
}

+ (NSDateFormatter *)exifDateWithoutTimeZoneFormatter
{
    static NSDateFormatter *formatter = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        formatter = [[NSDateFormatter alloc] init];
        [formatter setDateFormat:@"yyyy:MM:dd HH:mm:ss"];
    });
    
    return formatter;
}

+ (NSDateFormatter *)videoDateFormatter
{
    static NSDateFormatter *formatter = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        formatter = [[NSDateFormatter alloc] init];
        [formatter setDateFormat:@"yyyy-MM-dd'T'HH:mm:ssZ"];
    });
    
    return formatter;
}

- (VEAIMomentMaterialInfo *)createMaterialInfo
{
    VEAIMomentMaterialInfo *oneMaterialInfo = [[VEAIMomentMaterialInfo alloc] init];
    VEAIMomentMetaInfo *metaInfo = [[VEAIMomentMetaInfo alloc] init];
    VEAIMomentContentInfo *contentInfo = [[VEAIMomentContentInfo alloc] init];
    
    oneMaterialInfo.materialId = self.uid;
    
    {
        metaInfo.width = self.pixelWidth;
        metaInfo.height = self.pixelHeight;
        metaInfo.orientation = self.orientation;
        if (self.mediaType == PHAssetMediaTypeVideo) {
            // ms
            metaInfo.duration = self.duration * 1000;
        } else {
            metaInfo.duration = -1.0;
        }
        metaInfo.location = self.locationName;
        metaInfo.shotTime = self.creationDate.timeIntervalSince1970;
        metaInfo.createTime = self.creationDate.timeIntervalSince1970;
        metaInfo.modifyTime = self.modificationDate.timeIntervalSince1970;
        
        if (self.imageExif[@"DateTimeDigitized"]) {
            if (self.imageExif[@"OffsetTimeDigitized"]) {
                NSString *dateStr = [self.imageExif[@"DateTimeDigitized"] stringByAppendingFormat:@" %@", [self.imageExif[@"OffsetTimeDigitized"] stringByReplacingOccurrencesOfString:@":" withString:@""]];
                metaInfo.shotTime = [[self.class exifDateFormatter] dateFromString:dateStr].timeIntervalSince1970;
            } else {
                metaInfo.shotTime = [[self.class exifDateWithoutTimeZoneFormatter] dateFromString:self.imageExif[@"DateTimeDigitized"]].timeIntervalSince1970;
            }
        }
        
        if (self.imageExif.count) {
            metaInfo.isCamera = YES;
        }
        
        if (self.videoModelString.length) {
            metaInfo.isCamera = YES;
        }
        if (self.videoCreateDateString.length) {
            metaInfo.shotTime = [[self.class videoDateFormatter] dateFromString:self.videoCreateDateString].timeIntervalSince1970;
        }
    }
    
    {
        contentInfo.tags = self.momentTags;
        contentInfo.faceFeatures = self.faceFeatures;
        contentInfo.totalScoreInfo = self.scoreInfo;
        contentInfo.scoreInfos = self.scoreInfos;
        contentInfo.isPorn = self.isPorn;
        contentInfo.isLeader = self.isLeader;
        contentInfo.peopleIds = self.peopleIds;
        contentInfo.simId = self.simId.longLongValue;
    }
    
    oneMaterialInfo.metaInfo = metaInfo;
    oneMaterialInfo.contentInfo = contentInfo;
    
    return oneMaterialInfo;
}

- (NSDictionary *)acc_materialInfoDict {
    VEAIMomentMaterialInfo *materialInfo = [self createMaterialInfo];
    
    NSString *localIdentifier = self.localIdentifier ?: @"";
    NSArray *c3FeatureData = self.c3Feature.featureData ? [self.c3Feature.featureData copy] : @[];
    
    
    NSAssert((localIdentifier.length > 0) && (c3FeatureData.count > 0),
             @"invalid material info == localIdentifier:%@ - c3FeatureData:%@",
             localIdentifier,
             c3FeatureData);
    
    return @{
        @"material_id": localIdentifier,
        @"content_info": [self configDictWithContentInfo:materialInfo.contentInfo],
        @"meta_info": [self configDictWithMetaInfo:materialInfo.metaInfo],
        @"c3_features": c3FeatureData,
    };
}

#pragma mark - 转成dict

- (NSDictionary *)configDictWithContentInfo:(VEAIMomentContentInfo *)contentInfo {
    // scoreInfo
    NSMutableArray *tempScores = [NSMutableArray array];
    for (VEAIMomentScoreInfo *scoreInfo in contentInfo.scoreInfos) {
        [tempScores acc_addObject:[scoreInfo acc_scoreInfoDict]];
    }
    
    // faceInfo
    NSMutableArray *tempFaceFeatures = [NSMutableArray array];
    for (VEAIMomentFaceFeature *faceFeature in contentInfo.faceFeatures) {
        [tempFaceFeatures acc_addObject:[faceFeature acc_faceInfoDict]];
    }
    
    // tagInfo
    NSMutableArray *tempTags = [NSMutableArray array];
    for (VEAIMomentTag *tag in contentInfo.tags) {
        [tempTags acc_addObject:[tag acc_tagInfoDict]];
    }
    
    return @{
        @"score_infos": [tempScores copy],
        @"face_infos": [tempFaceFeatures copy],
        @"tag_infos": [tempTags copy],
    };
}

- (NSDictionary *)configDictWithMetaInfo:(VEAIMomentMetaInfo *)metaInfo {
    return @{
        @"width": @(metaInfo.width),
        @"height": @(metaInfo.height),
        @"duration": @((int64_t)(metaInfo.duration)),
        @"shot_time": @(metaInfo.shotTime),
        @"create_time": @(metaInfo.createTime),
    };
}

@end
