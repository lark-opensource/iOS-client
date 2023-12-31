//
//  EMADebuggerMetaCommand.h
//  EEMicroAppSDK
//
//  Created by yinyuan on 2019/7/29.
//

#import "EMADebuggerCommand.h"

NS_ASSUME_NONNULL_BEGIN

@interface EMADebuggerMetaCommand : EMADebuggerCommand

@property (nonatomic, copy) NSString *phoneBrand;
@property (nonatomic, copy) NSString *appName;
@property (nonatomic, copy) NSString *appId;

@end

NS_ASSUME_NONNULL_END
