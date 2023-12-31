//
//  ACCMomentService.h
//  Pods
//
//  Created by Pinka on 2020/5/21.
//

#import <Foundation/Foundation.h>
#import <Photos/Photos.h>
#import <TTVideoEditor/VEAIMomentAlgorithm.h>
#import "ACCMomentAIMomentModel.h"
#import "ACCMomentTemplateModel.h"
#import "ACCMomentUserInfo.h"
#import "ACCMomentMediaScanManager.h"
#import "ACCMVTemplateMergedInfo.h"

NS_ASSUME_NONNULL_BEGIN

typedef void(^ACCMomentServiceCompletion)(ACCMomentMediaScanManagerCompleteState state, ACCMomentMediaAsset * _Nullable lastAsset, NSError * _Nullable error);
typedef void(^ACCMomentServiceMomentResult)(NSArray<ACCMomentAIMomentModel *> *result, NSError * _Nullable error);
typedef void(^ACCMomentServiceTemplateResult)(NSArray<ACCMomentTemplateModel *> *result, NSError * _Nullable error);
typedef BOOL(^ACCMomentServiceMaterialFilter)(PHAsset *asset);

typedef void(^ACCMomentServiceTemplateVerifyCallback)(NSArray<ACCMVTemplateMergedInfo *> *templateList);
typedef void(^ACCMomentServiceTemplateVerifyRequest)(NSArray<ACCMVTemplateMergedInfo *> *templateList, ACCMomentServiceTemplateVerifyCallback callback);

@interface ACCMomentService : NSObject

/// Scan Limit Count
@property (nonatomic, assign) NSUInteger scanLimitCount;

/// Scan Redundancy Scale, default is 0.2
@property (nonatomic, assign) CGFloat scanRedundancyScale;

/// Cover image crops info list | 封面图的裁剪信息列表
@property (nonatomic, copy  ) NSArray<NSNumber *> *crops;

/// User info be use for AIM & TIM | 用来过AIM和TIM的用户信息
@property (nonatomic, strong) ACCMomentUserInfo *userInfo;

/// Scan filter block
@property (nonatomic, copy  ) ACCMomentServiceMaterialFilter assetFilter;

/// Judge service is already
@property (nonatomic, assign, readonly) BOOL isAlready;

/// Multi-Thread Optimize
@property (nonatomic, assign) BOOL multiThreadOptimize;

/// Scan queue operation count
@property (nonatomic, assign) NSInteger scanQueueOperationCount;

@property (nonatomic, copy, readonly) NSArray<NSString *> *urlPrefix;

/// The pannel name from Moment Template Data, default is nil
@property (nonatomic, copy) NSString *aimPannelName;

/// Singleton
+ (instancetype)shareInstance;

/// Update AI-Model if it's not ready
- (void)updateModelIfNotReady;

/// Update config and AI-Model | 更新config和AI模型
- (void)updateConfigModel;

/// Quick clean Scan-Result which is not exist in Media-Library
/// @param completion completion callback
- (void)cleanScanResultNotExistWithCompletion:(ACCMomentServiceCompletion)completion;

/// Start media scan
/// @param perCallbackCount Callback per count, must equal or larger than scanQueueOperationCount
/// @param completion completion callback
- (void)startForegroundMediaScanWithPerCallbackCount:(NSUInteger)perCallbackCount
                                          completion:(ACCMomentServiceCompletion)completion;

- (void)startBackgroundMediaScanWithCompletion:(nullable ACCMomentServiceCompletion)completion;

- (void)startBackgroundMediaScanWithForce:(BOOL)force
                               completion:(ACCMomentServiceCompletion _Nullable)completion;

- (void)stopMediaScan;

/// Request AI Moments | 请求AI Moments
/// @param updateFlag If YES, it will reset moment's state after callback | 如果为YES，则在回调以后重置moment的状态
/// @param verifyTemplate verify given template ids which can be used | 验证传入的template ids是否可用
/// @param callback callback | 回调
- (void)requestMomentsWithUpdateFlag:(BOOL)updateFlag
                      verifyTemplate:(ACCMomentServiceTemplateVerifyRequest)verifyTemplate
                            callback:(ACCMomentServiceMomentResult)callback;

/// Request template result by a moment | 通过moment请求template结果
/// @param moment moment obj | moment对象
/// @param verifyTemplate verify given template ids which can be used | 验证传入的template ids是否可用
/// @param callback callback | 回调
- (void)requestTemplateWithMoment:(ACCMomentAIMomentModel *)moment
                   verifyTemplate:(ACCMomentServiceTemplateVerifyRequest)verifyTemplate
                         callback:(ACCMomentServiceTemplateResult)callback;


- (void)clearAllData;

@end

NS_ASSUME_NONNULL_END
