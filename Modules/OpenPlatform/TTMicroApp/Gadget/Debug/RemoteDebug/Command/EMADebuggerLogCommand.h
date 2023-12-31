//
//  EMADebuggerLogCommand.h
//  EEMicroAppSDK
//
//  Created by yinyuan on 2019/7/23.
//

#import "EMADebuggerCommand.h"

NS_ASSUME_NONNULL_BEGIN

@interface EMADebuggerLogCommand : EMADebuggerCommand

@property (nonatomic, copy) NSString *timestamp;
@property (nonatomic, copy) NSString *level;
@property (nonatomic, copy) NSString *tag;
@property (nonatomic, copy) NSString *content;
@property (nonatomic, copy) NSString *appId;
@property (nonatomic, copy) NSString *appName;

@end

NS_ASSUME_NONNULL_END
