//
//  ACCIntelligentMovieAIMManager.h
//  CameraClient-Pods-Aweme
//
//  Created by Lemonior on 2020/11/23.
//

#import <Foundation/Foundation.h>

@class ACCMomentAIMomentModel;
@class ACCMomentBIMResult;

@interface ACCIntelligentMovieAIMManager : NSObject

+ (ACCMomentAIMomentModel * _Nullable)generateAMomentWithAssetsID:(NSArray<NSString *> *)localIDs;

@end
