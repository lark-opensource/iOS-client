//
//  IESLiveResourceBundle+File.m
//  IESLiveResourcesButler
//
//  Created by lishuangyang on 2019/5/28.
//

#import "IESLiveResourceBundle+File.h"

@implementation IESLiveResouceBundle (File)

- (NSString *(^)(NSString *))filePath {
    return ^(NSString *key) {
        if (key) {
            NSString *filepath = [self objectForKey:key type:@"file"];
            return filepath;
        }
        return (NSString *)nil;
    };
}

- (NSString *(^)(NSString *, NSString *))filePathInfolder {
    return ^(NSString *key, NSString *folder) {
        NSString *fullPath = self.afilePath(key, folder);
        return [self objectForKey:fullPath type:@"file"];
    };
}

- (NSString *(^)(NSString *))bundlePath {
    return ^(NSString *key) {
        if (key) {
            NSString *bundlePath = [self objectForKey:[key stringByAppendingPathExtension:@"bundle"] type:@"bundle"];
            return bundlePath;
        }
        return (NSString *)nil;
    };
 }

- (NSString *(^)(NSString *, NSString *))afilePath {
    return ^(NSString *key, NSString *folder) {
        if (folder) {
            NSString *string = [folder stringByAppendingPathComponent:key];
            return string;
        } else {
            return (NSString *)key;
        }
    };
}

@end
