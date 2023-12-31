//
//  TTDnsResult.m
//  TTNetworkManager
//
//  Created by xiejin.rudy on 2020/8/7.
//

#import "TTDnsResult.h"
#import <Foundation/Foundation.h>

@implementation TTDnsResult

@synthesize ret = _ret;
@synthesize source = _source;
@synthesize cacheSource = _cacheSource;
@synthesize iplist = _iplist;
@synthesize detailedInfo = _detailedInfo;

- (id)initWithRet:(int)ret source:(int)source cacheSource:(int)cacheSource ipList:(NSArray<NSString*>*)ipList detailedInfo:(NSString*)detailedInfo{
    self = [super init];
    if (self) {
        _ret = ret;
        _source = source;
        _cacheSource = cacheSource;
        _iplist = ipList;
        _detailedInfo = detailedInfo;
    }

    return self;
}

@end
