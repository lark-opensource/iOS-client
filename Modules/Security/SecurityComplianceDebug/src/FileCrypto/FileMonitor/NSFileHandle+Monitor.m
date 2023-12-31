//
//  NSFileHandle+Monitor.m
//  SecurityComplianceDebug
//
//  Created by qingchun on 2023/11/20.
//

#import "NSFileHandle+Monitor.h"
#import "SecurityComplianceDebug-Swift.h"

#import <ByteDanceKit/NSObject+BTDAdditions.h>
@import LarkSecurityCompliance;

@implementation NSFileHandle (Monitor)

+ (void)setupMonitor
{
    Class NSConcreteFileHandleClass = NSClassFromString(@"NSConcreteFileHandle");
    [NSConcreteFileHandleClass btd_swizzleInstanceMethod:@selector(readDataUpToLength:error:) with:@selector(fc_readDataUpToLength:error:)];
    [NSConcreteFileHandleClass btd_swizzleInstanceMethod:@selector(readDataToEndOfFileAndReturnError:) with:@selector(fc_readDataToEndOfFileAndReturnError:)];
}

- (NSData *)fc_readDataUpToLength:(NSUInteger)length error:(out NSError *__autoreleasing  _Nullable *)error
{
    NSData *data = [self fc_readDataUpToLength:length error:error];
    [self monitorWithData:data];
    return data;
}

- (NSData *)fc_readDataToEndOfFileAndReturnError:(out NSError *__autoreleasing  _Nullable *)error
{
    NSData *data = [self fc_readDataToEndOfFileAndReturnError:error];
    [self monitorWithData:data];
    return data;
}

- (void)monitorWithData:(NSData *)data
{
    if ([self isSecureAccess]) {
        return ;
    }
    char path[MAXPATHLEN];
    if (fcntl([self fileDescriptor], F_GETPATH, path) != -1) {
        NSString *filePath = [NSString stringWithUTF8String:path];
        [FCFileMonitor eventFileHandleIfNeededWithData:data path:filePath];
    }
}

@end
