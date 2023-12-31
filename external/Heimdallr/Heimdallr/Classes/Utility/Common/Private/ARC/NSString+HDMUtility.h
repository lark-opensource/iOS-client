//
//  NSString+HDMUtility.h
//  Heimdallr
//
//  Created by 刘诗彬 on 2018/12/11.
//

#import <Foundation/Foundation.h>

@interface NSString (HDMUtility)
+ (NSString *)hmd_stringWithJSONObject:(id)infoDict;
- (NSDictionary *)hmd_dictionaryWithJSONString;
- (NSString *)hmd_base64Decode;// base64解码
- (NSString *)hmd_base64Encode;// base64编码
+ (NSString *)hmd_Base64StringWithJSONData:(NSData *)data;
- (NSData *)hmd_decodedDataWithBase64String;
- (NSString *)hmdAppendHTTPSSafely;

@end
