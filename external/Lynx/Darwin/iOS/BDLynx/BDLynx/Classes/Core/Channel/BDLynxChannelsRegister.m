//
//  BDLynxChannelsRegister.m
//  BDLynx
//
//  Created by  wanghanfeng on 2020/2/6.
//

#import "BDLynxChannelsRegister.h"

@interface BDLynxChannelsRegister ()

@property(nonatomic, strong) NSMutableArray<BDLynxChannelRegisterConfig *> *registChannels;
@property(nonatomic, strong)
    NSMutableArray<BDLynxChannelRegisterConfig *> *registHighPriorityChannels;
@property(nonatomic, strong)
    NSMutableArray<BDLynxChannelRegisterConfig *> *registDefaultPriorityChannels;

@property(nonatomic, strong) NSLock *registLock;

@end

@implementation BDLynxChannelsRegister

+ (instancetype)sharedInstance {
  static BDLynxChannelsRegister *instance;
  static dispatch_once_t onceToken;
  dispatch_once(&onceToken, ^{
    instance = [[BDLynxChannelsRegister alloc] init];
  });
  return instance;
}

- (instancetype)init {
  if (self = [super init]) {
    _registChannels = [NSMutableArray arrayWithCapacity:20];
    _registHighPriorityChannels = [NSMutableArray arrayWithCapacity:20];
    _registDefaultPriorityChannels = [NSMutableArray arrayWithCapacity:20];
    _registLock = [[NSLock alloc] init];
  }
  return self;
}

- (void)registChannel:(BDLynxChannelRegisterConfig *)channelConfig {
  if (channelConfig && [channelConfig isKindOfClass:[BDLynxChannelRegisterConfig class]]) {
    [self.registLock lock];
    [self.registChannels addObject:channelConfig];
    if (channelConfig.loadPolicy == BDLynxLoadChannelPolicyHigh) {
      [self.registHighPriorityChannels addObject:channelConfig];
    } else if (channelConfig.loadPolicy == BDLynxLoadChannelPolicyNormal) {
      [self.registDefaultPriorityChannels addObject:channelConfig];
    }
    [self.registLock unlock];
  }
}

- (void)registChannels:(NSArray<BDLynxChannelRegisterConfig *> *)channelConfigs {
  for (BDLynxChannelRegisterConfig *channelConfig in channelConfigs) {
    [self registChannel:channelConfig];
  }
}

- (NSArray<BDLynxChannelRegisterConfig *> *)registedChannels {
  return [self.registChannels copy];
}

- (NSArray<BDLynxChannelRegisterConfig *> *)registedHighPriorityChannels {
  return [self.registHighPriorityChannels copy];
}

- (NSArray<BDLynxChannelRegisterConfig *> *)registedDefaultPriorityChannels {
  return [self.registDefaultPriorityChannels copy];
}

@end
