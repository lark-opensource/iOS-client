//
//  ACCMomentCIMManager.h
//  Pods
//
//  Created by Pinka on 2020/6/8.
//

#import <Foundation/Foundation.h>

#import "ACCMomentMediaDataProvider.h"

#import <TTVideoEditor/VEAIMomentAlgorithm.h>

NS_ASSUME_NONNULL_BEGIN

typedef void(^ACCMomentCIMManagerCompletion)(VEAIMomentCIMResult * _Nullable cimResult, NSError *error);

@interface ACCMomentCIMManager : NSObject

@property (nonatomic, weak) VEAIMomentAlgorithm *aiAlgorithm;

- (instancetype)initWithDataProvider:(ACCMomentMediaDataProvider *)dataProvider;

- (void)calculateCIMResult:(ACCMomentCIMManagerCompletion)completion;

@end

NS_ASSUME_NONNULL_END
