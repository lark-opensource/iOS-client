//
//  IESEffectModelDownloadTask.h
//  EffectPlatformSDK
//
//  Created by zhangchengtao on 2020/3/9.
//

#import <Foundation/Foundation.h>
#import <EffectPlatformSDK/IESEffectBaseDownloadTask.h>

@class IESEffectModel;
@class IESManifestManager;

NS_ASSUME_NONNULL_BEGIN

@interface IESEffectModelDownloadTask : IESEffectBaseDownloadTask

@property (nonatomic, strong) IESManifestManager *manifestManager;

@property (nonatomic, strong) IESEffectModel *effectModel;

- (instancetype)initWithEffectModel:(IESEffectModel *)effectModel
                        destination:(NSString *)destination;

- (instancetype)init NS_UNAVAILABLE;

@end

NS_ASSUME_NONNULL_END
