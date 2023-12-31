//
//  ACCIntelligentMovieAIMManager.m
//  CameraClient-Pods-Aweme
//
//  Created by Lemonior on 2020/11/23.
//

#import "ACCIntelligentMovieAIMManager.h"
#import <CameraClient/ACCMomentAIMomentModel.h>
#import <CameraClient/ACCMomentBIMResult.h>

@implementation ACCIntelligentMovieAIMManager

+ (ACCMomentAIMomentModel * _Nullable)generateAMomentWithAssetsID:(NSArray<NSString *> *)localIDs {
    NSAssert(localIDs.count > 0, @"need nature generate a moment with assets");
    ACCMomentAIMomentModel *moment = nil;
    if (localIDs && localIDs.count > 0) {
        moment = [[ACCMomentAIMomentModel alloc] init];
        moment.title = @"自然聚合模板";
        moment.materialIds = localIDs;
        moment.coverMaterialId = [localIDs firstObject];
        NSAssert(moment.coverMaterialId.length > 0, @"please cheack coverMaterialId for this Moments");
    }
    return moment;
}

@end
