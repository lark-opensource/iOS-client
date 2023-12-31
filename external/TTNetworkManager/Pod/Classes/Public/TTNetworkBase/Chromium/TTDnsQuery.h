//
//  TTDnsOuterService.h
//  TTNetworkManager
//
//  Created by xiejin.rudy on 2020/8/7.
//

#import <Foundation/Foundation.h>
#import "TTNetworkDefine.h"
#import "TTDnsResult.h"


@interface TTDnsQuery : NSObject

@property(nonatomic, copy) NSString *host;

@property(nonatomic, assign) int sdkId;

@property(nonatomic, copy) NSString *uuid;

@property(nonatomic, strong) TTDnsResult *result;

@property(nonatomic, strong) dispatch_semaphore_t semaphore;

- (id)initWithHost:(NSString*)host sdkId:(int)sdkId;

- (void)await;

- (void)resume;

- (void)doQuery;

@end

