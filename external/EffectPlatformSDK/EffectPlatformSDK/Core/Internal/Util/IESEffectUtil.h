//
//  IESEffectUtil.h
//  EffectPlatformSDK
//
//  Created by zhangchengtao on 2020/3/11.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@class IESAlgorithmRecord;
@class IESEffectAlgorithmModel;

typedef void(^ies_effect_result_block_t)(BOOL success, NSError * _Nullable error);

@interface IESEffectUtil : NSObject

@property (nonatomic, assign, class) BOOL disablePeekResource;

/**
 * Version Compare
 */
+ (BOOL)isVersion:(NSString *)version higherOrEqualThan:(NSString *)baseVersion;
+ (BOOL)isVersion:(NSString *)version higherThan:(NSString *)baseVersion;

/**
 * Version,  Size  and  MD5  Compare
 */
+ (BOOL)compareOnlineModel:(IESEffectAlgorithmModel *)onlineModel withBaseRecord:(IESAlgorithmRecord *)record;

/**
 * merge  the  algorithmModelNames  mapped  from  requirements  with  modelNames
 */
+ (NSSet<NSString *> *)mergeRequirements:(NSArray<NSString *> *)requirements withModelNames:(NSDictionary<NSString *, NSArray<NSString *> *> *)modelNames;

/**
 * Get algorirhm names from requirements
 * This method wraps the EffectSDK_iOS function 'bef_effect_peek_resources_needed_by_requirements'
 * @param algorithmRequirements Requirements array, can not be empty. e.g. ["objectDetect", "petBodyDetect"]
 * @return Algorithm names array needed by requirements. e.g. ["ttobjectmodel/tt_object_v5.0.model", "petbodymodel/petbody_v2.4.model"]
 */
+ (NSArray<NSString *> *)getAlgorithmNamesFromAlgorithmRequirements:(NSArray<NSString *> *)algorithmRequirements;

/**
 * whether  a  NSString  match  the  version  pattern
 */
+ (BOOL)isVersionString:(NSString *)string;

/**
 * Get short name and version from modelName
 * @param modelName e.g. 'ttobjectmodel/tt_object_v5.0.model' or 'tt_object_v5.0.model'
 * @param shortName tt_object
 * @param version 5.0
 */
+ (BOOL)getShortNameAndVersionWithModelName:(NSString *)modelName shortName:(NSString **)shortName version:(NSString **)version;

/// get short name, version and size type from model name.
/// @param modelFilePath e.g. 'ttobjectmodel/tt_object_v5.0_size1.model' or 'tt_object_v5.0_size1.model'
/// @param completion parsed callback
+ (void)parseModelFilePath:(NSString *)modelFilePath completion:(void(^)(BOOL isSuccess, NSString * __nullable shortName, NSString * __nullable version, NSInteger sizeType))completion;

@end

NS_ASSUME_NONNULL_END
