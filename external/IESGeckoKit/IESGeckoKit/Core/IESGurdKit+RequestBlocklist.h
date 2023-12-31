//
//  IESGurdKit+RequestBlocklist.h
//  Aspects
//
//  Created by 陈煜钏 on 2021/9/13.
//

#import "IESGeckoKit.h"

NS_ASSUME_NONNULL_BEGIN

@interface IESGurdKit (RequestBlocklist)

+ (void)addRequestBlocklistGroupNames:(NSArray<NSString *> *)groupNames forAccessKey:(NSString *)accessKey;

+ (void)removeRequestBlocklistGroupNames:(NSArray<NSString *> *)groupNames forAccessKey:(NSString *)accessKey;

+ (void)addRequestBlocklistChannels:(NSArray<NSString *> *)channels forAccessKey:(NSString *)accessKey;

+ (void)removeRequestBlocklistChannels:(NSArray<NSString *> *)channels forAccessKey:(NSString *)accessKey;

@end

@interface NSString (IESGurdRequestParams)

- (BOOL)iesgurdkit_shouldRequestGroupNameForForAccessKey:(NSString *)accessKey;

@end

@interface NSArray (IESGurdRequestParams)

- (NSArray<NSString *> *)iesgurdkit_filteredGroupNamesForAccessKey:(NSString *)accessKey;

- (NSArray<NSString *> *)iesgurdkit_filteredChannelsForAccessKey:(NSString *)accessKey;

@end

NS_ASSUME_NONNULL_END
