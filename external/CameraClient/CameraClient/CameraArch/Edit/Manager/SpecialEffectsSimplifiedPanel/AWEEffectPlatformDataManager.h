//
//  AWEEffectPlatformDataManager.h
//  Indexer
//
//  Created by Daniel on 2021/11/15.
//

#import <Foundation/Foundation.h>

@class IESEffectPlatformResponseModel;
@class IESEffectModel;

@interface AWEEffectPlatformDataManager : NSObject

- (IESEffectPlatformResponseModel *)getEffectsSynchronicallyInPanel:(NSString *)panelName;

- (void)getEffectsInPanel:(NSString *)panelName
               completion:(void (^ _Nullable)(IESEffectPlatformResponseModel * _Nullable))completion;

- (IESEffectPlatformResponseModel *)getCachedEffectsInPanel:(NSString *)panelName;

- (void)downloadFilesOfEffect:(IESEffectModel * _Nullable)effectModel
                   completion:(void (^ _Nullable)(BOOL, IESEffectModel * _Nullable))completion;

+ (NSArray<IESEffectModel *> *)getCachedEffectsOfPanel:(NSString *)panelName;

@end
