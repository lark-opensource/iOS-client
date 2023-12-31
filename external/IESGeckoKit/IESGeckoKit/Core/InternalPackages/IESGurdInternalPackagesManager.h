//
//  IESGurdInternalPackagesManager.h
//  BDAssert
//
//  Created by 陈煜钏 on 2020/9/16.
//

#import <Foundation/Foundation.h>

#import "IESGurdInternalPackageMetaInfo.h"

NS_ASSUME_NONNULL_BEGIN

extern void IESGurdInternalPackageBusinessLog (NSString *accessKey,
                                               NSString *channel,
                                               NSString *message,
                                               BOOL hasError,
                                               BOOL shouldLog);

extern void IESGurdInternalPackageMessageLog (NSString *message, BOOL hasError, BOOL shouldLog);

extern void IESGurdInternalPackageAsyncExecuteBlock (dispatch_block_t block);

@interface IESGurdInternalPackagesManager : NSObject

+ (NSInteger)internalPackageIdForAccessKey:(NSString *)accessKey
                                   channel:(NSString *)channel;

+ (IESGurdDataAccessPolicy)dataAccessPolicyForAccessKey:(NSString *)accessKey
                                                channel:(NSString *)channel;

+ (void)updateDataAccessPolicy:(IESGurdDataAccessPolicy)policy
                     accessKey:(NSString *)accessKey
                       channel:(NSString *)channel;

+ (void)saveInternalPackageMetaInfo:(IESGurdInternalPackageMetaInfo *)metaInfo;

+ (void)clearInternalPackageForAccessKey:(NSString *)accessKey channel:(NSString *)channel;

+ (void)didAccessInternalPackageWithAccessKey:(NSString *)accessKey
                                      channel:(NSString *)channel
                                         path:(NSString *)path
                             dataAccessPolicy:(IESGurdDataAccessPolicy)dataAccessPolicy;

@end

NS_ASSUME_NONNULL_END
