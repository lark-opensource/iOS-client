//
//  NSData+DataDecorator.m
//  BDDataDecorator
//
//  Created by bob on 2019/11/7.
//

#import "NSData+DataDecoratorTob.h"
#import "app_log_private.h"
#import <OneKit/NSData+OKDecorator.h>


@implementation NSData (DataDecoratorTob)

/// 这里为了不使用encrypt和AES等敏感词，用Random替代
- (NSData *)bd_dataByPrivateDecorated {
    return [self rsk_dataByDecorated];
}

@end
