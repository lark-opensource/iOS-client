//
//  BDPNetworkManager.h
//  Timor
//
//  Created by liubo on 2018/11/19.
//

#import <Foundation/Foundation.h>
#import "BDPNetworkOperation.h"

@interface BDPNetworkManager : NSObject

+ (instancetype)defaultManager;

- (void)startOperation:(BDPNetworkOperation *)operation;

- (void)cancelAllOperations;

@end
