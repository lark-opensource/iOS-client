//
//  TSPKRelationObjectCacheStore.h
//  TSPrivacyKit
//
//  Created by PengYan on 2021/3/26.
//

#import <Foundation/Foundation.h>

#import "TSPKStore.h"



// used for release check
@interface TSPKRelationObjectCacheStore : NSObject<TSPKStore>

- (NSTimeInterval)getCleanTime;

- (void)updateReportTime:(NSTimeInterval)reportTime;

@end


