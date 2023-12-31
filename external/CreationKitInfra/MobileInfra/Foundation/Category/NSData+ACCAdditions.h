//
//  NSData+ACCAdditions.h
//  CameraClient
//
//  Created by Liu Deping on 2019/12/4.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

FOUNDATION_EXTERN NSString *const ACCDataWriteErrorStepKey;

@interface NSData (ACCAdditions)

- (NSString *)acc_md5String;

/**
 NSData generates an NSArray or NSDictionary

 @return returns an NSArray or NSDictionary, or null if there is an error
 */
- (nullable id)acc_jsonValueDecoded;
- (nullable id)acc_jsonValueDecoded:(NSError * _Nullable __autoreleasing * _Nullable)error;

- (nullable NSArray *)acc_jsonArray;
- (nullable NSDictionary *)acc_jsonDictionary;

- (nullable NSArray *)acc_jsonArray:(NSError * _Nullable __autoreleasing * _Nullable)error;
- (nullable NSDictionary *)acc_jsonDictionary:(NSError * _Nullable __autoreleasing * _Nullable)error;


- (BOOL)acc_writeToFile:(NSString *)path atomically:(BOOL)useAuxiliaryFile;
- (BOOL)acc_writeToFile:(NSString *)path options:(NSDataWritingOptions)writeOptionsMask error:(NSError **)errorPtr;
- (BOOL)acc_writeToURL:(NSURL *)url atomically:(BOOL)atomically;
- (BOOL)acc_writeToURL:(NSURL *)url options:(NSDataWritingOptions)writeOptionsMask error:(NSError **)errorPtr;

/**
 * convert to hexadecimal string expression
 * @return all characters to lowercase
 */
- (NSString *)acc_toHex;

/**
 * Convert a hexadecimal string to an NSData object
 *
 * @param command The hexadecimal string to be converted
 *
 * @return convert the finished NSData object
 */
+ (NSData *)acc_dataFromHEXString:(NSString *)command;

@end

NS_ASSUME_NONNULL_END
