//
//  ARTEffectManager.h
//  ArtistOpenPlatformSDK
//
//  Created by wuweixin on 2020/10/21.
//

#import <Foundation/Foundation.h>

@class ARTEffectConfig;
@class ARTEffectModel;
@protocol ARTEffectPrototype;

typedef void(^ARTEffectListFetchCompletion)(NSArray<id<ARTEffectPrototype>> *_Nullable effects, NSError *_Nullable error);

@protocol ARTEffectManagerRequestDelegate <NSObject>
@required
-(void)fetchEffectListWithEffectIDs:(NSArray<NSString*> *_Nonnull)effectIDs completion:(ARTEffectListFetchCompletion _Nullable )completion;
-(void)fetchEffectListWithResourceIDs:(NSArray<NSString*> *_Nonnull)resourceIDs completion:(ARTEffectListFetchCompletion _Nullable )completion;
@end

NS_ASSUME_NONNULL_BEGIN

@interface ARTEffectManager : NSObject

@property (nonatomic, strong, readonly) ARTEffectConfig *config;
@property (nonatomic, strong) id<ARTEffectManagerRequestDelegate> requestDelegate;
/**
 * @param config The configuration. Can not be nil.
 */
- (instancetype)initWithConfig:(ARTEffectConfig *)config;
- (instancetype)init NS_UNAVAILABLE;

+ (instancetype)defaultManager;

- (void)setUp;

-(void)fetchEffectListWithEffectIDs:(NSArray<NSString*> *)effectIDs completion:(ARTEffectListFetchCompletion)completion;
-(void)fetchEffectListWithResourceIDs:(NSArray<NSString*> *)resourceIDs completion:(ARTEffectListFetchCompletion)completion;

/**
 * Download effect resource
 * @param effect The effect to be download.
 * @param progress Call on main thread.
 * @param completion Call on main thread.
 */
- (void)downloadEffect:(id<ARTEffectPrototype>)effect
              progress:(void (^ __nullable)(CGFloat progress))progress
            completion:(void (^ __nullable)(NSString *path, NSError *error))completion;

- (void)downloadEffectModel:(ARTEffectModel *)effectModel
                   progress:(void (^ __nullable)(CGFloat progress))progress
                 completion:(void (^ __nullable)(NSString *path, NSError *error))completion;

/**
 * Thread Safe method
 * @param effectModel effectModel
 * @return The path of the effect if the requirements and effect both exist, otherwise nil.
 */
- (nullable NSString *)effectPathForEffectModel:(id<ARTEffectPrototype>)effectModel;

/**
 * Thread Safe method
 * @param effectMD5 The md5 value of a effect.
 * @return The path of the effect.
 */
- (nullable NSString *)effectPathForEffectMD5:(NSString *)effectMD5;

@end

@interface ARTEffectManager (Statistic)

- (void)updateUseCountForEffect:(id<ARTEffectPrototype>)effectModel byValue:(NSInteger)value;

- (void)updateRefCountForEffect:(id<ARTEffectPrototype>)effectModel byValue:(NSInteger)value;

@end

@interface ARTEffectManager (DiskClean)

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
