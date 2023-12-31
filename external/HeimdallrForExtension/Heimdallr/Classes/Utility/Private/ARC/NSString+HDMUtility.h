//
//  NSString+HDMUtility.h
//  Heimdallr
//
//  Created by 刘诗彬 on 2018/12/11.
//

#import <Foundation/Foundation.h>

@interface NSString (HDMUtility)
+ (NSString *)stringWithJSONObject:(id)infoDict;
- (NSDictionary *)dictionaryWithJSONString;
- (NSString *)base64Decode;// base64解码
- (NSString *)base64Encode;// base64编码

+ (NSString *)Base64StringWithJSONData:(NSData *)data;
+ (NSData *)decodedDataWithBase64String;

- (NSString *)hmdAppendHTTPSSafely;

@end
