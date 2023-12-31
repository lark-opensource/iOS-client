//
//  TTExpDiagnosisService.h
//  TTNetworkManager
//
//  Created by zhangzeming on 2021/6/14.
//  Copyright © 2021 bytedance. All rights reserved.
//

#ifndef TTExpDiagnosisService_h
#define TTExpDiagnosisService_h

#import <Foundation/Foundation.h>
#import "TTExpDiagnosisCallback.h"
#import "TTExpDiagnosisRequestProtocol.h"

typedef NS_ENUM(int, TTExpRequestType) {
    // 向指定目标地址发起DNS解析任务，结果通过回调以JSON字符串返回。
    DNS_RESOLVE_TARGET = 0,
    
    // 对输入的若干目标地址发起竞速任务，竞速结果通过回调以JSON字符串返回。
    RACE_TARGETS = 1,
    
    // 对输入的目标地址发起就近加速任务。首先会对目标地址发起DNS解析，如果
    // TNC下发了配置需要对目标地址的解析结果做就近加速，那么会对解析出来的
    // IP发起竞速。最终结果通过回调已JSON字符串返回。
    ACCELERATE_TARGET = 2,
    
    // 首先对输入目标发起Trace Route，然后获取第一跳、倒数第二跳、最后一跳的
    // 信息。如果是WiFi网络，还会返回第一个公网IP跳的信息。结果通过回调以JSON
    // 字符串返回。
    DIAGNOSE_TARGET = 3,

    // 首先对输入目标发起Trace Route，然后获取第一跳、倒数第二跳、最后一跳的
    // 信息。然后对TNC下发的目标地址周期性地测速，如果发现测速结果跳变，则对
    // Trace Route获取的关键节点发起ICMP Ping诊断。
    DIAGNOSE_V2_TARGET = 4,

    // 直接执行指定类型的探测任务，并发量和任务超时时间由TNC控制。
    RAW_DETECT_TARGETS = 5,
};

typedef NS_ENUM(int, TTExpNetDetectType) {
    // 用HTTP GET发起网络探测，根据TTFB打分。TTFB越小分越高，目标地址会在结果中排越前面。
    NET_DETECT_HTTP_GET = 1 << 0,

    // 用ICMP ping发起网络探测，根据RTT和丢包率综合打分。综合分越小分越高，目标地址会在结果中排越前面。
    NET_DETECT_ICMP_PING = 1 << 1,

    // 用ICMP包发起Traceroute网络探测。
    NET_DETECT_TRACEROUTE = 1 << 2,

    // 进行本地域名解析探测。
    NET_DETECT_LOCAL_DNS = 1 << 3,

    // 用UDP ping发起网络探测，根据RTT和丢包率综合打分。综合分越小分越高，目标地址会在结果中排越前面。
    NET_DETECT_UDP_PING = 1 << 6,

    // 进行全策略的域名解析探测。
    NET_DETECT_FULL_DNS = 1 << 7,

    // 发起TCP连接进行Connect请求探测。
    NET_DETECT_TCP_CONNECT = 1 << 8,

    // 向指定服务端发起TCP连接，进行Echo回包探测。
    NET_DETECT_TCP_ECHO = 1 << 9,

    // 向指定服务端发起UDP Perf打流探测。
    NET_DETECT_UDP_PERF = 1 << 10,

    // 向指定服务端发起TCP Perf打流探测。
    NET_DETECT_TCP_PERF = 1 << 11,

    // 发起HTTP请求探测多ISP出口。
    NET_DETECT_HTTP_ISP = 1 << 12,

    NET_DETECT_ALL = ~0x0,
};

typedef NS_ENUM(int, TTExpMultiNetAction) {
    // 不强制指定网络通道，接受TTNet的网络调度策略，multiNetAction默认为此值。
    ACTION_UNSPECIFIED = 0,
    // 强制指定使用移动数据网络发送探测。
    ACTION_FORCE_CELLULAR = 1,
    // 强制指定使用WIFI网络发送探测。
    ACTION_FORCE_WIFI = 2,
    // 强制指定使用系统默认网络发送探测，TTNet的网络调度策略失效。
    ACTION_FORCE_DEFAULT =3,
};

@interface TTExpDiagnosisService : NSObject

