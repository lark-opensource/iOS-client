//
//  ACCDraftResourceRecoverProtocol.h
//  CameraClient
//
//  Created by HuangHongsen on 2020/9/10.
//

#ifndef ACCDraftResourceRecoverProtocol_h
#define ACCDraftResourceRecoverProtocol_h
NS_ASSUME_NONNULL_BEGIN
@class AWEVideoPublishViewModel, IESEffectModel;
typedef void(^ACCDraftRecoverCompletion)(NSError *_Nullable error, BOOL fatalError);
typedef void(^ACCDraftRecoverBlock)(ACCDraftRecoverCompletion);

@protocol ACCDraftResourceRecoverProtocol <NSObject>

+ (nullable NSArray<NSString *> *)draftResourceIDsToDownloadForPublishViewModel:(AWEVideoPublishViewModel *)publishModel;

@optional

+ (NSArray<NSString *> *)requirementsToDownloadForPublishViewModel:(AWEVideoPublishViewModel *)publishModel;
+ (nullable NSArray<NSString *> *)modelsToDownloadForPublishViewModel:(AWEVideoPublishViewModel *)publishModel;
+ (nullable NSArray<ACCDraftRecoverBlock> *)recoverBlocksForPublishModel:(AWEVideoPublishViewModel *)publishModel;

+ (void)updateRelatedResourcesFor:(IESEffectModel *)effect
                 withPublishModel:(AWEVideoPublishViewModel *)publishModel
                       completion:(ACCDraftRecoverCompletion)completion;

+ (void)updateWithDownloadedEffects:(NSArray<IESEffectModel *> *)effects
                   publishViewModel:(AWEVideoPublishViewModel *)publishModel
                         completion:(ACCDraftRecoverCompletion)completion;

+ (void)regenerateTheNecessaryResourcesForPublishViewModel:(AWEVideoPublishViewModel *)publishModel
                                                completion:(ACCDraftRecoverCompletion)completion;

@end
NS_ASSUME_NONNULL_END

#endif /* ACCDraftResourceRecoverProtocol_h */
