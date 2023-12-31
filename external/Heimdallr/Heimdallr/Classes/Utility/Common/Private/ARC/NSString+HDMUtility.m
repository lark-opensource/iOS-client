//
//  NSString+HDMUtility.m
//  Heimdallr
//
//  Created by 刘诗彬 on 2018/12/11.
//

#import "NSString+HDMUtility.h"

@implementation NSString (HDMUtility)
+ (NSString *)hmd_stringWithJSONObject:(id)infoDict
{
    if (!infoDict || ![NSJSONSerialization isValidJSONObject:infoDict]) {
        return nil;
    }
    
    NSError *error;
    NSData *jsonData = [NSJSONSerialization dataWithJSONObject:infoDict
                                                       options:NSJSONWritingPrettyPrinted // Pass 0 if you don't care about the readability of the generated string
                                                         error:&error];
    
    NSString *jsonString = @"";
    
    if (jsonData) {
        jsonString = [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
    }
    
    jsonString = [jsonString stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];  //Remove the first and last blank characters and newline characters
    
    [jsonString stringByReplacingOccurrencesOfString:@"\n" withString:@""];
    
    return jsonString;
}

- (NSDictionary *)hmd_dictionaryWithJSONString
{
    NSData *jsonData = [self dataUsingEncoding:NSUTF8StringEncoding];
    NSError *err;
    NSDictionary *dic = [NSJSONSerialization JSONObjectWithData:jsonData
                                                        options:NSJSONReadingMutableContainers
                                                          error:&err];
    if(err)
    {
        return nil;
    }
    return dic;
}

- (NSString *)hmd_base64Decode {
    NSData *data = [[NSData alloc] initWithBase64EncodedString:self options:0];
    if (data) {
        return [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
    }
    
    return nil;
}

- (NSString *)hmd_base64Encode {
    NSData* data = [self dataUsingEncoding:NSUTF8StringEncoding];
    return [data base64EncodedStringWithOptions:0];
}

+ (NSString *)hmd_Base64StringWithJSONData:(NSData *)data
{
    return [data base64EncodedStringWithOptions:NSDataBase64Encoding64CharacterLineLength];
}

- (NSData *)hmd_decodedDataWithBase64String
{
    return [[NSData alloc] initWithBase64EncodedString:self
                                               options:NSDataBase64DecodingIgnoreUnknownCharacters];
}

- (NSString *)hmdAppendHTTPSSafely {
    if ([self hasPrefix:@"https://"]) {
        return self;
    }
    return [NSString stringWithFormat:@"https://%@",self];
}

@end
