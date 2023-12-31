//
//  BDLynxGurdModule.m
//  BDLynx
//
//  Created by bill on 2020/2/4.
//

#import "BDLynxGurdModule.h"
#import "BDLGeckoProtocol.h"
#import "BDLGeckoTemplateManager.h"
#import "BDLGurdSyncResourcesManager.h"
#import "BDLGurdSyncResourcesTask.h"
#import "BDLHostProtocol.h"
#import "BDLSDKManager.h"
#import "BDLSDKProtocol.h"
#import "BDLTemplateManager.h"
#import "BDLynxBundle.h"
#import "BDLynxChannelsRegister.h"
#import "LynxComponentRegistry.h"

NSString *BDGurdLynxKeyPlaceholder = @"lynx_common_channel";

NSString *const BDGurdLynxBusinessModuleDidSyncResources =
    @"BDGurdLynxBusinessModuleDidSyncResources";
NSString *const BDGurdLynxBusinessModuleDidSyncHighPriorityResources =
    @"BDGurdLynxBusinessModuleDidSyncHighPriorityResources";

@implementation BDLynxGurdModule

LYNX_LOAD_LAZY(BDL_BIND_SERVICE(self.class, BDLGurdModuleProtocol);)

+ (instancetype)sharedInstance {
  static BDLynxGurdModule *instance;
  static dispatch_once_t onceToken;
  dispatch_once(&onceToken, ^{
    instance = [[BDLynxGurdModule alloc] init];
  });
  return instance;
}

- (BOOL)enableGurd {
  return YES;
}

- (NSString *)accessKeyDirectory {
  NSString *accessKey = [BDL_SERVICE(BDLGeckoProtocol) accessKey];
  return [BDL_SERVICE(BDLGeckoProtocol) rootDirectoryForAccessKey:accessKey];
}

- (NSString *)lynxFilePathForChannel:(NSString *)channel {
  NSString *accessKey = [BDL_SERVICE(BDLGeckoProtocol) accessKey];
  return [BDL_SERVICE(BDLGeckoProtocol) rootDirectoryForAccessKey:accessKey channel:channel];
}

- (BOOL)isSingleLynxFileForChannel:(NSString *)channel {
  NSString *accessKey = [BDL_SERVICE(BDLGeckoProtocol) accessKey];
  BDLGurdChannelFileType type = [BDL_SERVICE(BDLGeckoProtocol) fileTypeForAccessKey:accessKey
                                                                            channel:channel];
  return (type == BDLGurdChannelFileTypeUncompressed);
}

- (void)syncResourcesIfNeeded {
  [self _syncHighPriorityResources];
  [self _syncDefaultPriorityResources];
}

- (void)syncResourcesWithChannel:(NSString *)channel
                        isUrgent:(BOOL)isUrgent
                      completion:(BDGurdLynxSyncResourcesCompletion)completion {
  if (channel.length == 0) {
    !completion ?: completion(NO);
    return;
  }
  static NSMutableDictionary<NSString *, NSMutableArray *> *completionDictionary = nil;
  static dispatch_once_t onceToken;
  dispatch_once(&onceToken, ^{
    completionDictionary = [NSMutableDictionary dictionary];
  });
  __block BOOL shouldSyncResources = NO;
  @synchronized(completionDictionary) {
    NSMutableArray *completionArray = completionDictionary[channel];
    if (!completionArray) {
      completionArray = [NSMutableArray array];
      completionDictionary[channel] = completionArray;
    }
    shouldSyncResources = (completionArray.count == 0);

    if (!completion) {
      completion = ^(BOOL succeed) {
        // 空实现占位
      };
    }
    [completionArray addObject:completion];
  }
  if (!shouldSyncResources) {
    completion(YES);
    return;
  }

  BDLGurdSyncResourcesTaskCompletion taskCompletion =
      ^(BOOL succeed, NSDictionary<NSString *, NSNumber *> *info) {
        __block NSArray<BDGurdLynxSyncResourcesCompletion> *array = nil;
        @synchronized(completionDictionary) {
          NSMutableArray *completionArray = completionDictionary[channel];
          array = [completionArray copy];
          [completionArray removeAllObjects];
        }
        [array enumerateObjectsUsingBlock:^(BDGurdLynxSyncResourcesCompletion block, NSUInteger idx,
                                            BOOL *stop) {
          block(succeed);
        }];
      };
  BDLGurdSyncResourcesOptions options =
      isUrgent ? BDLGurdSyncResourcesOptionsUrgent : BDLGurdSyncResourcesOptionsNone;
  [self _syncResourcesWithChannels:@[ channel ] options:options completion:taskCompletion];
}

- (void)bytedSettingDidChange {
  [self syncResourcesIfNeeded];
}

// ------------------------------------ OnCard在线流程 BEGIN
// ------------------------------------------------

- (void)syncResourcesWithChannel:(NSString *)channel
                      completion:(BDGurdLynxSyncResourcesCompletion)completion {
  [self syncResourcesWithChannel:channel accessKey:nil completion:completion];
}

