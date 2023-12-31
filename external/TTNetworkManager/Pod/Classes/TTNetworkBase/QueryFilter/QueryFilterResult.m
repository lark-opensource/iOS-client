//
//  QueryFilterResult.m
//  TTNetworkManager
//
//  Created by dongyangfan on 2022/3/24.
//

#import "QueryFilterResult.h"

@implementation QueryFilterObject

- (instancetype)initWithQueryPairArray:(NSArray<QueryPairObject *> *)queryPairArray
                       keyAndIndexDict:(NSDictionary <NSString *, NSArray *> *)keyAndIndexDict {
    if (self = [super init]) {
        self.queryPairArray = queryPairArray;
        self.keyAndIndexDict = keyAndIndexDict;
    }
    
    return self;
}
@end



@implementation QueryFilterResult


@end
