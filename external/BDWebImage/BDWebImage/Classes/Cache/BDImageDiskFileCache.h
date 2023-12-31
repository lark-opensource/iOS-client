//
//  BDImageDiskFileCache.h
//  BDWebImage
//
//  Created by 陈奕 on 2019/9/27.
//

#import <Foundation/Foundation.h>
#import "BDDiskCache.h"

NS_ASSUME_NONNULL_BEGIN

@interface BDImageDiskFileCache : NSObject<BDDiskCache>

@property (nonatomic, strong, readonly, nonnull) BDImageCacheConfig *config;

@property (nonatomic, copy)BDImageDiskTrimBlock trimBlock;

- (nonnull instancetype)init NS_UNAVAILABLE;

@end

NS_ASSUME_NONNULL_END
