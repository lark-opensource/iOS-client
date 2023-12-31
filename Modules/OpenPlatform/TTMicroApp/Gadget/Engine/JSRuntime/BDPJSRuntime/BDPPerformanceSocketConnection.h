//
//  BDPPerformanceSocketConnection.h
//  TTMicroApp
//
//  Created by ChenMengqi on 2022/12/12.
//

#import <Foundation/Foundation.h>
#import "BDPPerformanceSocketMessage.h"

NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM(NSUInteger, BDPPerformanceSocketStatus) {
    BDPPerformanceSocketStatusDisconnected = 0, // 未连接
    BDPPerformanceSocketStatusConnecting,   // 连接中
    BDPPerformanceSocketStatusConnected,    // 已连接
    BDPPerformanceSocketStatusFailed,     // 连接失败
};

@class BDPPerformanceSocketConnection;

@protocol BDPPerformanceSocketConnectionDelegate <NSObject>

@required

- (void)connection:(BDPPerformanceSocketConnection *)connection statusChanged:(BDPPerformanceSocketStatus)status;
- (void)connection:(BDPPerformanceSocketConnection *)connection didReceiveMessage:(BDPPerformanceSocketMessage *)message;

@optional
- (void)socketDidConnected;
- (void)socketDidFailWithError:(NSError *)error;
- (void)socketDidCloseWithCode:(NSInteger)code reason:(NSString *)reason wasClean:(BOOL)wasClean;

@end


@interface BDPPerformanceSocketConnection : NSObject

@property (nonatomic, assign, readonly) BDPPerformanceSocketStatus status;

+ (instancetype)createConnectionWithAddress:(NSString *)address
                                   delegate:(id<BDPPerformanceSocketConnectionDelegate>)delegate;

// 开始连接
- (void)connect;
// 断开连接，
- (void)disConnect;
// 发送消息，
- (BOOL)sendMessage:(BDPPerformanceSocketMessage *)message;

@end

NS_ASSUME_NONNULL_END
