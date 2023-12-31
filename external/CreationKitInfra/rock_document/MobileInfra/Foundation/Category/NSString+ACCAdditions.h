//
//  NSString+ACCAdditions.h
//  CameraClient
//
//  Created by Liu Deping on 2019/12/4.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface NSString (ACCAdditions)

- (NSString *)acc_md5String;

- (CGFloat)acc_widthWithFont:(UIFont *)font height:(CGFloat)maxHeight;

- (CGFloat)acc_heightWithFont:(UIFont *)font width:(CGFloat)maxWidth;

- (CGSize)acc_sizeWithFont:(UIFont *)font width:(CGFloat)maxWidth maxLine:(NSInteger)maxLine;

- (NSInteger)acc_lineCountWithFont:(UIFont *)font
                    paragraphStyle:(NSMutableParagraphStyle * _Nullable)paragraphStyle
             appendOtherAttributes:(void(^ _Nullable )(NSMutableDictionary <NSAttributedStringKey, id> * _Nonnull attributes))appendBlock
                          maxWidth:(CGFloat)maxWidth;

//- (NSString *)acc_stringByURLEncode;
//
//- (NSString *)acc_stringByURLDecode;

- (nullable id)acc_jsonValueDecoded;
- (nullable id)acc_jsonValueDecoded:(NSError * _Nullable __autoreleasing * _Nullable)error;
- (nullable id)acc_ContentJsonDecoded;

- (nullable NSArray *)acc_jsonArray;
- (nullable NSDictionary *)acc_jsonDictionary;

- (nullable NSArray *)acc_jsonArray:(NSError * _Nullable __autoreleasing * _Nullable)error;
- (nullable NSDictionary *)acc_jsonDictionary:(NSError * _Nullable __autoreleasing * _Nullable)error;


// RTL
- (BOOL)acc_isRTLString;
- (BOOL)acc_isLTRString;
- (NSString *)acc_RTLString;
- (NSString *)acc_LTRString;
- (NSString *)accrtl_FSIString;

// write
- (BOOL)acc_writeToURL:(NSURL *)url atomically:(BOOL)useAuxiliaryFile encoding:(NSStringEncoding)enc error:(NSError **)error;
- (BOOL)acc_writeToFile:(NSString *)path atomically:(BOOL)useAuxiliaryFile encoding:(NSStringEncoding)enc error:(NSError **)error;

// URL
- (NSString *)acc_urlEncodedString;
- (NSString *)acc_urlDecodedString;


// Color
- (uint32_t)acc_argbColorHexValue;
+ (NSString *)acc_colorHexStringFrom:(uint32_t)hexValue;

/**
 * @brief Determine if the string contains a number
 * @return contains returns YES, otherwise returns NO
 */
- (BOOL)acc_containsNumberOnly;


@end

NS_ASSUME_NONNULL_END
