//
//  UserDefault_iOS.cpp
//  Hermas
//
//  Created by 崔晓兵 on 28/4/2022.
//

#include "UserDefault_iOS.h"
#include "HMEngine.h"


NSUserDefaults *customUserDefault() {
    static NSUserDefaults *instance;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [[NSUserDefaults alloc] initWithSuiteName:hermas_plist_suite_name()];
    });
    return instance;
};

namespace hermas {
std::string UserDefault_iOS::Read(const std::string& key) {
    @autoreleasepool {
        NSString *keyStr = [NSString stringWithUTF8String:key.c_str()];
        NSString *value = [customUserDefault() stringForKey:keyStr];
        return value ? value.UTF8String : "";
    }
}

void UserDefault_iOS::Write(const std::string& key, const std::string& value) {
    @autoreleasepool {
        NSString *keyStr = [NSString stringWithUTF8String:key.c_str()];
        NSString *valueStr = [NSString stringWithCString:value.c_str() encoding:NSUTF8StringEncoding];
        [customUserDefault() setValue:valueStr forKey:keyStr];
    }
}

void UserDefault_iOS::Remove(const std::string& key) {
    @autoreleasepool {
        NSString *keyStr = [NSString stringWithUTF8String:key.c_str()];
        [customUserDefault() removeObjectForKey:keyStr];
    }
}

}
