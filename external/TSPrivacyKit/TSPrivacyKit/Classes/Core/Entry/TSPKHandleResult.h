//
//  TSPKHandleResult.h
//  Indexer
//
//  Created by admin on 2021/12/21.
//

#import <Foundation/Foundation.h>
#import "TSPKEventData.h"

typedef NS_ENUM(NSInteger, TSPKResultAction) {
    TSPKResultActionFuse = 1,
    TSPKResultActionCache
};

extern NSString *_Nonnull const TSPKReturnValue;

@interface TSPKHandleResult : NSObject

@property (nonatomic) TSPKResultAction action;
@property (nonatomic, strong, nonnull) NSString *returnValue;
@property (nonatomic, assign) BOOL cacheNeedUpdate;

- (nullable id)getObjectWithReturnType:(NSString *_Nonnull)returnType defaultValue:(id _Nullable)defaultValue;

@end
