//
//  ACCMomentMaterialSegInfo.h
//  Pods
//
//  Created by Pinka on 2020/6/8.
//

#import <Mantle/Mantle.h>
#import "ACCMomentReframe.h"

NS_ASSUME_NONNULL_BEGIN

@interface ACCMomentMaterialSegInfo : MTLModel <MTLJSONSerializing, NSCopying>

@property (nonatomic, copy  ) NSString *fragmentId;
@property (nonatomic, copy  ) NSString *materialId;
@property (nonatomic, assign) float startTime;
@property (nonatomic, assign) float endTime;
@property (nonatomic, strong) ACCMomentReframe *clipFrame;

@end

NS_ASSUME_NONNULL_END
