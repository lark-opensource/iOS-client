//
//  IESGurdChannelUsageMananger.h
//  IESGeckoKit
//
//  Created by 黄李磊 on 2021/5/20.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM(NSInteger, IESGurdDataAccessType) {
    IESGurdDataAccessTypeSyncAccess = 1,
    IESGurdDataAccessTypeAsyncAccess = 2,
    IESGurdDataAccessTypeDirectoryAccess = 3
};

@interface IESGurdChannelUsageMananger : NSObject

+ (void)accessDataWithType:(IESGurdDataAccessType)type
                 accessKey:(NSString *)accessKey
                   channel:(NSString *)channel
                   hitData:(BOOL)hitData;

+ (BOOL)isChannelUsed:(NSString *)accessKey channel:(NSString *)channel;

@end

NS_ASSUME_NONNULL_END
