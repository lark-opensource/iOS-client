//
//  NSData+OK.h
//  OneKit
//
//  Created by bob on 2020/4/27.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface NSData (OK)

- (NSString *)ok_md5String;
- (NSString *)ok_sha256String;
- (NSString *)ok_hexString;
- (nullable id)ok_jsonValueDecoded;
- (nullable id)ok_jsonValueDecoded:(NSError *__autoreleasing *)error;

@end

NS_ASSUME_NONNULL_END
