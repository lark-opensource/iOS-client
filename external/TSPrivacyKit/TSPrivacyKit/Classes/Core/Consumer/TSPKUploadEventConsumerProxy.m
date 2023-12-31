//
//  TSPKUploadEventConsumerProxy.m
//  BDRuleEngine-Pods-Baymax_MusicallyTests-Unit-_Tests
//
//  Created by admin on 2022/6/23.
//

#import "TSPKUploadEventConsumerProxy.h"
#import "TSPKUploadEvent.h"

@implementation TSPKUploadEventConsumerProxy

+ (instancetype)sharedConsumer
{
    static TSPKUploadEventConsumerProxy *consumer;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        Class targetClass = NSClassFromString(@"TSPKUploadEventConsumer");
        if(targetClass){
            consumer = [[targetClass alloc] init];
        }
    });
    return consumer;
}

- (NSString *)tag {
    return TSPKEventTagBadcase;
}

- (void)consume:(TSPKBaseEvent *)event {}

@end
