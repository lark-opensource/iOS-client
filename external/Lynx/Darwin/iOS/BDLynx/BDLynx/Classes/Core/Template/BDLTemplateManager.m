//
//  BDLTemplateManager.m
//  BDLynx
//
//  Created by zys on 2020/2/6.
//

#import "BDLTemplateManager.h"
#import "BDLGeckoProtocol.h"
#import "BDLGurdModuleProtocol.h"
#import "BDLNetProtocol.h"
#import "BDLSDKManager.h"
#import "BDLTemplateProtocol.h"
#import "BDLUtils.h"
#import "BDLynxBundle.h"
#import "BDLynxKitModule.h"
#import "BDLynxResourceDownloader.h"
#import "NSDictionary+BDLynxAdditions.h"

@interface BDLTemplateManager () {
  void *templateQueueKey;
}

@property(nonatomic, strong) dispatch_queue_t templateQueue;

@property(nonatomic, strong) NSMutableDictionary<NSString *, BDLynxBundle *> *bundleCache;

@property(nonatomic, strong) NSMapTable *dataUpdateBlocks;

@end

@implementation BDLTemplateManager

#pragma mark - Private

- (NSData *)dataForCardID:(NSString *)cardID groupID:(NSString *)groupID {
  BDLynxBundle *lynxBundle = [self lynxBundleForGroupID:groupID cardID:cardID];
  return [lynxBundle lynxDataWithCardID:cardID];
}

- (void)asyncGetDataForCardID:(NSString *)cardID
                      groupID:(NSString *)groupID
                   completion:(void (^)(NSData *data))completion {
  dispatch_async(self.templateQueue, ^{
    NSData *data = [self dataForCardID:cardID groupID:groupID];
    if (BDL_SERVICE(BDLTemplateProtocol) &&
        [BDL_SERVICE(BDLTemplateProtocol) respondsToSelector:@selector(registerDataUpdate:
                                                                               forGroupID:)]) {
      [BDL_SERVICE(BDLTemplateProtocol)
          registerDataUpdate:^(NSString *_Nonnull groupID, BOOL succeed) {
            [self lynxTemplateDataDidUpdate:groupID cardID:cardID];
          }
                  forGroupID:groupID];
    } else {
      BDLERROR(@"Didn't register registerDataUpdate method");
    }
    dispatch_async(dispatch_get_main_queue(), ^{
      if (completion) {
        completion(data);
      }
    });
  });
}

// ------------------------------------ OnCard在线流程 BEGIN
// ------------------------------------------------

- (void)loadGurdBundle:(NSString *)channel
             completion:(void (^)(BDLynxBundle *bundle, BOOL success))completion {
  [self loadGurdBundle:channel accessKey:nil completion:completion];
}

- (void)loadGurdBundle:(NSString *)channel
              accessKey:(NSString *)accessKey
             completion:(void (^)(BDLynxBundle *bundle, BOOL success))completion {
  accessKey = BDLIsEmptyString(accessKey) ? [BDL_SERVICE(BDLGeckoProtocol) accessKey] : accessKey;
  NSString *rootDir = [BDL_SERVICE(BDLGeckoProtocol) rootDirectoryForAccessKey:accessKey
                                                                       channel:channel];

  if (!rootDir) {
    if (completion) {
      completion(nil, NO);
    }
    return;
  }

  void (^mainThreadExecuteBlock)(BOOL success) = ^(BOOL success) {
    dispatch_async(dispatch_get_main_queue(), ^{
      BDLynxBundle *bundle = [[BDLynxBundle alloc] initWithRootDir:[NSURL fileURLWithPath:rootDir]
                                                           groupID:channel];
      if (completion) {
        completion(bundle, bundle && success);
      }
    });
  };

  if ([[NSFileManager defaultManager] fileExistsAtPath:rootDir]) {
    mainThreadExecuteBlock(YES);
    return;
  }

  // 等待gecko返回时回调
  [self
      registerDataUpdate:^(BOOL success) {
        mainThreadExecuteBlock(success);
      }
              forGroupID:channel];

  [BDL_SERVICE(BDLGurdModuleProtocol) syncResourcesWithChannel:channel
                                                     accessKey:accessKey
                                                    completion:^(BOOL succeed){

                                                    }];
}

- (void)loadGurdBundleAndResource:(NSString *)channel
                         accessKey:(NSString *)accessKey
                        completion:(void (^)(BDLynxBundle *bundle, BOOL success))completion {
  [self loadGurdBundle:channel
             completion:^(BDLynxBundle *_Nonnull bundle, BOOL success) {
               if (bundle) {
                 // 检查离线资源有没下载，没有就触发下载逻辑
                 for (BDLynxTemplateConfig *config in bundle.channelConfig.iOSConfig.templateList) {
                   if (config.hasExtResource) {
                     NSString *resourceChannel = [channel stringByAppendingString:@"_resource"];
                     NSURL *resourceRoot = [[config.rootDirURL URLByDeletingLastPathComponent]
                         URLByAppendingPathComponent:[config.groupID
                                                         stringByAppendingString:@"_resource"]
                                         isDirectory:YES];

                     if (![[NSFileManager defaultManager] fileExistsAtPath:[resourceRoot path]]) {
                       [BDL_SERVICE(BDLGurdModuleProtocol)
                           syncResourcesWithChannel:resourceChannel
                                          accessKey:accessKey
                                         completion:^(BOOL succeed) {
                                           dispatch_async(dispatch_get_main_queue(), ^{
                                             if (completion) {
                                               completion(bundle, success);
                                             }
                                           });
                                         }];
                       return;
                     }
                     break;
                   }
                 }
               }
               if (completion) {
                 completion(bundle, success);
               }
             }];
}

