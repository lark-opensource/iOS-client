//
//  ACCIntelligentMovieBIMManager.h
//  CameraClient-Pods-Aweme
//
//  Created by Lemonior on 2020/11/22.
//

#import <Foundation/Foundation.h>

@class PHAsset, ACCAlgorithmService;

@interface ACCIntelligentMovieBIMManager : NSObject

/// Multi-Thread Optimize, Default is YES
@property (nonatomic, assign) BOOL multiThreadOptimize;
@property (nonatomic, assign) NSInteger scanQueueOperationCount;
@property (nonatomic, assign) NSInteger frameGeneratorFPS;

@property (nonatomic, strong) NSArray<PHAsset *> *selectedAssets;

- (instancetype)initWithAlgorithmService:(ACCAlgorithmService *)algorithmService;

- (void)startAnalyseSelecteAssetsFeature:(void (^)(BOOL success))completion;

@end
