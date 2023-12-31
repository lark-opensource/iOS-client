//
//  BDALogAssertionHandler.m
//  BDAlogProtocol
//
//  Created by 李琢鹏 on 2019/3/11.
//

#import "BDALogAssertionPlugin.h"
#import <BDAlogProtocol/BDAlogProtocol.h>

@implementation BDALogAssertionPlugin

+ (void)load {
    [BDAssertionPluginManager addPlugin:self];
}

+ (void)handleFailureWithDesc:(NSString *)desc {
    BDALOG_PROTOCOL_ERROR(@"*** Assertion failure due to \"%@\"", desc);
}

@end
