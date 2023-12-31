//
//  NSString+IESFalconConvenience.m
//  Pods
//
//  Created by 陈煜钏 on 2019/9/20.
//

#import "NSString+IESFalconConvenience.h"
#import "BDWebKitUtil.h"

#import <MobileCoreServices/MobileCoreServices.h>

@implementation NSString (IESFalconConvenience)

- (nullable NSString *)ies_removeFragment
{
    return [self componentsSeparatedByString:@"#"].firstObject;
}

- (nullable NSString *)ies_removeQuery
{
    NSError *error;
    NSRegularExpression *regex = [[NSRegularExpression alloc] initWithPattern:@"\\\?.*?$" options:0 error:&error];
    NSRange matchedRange = [regex rangeOfFirstMatchInString:self options:0 range:NSMakeRange(0, self.length)];
    
    NSString *removedQueryPath;
    if (matchedRange.location != NSNotFound) {
        removedQueryPath = [self substringToIndex:matchedRange.location];
    }
    return removedQueryPath;
}

- (BOOL)ies_comboAllowExtention
{
    return [@[@"js", @"css"] containsObject:self.pathExtension.lowercaseString];
}

- (NSArray <NSString *> *)ies_comboPaths
{
    NSRange comboSeparateRange = [self rangeOfString:@"??"];
    if (comboSeparateRange.location == NSNotFound) {
        return @[self];
    }
    
    NSString *basePath = comboSeparateRange.location == 0 ? @"" : [self substringWithRange:NSMakeRange(0, comboSeparateRange.location - 1)];
    
    NSUInteger searchStringLocation = comboSeparateRange.location + comboSeparateRange.length;
    NSString *searchString = [self substringWithRange:NSMakeRange(searchStringLocation, self.length - searchStringLocation)];
    
    NSArray<NSString *> *subPaths = [searchString componentsSeparatedByString:@","];
    
    __block NSMutableArray *comboPaths = [NSMutableArray array];
    [subPaths enumerateObjectsUsingBlock:^(NSString * _Nonnull subPath, NSUInteger idx, BOOL * _Nonnull stop) {
        if ([NSURL URLWithString:subPath].path.length == 0) {
            return ;
        }
        
        subPath = [basePath stringByAppendingPathComponent:subPath];
        subPath = [subPath stringByTrimmingCharactersInSet:[NSCharacterSet characterSetWithCharactersInString:@"/"]];
        [comboPaths addObject:subPath];
    }];
    
    return comboPaths;
}

- (NSString *)ies_stringByTrimmingQueryString
{
    NSRange range = [self rangeOfString:@"?"];
    if (range.location != NSNotFound) {
        return [self substringToIndex:range.location];
    }

    return [self copy];
}

- (NSString *)ies_prefixMatchedByRegex:(NSString *)pattern
{
    return [BDWebKitUtil prefixMatchesInString:self withPattern:pattern];
}

@end
