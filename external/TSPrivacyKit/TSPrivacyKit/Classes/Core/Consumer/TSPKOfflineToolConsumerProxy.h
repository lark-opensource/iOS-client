//
//  TSPKFakeConsumer.h
//  MT-Test
//
//  Created by admin on 2021/12/7.
//

#import <Foundation/Foundation.h>
#import "TSPKConsumer.h"

@interface TSPKOfflineToolConsumerProxy : NSObject<TSPKConsumer>

+ (instancetype _Nullable)sharedConsumer;

@end
