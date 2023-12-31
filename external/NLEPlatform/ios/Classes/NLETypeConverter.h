//
//  NLETypeConverter.h
//  NLEPlatform
//
//  Created by bytedance on 2020/12/7.
//

#import <Foundation/Foundation.h>
#include <string>

inline NSString* toObjCString(const std::string& str){
    return [NSString stringWithUTF8String:str.c_str()];
}

inline std::string toCPPString(NSString* str){
    return str.length <= 0 ? "" : str.UTF8String;
}

@interface NLETypeConverter : NSObject

+ (NSString *)covertCPPString:(const std::string)string;

+ (std::string)covertObjCString:(NSString *)string;

+ (std::wstring)covertObjCWString:(NSString*)string;

+ (NSString *)covertCPPWString:(std::wstring)string;

@end
