//
//  TSPKSignalManager+log.m
//  Musically
//
//  Created by ByteDance on 2022/12/20.
//

#import "TSPKSignalManager+log.h"
#import "TSPKSignalManager+private.h"
#import <ByteDanceKit/ByteDanceKit.h>

@implementation TSPKSignalManager (log)

+ (void)addLogWithTag:(nullable NSString *)tag content:(nullable NSString *)content {
    if (tag.length == 0 || content.length == 0) {
        return;
    }
    
    NSDictionary *logConfig = [TSPKSignalManager sharedManager].logConfig;
    if (logConfig == nil) {
        return;
    }
    
    NSArray *logArray = [logConfig btd_arrayValueForKey:tag];
    if (logArray.count == 0) {
        return;
    }
    
    [logArray enumerateObjectsUsingBlock:^(NSDictionary * _Nonnull log, NSUInteger idx, BOOL * _Nonnull stop) {
        NSString *matchedContent = [log btd_stringValueForKey:@"content"];
        // partial match
        if (matchedContent.length > 0 && [content containsString:matchedContent]) {
            NSArray *dataTypes = [log btd_arrayValueForKey:@"dataTypes"];
            NSString *actualContent = [NSString stringWithFormat:@"[%@]%@", tag, content];
            [dataTypes enumerateObjectsUsingBlock:^(NSString * _Nonnull dataType, NSUInteger idx, BOOL * _Nonnull innerStop) {
                [TSPKSignalManager addSignalWithType:TSPKSignalTypeLog permissionType:dataType content:actualContent];
            }];
            *stop = YES;
        }
    }];
}

@end
