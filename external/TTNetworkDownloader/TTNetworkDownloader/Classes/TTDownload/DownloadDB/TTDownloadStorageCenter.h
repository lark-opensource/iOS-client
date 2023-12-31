#import <Foundation/Foundation.h>
#import "TTDownloadStorageProtocol.h"

typedef NS_ENUM (NSInteger, TTDownloadStorageImplType) {
    TTDownloadStorageImplTypeSqlite = 0
};

@interface TTDownloadStorageCenter : NSObject <TTDownloadStorageProtocol>

- (id)initWithDownloadStorageImplType:(TTDownloadStorageImplType)impl;

@end
