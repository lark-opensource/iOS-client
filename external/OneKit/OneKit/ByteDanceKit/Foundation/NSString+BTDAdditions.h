/**
 * @file NSString+BTDAdditions
 * @author David<gaotianpo@songshulin.net>
 *
 * @brief NSString's additions.
 * 
 * @details NSString's additions.
 * 
 */
//
//  Created by David Alpha Fox on 3/8/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#if TARGET_OS_IPHONE
#import <UIKit/UIKit.h>
#else
#import <AppKit/AppKit.h>
#endif

#import <Foundation/Foundation.h>


NS_ASSUME_NONNULL_BEGIN

@interface NSString (BTDAdditions)

- (NSString *)btd_trimmed;

/**
 
 @return A md5 NSString.
 */
- (nonnull NSString *)btd_md5String;
/**

 @return A sha1 NSString.
 */
- (nonnull NSString *)btd_sha1String;
/**

 @return A sha256 NSString.
 */
- (nonnull NSString *)btd_sha256String;
/**
 Return an UUID NSString.
 */
+ (nonnull NSString *)btd_stringWithUUID;
+ (nonnull NSString *)btd_HMACMD5WithKey:(nonnull NSString *)key andData:(nullable NSString *)data;
/**
 Return a hex NSString in UTF-16 code unit.
 */
- (nonnull NSString *)btd_hexString;

/**
 Return a NSString encoded according to base64.
 */
- (nullable NSString *)btd_base64EncodedString;

/**
 Return a NSString decoded according to base64.
 */
- (nullable NSString *)btd_base64DecodedString;

/**
 Split a NSString.
 @param characterSet The split rule.
 @return A NSString.
  Sample Code:
 NSString *str =@"A~B^C";
 NSString *resultStr =[str btd_stringByRemoveAllCharactersInSet:
 [NSCharacterSet characterSetWithCharactersInString:@"^~"]];
 resultStr:ABC
 */
- (nullable NSString *)btd_stringByRemoveAllCharactersInSet:(nonnull NSCharacterSet *)characterSet;
/**

 @return Return a NSString after removing all whitespace and newline characters.
 */
- (nullable NSString *)btd_stringByRemoveAllWhitespaceAndNewlineCharacters;

#if TARGET_OS_IPHONE
/**
 Calculate the size of the text.
 */
- (CGFloat)btd_heightWithFont:(nonnull UIFont *)font width:(CGFloat)maxWidth;

- (CGFloat)btd_widthWithFont:(nonnull UIFont *)font height:(CGFloat)maxHeight;

- (CGSize)btd_sizeWithFont:(nonnull UIFont *)font width:(CGFloat)maxWidth;

- (CGSize)btd_sizeWithFont:(nonnull UIFont *)font width:(CGFloat)maxWidth maxLine:(NSInteger)maxLine;
#else
- (CGFloat)btd_heightWithFont:(nonnull NSFont *)font width:(CGFloat)maxWidth;

- (CGFloat)btd_widthWithFont:(nonnull NSFont *)font height:(CGFloat)maxHeight;

- (CGSize)btd_sizeWithFont:(nonnull NSFont *)font width:(CGFloat)maxWidth;

- (CGSize)btd_sizeWithFont:(nonnull NSFont *)font width:(CGFloat)maxWidth maxLine:(NSInteger)maxLine;
#endif

/**
 Replace "\n\n" with "\n".

 @return A NSString after replacing.
 */
- (nullable NSString *)btd_stringByMergingContinuousNewLine;
/**

 @return A NSString afrer URLEncoding.
 */
- (nullable NSString *)btd_stringByURLEncode;
/**

 @return A NSString after URLDecoding.
 */
- (nullable NSString *)btd_stringByURLDecode;
/**
 Does a NSString contain numbers only?

 @return Return YES if the NSString contain numbers only.Otherwise, return NO.
 */
- (BOOL)btd_containsNumberOnly;

/**
 Does a NSString match a regex?

 @param regex A regex NSString.
 @return Return YES if the NSString match the regex.Otherwise, return NO.
 */
