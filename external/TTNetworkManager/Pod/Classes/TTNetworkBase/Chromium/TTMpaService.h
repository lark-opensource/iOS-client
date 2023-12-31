//
//  TTMpaService.h
//  TTNetworkManager
//
//  Created by changxing on 2021/9/28.
//

#ifndef TTMpaService_h
#define TTMpaService_h

#import <Foundation/Foundation.h>

/**
 *  双通道初始化回调接口。
 *
 *  @param isSuccess 初始化是否成功。
 *  @param extraMsg 额外透传信息，用于问题排查。
 */
typedef void (^ICallback)(BOOL isSuccess, NSString* extraMsg);

@interface TTMpaService : NSObject
/**
 *  生成TTMpaService单例。
 *
 *  @return TTMpaService单例。
 */
+ (instancetype)shareInstance;

/**
 *  双通道功能初始化。
 *
 *  @param callback 初始化接口，双通道初始化完成后调用方可调用其他接口。
 */
- (void)init:(ICallback)callback;

/**
 *  设置业务server地址。
 *
 *  @param address 业务server地址列表，格式ip:port。
 *  @param callback 设置server地址回调接口。
 */
- (void)setAccAddress:(NSArray<NSString*>*)address callback:(ICallback)callback;

/**
 *  开启加速，对战开始时调用。
 *
 *  @param userLog 用户自定义beginLog，用于埋点上报。
 */
- (void)start:(NSString*)userLog;

/**
 *  关闭加速，对战结束时调用。
 *
 *  @param userLog 用户自定义endLog，用于埋点上报。
 */
- (void)stop:(NSString*)userLog;

@end

#endif /* TTMpaService_h */
