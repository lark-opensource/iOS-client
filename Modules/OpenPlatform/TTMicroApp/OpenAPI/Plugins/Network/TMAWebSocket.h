//
//  TMAWebSocket.h
//  TTMicroApp
//
//  Created by ByteDance on 2023/11/21.
//

#import <SocketRocket/SocketRocket.h>
#import "TMAPluginNetworkDefines.h"

NS_ASSUME_NONNULL_BEGIN

@interface TMAWebSocket : SRWebSocket

@property (nonatomic, assign) SocketCloseType closeCode;

@end

NS_ASSUME_NONNULL_END
