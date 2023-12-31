//
//  TSPKPerfConusmerProxy.m
//  BDRuleEngine-Pods-Baymax_MusicallyTests-Unit-_Tests
//
//  Created by admin on 2022/6/23.
//

#import "TSPKStatisticConsumerProxy.h"
#import "TSPKStatisticEvent.h"

@implementation TSPKStatisticConsumerProxy

+ (instancetype)sharedConsumer
{
    static TSPKStatisticConsumerProxy *consumer;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        Class targetClass = NSClassFromString(@"TSPKStatisticConsumer");
        if(targetClass){
            consumer = [[targetClass alloc] init];
        }
    });
    return consumer;
}

- (NSString *)tag {
    return TSPKEventTagStatistic;
}

- (void)consume:(TSPKBaseEvent *)event {}

@end