- (BOOL)btd_matchsRegex:(nonnull NSString *)regex;

/**
 Does a NSString match a regex? If it does, block will be called to send some informations.
 

 @param regex A regex NSString.
 @param options The options.
 @param block A callback block.
 */
- (void)btd_enumerateRegexMatches:(nonnull NSString *)regex options:(NSRegularExpressionOptions)options usingBlock:(nonnull void (^)(NSString *_Nullable match, NSRange matchRange, BOOL * _Nullable stop))block;
/**
 Convert a NSString to a NSDictionary or a NSArray.If an error happened, nil would be returned.
 */
- (nullable id)btd_jsonValueDecoded;
- (nullable id)btd_jsonValueDecoded:(NSError * _Nullable __autoreleasing * _Nullable)error;

- (nullable NSArray *)btd_jsonArray;
- (nullable NSDictionary *)btd_jsonDictionary;

- (nullable NSArray *)btd_jsonArray:(NSError * _Nullable __autoreleasing * _Nullable)error;
- (nullable NSDictionary *)btd_jsonDictionary:(NSError * _Nullable __autoreleasing * _Nullable)error;

/**
 Convert a NSString to a NSNumber.If an error happened, nil would be returned.

 @return Return a NSNumber.If an error happened, the function would return nil.
 */
- (nullable NSNumber *)btd_numberValue;
/**
 Convert two strings to a new string.
 
 @param componentString a component string
 @return A NSString.
 Sample Code:
 NSString *str1 = @"http://www.baidu.com";
 NSSting *str2 = @"a=b&c=d"
 NSString *resultStr = [str1 btd_urlStringByAddingComponentString:str2];
 resultStr: http://www.baidu.com?a=b&c=d
 */
- (nullable NSString *)btd_urlStringByAddingComponentString:(nonnull NSString *)componentString;
/**
 Convert a string array to a new string.
 
 @param componentArray A string array.
 @return A NSString.
 */
- (nullable NSString *)btd_urlStringByAddingComponentArray:(NSArray<NSString *> * _Nonnull)componentArray;
/**
 Convert a dictionary to a string.

 @param parameters A param NSDictionary.
 @return A NSString.
 */
- (nullable NSString *)btd_urlStringByAddingParameters:(NSDictionary<NSString *, NSString *> * _Nonnull)parameters;

/**
 Remove strings in parameters from the NSString.

 @param parameters A NSArray consists of NSStrings.
 @return A NSString.
 */
- (nullable NSString *)btd_urlStringByRemovingParameters:(NSArray<NSString *> * _Nonnull)parameters;
/**

 @return Return A NSArray consists of path strings.If there is no path string, return nil.
 */
- (nullable NSArray<NSString *> *)btd_pathComponentArray;
/**
 Return a query param dictionary.Nonstandard parameters will be automatically filtered out. If there is no param, return nil.

 @return A NSDictionary.
 */
- (nullable NSDictionary<NSString *, NSString *> *)btd_queryParamDict;

/**

 @return Return the scheme. If the string is a empty string, return nil.
 */
- (nullable NSString *)btd_scheme;
/**
 
 @return Return the path.If there's no path, return nil.
 */
- (nullable NSString *)btd_path;

/**
 Prepend the string after the Library path.
 
 @return The string after prepending.
 */
- (NSString *)btd_prependingLibraryPath;

/**
 Prepend the string after the Cache path.

 @return The string after prepending.
 */
- (NSString *)btd_prependingCachePath;

/**
 Prepend the string after the Documents path.
 
 @return The string after prepending.
 */
- (NSString *)btd_prependingDocumentsPath;

/**
 Prepend the string after the tmp path.
 
 @return The string after prepending.
 */
- (NSString *)btd_prependingTemporaryPath;

@end

@interface NSAttributedString (BTDToBeDeprecated)

/**
 @return Return the height of the text when the max width of the text is maxWidth.
 */
- (CGFloat)btd_heightWithWidth:(CGFloat)maxWidth;

@end

NS_ASSUME_NONNULL_END
