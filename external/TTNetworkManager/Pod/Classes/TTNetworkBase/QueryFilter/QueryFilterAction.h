//
//  QueryFilterAction.h
//  TTNetworkManager
//
//  Created by dongyangfan on 2021/6/18.
//

#ifndef QueryFilterAction_h
#define QueryFilterAction_h

#import <Foundation/Foundation.h>
#import "QueryFilterResult.h"

@interface QueryFilterAction : NSObject

#pragma mark - methods

- (QueryFilterAction *)parseActionFromDict:(NSDictionary *)config;

- (void)takeAction:(QueryFilterObject **)originalQueryMap
     withUrlString:(NSString *)originalUrlString
       reqPriority:(NSInteger *)priority
             isHit:(BOOL *)isHit
 queryFilterResult:(QueryFilterResult **)filterResult;

- (NSInteger)getRequestPriority;

+ (QueryFilterObject *)convertQueryStringWithOrder:(NSString *)queryString;

@end

#endif /* QueryFilterAction_h */
