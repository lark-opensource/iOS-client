//
//  ACCModernPOIStickerDataHelperProtocol.h
//  CameraClient-Pods-Aweme
//
//  Created by 卜旭阳 on 2020/10/12.
//

#import <Foundation/Foundation.h>

@class IESEffectModel;

@protocol ACCModernPOIStickerDataHelperProtocol <NSObject>

// Prefetch default Resource
+ (void)prefetchDefaultPOIStyleResourceIfNeeded;

// Fetch All Effect Models, will download default effect
+ (void)fetchEffectWithEffectIds:(NSArray<NSString *> *)effectIds
                    defaultIndex:(NSUInteger)defaultIndex
                 completionBlock:(void(^)(NSArray<IESEffectModel *> *, IESEffectModel *, NSError *))completionBlock;

+ (void)fetchEffectWithModel:(IESEffectModel *)effect
             completionBlock:(void(^)(BOOL, NSError *))completionBlock;

+ (nonnull NSString *)generateTextParamsWithPOIName:(NSString *)poiName
                                         effectPath:(NSString *)effectPath
                                        effectModel:(IESEffectModel *)effectModel;

+ (void)saveBasicEffects:(NSArray<IESEffectModel *> *)effects;

+ (nonnull NSArray *)basicEffectIds;

+ (nonnull NSArray *)commonEffectIds;

+ (nonnull NSArray *)standardEffectIds;

+ (nonnull NSString *)optimizeTextParams:(NSString *)textParams;

@end
