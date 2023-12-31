//
//  NSData+Monitor.m
//  SecurityComplianceDebug
//
//  Created by qingchun on 2023/11/17.
//

#import "NSData+Monitor.h"
#import <ByteDanceKit/NSObject+BTDAdditions.h>
#import "SecurityComplianceDebug-Swift.h"

@implementation NSData (Monitor)

+ (void)setupMonitor
{
    [self btd_swizzleInstanceMethod:@selector(initWithContentsOfURL:) with:@selector(fc_initWithContentsOfURL:)];
    [self btd_swizzleInstanceMethod:@selector(initWithContentsOfURL:options:error:) with:@selector(fc_initWithContentsOfURL:options:error:)];
    [self btd_swizzleInstanceMethod:@selector(dataWithContentsOfURL:) with:@selector(fc_dataWithContentsOfURL:)];
    [self btd_swizzleInstanceMethod:@selector(dataWithContentsOfURL:options:error:) with:@selector(fc_dataWithContentsOfURL:options:error:)];
    
    [self btd_swizzleInstanceMethod:@selector(initWithContentsOfFile:options:error:) with:@selector(fc_initWithContentsOfFile:options:error:)];
    [self btd_swizzleInstanceMethod:@selector(dataWithContentsOfFile:options:error:) with:@selector(fc_dataWithContentsOfFile:options:error:)];
    [self btd_swizzleInstanceMethod:@selector(initWithContentsOfFile:) with:@selector(fc_initWithContentsOfFile:)];
    [self btd_swizzleInstanceMethod:@selector(dataWithContentsOfFile:) with:@selector(fc_dataWithContentsOfFile:)];
    
}

#pragma mark url read

- (instancetype)fc_initWithContentsOfURL:(NSURL *)url options:(NSDataReadingOptions)readOptionsMask error:(NSError *__autoreleasing  _Nullable *)errorPtr
{
    NSData *data = [self fc_initWithContentsOfURL:url options:readOptionsMask error:errorPtr];
    [FCFileMonitor eventIfNeededWithData:data path:url.path];
    return data;
}

- (instancetype)fc_initWithContentsOfURL:(NSURL *)url
{
    NSData *data = [self fc_initWithContentsOfURL:url];
    [FCFileMonitor eventIfNeededWithData:data path:url.path];
    return data;
}

+ (instancetype)fc_dataWithContentsOfURL:(NSURL *)url
{
    NSData *data = [self fc_dataWithContentsOfURL:url];
    [FCFileMonitor eventIfNeededWithData:data path:url.path];
    return data;
}

+ (instancetype)fc_dataWithContentsOfURL:(NSURL *)url options:(NSDataReadingOptions)readOptionsMask error:(NSError *__autoreleasing  _Nullable *)errorPtr
{
    NSData *data = [self fc_dataWithContentsOfURL:url options:readOptionsMask error:errorPtr];
    [FCFileMonitor eventIfNeededWithData:data path:url.path];
    return data;
}

#pragma mark file read

- (instancetype)fc_initWithContentsOfFile:(NSString *)path options:(NSDataReadingOptions)readOptionsMask error:(NSError *__autoreleasing  _Nullable *)errorPtr
{
    NSData *data = [self fc_initWithContentsOfFile:path options:readOptionsMask error:errorPtr];
    [FCFileMonitor eventIfNeededWithData:data path:path];
    return data;
}

- (instancetype)fc_initWithContentsOfFile:(NSString *)path
{
    NSData *data = [self fc_initWithContentsOfFile:path];
    [FCFileMonitor eventIfNeededWithData:data path:path];
    return data;
}

+ (instancetype)fc_dataWithContentsOfFile:(NSString *)path options:(NSDataReadingOptions)readOptionsMask error:(NSError *__autoreleasing  _Nullable *)errorPtr
{
    NSData *data = [self fc_dataWithContentsOfFile:path options:readOptionsMask error:errorPtr];
    [FCFileMonitor eventIfNeededWithData:data path:path];
    return data;
}

+ (instancetype)fc_dataWithContentsOfFile:(NSString *)path
{
    NSData *data = [self fc_dataWithContentsOfFile:path];
    [FCFileMonitor eventIfNeededWithData:data path:path];
    return data;
}

@end
