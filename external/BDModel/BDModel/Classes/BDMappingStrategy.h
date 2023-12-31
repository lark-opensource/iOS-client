//
//  BDMappingStrategy.h
//  BDModel
//
//  Created by 马钰峰 on 2019/3/28.
//

#import <Foundation/Foundation.h>
#import "BDModelMappingDefine.h"

NS_ASSUME_NONNULL_BEGIN

@interface BDMappingStrategy : NSObject

+ (NSDictionary *)mapJSONKeyWithDictionary:(NSDictionary *)dic options:(BDModelMappingOptions)options;

+ (NSArray *)mapJSONKeyWithArray:(NSArray *)arr options:(BDModelMappingOptions)options;

+ (NSString *)mapCamelToSnakeCase:(NSString *)keyName;

+ (NSString *)mapSnakeCaseToCamel:(NSString *)keyName;

@end

NS_ASSUME_NONNULL_END
