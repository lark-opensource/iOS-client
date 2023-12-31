//
//  TTReachability+Network.h
//  TTReachability
//
//  Created by 李卓立 on 2020/2/17.
//

#import "TTReachability.h"

@interface TTReachability (Network)

typedef NS_ENUM(NSInteger, TTNetworkProtocolType) {
    // IPv4
    TTNetworkProtocolTypeIPv4 = 0,
    // IPv6
    TTNetworkProtocolTypeIPv6 = 1
};

/**
 获取当前设备的所有端口的IP地址，每个key为"端口名/IP协议类型"，Value为对应IP地址的字符串，支持IPv6
 比如获取Wi-Fi的IPv4地址，对应的Key就叫做"en0/ipv4"，Value为"192.168.1.1"。如果找不到任何IP地址，返回空字典
 @note 实现利用了系统调用getifaddrs，支持所有场景（包括VPN），性能开销低
 */
+ (nonnull NSDictionary<NSString *, NSString *> *)currentIPAddresses;

/**
 给定一个域名（或者服务名），获取它对应的IP地址（DNS解析后）
 比如给定"www.baidu.com"，如果当前设备以IPv4连接，返回"61.135.169.121"；IPv6连接，返回"2408:8000:1010:1::8"。如果解析失败，返回空字符串
 @note 实现利用了系统调用getaddrinfo，支持所有场景（包括VPN），有一定性能开销，用的时候注意
 */
+ (nonnull NSString *)IPAddressOfHostName:(nonnull NSString *)hostname;

/**
给定一个域名（或者服务名），并且给定协议类型，获取它对应的IP地址（DNS解析后）
比如给定"www.baidu.com"，指定协议类型IPv4，返回"61.135.169.121"；IPv6，返回"2408:8000:1010:1::8"。协议如果解析失败，或者协议不支持，返回空字符串
@note 实现利用了系统调用getaddrinfo，支持所有场景（包括VPN），有一定性能开销，用的时候注意
*/
+ (nonnull NSString *)IPAddressOfHostName:(nonnull NSString *)hostname protocolType:(TTNetworkProtocolType)protocolType;

@end
