//
//  TTDownloadLogLite.m
//  BDALog
//
//  Created by diweiguang on 2021/6/22.
//

#import <Foundation/Foundation.h>
#import "TTDownloadLogLite.h"

NS_ASSUME_NONNULL_BEGIN

@interface TTDownloadLogLite()

@property(atomic, strong, readwrite)NSMutableArray<NSString *> *errorLogArray;

@end

@implementation TTDownloadLogLite

- (instancetype)init
{
    self = [super init];
    if (self) {
        _errorLogArray = [[NSMutableArray alloc] init];
    }
    return self;
}

- (void)addDownloadLog:(NSString *)log error:(NSError *)error {
    if (!log && !error) {
        return;
    }
    @synchronized (_errorLogArray) {
        if (log) {
            [_errorLogArray addObject:log];
        }
        if (error) {
            [_errorLogArray addObject:[NSString stringWithFormat:@"%ld,%@,%@", (long)error.code, error.domain, error.description]];
        }
    }
}

@end

NS_ASSUME_NONNULL_END
