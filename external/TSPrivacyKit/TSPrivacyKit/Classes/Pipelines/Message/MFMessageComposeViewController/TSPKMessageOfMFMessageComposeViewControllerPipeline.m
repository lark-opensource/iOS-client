//
//  TSPKMessageOfMFMessageComposeViewControllerPipeline.m
//  Baymax_MusicallyTests
//
//  Created by admin on 2022/6/14.
//

#import "TSPKMessageOfMFMessageComposeViewControllerPipeline.h"
#import <MessageUI/MFMessageComposeViewController.h>
#import "NSObject+TSAddition.h"
#import "TSPKPipelineSwizzleUtil.h"

@implementation MFMessageComposeViewController (TSPrivacyKitMessage)

+ (void)tspk_message_preload
{
    [TSPKPipelineSwizzleUtil swizzleMethodWithPipelineClass:[TSPKMessageOfMFMessageComposeViewControllerPipeline class] clazz:self];
}

- (instancetype)tspk_message_init
{
    TSPKHandleResult *result = [TSPKMessageOfMFMessageComposeViewControllerPipeline handleAPIAccess:NSStringFromSelector(@selector(init)) className:[TSPKMessageOfMFMessageComposeViewControllerPipeline stubbedClass]];
    if (result.action == TSPKResultActionFuse) {
        return nil;
    } else {
        return [self tspk_message_init];
    }
}

@end


@implementation TSPKMessageOfMFMessageComposeViewControllerPipeline

+ (NSString *)pipelineType
{
    return TSPKPipelineMessageOfMFMessageComposeViewController;
}

+ (NSString *)dataType {
    return TSPKDataTypeMessage;
}

+ (NSString *)stubbedClass
{
    return @"MFMessageComposeViewController";
}

+ (NSArray<NSString *> *)stubbedClassAPIs
{
    return nil;
}

+ (NSArray<NSString *> *)stubbedInstanceAPIs
{
    return @[
        NSStringFromSelector(@selector(init))
    ];
}

+ (void)preload
{
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        [MFMessageComposeViewController tspk_message_preload];
    });
}

@end
