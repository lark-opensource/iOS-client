//
//  QueryFilterEngine.h
//  TTNetworkManager
//
//  Created by dongyangfan on 2021/6/18.
//

#ifndef QueryFilterEngine_h
#define QueryFilterEngine_h

#import <Foundation/Foundation.h>
#import "QueryFilterAction.h"
#import "TTHttpRequestChromium.h"

@interface QueryFilterEngine : NSObject

+ (instancetype)shareInstance;

- (void)setLocalCommonParamsConfig:(NSString *)localConfig;

- (NSString *)filterQuery:(TTHttpRequestChromium *)originalRequest;

- (void)parseTNCQueryFilterConfig:(NSDictionary *)data;

@end


#endif /* QueryFilterEngine_h */
