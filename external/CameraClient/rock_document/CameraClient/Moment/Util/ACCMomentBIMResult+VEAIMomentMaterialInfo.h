//
//  ACCMomentBIMResult+VEAIMomentMaterialInfo.h
//  Pods
//
//  Created by Pinka on 2020/6/9.
//

#import "ACCMomentBIMResult.h"
#import <TTVideoEditor/VEAIMomentAlgorithm.h>

NS_ASSUME_NONNULL_BEGIN

@interface ACCMomentBIMResult (VEAIMomentMaterialInfo)

- (VEAIMomentMaterialInfo *)createMaterialInfo;
- (NSDictionary *)acc_materialInfoDict;

@end

NS_ASSUME_NONNULL_END
