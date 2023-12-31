//
//  NSString+TSASignature.h
//  TTTopSignature
//
//  Created by 黄清 on 2018/10/17.


#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

#ifndef __TSAHTTPMethod__
#define __TSAHTTPMethod__

typedef NS_ENUM(NSInteger, TSAHTTPMethod) {
    TSAHTTPMethodUnknown,
    TSAHTTPMethodGET,
    TSAHTTPMethodHEAD,
    TSAHTTPMethodPOST,
    TSAHTTPMethodPUT,
    TSAHTTPMethodPATCH,
    TSAHTTPMethodDELETE
};
#endif

@interface NSString (TSASignature)

+ (NSString *)tsa_base64md5FromData:(NSData *)data;
- (NSString *)tsa_stringWithURLEncoding;
- (NSString *)tsa_decodeURLEncoding;
+ (NSString *)tsa_hexEncode:(NSString *)string;
+ (NSString *)tsa_hashString:(NSString *)stringToHash;

+ (instancetype)tsa_stringWithHTTPMethod:(TSAHTTPMethod)HTTPMethod;

@end

NS_ASSUME_NONNULL_END
