//
//  BDXGurdSyncManager.h
//  BDXResourceLoader-Pods-Aweme
//
//  Created by bill on 2021/3/4.
//

#ifndef GurdSyncResourcesManager_h
#define GurdSyncResourcesManager_h

#import <Foundation/Foundation.h>
#import "BDXGurdSyncTask.h"

@interface BDXGurdSyncManager : NSObject

+ (void)enableGurd;

+ (void)disableGurd;

+ (void)enqueueSyncResourcesTask:(BDXGurdSyncTask *)task;

+ (void)syncResourcesIfNeeded;

+ (void)enableHighPrioritySync;

@end

#endif /* GurdSyncResourcesManager_h */
