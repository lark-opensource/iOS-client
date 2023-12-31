//
//  IESAlgorithmModelDownloadTask.h
//  EffectPlatformSDK
//
//  Created by zhangchengtao on 2020/3/9.
//

#import <Foundation/Foundation.h>
#import <EffectPlatformSDK/IESEffectBaseDownloadTask.h>
#import <EffectPlatformSDK/IESEffectAlgorithmModel.h>

NS_ASSUME_NONNULL_BEGIN

@interface IESAlgorithmModelDownloadTask : IESEffectBaseDownloadTask

@property (nonatomic, strong) IESEffectAlgorithmModel *algorithmModel;

- (instancetype)initWithAlgorithmModel:(IESEffectAlgorithmModel *)algorithmModel
                           destination:(NSString *)destination;

- (instancetype)init NS_UNAVAILABLE;

@end

NS_ASSUME_NONNULL_END
