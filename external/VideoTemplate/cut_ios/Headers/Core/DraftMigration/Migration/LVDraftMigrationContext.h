//
//  LVDraftMigrationContext.h
//  LVDraftMigration
//
//  Created by luochaojing on 2020/3/16.
//

#import <Foundation/Foundation.h>
#import <EffectPlatformSDK/EffectPlatform.h>

NS_ASSUME_NONNULL_BEGIN

typedef NSNumber * _Nullable (^LVMigrationGameplayReshapeFechter)(NSString *gameplayAlgorithm);

@interface LVDraftMigrationContext : NSObject

@property (class, nonatomic, copy, nullable) LVMigrationGameplayReshapeFechter gameplayReshapeFechter;

+ (instancetype)shared;

@property (nonatomic, strong, readonly) EffectPlatform *effectPlatform;

@end

NS_ASSUME_NONNULL_END
