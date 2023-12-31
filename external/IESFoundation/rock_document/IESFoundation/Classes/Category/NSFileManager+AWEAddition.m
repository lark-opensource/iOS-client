//
//  NSFileManager+AWEAddition.m
//  Aweme
//
//  Created by 旭旭 on 2018/1/29.
//  Copyright © 2018年 Bytedance. All rights reserved.
//

#import "NSFileManager+AWEAddition.h"

@implementation NSFileManager (AWEAddition)

- (NSArray<NSString *> *)awe_allDirsInPath:(NSString *)path
{
    NSMutableArray *retArray = [@[] mutableCopy];
    NSArray *resourceKeys = @[NSURLIsDirectoryKey];

    NSDirectoryEnumerator *fileEnumerator = [self enumeratorAtURL:[NSURL fileURLWithPath:path]
                                       includingPropertiesForKeys:resourceKeys
                                                          options:NSDirectoryEnumerationSkipsHiddenFiles|NSDirectoryEnumerationSkipsSubdirectoryDescendants
                                                     errorHandler:nil];
    for (NSURL *url in fileEnumerator) {
        NSDictionary *resourceValues = [url resourceValuesForKeys:resourceKeys error:NULL];
        if ([resourceValues[NSURLIsDirectoryKey] boolValue] &&
            ![url.path containsString:@"__MACOSX"]) {
            [retArray addObject:url.path];
        }
    }
    return retArray;
}

@end
