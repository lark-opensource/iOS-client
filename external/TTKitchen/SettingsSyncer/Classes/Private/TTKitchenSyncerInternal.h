//
//  TTKitchenSyncer+TTKitchenSyncerInternal.h
//  TTKitchen
//
//  Created by bytedance on 2020/10/28.

#import "TTKitchenSyncer.h"

static NSString * const kTTKitchenSynchronizeDate = @"kTTKitchenSynchronizeDate";

NS_ASSUME_NONNULL_BEGIN

@interface TTKitchenSyncer ()

@property (nonatomic, assign) NSUInteger retryCount;
@property (nonatomic, assign) BOOL synchronizing;
@property (nonatomic, copy) NSString *defaultURLPath;
@property (nonatomic, copy) NSDictionary *cachedHeader;

- (void)synchronizeSettings;

@end

NS_ASSUME_NONNULL_END
