//
//  IESPrefetchManager+Gecko.m
//  BDWebKit
//
//  Created by Hao Wang on 2020/3/16.
//

#import "IESPrefetchManager+Gecko.h"
#import <IESGeckoKit/IESGeckoKit.h>

@implementation IESPrefetchManager (Gecko)

- (void)bindGeckoAccessKey:(NSString *)accessKey channels:(NSArray<NSString *> *)channels forBusiness:(NSString *)business {
    id<IESPrefetchLoaderProtocol> loader = [self loaderForBusiness:business];
    NSCAssert(loader != nil, @"Please first register capability use `registerCapability:forBusiness:`");
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        NSMutableArray<NSString *> *configs = [NSMutableArray arrayWithCapacity:channels.count];
        [channels enumerateObjectsUsingBlock:^(NSString * _Nonnull channel, NSUInteger idx, BOOL * _Nonnull stop) {
            NSString *jsonName = [NSString stringWithFormat:@"%@.prefetch.json", channel];
            NSData *data = [IESGeckoKit dataForPath:jsonName accessKey:accessKey channel:channel];
            if (!data) {
                data = [IESGeckoKit dataForPath:@"prefetch.json" accessKey:accessKey channel:channel];;
            }
            
            NSString *json = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
            if (json.length > 0) {
                [configs addObject:json];
            }
        }];
        [loader loadAllConfigurations:configs];     
    });
}

@end
