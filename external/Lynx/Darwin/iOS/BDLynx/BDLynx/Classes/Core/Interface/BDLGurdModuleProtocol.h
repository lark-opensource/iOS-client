//
//  BDLGurdModuleProtocol.h
//  BDLynx
//
//  Created by annidy on 2020/3/30.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

typedef void (^BDGurdLynxSyncResourcesCompletion)(BOOL succeed);

@protocol BDLGurdModuleProtocol <NSObject>

- (BOOL)enableGurd;

- (NSString *)accessKeyDirectory;

- (NSString *)lynxFilePathForChannel:(NSString *)channel;

- (BOOL)isSingleLynxFileForChannel:(NSString *)channel;

- (void)syncResourcesIfNeeded;

/// 请求channel资源
/// @param channel channel名
/// @param isUrgent 是否紧急
/// @param completion completion
- (void)syncResourcesWithChannel:(NSString *)channel
                        isUrgent:(BOOL)isUrgent
                      completion:(BDGurdLynxSyncResourcesCompletion)completion;

- (void)bytedSettingDidChange;

// ------------------------------------ OnCard在线流程 BEGIN
// ------------------------------------------------

- (void)syncResourcesWithChannel:(NSString *)channel
                      completion:(BDGurdLynxSyncResourcesCompletion)completion;

- (void)syncResourcesWithChannel:(NSString *)channel
                       accessKey:(nullable NSString *)accessKey
                      completion:(BDGurdLynxSyncResourcesCompletion)completion;

// ------------------------------------ OnCard在线流程 END
// ------------------------------------------------

@end

NS_ASSUME_NONNULL_END
