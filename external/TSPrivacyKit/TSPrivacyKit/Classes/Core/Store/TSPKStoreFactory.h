//
//  TSPKStoreFactory.h
//  TSPrivacyKit
//
//  Created by PengYan on 2021/3/26.
//

#import <Foundation/Foundation.h>

#import "TSPKStore.h"
#import "TSPrivacyKitConstants.h"



@interface TSPKStoreFactory : NSObject

+ (id<TSPKStore> _Nullable)storeWithType:(TSPKStoreType)storeType;

@end


