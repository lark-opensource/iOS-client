//
//  ACCMomentTemplateManagerProtocol.h
//  CameraClient-Pods-Aweme
//
//  Created by Chen Long on 2020/6/1.
//

#import <CreationKitInfra/ACCModuleService.h>
#import "ACCMVTemplateMergedInfo.h"

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

// 0 : 经典影集、同步到抖音的剪同款模板
// 1 : 未同步到抖音的剪同款模板
// 2 : 上传路径一键成片
// 3 : 音乐一键MV
typedef NS_ENUM(NSUInteger, ACCCutSameTemplateSource) {
    ACCCutSameTemplateSourceDefault = 0,
    ACCCutSameTemplateSourceNotSync,
    ACCCutSameTemplateSourceOneClick,
    ACCCutSameTemplateSourceSmartMV,
};

@class ACCMomentAIMomentModel, ACCMomentMaterialSegInfo;
@protocol ACCMVTemplateModelProtocol;
@protocol ACCMomentTemplateManagerProtocol <NSObject>

+ (void)fetchValidMomentTemplates:(NSArray<ACCMVTemplateMergedInfo *> *)templatesInfo completionHandle:(void(^)(NSArray<ACCMVTemplateMergedInfo *> * _Nullable, NSError * _Nullable))completion;

//+ (void)fetchMomentTemplateModels:(NSArray<ACCMVTemplateMergedInfo *> *)templatesInfo completionHandle:(void(^)(NSArray<ACCMVTemplateMergedDetailModel *> * _Nullable, NSError * _Nullable))completion;

+ (void)fetchTemplateModelWithInfo:(ACCMVTemplateMergedInfo *)templateInfo completion:(void (^)(id<ACCMVTemplateModelProtocol> _Nullable, NSError * _Nullable))completion;

+ (void)fetchMomentTemplate:(ACCMomentAIMomentModel *)moment
              progressBlock:(void(^)(CGFloat progress))progressBlock
                 completion:(void(^)(id<ACCMVTemplateModelProtocol> _Nullable templateModel,
                                     NSArray<ACCMomentMaterialSegInfo *> * _Nullable segInfos,
                                     NSError * _Nullable error))completon;


+ (void)batchFetchMomentTemplate:(ACCMomentAIMomentModel *)moment
                      limitCount:(NSInteger)limitCount
                   progressBlock:(void(^)(CGFloat progress))progressBlock
                      completion:(void (^)(NSArray<id<ACCMVTemplateModelProtocol>> * _Nullable,
                                           NSArray< NSArray<ACCMomentMaterialSegInfo *> * > * _Nullable,
                                           NSError * _Nullable error))completon;

+ (void)batchFetchTemplateModelWithInfoArray:(NSArray<ACCMVTemplateMergedInfo *>  *)templateInfoArray
                              templateSource:(ACCCutSameTemplateSource)templateSource
                                  completion:(void (^)(NSArray<id<ACCMVTemplateModelProtocol>> * modelArray, NSError * error))completion;

+ (void)batchFetchTemplateModelWithInfoArray:(NSArray<ACCMVTemplateMergedInfo *>  *)templateInfoArray
                                  completion:(void (^)(NSArray<id<ACCMVTemplateModelProtocol>> * modelArray, NSError * error))completion;

@end

NS_ASSUME_NONNULL_END
