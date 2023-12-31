//
//  BDLGurdSyncResourcesTask.m
//  BDLynx
//
//  Created by  wanghanfeng on 2020/2/7.
//

#import "BDLGurdSyncResourcesTask.h"

@interface BDLGurdSyncResourcesTask ()

@property(nonatomic, readwrite, copy) NSString *identifier;

@property(nullable, nonatomic, readwrite, copy) NSString *accessKey;

@property(nonatomic, readwrite, copy) NSArray<NSString *> *channelsArray;

@property(nullable, nonatomic, readwrite, copy) NSString *businessDomain;

@property(nullable, nonatomic, readwrite, copy) BDLGurdSyncResourcesTaskCompletion completion;

@property(nonatomic, readwrite, assign, getter=isExecuting) BOOL executing;

@end

@implementation BDLGurdSyncResourcesTask

+ (instancetype)taskWithAccessKey:(NSString *_Nullable)accessKey
                         channels:(NSArray<NSString *> *)channels
                   businessDomain:(NSString *_Nullable)businessDomain
                       completion:(BDLGurdSyncResourcesTaskCompletion _Nullable)completion {
  if (channels.count == 0) {
    return nil;
  }
  BDLGurdSyncResourcesTask *task = [[self alloc] init];
  task.accessKey = accessKey;
  task.channelsArray = channels;
  task.businessDomain = businessDomain;
  task.completion = completion;
  return task;
}

+ (instancetype)taskWithChannels:(NSArray<NSString *> *)channels
                  businessDomain:(NSString *_Nullable)businessDomain
                      completion:(BDLGurdSyncResourcesTaskCompletion _Nullable)completion;
{
  return [self taskWithAccessKey:nil
                        channels:channels
                  businessDomain:businessDomain
                      completion:completion];
}

- (BOOL)forceRequest {
  return self.options & BDLGurdSyncResourcesOptionsForceRequest;
}

#pragma mark - Getter

- (NSString *)identifier {
  if (!_identifier) {
    NSArray *sortedChannels =
        [self.channelsArray sortedArrayUsingSelector:@selector(localizedCaseInsensitiveCompare:)];
    _identifier = [sortedChannels componentsJoinedByString:@"+"];
  }
  return _identifier;
}

@end
