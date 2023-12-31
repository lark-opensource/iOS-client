//
//  HTSCloudControlDecode.m
//  LiveStreaming
//
//  Created by 权泉 on 2017/2/16.
//  Copyright © 2017年 Bytedance. All rights reserved.
//

#import "AWECloudControlDecode.h"
#import "NSData+AES.h"

@implementation AWECloudControlDecode

+ (id)payloadWithDecryptData:(NSData *)data withKey:(NSString *)key
{
    if (!data) {
        return nil;
    }

    NSData *base64DecodeData = [[NSData alloc] initWithBase64EncodedData:data options:NSDataBase64DecodingIgnoreUnknownCharacters];
    
    NSData *decryptedData = [base64DecodeData AES128DecryptedDataWithKey:key iv:key];
    NSString *decryptString = [[NSString alloc] initWithData:decryptedData encoding:NSASCIIStringEncoding];

    NSRange range = [decryptString rangeOfString:@"$"];
    
    if (range.location == NSNotFound || range.location + range.length > decryptString.length) {
        return nil;
    }
    
    NSString *jsonString = [decryptString substringToIndex:range.location];
    
    NSError *error = nil;
    NSDictionary *json = [NSJSONSerialization JSONObjectWithData:[jsonString dataUsingEncoding:NSUTF8StringEncoding]
                                                         options:NSJSONReadingAllowFragments
                                                           error:&error];
    if (error || !json) {
        return nil;
    } else {
        return json;
    }
}

@end
