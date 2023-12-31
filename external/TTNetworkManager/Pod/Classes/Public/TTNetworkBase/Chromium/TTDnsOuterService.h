//
//  TTDnsOuterService.h
//  TTNetworkManager
//
//  Created by xiejin.rudy on 2020/8/9.
//

#import <Foundation/Foundation.h>
#import "TTNetworkDefine.h"
#import "TTDnsResult.h"
#import "TTDnsQuery.h"


@interface TTDnsOuterService : NSObject

@property(nonatomic, strong) NSMutableDictionary<NSString *, TTDnsQuery *> *dnsQueryMap;

- (TTDnsResult*)ttDnsResolveWithHost:(NSString*)host
                               sdkId:(int)sdkId;

- (void)handleTTDnsResultWithUUID:(NSString*)uuid
                             host:(NSString*)host
                              ret:(int)ret
                           source:(int)source
                      cacheSource:(int)cacheSource
                           ipList:(NSArray<NSString*>*)ipList
                     detailedInfo:(NSString*)detailedInfo;
@end
