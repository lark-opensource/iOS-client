//
//  BDLynxContextPool.h
//  BDLynx-Pods-Aweme
//
//  Created by bill on 2020/5/19.
//

#import <Foundation/Foundation.h>
#import "BDLynxView.h"

NS_ASSUME_NONNULL_BEGIN

@interface BDLynxContextPool : NSObject

@property(nonatomic, strong, readonly) NSMutableDictionary *sharedPipers;

@property(nonatomic, strong) NSMutableArray *cardPool;
@property(nonatomic, strong) NSMutableArray *cardsInUse;

+ (instancetype)sharedInstance;

- (void)addLynxContext:(id)context schema:(NSString *)schema;
- (void)removeContext:(NSString *)schema;
- (BOOL)contextExistsWithSchema:(NSString *)schema;
- (nullable id)cardWithSchema:(NSString *)schema;

@end

NS_ASSUME_NONNULL_END
