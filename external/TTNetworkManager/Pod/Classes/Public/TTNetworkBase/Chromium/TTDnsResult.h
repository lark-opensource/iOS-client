//
//  TTDnsResult.h
//  TTNetworkManager
//
//  Created by xiejin.rudy on 2020/8/7.
//

#import <Foundation/Foundation.h>
#import "TTNetworkDefine.h"


@interface TTDnsResult : NSObject

@property(nonatomic, assign) int ret;

@property(nonatomic, assign) int source;

@property(nonatomic, assign) int cacheSource;

@property(nonatomic, strong) NSArray<NSString*>* iplist;

@property(nonatomic, strong) NSString *detailedInfo;

- (id)initWithRet:(int)ret source:(int)source cacheSource:(int)cacheSource ipList:(NSArray<NSString*>*)ipList detailedInfo:(NSString*)detailedInfo;

@end
