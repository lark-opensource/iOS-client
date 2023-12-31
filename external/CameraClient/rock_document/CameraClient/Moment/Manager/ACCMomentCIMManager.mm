//
//  ACCMomentCIMManager.m
//  Pods
//
//  Created by Pinka on 2020/6/8.
//

#import "ACCMomentCIMManager.h"
#import <CreativeKit/ACCMonitorProtocol.h>
#import <BDWCDB/WCDB/WCDB.h>

static NSString *const ACCMomentCIMManagerErrorDomain = @"com.acc.moment.cim.manager";
static NSInteger const ACCMomentCIMManagerNoResultErrorCode = -1;

@interface ACCMomentCIMManager ()

@property (nonatomic, strong) ACCMomentMediaDataProvider *dataProvider;

@property (nonatomic, strong) dispatch_queue_t cimQueue;

@end

@implementation ACCMomentCIMManager

- (instancetype)initWithDataProvider:(ACCMomentMediaDataProvider *)dataProvider
{
    self = [super init];
    
    if (self) {
        _dataProvider = dataProvider;
        _cimQueue = dispatch_queue_create("com.acc.moment.cim", DISPATCH_QUEUE_SERIAL);
    }
    
    return self;
}

- (void)calculateCIMResult:(ACCMomentCIMManagerCompletion)completion
{
    [self.dataProvider loadBIMResultToSelectObj:^(WCTSelect * _Nonnull select, NSError * _Nullable error) {
        dispatch_async(self.dataProvider.databaseQueue, ^{
            NSMutableArray *simDatas = [[NSMutableArray alloc] init];
            NSMutableArray *verifyDatas = [[NSMutableArray alloc] init];
            NSMutableArray *picIdxs = [[NSMutableArray alloc] init];
            
            NSMutableArray *simBIMUids = [[NSMutableArray alloc] init];
            NSMutableArray *verifyBIMUids = [[NSMutableArray alloc] init];
            ACCMomentBIMResult *oneBim = nil;
            
            NSUInteger curIdx = 0;
            while ((oneBim = select.nextObject)) {
                if (oneBim.similarityData.length) {
                    [simDatas addObject:oneBim.similarityData];
                    [simBIMUids addObject:@(oneBim.uid)];
                }
                
                if (oneBim.faceVertifyFeatures.count) {
                    [oneBim.faceVertifyFeatures enumerateObjectsUsingBlock:^(NSArray<NSNumber *> * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
                        [verifyDatas addObject:obj];
                        [picIdxs addObject:@(oneBim.uid)];
                    }];
                    
                    [verifyBIMUids addObject:@(oneBim.uid)];
                }
                
                curIdx += 1;
            }

            dispatch_async(self.cimQueue, ^{
                CFAbsoluteTime ctime = CFAbsoluteTimeGetCurrent();
                NSError *error;
                VEAIMomentCIMResult *cimResult =
                [self.aiAlgorithm getCIMInfoForSimilartyFeatures:simDatas
                                                 vertifyFeatures:verifyDatas
                                                           error:&error];

                if (cimResult) {
                    CFAbsoluteTime gap = CFAbsoluteTimeGetCurrent() - ctime;
                    NSMutableDictionary *extra =
                    [NSMutableDictionary dictionaryWithDictionary:@{
                        @"duration": @(gap)
                    }];
                    if (error.userInfo[VEAIMomentErrorCodeKey]) {
                        extra[@"moment_errorcode"] = error.userInfo[VEAIMomentErrorCodeKey];
                    }
                    [ACCMonitor() trackService:@"moment_cim_access"
                                        status:cimResult? 0: 1
                                         extra:extra];
                    
                    [self.dataProvider updateCIMSimIds:cimResult.clusterInfo bimUids:simBIMUids completion:^(NSError * _Nullable error) {
                        ;
                    }];
                    
                    NSMutableDictionary *faceMap = [[NSMutableDictionary alloc] init];
                    [cimResult.faceClusterList enumerateObjectsUsingBlock:^(NSArray<NSNumber *> * _Nonnull oneFace, NSUInteger faceIdx, BOOL * _Nonnull stop) {
                        [oneFace enumerateObjectsUsingBlock:^(NSNumber * _Nonnull oncPic, NSUInteger idx, BOOL * _Nonnull stop) {
                            NSNumber *theUid = picIdxs[oncPic.integerValue];
                            NSMutableSet *tmpSet = faceMap[theUid];
                            if (!tmpSet) {
                                tmpSet = [[NSMutableSet alloc] init];
                                faceMap[theUid] = tmpSet;
                            }
                            [tmpSet addObject:@(faceIdx)];
                        }];
                    }];
                    
                    NSMutableArray *peopleIds = [[NSMutableArray alloc] init];
                    [verifyBIMUids enumerateObjectsUsingBlock:^(NSNumber * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
                        NSMutableSet *onePeopleIds = faceMap[obj];
                        if (onePeopleIds) {
                            [peopleIds addObject:onePeopleIds.allObjects];
                        } else {
                            [peopleIds addObject:@[]];
                        }
                    }];
                    
                    [self.dataProvider updateCIMPeopleIds:peopleIds bimUids:verifyBIMUids completion:^(NSError * _Nullable error) {
                        if (completion) {
                            completion(cimResult, error);
                        }
                    }];
                } else {
                    if (completion) {
                        completion(nil, [NSError errorWithDomain:ACCMomentCIMManagerErrorDomain code:ACCMomentCIMManagerNoResultErrorCode userInfo:nil]);
                    }
                }
            });
        });
    }];
}

@end
