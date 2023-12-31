//
//  BDUGAlbumImageCacheManager.h
//  AFgzipRequestSerializer
//
//  Created by 杨阳 on 2019/7/17.
//

typedef NS_ENUM(NSInteger, BDUGAlbumImageCacheStatus) {
    BDUGAlbumImageCacheStatusHitValid,
    BDUGAlbumImageCacheStatusHitExit,
    BDUGAlbumImageCacheStatusMiss,
};

#import <Foundation/Foundation.h>

@interface BDUGAlbumImageCacheManager : NSObject

@property (nonatomic, assign) NSInteger cacheLength;

- (BDUGAlbumImageCacheStatus)cacheStatusWithLocalIdentifier:(NSString *)localIdentifier;

- (void)addCacheWithLocalIdentifier:(NSString *)localIdentifier infoValid:(BOOL)infoValid;

- (void)cleanCache;

@end

