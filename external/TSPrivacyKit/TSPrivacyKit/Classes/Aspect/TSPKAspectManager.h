//
//  TSPKAspectManager.h
//  Indexer
//
//  Created by bytedance on 2022/3/31.
//

#import <Foundation/Foundation.h>

@interface TSPKAspectManager : NSObject

+ (void)setupDynamicAspect;

+ (BOOL)checkIfAllowKlass:(nullable NSString *)klassName;

+ (BOOL)isAspectClassAllMethodsEnabled;

@end
