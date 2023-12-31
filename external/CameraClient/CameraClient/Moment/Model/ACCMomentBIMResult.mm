//
//  ACCMomentBIMResult.mm
//  Pods
//
//  Created by Pinka on 2020/6/2.
//

#import "ACCMomentBIMResult+WCTTableCoding.h"
#import "ACCMomentBIMResult.h"
#import <BDWCDB/WCDB/WCDB.h>

#import <CreativeKit/NSArray+ACCAdditions.h>

NSInteger const ACCMomentBIMResultDefaultSimId = -99;

@interface ACCMomentBIMResult ()

@end

@implementation ACCMomentBIMResult

WCDB_IMPLEMENTATION(ACCMomentBIMResult)

WCDB_SYNTHESIZE(ACCMomentBIMResult, scanDate)
WCDB_SYNTHESIZE(ACCMomentBIMResult, localIdentifier)
WCDB_SYNTHESIZE(ACCMomentBIMResult, mediaType)
WCDB_SYNTHESIZE(ACCMomentBIMResult, mediaSubtypes)
WCDB_SYNTHESIZE(ACCMomentBIMResult, pixelWidth)
WCDB_SYNTHESIZE(ACCMomentBIMResult, pixelHeight)
WCDB_SYNTHESIZE(ACCMomentBIMResult, creationDate)
WCDB_SYNTHESIZE(ACCMomentBIMResult, modificationDate)
WCDB_SYNTHESIZE(ACCMomentBIMResult, duration)

WCDB_PRIMARY(ACCMomentBIMResult, localIdentifier)

WCDB_SYNTHESIZE(ACCMomentBIMResult, orientation)
WCDB_SYNTHESIZE(ACCMomentBIMResult, imageExif)
WCDB_SYNTHESIZE(ACCMomentBIMResult, videoModelString)
WCDB_SYNTHESIZE(ACCMomentBIMResult, videoCreateDateString)

#pragma mark - BIM
WCDB_SYNTHESIZE(ACCMomentBIMResult, uid)
WCDB_UNIQUE(ACCMomentBIMResult, uid)
WCDB_SYNTHESIZE(ACCMomentBIMResult, locationName)
WCDB_SYNTHESIZE(ACCMomentBIMResult, checkModDate)

WCDB_SYNTHESIZE(ACCMomentBIMResult, faceVertifyFeatures)
WCDB_SYNTHESIZE(ACCMomentBIMResult, faceFeatures)
WCDB_SYNTHESIZE(ACCMomentBIMResult, momentTags)
WCDB_SYNTHESIZE(ACCMomentBIMResult, isPorn)
WCDB_SYNTHESIZE(ACCMomentBIMResult, isLeader)
WCDB_SYNTHESIZE(ACCMomentBIMResult, scoreInfo)
WCDB_SYNTHESIZE(ACCMomentBIMResult, scoreInfos)
WCDB_SYNTHESIZE(ACCMomentBIMResult, similarityData)
WCDB_SYNTHESIZE(ACCMomentBIMResult, reframeInfos)
WCDB_SYNTHESIZE(ACCMomentBIMResult, simId)
WCDB_SYNTHESIZE(ACCMomentBIMResult, peopleIds)
WCDB_SYNTHESIZE(ACCMomentBIMResult, c3Feature)

- (instancetype)initWithVEBIM:(VEAIMomentBIMResult *)bimResult
{
    self = [super init];
    
    if (self) {
        _simId = @(ACCMomentBIMResultDefaultSimId);
        _faceVertifyFeatures = bimResult.faceVertifyFeatures;
        _faceFeatures = bimResult.faceFeatures;
        _momentTags = bimResult.momentTags;
        _isPorn = bimResult.isPorn;
        _isLeader = bimResult.isLeader;
        _scoreInfo = bimResult.scoreInfo;
        _scoreInfos = bimResult.scoreInfos;
        _similarityData = bimResult.similarityData;
        _reframeInfos = bimResult.reframeInfos;
        _c3Feature = bimResult.c3Feature;
    }
    
    return self;
}

- (void)configWithAssetModel:(__kindof ACCMomentMediaAsset *)asset
{
    self.scanDate = asset.scanDate;
    self.localIdentifier = asset.localIdentifier;
    self.mediaType = asset.mediaType;
    self.mediaSubtypes = asset.mediaSubtypes;
    self.pixelWidth = asset.pixelWidth;
    self.pixelHeight = asset.pixelHeight;
    self.creationDate = asset.creationDate;
    self.modificationDate = asset.modificationDate;
    self.duration = asset.duration;
    self.checkModDate = asset.modificationDate.timeIntervalSince1970*1000;
}

@end
