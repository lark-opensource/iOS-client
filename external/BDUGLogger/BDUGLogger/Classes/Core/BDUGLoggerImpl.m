//
//  BDUGLoggerImpl.m
//  Pods
//
//  Created by shuncheng on 2019/6/18.
//

#import "BDUGLoggerImpl.h"
#import <BDAlogProtocol/BDAlogProtocol.h>

@implementation BDUGLoggerImpl

+ (void)load
{
    BDUG_BIND_CLASS_PROTOCOL(self, BDUGLoggerInterface);
}

+ (instancetype)sharedInstance
{
    static dispatch_once_t onceToken;
    static BDUGLoggerImpl *ins;
    dispatch_once(&onceToken, ^{
        ins = [[BDUGLoggerImpl alloc] init];
    });
    return ins;
}

- (void)logMessage:(NSString *)message withLevType:(BDUGLoggerLevType)lev
{
    NSString *tag = @"UserGrowth";
    if (lev == BDUGLoggerDebugType) {
        BDALOG_PROTOCOL_DEBUG_TAG(tag, @"%@", message)
    } else if (lev == BDUGLoggerInfoType) {
        BDALOG_PROTOCOL_INFO_TAG(tag, @"%@", message)
    } else if (lev == BDUGLoggerWarnType) {
        BDALOG_PROTOCOL_WARN_TAG(tag, @"%@", message)
    } else if (lev == BDUGLoggerErrorType) {
        BDALOG_PROTOCOL_ERROR_TAG(tag, @"%@", message)
    } else if (lev == BDUGLoggerFatalType) {
        BDALOG_PROTOCOL_FATAL_TAG(tag, @"%@", message)
    } else {
        NSLog(@"%@", message);
    }
}

@end