/**
 *  生成TTExpDiagnosisService单例
 *
 *  @return TTExpDiagnosisService单例
 */
+ (instancetype)shareInstance;


/**
 * 创建网络体验探测请求。DNS、Acceleration、Diagnose类型的请求调用此接口。
 * 网络类型默认是ACTION_UNSPECIFIED，即不强制指定网络通道，接受TTNet的网络调度策略。
 * @param reqType 请求类型，详见TTExpRequestType枚举。
 * @param target 网络体验探测目标地址。
 * @param netDetectType 网络体验探测类型。只有Race和Acceleration两种类型的任务需要传入此参数。
 *                      其他类型任务下传递此参数会被忽略。
 * @param timeoutMs 请求超时时间。请求都是异步进行，如果超时，则执行回调。
 * @param callback 探测请求结束之后的回调。 
 *
 * @return NSObject<TTExpDiagnosisRequestProtocol>*
 * 由调用者负责持有和管理请求对象。如果传参异常，或者TTNet还未初始化完毕就调用，则返回nil。
 * 如果对象内存被释放，那么探测请求也会结束。
 */
- (NSObject<TTExpDiagnosisRequestProtocol>*)createRequestWithReqestType:(TTExpRequestType)reqType
                                                                 target:(NSString*)target
                                                          netDetectType:(TTExpNetDetectType)netDetectType
                                                              timeoutMs:(int64_t)timeoutMs
                                                               callback:(DiagnosisCallback)callback;

/**
 * 创建网络体验探测请求。DNS、Acceleration、Diagnose类型的请求调用此接口。
 * @param reqType 请求类型，详见TTExpRequestType枚举。
 * @param target 网络体验探测目标地址。
 * @param netDetectType 网络体验探测类型。只有Race和Acceleration两种类型的任务需要传入此参数。
 *                      其他类型任务下传递此参数会被忽略。
 * @param timeoutMs 请求超时时间。请求都是异步进行，如果超时，则执行回调。
 * @param multiNetAction 用于指定体验探测的网络类型。当前仅DIAGNOSE_TARGET任务类型支持指定网络。
 * @param callback 探测请求结束之后的回调。
 *
 * @return NSObject<TTExpDiagnosisRequestProtocol>*
 * 由调用者负责持有和管理请求对象。如果传参异常，或者TTNet还未初始化完毕就调用，则返回nil。
 * 如果对象内存被释放，那么探测请求也会结束。
 */
- (NSObject<TTExpDiagnosisRequestProtocol>*)createRequestWithReqestType:(TTExpRequestType)reqType
                                                                 target:(NSString*)target
                                                          netDetectType:(TTExpNetDetectType)netDetectType
                                                         multiNetAction:(TTExpMultiNetAction)multiNetAction
                                                              timeoutMs:(int64_t)timeoutMs
                                                               callback:(DiagnosisCallback)callback;

/**
 * 创建网络体验探测请求。
 * Race类型请求调用此接口。
 * @param reqType 请求类型，详见TTExpRequestType枚举。
 * @param targets 网络体验探测目标地址列表。
 * @param netDetectType 网络体验探测类型。只有Race和Acceleration两种类型的任务需要传入此参数。
 *                      其他类型任务下传递此参数会被忽略。
 * @param timeoutMs 请求超时时间。请求都是异步进行，如果超时，则执行回调。
 * @param callback 探测请求结束之后的回调。
 *
 * @return NSObject<TTExpDiagnosisRequestProtocol>*
 * 由调用者负责持有和管理请求对象。如果传参异常，或者TTNet还未初始化完毕就调用，则返回nil。
 * 如果对象内存被释放，那么探测请求也会结束。
 */
- (NSObject<TTExpDiagnosisRequestProtocol>*)createRequestWithReqestType:(TTExpRequestType)reqType
                                                                targets:(NSArray<NSString*>*)targets
                                                          netDetectType:(TTExpNetDetectType)netDetectType
                                                              timeoutMs:(int64_t)timeoutMs
                                                               callback:(DiagnosisCallback)callback;

/**
 * 用户自定义的日志上报接口。
 * @param log 日志内容。可以是JSON字符串，也可以是任意字符串形式。建议用JSON字符串。
 */
- (void)reportUserLog:(NSString*)log;
@end


#endif /* TTExpDiagnosisService_h */
