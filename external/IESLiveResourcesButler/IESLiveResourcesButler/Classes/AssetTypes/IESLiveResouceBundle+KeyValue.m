//
//  IESLiveResouceBundle+KeyValue.m
//  Pods
//
//  Created by Zeus on 2016/12/21.
//
//

#import "IESLiveResouceBundle+KeyValue.h"
#import "IESLiveResouceManagerForKeyValue.h"

@implementation IESLiveResouceBundle (KeyValue)

- (id (^)(NSString *key))value {
    return ^(NSString *key){
        return [self objectForKey:key type:@"keyvalue"];
    };
}

- (BOOL (^)(NSString *key))is {
    return ^(NSString *key) {
        return [self.value(key) boolValue];
    };
}

- (id (^)(NSString *key))config {
    return ^(NSString *key){
        return [self objectForKey:key type:@"config"];
    };
}

@end
