//
//  BDAssert.h
//  BDAssert
//
//  Created by 李琢鹏 on 2019/1/31.
//

#import <Foundation/Foundation.h>

FOUNDATION_EXPORT void BDAssert(BOOL condition, NSString *desc, ...);
FOUNDATION_EXPORT void BDParameterAssert(BOOL condition);

@protocol BDAssertionPlugin <NSObject>

+ (void)handleFailureWithDesc:(NSString *)desc;

@end

@interface BDAssertionPluginManager : NSObject

+(void)addPlugin:(Class<BDAssertionPlugin>)plugin;
+(void)removePlugin:(Class<BDAssertionPlugin>)plugin;
+ (void)handleFailureWithDesc:(NSString *)desc;

@end
