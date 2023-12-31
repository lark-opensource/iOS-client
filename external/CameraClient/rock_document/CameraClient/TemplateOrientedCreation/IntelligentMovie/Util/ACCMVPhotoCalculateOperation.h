//
//  ACCMVPhotoCalculateOperation.h
//  CameraClient-Pods-Aweme
//
//  Created by Lemonior on 2020/11/25.
//

#import <Foundation/Foundation.h>
#import <TTVideoEditor/VEAIMomentAlgorithm.h>

@class ACCMomentMediaAsset;

@interface ACCMVPhotoCalculateOperationResult : NSObject

@property (nonatomic, strong, nullable) VEAIMomentBIMResult *bimResult;

@property (nonatomic, assign) NSUInteger orientation;

@property (nonatomic, strong, nullable) NSDictionary *imageExif;

@property (nonatomic, copy, nullable) NSString *videoModelString;

@property (nonatomic, copy, nullable) NSString *videoCreateDateString;

@property (nonatomic, strong, nullable) NSError *error;

@end


typedef void(^ACCMVPhotoCalculateOperationCompletion)(ACCMVPhotoCalculateOperationResult *_Nullable result);

@protocol ACCMVPhotoCalculateOperationDelegate <NSObject>

- (BOOL)isOpBIMModelReady;

@end

@interface ACCMVPhotoCalculateOperation : NSOperation

@property (nonatomic, assign) VEAIAlgorithmType algorithmType;

@property (nonatomic, weak) VEAIMomentAlgorithm *aiAlgorithm;

@property (nonatomic, strong) ACCMomentMediaAsset *asset;

@property (nonatomic, copy) ACCMVPhotoCalculateOperationCompletion bimCompletion;

@property (nonatomic, weak) dispatch_queue_t calculateQueue;

@property (nonatomic, assign) NSInteger calculateIndex;

@property (nonatomic, weak) id<ACCMVPhotoCalculateOperationDelegate> opDelegate;

@end