- (void)syncResourcesWithChannel:(NSString *)channel
                       accessKey:(NSString *)accessKey
                      completion:(BDGurdLynxSyncResourcesCompletion)completion {
  accessKey =
      accessKey ?: [BDL_SERVICE_WITH_SELECTOR(BDLGeckoProtocol, @selector(accessKey)) accessKey];

  BDLGurdSyncResourcesTaskCompletion taskCompletion = ^(
      BOOL succeed, NSDictionary<NSString *, NSNumber *> *_Nonnull info) {
    [[BDLTemplateManager sharedInstance] bundleUpdate:channel success:succeed];
    // 同步完成后解析config文件，如果有资源分包需要同步资源gecko
    if (succeed) {
      BOOL hasExtResource = NO;
      NSString *rootDir = [BDL_SERVICE(BDLGeckoProtocol) rootDirectoryForAccessKey:accessKey
                                                                           channel:channel];
      if (!rootDir) {
        if (completion) {
          completion(succeed);
        }
        return;
      }
      BDLynxBundle *bundle = [[BDLynxBundle alloc] initWithRootDir:[NSURL fileURLWithPath:rootDir]
                                                           groupID:channel];
      for (BDLynxTemplateConfig *config in bundle.channelConfig.iOSConfig.templateList) {
        if (config.hasExtResource) {
          hasExtResource = YES;
          break;
        }
      }
      if (hasExtResource) {
        [self syncResourcesWithChannel:[channel stringByAppendingString:@"_resource"]
                             accessKey:accessKey
                            completion:^(BOOL succeed){
                            }];
      }
    }

    if (completion) {
      completion(succeed);
    }
  };

  [BDL_SERVICE(BDLGeckoProtocol) registerChannels:@[ channel ] forAccessKey:accessKey];

  [BDL_SERVICE_WITH_SELECTOR(BDLGeckoProtocol, @selector(syncResourcesForAccessKey:
                                                                          channels:completion:))
      syncResourcesForAccessKey:accessKey
                       channels:@[ channel ]
                     completion:^(BOOL succeed,
                                  NSDictionary<NSString *, NSNumber *> *_Nonnull dict) {
                       taskCompletion(succeed, dict);
                     }];
}

// ------------------------------------ OnCard在线流程 END
// ------------------------------------------------

#pragma mark - Private

- (void)_syncHighPriorityResources {
  NSMutableArray<NSString *> *channels = [NSMutableArray array];
  NSArray<BDLynxChannelRegisterConfig *> *registedChannels =
      [[BDLynxChannelsRegister sharedInstance] registedHighPriorityChannels];

  if (registedChannels.count == 0) {
    return;
  }

  [registedChannels enumerateObjectsUsingBlock:^(BDLynxChannelRegisterConfig *_Nonnull obj,
                                                 NSUInteger idx, BOOL *_Nonnull stop) {
    [channels addObject:obj.channelName];
  }];

  BDLGurdSyncResourcesTaskCompletion completion =
      ^(BOOL succeed, NSDictionary<NSString *, NSNumber *> *info) {
        [[NSNotificationCenter defaultCenter]
            postNotificationName:BDGurdLynxBusinessModuleDidSyncHighPriorityResources
                          object:@{@"code" : @(succeed)}];
      };
  [self _syncResourcesWithChannels:[channels copy]
                           options:BDLGurdSyncResourcesOptionsHighPriority
                        completion:completion];
}

- (void)_syncDefaultPriorityResources {
  NSMutableArray<NSString *> *channels = [NSMutableArray array];
  NSArray<BDLynxChannelRegisterConfig *> *registedChannels =
      [[BDLynxChannelsRegister sharedInstance] registedDefaultPriorityChannels];

  if (registedChannels.count == 0) {
    return;
  }

  [registedChannels enumerateObjectsUsingBlock:^(BDLynxChannelRegisterConfig *_Nonnull obj,
                                                 NSUInteger idx, BOOL *_Nonnull stop) {
    [channels addObject:obj.channelName];
  }];

  BDLGurdSyncResourcesTaskCompletion completion =
      ^(BOOL succeed, NSDictionary<NSString *, NSNumber *> *info) {
        [[NSNotificationCenter defaultCenter]
            postNotificationName:BDGurdLynxBusinessModuleDidSyncHighPriorityResources
                          object:@{@"code" : @(succeed)}];
      };
  [self _syncResourcesWithChannels:[channels copy]
                           options:BDLGurdSyncResourcesOptionsNone
                        completion:completion];
}

- (void)_syncResourcesWithChannels:(NSArray<NSString *> *)channels
                           options:(BDLGurdSyncResourcesOptions)options
                        completion:(BDLGurdSyncResourcesTaskCompletion)completion {
  BDLGurdSyncResourcesTaskCompletion taskCompletion =
      ^(BOOL succeed, NSDictionary<NSString *, NSNumber *> *_Nonnull info) {
        [channels enumerateObjectsUsingBlock:^(NSString *_Nonnull channel, NSUInteger idx,
                                               BOOL *_Nonnull stop) {
          [[BDLGeckoTemplateManager sharedInstance] gurdDataUpdate:channel succeed:succeed];
        }];
        if (completion) {
          completion(succeed, info);
        }
      };

  NSString *businessDomain = [BDL_SERVICE(BDLSDKProtocol) lynxBusinessDomain];
  BDLGurdSyncResourcesTask *task = [BDLGurdSyncResourcesTask taskWithChannels:channels
                                                               businessDomain:businessDomain
                                                                   completion:taskCompletion];
  task.options = options;
  [BDLGurdSyncResourcesManager enqueueSyncResourcesTask:task];
}

@end
