//
//  IESGurdSyncResourcesGroup.h
//  IESGeckoKit
//
//  Created by 陈煜钏 on 2020/12/20.
//

#import <Foundation/Foundation.h>

#import "IESGeckoDefines.h"

NS_ASSUME_NONNULL_BEGIN

@interface IESGurdSyncResourcesGroup : NSObject

+ (instancetype)groupWithCompletion:(IESGurdSyncStatusDictionaryBlock)completion;

- (void)enter;

- (void)leaveWithChannel:(NSString *)channel
            isSuccessful:(BOOL)isSuccessful
                  status:(IESGurdSyncStatus)status;

- (void)notifyWithBlock:(dispatch_block_t _Nullable)block;

@end

NS_ASSUME_NONNULL_END
