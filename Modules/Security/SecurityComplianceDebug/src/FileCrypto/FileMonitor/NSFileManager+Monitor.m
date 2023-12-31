//
//  NSFileManager+Monitor.m
//  SecurityComplianceDebug
//
//  Created by qingchun on 2023/11/20.
//

#import "NSFileManager+Monitor.h"
#import <ByteDanceKit/NSObject+BTDAdditions.h>
#import "SecurityComplianceDebug-Swift.h"

@implementation NSFileManager (Monitor)

+ (void)setupMonitor
{
    [self btd_swizzleInstanceMethod:@selector(contentsAtPath:) with:@selector(fc_contentsAtPath:)];
}

- (NSData *)fc_contentsAtPath:(NSString *)path
{
    NSData *data = [self fc_contentsAtPath:path];
    [FCFileMonitor eventFileManagerIfNeededWithData:data path:path];
    return data;
}

@end
