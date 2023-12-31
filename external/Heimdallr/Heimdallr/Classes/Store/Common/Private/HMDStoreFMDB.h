//
//  HMDStoreFMDB.h
//  Heimdallr
//
//  Created by joy on 2018/6/12.
//

#import <Foundation/Foundation.h>
#import "HMDStoreIMP.h"

@interface HMDStoreFMDB : NSObject <HMDStoreIMP>
- (instancetype _Nonnull)initWithPath:(NSString *_Nonnull)path;
@end
