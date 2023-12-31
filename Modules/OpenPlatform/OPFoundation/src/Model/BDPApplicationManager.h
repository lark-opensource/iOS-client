//
//  BDPApplicationManager.h
//  Timor
//
//  Created by 王浩宇 on 2019/1/26.
//

#import <Foundation/Foundation.h>
#import "BDPModuleEngineType.h"
#import "BDPSchema.h"

NS_ASSUME_NONNULL_BEGIN

FOUNDATION_EXTERN NSString *const BDPAppNameKey ;
FOUNDATION_EXTERN NSString *const BDPAppVersionKey;
FOUNDATION_EXTERN NSString *const BDPAppLanguageKey;

@interface BDPApplicationManager : NSObject

@property (nonatomic, copy, readonly) NSDictionary *applicationInfo;
@property (nonatomic, copy, readonly) NSDictionary *sceneInfo;

+ (instancetype)sharedManager;

/* ------------- 💡便捷方法 ------------- */
+ (NSDictionary *)getOnAppEnterForegroundParams:(BDPSchema *)schema;
+ (NSDictionary *)getLaunchOptionParams:(BDPSchema *)schema type:(BDPType)type;
+ (NSString * _Nullable)language;
@end

NS_ASSUME_NONNULL_END