- (void)registerDataUpdate:(nonnull void (^)(BOOL success))block
                forGroupID:(nonnull NSString *)groupID {
  if (!block) {
    return;
  }
  @synchronized(self) {
    [self.dataUpdateBlocks setObject:block forKey:groupID];
  }
}

- (void)bundleUpdate:(NSString *)groupID success:(BOOL)success {
  void (^block)(BOOL success) = nil;
  @synchronized(self) {
    block = [self.dataUpdateBlocks objectForKey:groupID];
    [self.dataUpdateBlocks removeObjectForKey:groupID];
  }
  if (block) {
    block(success);
  }
}

// ------------------------------------ OnCard在线流程 END
// ------------------------------------------------

- (BDLynxBundle *)lynxBundleForGroupID:(NSString *)groupID {
  NSString *rootDir = [BDL_SERVICE_WITH_SELECTOR(BDLTemplateProtocol, @selector(rootDirForGroupID:))
      rootDirForGroupID:groupID];
  if ([[NSFileManager defaultManager] fileExistsAtPath:rootDir]) {
    return [[BDLynxBundle alloc] initWithRootDir:[NSURL fileURLWithPath:rootDir] groupID:groupID];
  }
  return nil;
}

- (BDLynxBundle *)lynxBundleForGroupID:(NSString *)groupID cardID:(NSString *)cardID {
  if (!groupID) {
    groupID =
        [BDL_SERVICE_WITH_SELECTOR(BDLTemplateProtocol, @selector(defaultGroupID)) defaultGroupID];
    if (!groupID) {
      return nil;
    }
  }
  __block BDLynxBundle *lynxBundle = nil;
  [self runInOperationQueue:^{
    lynxBundle = [self cacheObjectForKey:[NSString stringWithFormat:@"%@/%@", groupID, cardID]];
    if (!lynxBundle) {
      NSString *rootDir = [BDL_SERVICE_WITH_SELECTOR(
          BDLTemplateProtocol, @selector(rootDirForGroupID:)) rootDirForGroupID:groupID];
      NSString *filePath = [BDL_SERVICE_WITH_SELECTOR(
          BDLTemplateProtocol, @selector(fileForGroupID:)) fileForGroupID:groupID];

      if (rootDir && [[NSFileManager defaultManager] fileExistsAtPath:rootDir]) {
        lynxBundle = [[BDLynxBundle alloc] initWithRootDir:[NSURL fileURLWithPath:rootDir]
                                                   groupID:groupID];
      } else if (filePath && [[NSFileManager defaultManager] fileExistsAtPath:filePath]) {
        lynxBundle =
            [[BDLynxBundle alloc] initWithSingleBundleFileURL:[NSURL fileURLWithPath:filePath]
                                                      groupID:groupID];
      }
    }
    if (lynxBundle) {
      [self setCacheObject:lynxBundle forKey:[NSString stringWithFormat:@"%@/%@", groupID, cardID]];
    }
  }];
  return lynxBundle;
}

- (void)asyncGetDataForDirectURL:(NSURL *)url completion:(void (^)(NSData *data))completion {
  [[BDLynxResourceDownloader sharedDownloader]
      downloadLynxFile:url.absoluteString
            completion:^(NSError *_Nonnull error, NSString *_Nonnull location) {
              NSData *data = nil;
              if (!error && [[NSFileManager defaultManager] fileExistsAtPath:location]) {
                data = [NSData dataWithContentsOfFile:location];
              }

              dispatch_async(dispatch_get_main_queue(), ^{
                if (completion) {
                  completion(data);
                }
              });
            }];
}

- (void)lynxTemplateDataDidUpdate:(NSString *)groupID cardID:(NSString *)cardID {
  dispatch_async(self.templateQueue, ^{
    BOOL channelDidUpdate = NO;
    BDLynxBundle *bundle =
        [self cacheObjectForKey:[NSString stringWithFormat:@"%@/%@", groupID, cardID]];

    if (bundle) {
      NSString *rootDir = [BDL_SERVICE_WITH_SELECTOR(
          BDLTemplateProtocol, @selector(rootDirForGroupID:)) rootDirForGroupID:groupID];

      NSString *filePath = [BDL_SERVICE_WITH_SELECTOR(
          BDLTemplateProtocol, @selector(fileForGroupID:)) fileForGroupID:groupID];

      if (rootDir && [[NSFileManager defaultManager] fileExistsAtPath:rootDir]) {
        channelDidUpdate = [bundle updateDataWithRootDir:[NSURL fileURLWithPath:rootDir]];
      } else if (filePath && [[NSFileManager defaultManager] fileExistsAtPath:filePath]) {
        channelDidUpdate = [bundle updateDataWithSingleBundleFile:[NSURL fileURLWithPath:filePath]];
      }

      if (channelDidUpdate) {
        [[NSNotificationCenter defaultCenter] postNotificationName:kChannelTemplateDidUpdate
                                                            object:groupID];
      }
    }
  });
}

