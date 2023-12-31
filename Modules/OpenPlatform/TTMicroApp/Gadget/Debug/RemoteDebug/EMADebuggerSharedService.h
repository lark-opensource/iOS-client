//
//  EMADebuggerSharedService.h
//  TTMicroApp
//
//  Created by baojianjun on 2023/5/29.
//

#import <Foundation/Foundation.h>
#import "EMADebuggerCommand.h"
#import <OPFoundation/BDPUniqueID.h>

NS_ASSUME_NONNULL_BEGIN

@protocol EMADebuggerSharedService <NSObject>

/// 处理 wsURL 调用
- (void)handleDebuggerWSURL:(NSString * _Nonnull)wsURL;

/// 推送命令
- (void)pushCmd:(EMADebuggerCommand * _Nonnull)cmd forUniqueID:(BDPUniqueID * _Nonnull)uniqueID;

@end

NS_ASSUME_NONNULL_END
