//
//  QueryFilterResult.h
//  TTNetworkManager
//
//  Created by dongyangfan on 2022/3/24.
//

#ifndef QueryFilterResult_h
#define QueryFilterResult_h

#import <Foundation/Foundation.h>
#import "TTNetworkUtil.h"

//convert from original query string
@interface QueryFilterObject : NSObject
//use NSArray to ensure query order
@property (nonatomic, copy) NSArray<QueryPairObject *> *queryPairArray;
//use NSDictionary to quickly locate a key
@property (nonatomic, copy) NSDictionary<NSString *, NSArray *> *keyAndIndexDict;

- (instancetype)initWithQueryPairArray:(NSArray<QueryPairObject *> *)queryPairArray
                       keyAndIndexDict:(NSDictionary<NSString *, NSArray *> *)keyAndIndexDict;

@end


//indicate remove and encrypt info
@interface QueryFilterResult : NSObject

@property (nonatomic, strong) NSMutableIndexSet *removingIndexSet;

@property (nonatomic, strong) NSMutableIndexSet *queryEncryptIndexSet;

@property (nonatomic, assign) BOOL bodyEncryptEnabled;

@end

#endif /* QueryFilterResult_h */