#pragma mark - init

+ (BDLTemplateManager *)sharedInstance {
  static BDLTemplateManager *_instance = nil;
  static dispatch_once_t onceToken;
  dispatch_once(&onceToken, ^{
    _instance = [[self alloc] init];
  });
  return _instance;
}

- (instancetype)init {
  self = [super init];
  if (self) {
    [self config];
    _bundleCache = [NSMutableDictionary new];
    _dataUpdateBlocks = [[NSMapTable alloc] initWithKeyOptions:NSMapTableStrongMemory
                                                  valueOptions:NSMapTableCopyIn
                                                      capacity:0];
    templateQueueKey = &templateQueueKey;
  }
  return self;
}

- (void)config {
  [[NSNotificationCenter defaultCenter] addObserver:self
                                           selector:@selector(didReceiveMemoryWarning)
                                               name:UIApplicationDidReceiveMemoryWarningNotification
                                             object:nil];
}

- (void)didReceiveMemoryWarning {
  BDLINFO(@"Receive Memory Warning and clear all Cache");
  [self removeAllCache];
}

#pragma mark - dealloc
- (void)dealloc {
  [[NSNotificationCenter defaultCenter] removeObserver:self];
}

#pragma mark - queue
- (void)setCacheObject:(BDLynxBundle *)object forKey:(NSString *)key {
  dispatch_barrier_async(self.templateQueue, ^{
    [self.bundleCache setValue:object forKey:key];
  });
}

- (void)removeCacheObjectForKey:(NSString *)key {
  dispatch_barrier_async(self.templateQueue, ^{
    [self.bundleCache removeObjectForKey:key];
  });
}

- (void)removeAllCache {
  dispatch_barrier_async(self.templateQueue, ^{
    [self.bundleCache removeAllObjects];
  });
}

- (BDLynxBundle *)cacheObjectForKey:(NSString *)key {
  __block id cacheObject = nil;

  [self runInOperationQueue:^{
    cacheObject = [self.bundleCache objectForKey:key];
  }];

  if ([cacheObject isKindOfClass:[BDLynxBundle class]]) {
    return cacheObject;
  }

  return nil;
}

- (void)runInOperationQueue:(DISPATCH_NOESCAPE dispatch_block_t)handler {
  if (dispatch_get_specific(templateQueueKey)) {
    handler();
  } else {
    dispatch_sync(self.templateQueue, ^{
      handler();
    });
  }
}

- (dispatch_queue_t)templateQueue {
  if (!_templateQueue) {
    _templateQueue = dispatch_queue_create("com.bdlynx.template", DISPATCH_QUEUE_CONCURRENT);
    dispatch_set_target_queue(_templateQueue, dispatch_get_global_queue(QOS_CLASS_DEFAULT, 0));
    dispatch_queue_set_specific(_templateQueue, templateQueueKey, (__bridge void *_Nullable)(self),
                                NULL);
  }
  return _templateQueue;
}

#pragma mark - Public

+ (NSData *)dataForCardID:(NSString *)cardID groupID:(NSString *)groupID {
  return [[self sharedInstance] dataForCardID:cardID groupID:groupID];
}

+ (void)asyncGetDataForCardID:(NSString *)cardID
                      groupID:(NSString *)groupID
                   completion:(void (^)(NSData *data))completion {
  [[self sharedInstance] asyncGetDataForCardID:cardID groupID:groupID completion:completion];
}

+ (BDLynxBundle *)lynxBundleForGroupID:(NSString *)groupID cardID:(NSString *)cardID {
  return [[self sharedInstance] lynxBundleForGroupID:groupID cardID:cardID];
}

+ (NSString *)lynxBundlePathForGroupID:(NSString *)groupID cardID:(NSString *)cardID {
  return [[[self sharedInstance] lynxBundleForGroupID:groupID
                                               cardID:cardID].rootDirURL absoluteString];
}

+ (NSData *)lynxDataForGroupID:(NSString *)groupID cardID:(NSString *)cardID {
  BDLynxBundle *lynxBundle = [self lynxBundleForGroupID:groupID cardID:cardID];
  return [lynxBundle lynxDataWithCardID:cardID];
}

+ (void)asyncGetDataForDirectURL:(NSURL *)url completion:(void (^)(NSData *data))completion {
  [[self sharedInstance] asyncGetDataForDirectURL:url completion:completion];
}

@end
