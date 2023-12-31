//
//  TSPKUploadEventConsumerProxy.h
//  BDRuleEngine-Pods-Baymax_MusicallyTests-Unit-_Tests
//
//  Created by admin on 2022/6/23.
//

#import <Foundation/Foundation.h>
#import "TSPKConsumer.h"

@interface TSPKUploadEventConsumerProxy : NSObject<TSPKConsumer>

+ (instancetype _Nullable)sharedConsumer;

@end
