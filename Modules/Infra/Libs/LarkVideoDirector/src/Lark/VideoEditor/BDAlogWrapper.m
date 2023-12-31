//
//  BDAlogWrapper.m
//  LarkVideoDirector
//
//  Created by 李晨 on 2022/11/21.
//

#import "BDAlogWrapper.h"
#import <BDALogProtocol/BDAlogProtocol.h>

@implementation BDAlogWrapper

+ (void)error:(NSString*)message {
    BDALOG_PROTOCOL_ERROR(@"%@", message)
}

+ (void)warn:(NSString*)message {
    BDALOG_PROTOCOL_WARN(@"%@", message)
}

+ (void)info:(NSString*)message {
    BDALOG_PROTOCOL_INFO(@"%@", message)
}

+ (void)debug:(NSString*)message {
    BDALOG_PROTOCOL_DEBUG(@"%@", message)
}

@end
