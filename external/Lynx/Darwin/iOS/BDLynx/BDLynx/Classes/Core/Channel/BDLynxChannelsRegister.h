//
//  BDLynxChannelsRegister.h
//  BDLynx
//
//  Created by  wanghanfeng on 2020/2/6.
//

#import <Foundation/Foundation.h>
#import "BDLyxnChannelConfig.h"

NS_ASSUME_NONNULL_BEGIN

@interface BDLynxChannelsRegister : NSObject

+ (instancetype)sharedInstance;

- (void)registChannel:(BDLynxChannelRegisterConfig *)channelConfig;

- (void)registChannels:(NSArray<BDLynxChannelRegisterConfig *> *)channelConfigs;

/**
已注册的channels
*/
- (NSArray<BDLynxChannelRegisterConfig *> *)registedChannels;

/**
已注册的高优先级channels
*/
- (NSArray<BDLynxChannelRegisterConfig *> *)registedHighPriorityChannels;

/**
已注册的默认优先级channels
*/
- (NSArray<BDLynxChannelRegisterConfig *> *)registedDefaultPriorityChannels;

@end

NS_ASSUME_NONNULL_END
