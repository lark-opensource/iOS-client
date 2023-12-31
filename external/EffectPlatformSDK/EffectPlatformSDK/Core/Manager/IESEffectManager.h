//
//  IESEffectManager.h
//  EffectPlatformSDK
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import <EffectPlatformSDK/IESEffectConfig.h>
#import <EffectPlatformSDK/IESEffectModel.h>
#import <EffectPlatformSDK/IESEffectAlgorithmModel.h>

typedef char *_Nullable (*ieseffectmanager_resource_finder_t)(void *, const char *, const char *);
typedef void(^ieseffectmanager_effect_download_completion_t)(IESEffectModel *effectModel, BOOL success, NSError * _Nullable error, NSTimeInterval duration);
typedef void(^ieseffectmanager_algorithm_download_completion_t)(IESEffectAlgorithmModel *algorithmModel, BOOL success, NSError * _Nullable error, NSTimeInterval duration);
typedef void(^ieseffectmanager_algorithm_find_t)(NSString *modelName, NSString *modelShortName, NSString *version, NSInteger sizeType, BOOL found);

NS_ASSUME_NONNULL_BEGIN

@class IESAlgorithmRecord;
/**
 * @bref The Effects and Algorithm Models Manager
 */
@interface IESEffectManager : NSObject

@property (nonatomic, strong, readonly) IESEffectConfig *config;
/**
 * @param config The configuration. Can not be nil.
 */
- (instancetype)initWithConfig:(IESEffectConfig *)config;
- (instancetype)init NS_UNAVAILABLE;

+ (instancetype)manager;

/**
 * @bref Set Up the manager
 */
- (void)setUp;

- (ieseffectmanager_resource_finder_t)getResourceFinder;

/**
 * Thread Safe method
 * @param effectModel
 * @return The path of the effect if the requirements and effect both exist, otherwise nil.
 */
- (nullable NSString *)effectPathForEffectModel:(IESEffectModel *)effectModel;

/**
 * Thread Safe method
 * @param effectMD5 The md5 value of a effect.
 * @return The path of the effect.
 */
- (nullable NSString *)effectPathForEffectMD5:(NSString *)effectMD5;

/**
* Thread Safe method
* @param algorithmRequirements e.g. ["objectDetect", "petBodyDetect"]
* @return Return if the requirements are all downloaded. If requirements has invalid name, return NO.
*/
- (BOOL)isAlgorithmRequirementsDownloaded:(NSArray<NSString *> *)algorithmRequirements;

/**
 * Thread Safe method
 * @param algorithmNames e.g. ["skysegmodel/tt_skyseg_v6.0.model", "objectDetect/tt_joints_v4.2_size0.model"]
 * @return Return if the algorithmNames are all downloaded. If algorithmNames has invalid name, return NO.
 */
- (BOOL)isAlgorithmDownloaded:(NSArray<NSString *> *)algorithmNames;

/**
 * Download effect resource and requriments
 * @param effect The effect to be download.
 * @param progress Call on main thread.
 * @param completion Call on main thread.
 */
- (void)downloadEffect:(IESEffectModel *)effect
              progress:(void (^ __nullable)(CGFloat progress))progress
            completion:(void (^ __nullable)(NSString *path, NSError *error))completion;

- (void)downloadEffect:(IESEffectModel *)effect
 downloadQueuePriority:(NSOperationQueuePriority)queuePriority
downloadQualityOfService:(NSQualityOfService)qualityOfService
              progress:(void (^ __nullable)(CGFloat progress))progress
            completion:(void (^ __nullable)(NSString *path, NSError *error))completion;

/**
 * Download Requirements
 * @param requirements e.g. ["objectDetect", "petBodyDetect"]
 * @param completion Call on main thread.
 */
- (void)downloadRequirements:(NSArray<NSString *> *)requirements
                  completion:(void (^ __nullable)(BOOL success, NSError *error))completion;

/**
 Download requirements and modelNames
 @param requirements e.g, ["objectDetect", "hdrnet"]
 @param modelNames e.g. { "ObjectTrack": ["ObjectTrack_AssignedTwo", "ObjectTrack_AssignedThree"],
                      "hdrnet":["hdrnet_TONE"] }
 @param completion call on main thread
 */
- (void)fetchResourcesWithRequirements:(NSArray<NSString *> *)requirements
                            modelNames:(NSDictionary<NSString *, NSArray<NSString *> *> *)modelNames
                            completion:(void (^ __nullable)(BOOL success, NSError *error))completion;

/**
 Fetch online model infos and download model
 @param modelNames eg {"ObjectTrack_AssignedTwo", "ObjectTrack_AssignedThree", "hdrnet_TONE"}
 @param completion call on main thread
 */
- (void)fetchOnlineInfosAndResourcesWithModelNames:(NSArray<NSString *> *)modelNames
                                             extra:(NSDictionary *)parameters
                                        completion:(void (^)(BOOL success, NSError *error))completion;

/**
return the model information by assigned requirements and modelNames after calling download method
@param requirements e.g. ["objectDetect", "petBodyDetect"]
@param modelNames e.g. { "ObjectTrack": ["ObjectTrack_AssignedTwo", "ObjectTrack_AssignedThree"],
                     "hdrnet":["hdrnet_TONE"] }
 */
- (NSDictionary<NSString *, IESAlgorithmRecord *> *)checkoutModelInfosWithRequirements:(NSArray<NSString *> *)requirements
                                                                            modelNames:(NSDictionary<NSString *,  NSArray<NSString *> *> *)modelNames;
@end

@interface IESEffectManager (Statistic)

- (void)updateUseCountForEffect:(IESEffectModel *)effectModel byValue:(NSInteger)value;

- (void)updateRefCountForEffect:(IESEffectModel *)effectModel byValue:(NSInteger)value;

@end

@interface IESEffectManager (DiskClean)

/**
 *@add allow panel list for effect unclean
 */
- (void)addAllowPanelListForEffectUnClean:(NSArray<NSString *> *)allowPanelList;

/**
 * @breif Get total bytes all effects, algorithms, tmp files allocated.
 */
- (unsigned long long)getTotalBytes;

/**
 * @breif Clean all effects, algorithm models, tmp files
 */
- (void)removeAllCacheFiles;

@end

NS_ASSUME_NONNULL_END
