//
//  HMTools.m
//  Hermas
//
//  Created by 崔晓兵 on 7/6/2022.
//

#import "HMTools.h"

namespace hermas {

NSString* stringWithDictionary(NSDictionary *dic) {
    @autoreleasepool {
        NSMutableDictionary *temp = [NSMutableDictionary dictionaryWithDictionary:dic];
        NSError *error = nil;
        NSData *data = [NSJSONSerialization dataWithJSONObject:temp options:NSJSONWritingPrettyPrinted error:&error];
        if (error) return nil;
        NSString *str = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
        if (!str) return nil;
        return str;
    }
}

NSDictionary* dictionaryWithJsonString(NSString *jsonString) {
    @autoreleasepool {
        if (jsonString == nil) {
            return nil;
        }
        NSData *jsonData = [jsonString dataUsingEncoding:NSUTF8StringEncoding];
        NSError *error;
        NSDictionary *dic = [NSJSONSerialization JSONObjectWithData:jsonData options:NSJSONReadingMutableContainers error:&error];
        if (error) {
            return nil;
        }
        return dic;
    }
}


std::map<int, int> convertNSDictionayToIntTypeMap(NSDictionary * _Nonnull dic) {
    @autoreleasepool {
        std::map<int, int> res;
        for (NSNumber *key in dic) {
            res[[key intValue]] = [[dic objectForKey:key] intValue];
        }
        return res;
    }
}

std::vector<std::string> vectorWithNSArray(NSArray<NSString*> * _Nonnull arr) {
    @autoreleasepool {
        __block std::vector<std::string> vec;
        vec.reserve([arr count]);
        [arr enumerateObjectsUsingBlock:^(NSString * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
            vec.push_back(obj.UTF8String);
        }];
        return vec;
    }
}

std::string stringWithNSArray(NSArray<NSString*> *arr) {
    @autoreleasepool {
        std::string arrstr;
        if (arr.count > 0) {
            arrstr = [arr componentsJoinedByString:@"_"].UTF8String;
        }
        return arrstr;
    }
}

std::map<std::string, std::vector<std::string>> mapWithNSDictionary(NSDictionary * _Nonnull dic) {
    @autoreleasepool {
        __block std::map<std::string, std::vector<std::string>> res;
        [dic enumerateKeysAndObjectsUsingBlock:^(NSString * _Nonnull key, NSArray<NSString*> * _Nonnull obj, BOOL * _Nonnull stop) {
            res[key.UTF8String] = vectorWithNSArray(obj);
        }];
        return res;
    }
}

std::map<std::string, double> mapWithDoubleNSDictionary(NSDictionary * _Nonnull dic) {
    @autoreleasepool {
        __block std::map<std::string, double> res;
        [dic enumerateKeysAndObjectsUsingBlock:^(NSString * _Nonnull key, NSNumber * _Nonnull obj, BOOL * _Nonnull stop) {
            res[key.UTF8String] = obj.doubleValue;
        }];
        return res;
    }
}

bool isDictionaryEmpty(NSDictionary * _Nullable dict) {
    return (!dict || ![dict isKindOfClass:[NSDictionary class]] || ((NSDictionary *)dict).count == 0);
}

}
