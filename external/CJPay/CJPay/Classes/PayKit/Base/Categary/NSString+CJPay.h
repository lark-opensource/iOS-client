//
//  NSString+CJPay.h
//  AFNetworking
//
//  Created by jiangzhongping on 2018/8/17.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface NSString (CJPay)

- (CGSize)cj_sizeWithFont:(UIFont *_Nonnull)font maxSize:(CGSize)size;
- (CGSize)cj_sizeWithFont:(UIFont*)font width:(CGFloat)width;

- (NSString *_Nullable)cj_URLEncode;

- (NSString *_Nullable)cj_md5String;

- (NSData *_Nullable)base64DecodeData;

- (NSData*_Nullable) hexToBytes;

- (NSString *_Nullable)cj_matchedByRegex:(NSString *_Nullable)pattern forcedMatchedFromPrefix:(BOOL)isPrefix;

// 删除书名号
- (NSString *_Nullable)cj_removeBookNum;

- (NSString *_Nullable)cj_remove:(NSString *_Nonnull)str;

- (NSString *_Nullable)cj_noSpace;

- (nullable NSDictionary *)cj_toDic;

- (NSString *_Nullable)cj_base64EncodeString;

+ (NSString *_Nullable)cj_joinedWithSubStrings:(NSString *_Nonnull)firstStr,...NS_REQUIRES_NIL_TERMINATION;
- (NSDictionary *)cj_urlQueryParams;
- (NSString *_Nullable)cj_urlPath;

- (NSString *)cj_safeURLString;

- (NSString *)cj_replaceUnicode;

- (NSMutableAttributedString *)attributedStringWithDollarSeparated;

@end

NS_ASSUME_NONNULL_END
