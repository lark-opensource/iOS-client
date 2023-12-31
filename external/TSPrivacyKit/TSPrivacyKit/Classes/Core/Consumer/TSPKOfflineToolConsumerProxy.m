//
//  TSPKFakeConsumer.m
//  MT-Test
//
//  Created by admin on 2021/12/7.
//

#import "TSPKOfflineToolConsumerProxy.h"
#import "TSPKEventManager.h"
#import "TSPKUploadEvent.h"

@implementation TSPKOfflineToolConsumerProxy

// offline tool need extend this consumer
+ (instancetype)sharedConsumer
{
    static TSPKOfflineToolConsumerProxy *consumer;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        Class targetClass = NSClassFromString(@"TSPKOfflineToolConsumer");
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
