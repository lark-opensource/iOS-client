//
//  SSCommon+JSON.h
//  Article
//
//  Created by SunJiangting on 14-6-16.
//
//

#import <Foundation/Foundation.h>

@interface NSString (JSONValue)

/// 可能返回 NSNull、NSDitionary、NSArray等类型
- (id _Nullable)JSONValue;

/// 返回 NSDitionary 类型，如果不是 NSDitionary 类型则返回 nil
- (NSDictionary * _Nullable)JSONDictionary;

-(NSDictionary * _Nullable)stringToDic;

@end

@interface NSArray (JSONValue)
- (NSString *)JSONRepresentation;
@end


@interface NSDictionary (JSONValue)
- (NSString *)JSONRepresentation;
- (NSString *)JSONRepresentationWithOptions:(NSJSONWritingOptions)options;
@end

@interface NSData (JSONValue)

/// 可能返回 NSNull、NSDitionary、NSArray等类型
- (id _Nullable)JSONValue;

/// 返回 NSDitionary 类型，如果不是 NSDitionary 类型则返回 nil
- (NSDictionary * _Nullable)JSONDictionary;

/// 安全方法.（NSJSONSerialization +JSONObjectWithData:options:error: 不安全，data为nil会crash）
- (nullable id)JSONValueWithOptions:(NSJSONReadingOptions)opt error:(NSError **)error;
@end
