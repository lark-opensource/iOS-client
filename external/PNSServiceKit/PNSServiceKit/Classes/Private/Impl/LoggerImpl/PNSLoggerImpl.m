//
//  PNSLoggerImpl.m
//  PNSServiceKit
//
//  Created by chirenhua on 2022/6/20.
//

#import "PNSLoggerImpl.h"
#import "PNSServiceCenter+private.h"
#import <BDAlogProtocol/BDAlogProtocol.h>

PNS_BIND_DEFAULT_SERVICE(PNSLoggerImpl, PNSLoggerProtocol)

@implementation PNSLoggerImpl

+ (void)setLogWithFileName:(NSString *)fileName
                  funcName:(NSString *)funcName
                       tag:(NSString *)tag
                      line:(int)line
                     level:(PNSLogLevel)level
                    format:(NSString *)format {
    [BDALogProtocol setALogWithFileName:fileName
                               funcName:funcName
                                    tag:tag
                                   line:line
                                  level:(int)level
                                 format:format];
}

@end
