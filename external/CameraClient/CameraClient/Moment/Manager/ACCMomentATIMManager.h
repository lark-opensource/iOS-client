//
//  ACCMomentATIMManager.h
//  Pods
//
//  Created by Pinka on 2020/6/8.
//

#import <Foundation/Foundation.h>

#import "ACCMomentAIMomentModel.h"
#import "ACCMomentTemplateModel.h"
#import <TTVideoEditor/VEAIMomentAlgorithm.h>

NS_ASSUME_NONNULL_BEGIN

typedef void(^ACCMomentATIMManagerAIMCompletion)(NSArray<ACCMomentAIMomentModel *> * _Nullable result, NSError * _Nullable error);

typedef void(^ACCMomentATIMManagerTIMCompletion)(NSArray<ACCMomentTemplateModel *> *result, NSError * _Nullable error);

FOUNDATION_EXTERN NSString* ACCMomentATIMManagerPath(void);
FOUNDATION_EXTERN NSString* ACCMomentATIMManagerAIMConfigPath(NSString *pannelName);

@interface ACCMomentATIMManager : NSObject

@property (nonatomic, copy  ) NSString *configJson;

@property (nonatomic, assign, readonly) BOOL aimIsReady;

@property (nonatomic, assign, readonly) BOOL timIsReady;

@property (nonatomic, copy, readonly) NSArray<NSString *> *urlPrefix;

@property (nonatomic, copy, readonly) NSString *templateReccommentAlgorithmModelPath;

@property (nonatomic, copy  ) NSString *pannelName;

@property (nonatomic, assign) NSUInteger scanLimitCount;

+ (instancetype)shareInstance;

- (void)updateAIMConfig;

- (void)updateTIMModel;

- (void)requestAIMResult:(ACCMomentATIMManagerAIMCompletion)completion;

- (void)requestTIMResultWithAIMoment:(ACCMomentAIMomentModel *)aiMoment
                           usedPairs:(nullable NSArray<VEAIMomentTemplatePair *> *)usedPairs
                          completion:(ACCMomentATIMManagerTIMCompletion)completion;

@end

NS_ASSUME_NONNULL_END
