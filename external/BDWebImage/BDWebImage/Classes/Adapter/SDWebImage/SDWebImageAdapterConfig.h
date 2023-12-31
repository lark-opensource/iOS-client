//
//  SDWebImageAdapterConfig.h
//  BDWebImage
//
//  Created by lizhuoli on 2017/12/11.
//

#import <Foundation/Foundation.h>
#import <SDWebImage/SDWebImageManager.h>

@interface SDWebImageAdapterConfig : NSObject <NSCopying>

@property (nonatomic, copy, nullable) SDWebImageCacheKeyFilterBlock cacheKeyFilter;
@property (nonatomic, assign) SDWebImageDownloaderExecutionOrder executionOrder;
@property (nonatomic, copy, nonnull) NSString * cacheNameSpace;

@end
