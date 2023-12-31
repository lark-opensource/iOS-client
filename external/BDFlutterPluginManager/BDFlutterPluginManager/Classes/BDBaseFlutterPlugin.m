//
//  BDBaseFlutterPlugin.m
//  BDBaseFlutterPlugin
//
//  Created by 林一一 on 2019/9/16.
//

#import "BDBaseFlutterPlugin.h"

@implementation BDBaseFlutterPlugin

- (NSMutableDictionary *)createStandardSuccessResWithInfos:(NSDictionary *)infos {
    NSMutableDictionary *res = [NSMutableDictionary dictionary];
    res[@"code"] = @(0);
    res[@"errMsg"] = nil;
    if (infos) {
        [res addEntriesFromDictionary:infos];
    }
    return res;
}

- (NSMutableDictionary *)createStandardFailResWithError:(NSError *)error {
    NSMutableDictionary *res = [NSMutableDictionary dictionary];
    res[@"code"] = error ? @(error.code) : @(-1);
    res[@"errMsg"] = error ? error.localizedDescription : @"unknown";
    return res;
}

@end
