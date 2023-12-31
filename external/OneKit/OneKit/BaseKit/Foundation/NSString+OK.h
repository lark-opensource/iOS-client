//
//  NSString+OK.h
//  OneKit
//
//  Created by bob on 2020/4/27.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface NSString (OK)

- (NSString *)ok_trimmed;
- (NSString *)ok_md5String;
- (NSString *)ok_sha256String;
- (nullable NSString *)ok_base64EncodedString;
- (nullable NSString *)ok_base64DecodedString;
- (nullable id)ok_jsonValueDecoded;
- (nullable id)ok_jsonValueDecoded:(NSError *__autoreleasing *)error;

- (NSString *)ok_stringByAppendingQueryDictionary:(NSDictionary *)params;
- (NSDictionary *)ok_queryDictionary;

+ (NSString *)ok_UUIDString;

- (id)ok_safeJsonObject;
- (NSString *)ok_safeJsonObjectKey;

@end

NS_ASSUME_NONNULL_END
