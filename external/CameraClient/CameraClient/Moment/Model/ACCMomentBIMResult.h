//
//  ACCMomentBIMResult.h
//  Pods
//
//  Created by Pinka on 2020/6/2.
//

#import "ACCMomentMediaAsset.h"
#import <TTVideoEditor/VEAIMomentBIMResult.h>

FOUNDATION_EXTERN NSInteger const ACCMomentBIMResultDefaultSimId;

@interface ACCMomentBIMResult : ACCMomentMediaAsset

@property (nonatomic, assign) NSUInteger uid;

@property (nonatomic, copy  ) NSString *locationName;

@property (nonatomic, assign) NSUInteger checkModDate;

#pragma mark - BIM
// face
@property (nonatomic, copy  ) NSArray<NSArray<NSNumber *> *> *faceVertifyFeatures;
@property (nonatomic, copy  ) NSArray<VEAIMomentFaceFeature *> *faceFeatures;

// tags
@property (nonatomic, copy  ) NSArray<VEAIMomentTag *> *momentTags;

// detect
@property (nonatomic, assign) BOOL isPorn;
@property (nonatomic, assign) BOOL isLeader;

// average score
@property (nonatomic, strong) VEAIMomentScoreInfo *scoreInfo;

@property (nonatomic, copy  ) NSArray<VEAIMomentScoreInfo *> *scoreInfos;

// similarity data
@property (nonatomic, strong) NSData *similarityData;

// photo info
@property (nonatomic, copy  ) NSArray<VEAIMomentReframeInfo *> *reframeInfos;

@property (nonatomic, strong) VEAIMomentC3Feature *c3Feature;

#pragma mark - Meta info
@property (nonatomic, assign) NSUInteger orientation;

@property (nonatomic, copy  ) NSDictionary *imageExif;

@property (nonatomic, copy  ) NSString *videoModelString;

@property (nonatomic, copy  ) NSString *videoCreateDateString;

#pragma mark - CIM Relate
// From CIM clusterInfo
@property (nonatomic, copy  ) NSNumber *simId;
// Calculate from CIM faceClusterList
@property (nonatomic, copy  ) NSArray<NSNumber *> *peopleIds;

- (instancetype)initWithVEBIM:(VEAIMomentBIMResult *)bimResult;

- (void)configWithAssetModel:(__kindof ACCMomentMediaAsset *)asset;

@end
