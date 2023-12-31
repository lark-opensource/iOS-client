//
//  ACCMomentPhotoCalculateOperation.h
//  Pods
//
//  Created by Pinka on 2020/5/22.
//

#import <Foundation/Foundation.h>
#import "ACCMomentMediaAsset.h"
#import <TTVideoEditor/VEAIMomentAlgorithm.h>

NS_ASSUME_NONNULL_BEGIN

@interface ACCMomentPhotoCalculateOperationResult : NSObject

@property (nonatomic, strong, nullable) VEAIMomentBIMResult *bimResult;

@property (nonatomic, assign) NSUInteger orientation;

@property (nonatomic, strong, nullable) NSDictionary *imageExif;

@property (nonatomic, copy, nullable) NSString *videoModelString;

@property (nonatomic, copy, nullable) NSString *videoCreateDateString;

@property (nonatomic, strong, nullable) NSError *error;

@end


typedef void(^ACCMomentPhotoCalculateOperationCompletion)(ACCMomentPhotoCalculateOperationResult *_Nullable result);

@interface ACCMomentPhotoCalculateOperation : NSOperation

@property (nonatomic, weak  ) VEAIMomentAlgorithm *aiAlgorithm;

@property (nonatomic, strong) ACCMomentMediaAsset *asset;

@property (nonatomic, copy, class) NSArray<NSNumber *> *crops;

@property (nonatomic, copy  ) ACCMomentPhotoCalculateOperationCompletion bimCompletion;

@property (nonatomic, weak  ) dispatch_queue_t calculateQueue;

@property (nonatomic, assign) NSInteger calculateIndex;

@end

NS_ASSUME_NONNULL_END
