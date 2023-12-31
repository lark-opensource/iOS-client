//
//  IESLiveResouceBundle+String.m
//  Pods
//
//  Created by Zeus on 2016/12/21.
//
//

#import "IESLiveResouceBundle+String.h"
#import "IESLiveResouceManager.h"
#import "NSString+IESLiveResouceBundle.h"

@implementation IESLiveResouceBundle (String)

- (NSString * (^)(NSString *key))string {
    return ^(NSString *key) {
        NSString *value = (NSString *)[self objectForKey:key type:@"string"];
        if ([value hasPrefix:@"@string/"]) {
            return self.string([value substringFromIndex:[@"@string/" length]]);
        }
        return value;
    };
}

- (NSString * (^)(NSString *key, NSDictionary *params))fstring {
    return ^(NSString *key, NSDictionary *params) {
        NSString *string = self.string(key);
        if (string) {
            string = [string ies_lr_formatWithParams:params];
        }
        return string;
    };
}

- (NSAttributedString * (^)(NSString *key))astring {
    return ^(NSString *key) {
        NSString *string = self.string(key);
        return [[IESLiveResouceHTMLParser sharedInstance] parseHTMLWithString:string error:nil];
    };
}

- (NSAttributedString * (^)(NSString *key, NSDictionary *params))afstring {
    return ^(NSString *key, NSDictionary *params) {
        NSString *string = self.fstring(key, params);
        return [[IESLiveResouceHTMLParser sharedInstance] parseHTMLWithString:string error:nil];
    };
}

@end
