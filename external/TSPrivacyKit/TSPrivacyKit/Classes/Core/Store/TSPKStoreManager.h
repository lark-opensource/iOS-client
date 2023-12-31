//
//  TSPKStoreManager.h
//  TSPrivacyKit
//
//  Created by PengYan on 2021/3/22.
//

#import <Foundation/Foundation.h>

#import "TSPKStore.h"
#import "TSPKEventData.h"



@interface TSPKStoreManager : NSObject

+ (instancetype _Nonnull)sharedManager;

- (void)initStoreOfStoreId:(NSString *_Nonnull)storeId storeType:(TSPKStoreType)storeType;

- (void)storeEventData:(TSPKEventData *_Nonnull)eventData;

- (id<TSPKStore>_Nonnull)getStoreOfStoreId:(NSString *_Nonnull)storeId;

@end


