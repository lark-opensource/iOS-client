//
//  BDLGeckoTemplateManager.m
//  BDLynx
//
//  Created by zys on 2020/2/9.
//

#import "BDLGeckoTemplateManager.h"
#import "BDLGeckoProtocol.h"
#import "BDLSDKManager.h"
#import "BDLynxGurdModule.h"
#import "LynxComponentRegistry.h"

@interface BDLGeckoTemplateManager ()

@property(nonatomic, strong) NSMapTable *dataUpdateBlocks;
@property(nonatomic, strong) NSLock *blocksLock;

@end

@implementation BDLGeckoTemplateManager

LYNX_LOAD_LAZY(BDL_BIND_SERVICE(self, BDLTemplateProtocol);)
/**
 * 单例对象
 */
+ (instancetype)sharedInstance {
  static id _instance = nil;
  static dispatch_once_t onceToken;
  dispatch_once(&onceToken, ^{
    _instance = [[self alloc] init];
  });
  return _instance;
}

- (nonnull NSString *)fileForGroupID:(nonnull NSString *)groupID {
  NSString *path = nil;
  if ([[BDLynxGurdModule sharedInstance] isSingleLynxFileForChannel:groupID]) {
    path = [[BDLynxGurdModule sharedInstance] lynxFilePathForChannel:groupID];
  }

  if (!path || (path && ![[NSFileManager defaultManager] fileExistsAtPath:path])) {
    path = [BDL_SERVICE_WITH_SELECTOR(BDLGeckoProtocol, @selector(defaultFileForGroupID:))
        defaultFileForGroupID:groupID];
  }
  return path;
}

- (nonnull NSString *)rootDirForGroupID:(nonnull NSString *)groupID {
  NSString *path = nil;
  if (![[BDLynxGurdModule sharedInstance] isSingleLynxFileForChannel:groupID]) {
    path = [[BDLynxGurdModule sharedInstance] lynxFilePathForChannel:groupID];
  }

  if (!path || (path && ![[NSFileManager defaultManager] fileExistsAtPath:path])) {
    path = [BDL_SERVICE_WITH_SELECTOR(BDLGeckoProtocol, @selector(defaultFilerootDirForGroupID:))
        defaultFilerootDirForGroupID:groupID];
  }
  return path;
}

- (void)registerDataUpdate:(nonnull void (^)(NSString *_Nonnull, BOOL))block
                forGroupID:(nonnull NSString *)groupID {
  if (!block) {
    return;
  }
  [self.blocksLock lock];
  [self.dataUpdateBlocks setObject:block forKey:groupID];
  [self.blocksLock unlock];
}

- (void)gurdDataUpdate:(NSString *)channel succeed:(BOOL)succeed {
  void (^block)(NSString *channel, BOOL succeed) = nil;
  [self.blocksLock lock];
  block = [self.dataUpdateBlocks objectForKey:channel];
  [self.blocksLock unlock];
  if (block) {
    block(channel, succeed);
  }
}

- (NSString *)defaultGroupID {
  return [BDL_SERVICE_WITH_SELECTOR(BDLGeckoProtocol, @selector(defaultGroupID)) defaultGroupID];
}

- (instancetype)init {
  if (self = [super init]) {
    self.dataUpdateBlocks = [[NSMapTable alloc] initWithKeyOptions:NSMapTableStrongMemory
                                                      valueOptions:NSMapTableCopyIn
                                                          capacity:0];
    self.blocksLock = [[NSLock alloc] init];
  }
  return self;
}

@end
