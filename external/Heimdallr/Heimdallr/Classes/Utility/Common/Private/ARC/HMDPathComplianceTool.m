//
//  HMDPathComplianceTool.m
//  Heimdallr
//
//  Created by zhouyang11 on 2022/11/7.
//

#import "HMDPathComplianceTool.h"

@implementation HMDPathComplianceTool
///   - originalPath: "/tmp/GWPAsanTmp/123/4567.txt"
///   - compliancePaths: ["/tmp/GWPASanTmp","/tmp/test"]
///   - return "tmp/GWPAsanTmp/***/****.txt"
+ (NSString*)complianceReleativePath:(NSString*)originalPath compliancePaths:(NSArray<NSString *> *)compliancePaths {
    for (int i = 0; i < compliancePaths.count; i++) {
        NSString* prefixPath = compliancePaths[i];
        if (![originalPath hasPrefix:prefixPath]) {
            continue;
        }
        NSString *compliancePath = [originalPath substringFromIndex:prefixPath.length];
        NSString *content = compliancePath.stringByDeletingPathExtension;
        NSString *extension = compliancePath.pathExtension;
        NSRegularExpression *regularExpression = [NSRegularExpression regularExpressionWithPattern:@"[^/]" options:0 error:nil];
        content = [regularExpression stringByReplacingMatchesInString:content options:0 range:NSMakeRange(0, content.length) withTemplate:@"*"];
        NSString* res = extension.length == 0 ? content : [NSString stringWithFormat:@"%@.%@", content, extension];
        return [NSString stringWithFormat:@"%@%@", prefixPath, res];
    }
    return originalPath;
}

+ (NSString*)compareReleativePath:(NSString*)originalPath compliancePaths:(NSArray<NSString *> *)compliancePaths isMatch:(BOOL*)isCompleteMatch{
    for (int i = 0; i < compliancePaths.count; i++) {
        NSString* prefixPath = compliancePaths[i];
        if ([prefixPath hasPrefix:@"/"]) {
            prefixPath = [prefixPath substringFromIndex:1];
        }
        
        if (![originalPath isEqualToString:prefixPath]) {
            continue;
        }
        if (isCompleteMatch != NULL) {
            *isCompleteMatch = YES;
        }
        return prefixPath;
    }
    if (isCompleteMatch != NULL) {
        *isCompleteMatch = NO;
    }
    return originalPath;
}

+ (NSString*)compareAbsolutePath:(NSString*)originalPath compliancePaths:(NSArray<NSString *> *)compliancePaths isMatch:(BOOL*)isCompleteMatch{
    for (int i = 0; i < compliancePaths.count; i++) {
        NSString* prefixPath = compliancePaths[i];
        NSString *absoluteCompliancePath = [NSHomeDirectory() stringByAppendingPathComponent:prefixPath];
        if (![originalPath isEqualToString:absoluteCompliancePath]) {
            continue;
        }
        if (isCompleteMatch != NULL) {
            *isCompleteMatch = YES;
        }
        return absoluteCompliancePath;
    }
    if (isCompleteMatch != NULL) {
        *isCompleteMatch = NO;
    }
    return originalPath;
}

///   - originalPath: "tmp/GWPAsanTmp"
///   - compliancePaths: "tmp"
///   - return "tmp/**********"
+ (NSString*)complianceReleativePath:(NSString *)originalPath prefixPath:(NSString * )prefixPath {
    NSString *compliancePath = [originalPath substringFromIndex:prefixPath.length];
    NSString *content = compliancePath.stringByDeletingPathExtension;
    NSString *extension = compliancePath.pathExtension;
    NSRegularExpression *regularExpression = [NSRegularExpression regularExpressionWithPattern:@"[^/]" options:0 error:nil];
    content = [regularExpression stringByReplacingMatchesInString:content options:0 range:NSMakeRange(0, content.length) withTemplate:@"*"];
    NSString* res = extension.length == 0 ? content : [NSString stringWithFormat:@"%@.%@", content, extension];
    return [NSString stringWithFormat:@"%@%@", prefixPath, res];
}

@end
