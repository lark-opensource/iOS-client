/*
 File: TTReachability.h
 Abstract: Basic demonstration of how to use the SystemConfiguration Reachablity APIs.
 Version: 3.5
 
 Disclaimer: IMPORTANT:  This Apple software is supplied to you by Apple
 Inc. ("Apple") in consideration of your agreement to the following
 terms, and your use, installation, modification or redistribution of
 this Apple software constitutes acceptance of these terms.  If you do
 not agree with these terms, please do not use, install, modify or
 redistribute this Apple software.
 
 In consideration of your agreement to abide by the following terms, and
 subject to these terms, Apple grants you a personal, non-exclusive
 license, under Apple's copyrights in this original Apple software (the
 "Apple Software"), to use, reproduce, modify and redistribute the Apple
 Software, with or without modifications, in source and/or binary forms;
 provided that if you redistribute the Apple Software in its entirety and
 without modifications, you must retain this notice and the following
 text and disclaimers in all such redistributions of the Apple Software.
 Neither the name, trademarks, service marks or logos of Apple Inc. may
 be used to endorse or promote products derived from the Apple Software
 without specific prior written permission from Apple.  Except as
 expressly stated in this notice, no other rights or licenses, express or
 implied, are granted by Apple herein, including but not limited to any
 patent rights that may be infringed by your derivative works or by other
 works in which the Apple Software may be incorporated.
 
 The Apple Software is provided by Apple on an "AS IS" basis.  APPLE
 MAKES NO WARRANTIES, EXPRESS OR IMPLIED, INCLUDING WITHOUT LIMITATION
 THE IMPLIED WARRANTIES OF NON-INFRINGEMENT, MERCHANTABILITY AND FITNESS
 FOR A PARTICULAR PURPOSE, REGARDING THE APPLE SOFTWARE OR ITS USE AND
 OPERATION ALONE OR IN COMBINATION WITH YOUR PRODUCTS.
 
 IN NO EVENT SHALL APPLE BE LIABLE FOR ANY SPECIAL, INDIRECT, INCIDENTAL
 OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
 SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
 INTERRUPTION) ARISING IN ANY WAY OUT OF THE USE, REPRODUCTION,
 MODIFICATION AND/OR DISTRIBUTION OF THE APPLE SOFTWARE, HOWEVER CAUSED
 AND WHETHER UNDER THEORY OF CONTRACT, TORT (INCLUDING NEGLIGENCE),
 STRICT LIABILITY OR OTHERWISE, EVEN IF APPLE HAS BEEN ADVISED OF THE
 POSSIBILITY OF SUCH DAMAGE.
 
 Copyright (C) 2014 Apple Inc. All Rights Reserved.
 
 */

#import <Foundation/Foundation.h>
#import <netinet/in.h>
@class CTCarrier;

NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM(NSInteger, NetworkStatus) {
    NotReachable = 0,
    ReachableViaWiFi,
    ReachableViaWWAN
};

typedef NS_ENUM(NSInteger, TTNetworkAuthorizationStatus) {
    // 程序无法判断出 App 的网络权限设置
    TTNetworkAuthorizationStatusNotDetermined = 0,
    // App 未开启蜂窝数据网络权限（仅允许使用WiFi连接）
    TTNetworkAuthorizationStatusCellularNotPermitted,
    // App 未开启无线局域网与蜂窝移动网络权限，此项仅可能在国行 iPhone 手机上出现（不允许使用网络连接）
    TTNetworkAuthorizationStatusWLANAndCellularNotPermitted
};

/**
 移动网络连接类型
 
 - TTCellularNetworkConnectionNone: 无连接
 - TTCellularNetworkConnectionUnknown: 未知类型
 - TTCellularNetworkConnection2G: 2G网络
 - TTCellularNetworkConnection3G: 3G网络
 - TTCellularNetworkConnection4G: 4G网络
 - TTCellularNetworkConnection5G: 5G网络
 */
typedef NS_ENUM(int32_t, TTCellularNetworkConnectionType) {
    TTCellularNetworkConnectionNone = 0,
    TTCellularNetworkConnectionUnknown,
    TTCellularNetworkConnection2G,
    TTCellularNetworkConnection3G,
    TTCellularNetworkConnection4G,
    TTCellularNetworkConnection5G
};

/**
 在搭载iOS 12+的iPhone XS Max和iPhone XR，支持了双SIM卡，因此当前蜂窝状态和和具体某张卡绑定的。每一种卡，在苹果的API概念里面叫做一个service。原来的is2GConnected等接口，可以传入关心的service来判定具体某张卡的蜂窝状态
 */
typedef NS_ENUM(NSInteger, TTCellularServiceType) {
    TTCellularServiceTypePrimary = 1, // 主卡状态
    TTCellularServiceTypeSecondary = 2, // 副卡状态
};

/**
 在reachability的状态发生变化时发送，注意通知不在主线程触发
 */
FOUNDATION_EXPORT NSNotificationName TTReachabilityChangedNotification;

@interface TTReachability : NSObject

/**
 当前连通性判断的域名，如果以IP Address初始化则为nil
 */
@property (nonatomic, copy, readonly, nullable) NSString *hostName;

/**
当前连通性判断的IP Address（从sockaddr_in解得），如果以域名初始化则为nil
*/
@property (nonatomic, copy, readonly, nullable) NSString *hostAddress;

/**
 当前连通性判断，是否采取了默认连接（非指定Host），实际等价于判断hostAddress是否为0.0.0.0
 */
@property (nonatomic, assign, readonly, getter=isInternetConnection) BOOL internetConnection;

/**
 判断指定域名的连通性

 @param hostName 域名
 @return TTReachability对象
 */
+ (instancetype)reachabilityWithHostName:(NSString *)hostName;


/**
 判断指定IP地址的连通性

 @param hostAddress IP地址
 @return TTReachability对象
 */
+ (instancetype)reachabilityWithAddress:(const struct sockaddr_in *)hostAddress;

/**
 返回单例，用于判断本地网络连接的连通性（而非连接到具体的某个IP或者域名）
 此接口相当于只考虑网卡连通，不考虑丢包（100%丢包也算），实际等价于判断0.0.0.0的IP的连通性
 @note 历史上曾经这个接口返回的是实例对象，但是现在返回的对象为单例，直接调用实例方法获取各种状态即可。避免重复的多个通知出现
 @note 单例会使用mainRunLoop和defaultMode监听连通性通知，如果需要定制，可单例初始化前赋值`internetConnectionNotifyRunLoop`和`internetConnectionNotifyRunLoopMode`

 @return TTReachability对象
 */
+ (instancetype)reachabilityForInternetConnection;

/**
 开始在当前runloop监听连通性通知
 @note 对于InternetConnection的单例对象调用无效，如果需要单独检测本机网络连接，请使用0.0.0.0地址初始化一个对象再调用

 @return 是否成功开始监听
 */
- (BOOL)startNotifier;


/**
 结束监听连通性通知
 @note 对于InternetConnection的单例对象调用无效，如果需要单独检测本机网络连接，请使用0.0.0.0地址初始化一个对象再调用
 */
- (void)stopNotifier;


/**
 当前连通性状态

 @return NetworkStatus枚举值
 */
- (NetworkStatus)currentReachabilityStatus;

/**
 是否需要连接。如WWAN需要首先建立一个可用连接才能被激活。WiFi可能需要一个VPN连接等

 @return 是否需要连接
 */
- (BOOL)connectionRequired;


/**
 获取 App 当前的网络权限设置状态
 
 因苹果尚未提供网络权限判断的 API，此方法目前只是在网络 NotReachable 时检查系统连接状态，
 利用排除法推断出 App 当前没有 蜂窝数据网络权限 或者 WIFI及蜂窝数据网络权限，排除原理参见
 https://wiki.bytedance.net/pages/viewpage.action?pageId=107808003
 
 在其它情况下（例如网络 Reachable 或者飞行模式）均返回 CantDetermined，上层业务调用方需注意

 @return 参见 TTNetworkAuthorizationStatus 定义
 */
- (TTNetworkAuthorizationStatus)currentNetworkAuthorizationStatus;

@end

#if TARGET_OS_IOS
/// 蜂窝相关方法，只有iOS平台存在
@interface TTReachability (Cellular)

/**
 @return 网络是否可以联调
 */
+ (BOOL)isNetworkConnected;

/**
 2G网络是否连通，仅主卡
 @warning 对于双卡设备，如果用户选择了蜂窝数据网络为副卡且主卡不可用，此接口永远返回为NO（苹果旧版API行为也如此），但实际上可以进行网络请求，建议针对双卡设备单独适配（通过currentAvailableServices和新接口组合使用）

 @return 是否连通
 */
+ (BOOL)is2GConnected;

/**
 3G网络是否连通，仅主卡
 @warning 对于双卡设备，如果用户选择了蜂窝数据网络为副卡且主卡不可用，此接口永远返回为NO（苹果旧版API行为也如此），但实际上可以进行网络请求，建议针对双卡设备单独适配（通过currentAvailableServices和新接口组合使用）
 
 @return 是否连通
 */
+ (BOOL)is3GConnected;

/**
 4G网络是否连通，仅主卡
 @warning 对于双卡设备，如果用户选择了蜂窝数据网络为副卡且主卡不可用，此接口永远返回为NO（苹果旧版API行为也如此），但实际上可以进行网络请求，建议针对双卡设备单独适配（通过currentAvailableServices和新接口组合使用）
 
 @return 是否连通
 */
+ (BOOL)is4GConnected;

/**
 5G网络是否连通，仅主卡
 @warning 对于双卡设备，如果用户选择了蜂窝数据网络为副卡且主卡不可用，此接口永远返回为NO（苹果旧版API行为也如此），但实际上可以进行网络请求，建议针对双卡设备单独适配（通过currentAvailableServices和新接口组合使用）
 
 @return 是否连通
 */
+ (BOOL)is5GConnected;

/**
 指定SIM卡的2G网络是否连通，对iOS 12以下设备只处理主卡
 
 @param service 指定的SIM卡服务
 @return 是否连通
 */
+ (BOOL)is2GConnectedForService:(TTCellularServiceType)service;

/**
 指定SIM卡的3G网络是否连通，对iOS 12以下设备只处理主卡
 
 @param service 指定的SIM卡服务
 @return 是否连通
 */
+ (BOOL)is3GConnectedForService:(TTCellularServiceType)service;

/**
 指定SIM卡的4G网络是否连通，对iOS 12以下设备只处理主卡
 
 @param service 指定的SIM卡服务
 @return 是否连通
 */
+ (BOOL)is4GConnectedForService:(TTCellularServiceType)service;

/**
 指定SIM卡的5G网络是否连通，对iOS 12以下设备只处理主卡，仅iOS 14.1+的iPhone 12系列有效
 
 @param service 指定的SIM卡服务
 @return 是否连通
 */
+ (BOOL)is5GConnectedForService:(TTCellularServiceType)service;

/**
 指定SIM卡的当前蜂窝数据制式类型，对iOS 12以下设备只处理主卡
 
 @param service 指定的SIM卡服务
 @return 当前蜂窝数据制式类型
 @note 正常情况下不会返回.none，只有在初始化阶段，或者所有SIM卡都不可用的时候，有这个状态
 */
+ (TTCellularNetworkConnectionType)currentCellularConnectionForService:(TTCellularServiceType)service;

/**
 返回当前用户配置的流量卡的当前蜂窝数据制式类型，利用iOS 13的API获取
 @note 对iOS 12设备设备暂时无法返回，永远为.none
 
 @return 当前蜂窝数据制式类型
 @note 如果获取不到哪张流量卡，也会返回.none，注意这个情景
 */
+ (TTCellularNetworkConnectionType)currentCellularConnectionForDataService;

/**
 指定SIM卡的当前蜂窝服务提供商的相关信息，对iOS 12以下设备只处理主卡
 后续可以通过`CTCarrier.carrierName`获取运营商名（如"中国联通"），MCC，MNC等信息

 @param service 指定的SIM卡服务
 @return 当前蜂窝服务提供商的信息，如果指定SIM卡不可用，会返回nil
 */
+ (nullable CTCarrier *)currentCellularProviderForService:(TTCellularServiceType)service;

/**
 返回当前用户配置的流量卡的SIM卡对应的CTCarrier对象。利用iOS 13的API获取
 @note 对iOS 12设备设备暂时无法返回，永远为nil
 
 @return 当前用户配置的流量卡的SIM卡蜂窝服务提供商的信息，如果不可获取，返回nil
 */
+ (nullable CTCarrier *)currentCellularProviderForDataService;

/**
指定SIM卡的详细蜂窝制式信息（CTRadioAccessTechnology），对iOS 12以下设备只处理主卡

@return 当前用户配置的流量卡的蜂窝制式信息，如果不可获取，返回nil
*/
+ (nullable NSString *)currentRadioAccessTechnologyForService:(TTCellularServiceType)service;

/**
 返回当前用户配置的流量卡的详细蜂窝制式信息（CTRadioAccessTechnology），利用iOS 13的API获取
@note 对iOS 12设备设备暂时无法返回，永远为nil

@return 当前用户配置的流量卡的蜂窝制式信息，如果不可获取，返回nil
*/
+ (nullable NSString *)currentRadioAccessTechnologyForDataService;

/**
 返回当前所有可用的SIM卡服务列表，可以理解为SIM卡可用性检测，iOS 12以下也可以用
 单卡设备会返回[.primary]，如果是双卡设备且双卡均可用，这里会返回[.primary, .secondary]，仅副卡可用就返回[.secondary]，无任何SIM卡可用时返回空数组

 @return 当前可用的SIM卡服务数组，每个元素为TTCellularServiceType枚举，不为空
 */
+ (NSArray<NSNumber *> *)currentAvailableCellularServices;

/**
 返回当前所有可用的SIM卡的CTCarrier列表，这个和上面的API的区别在于，上面的API如果SIM卡服务在本地区不可用（美国SIM卡插入国行机器），会返回空，而这个会返回具体的CTCarrier对象。iOS 12以下也可以用
 
 @return 当前可用的SIM卡CTCarrier数组，每个元素为CTCarrier对象，不为空
 */
+ (NSArray<CTCarrier *> *)currentAvailableCellularProviders;

@end
#endif

@interface TTReachability (Config)

/**
 用于指定TTReachability的联通状态缓存的更新间隔（秒）的Block，默认为nil；当Block返回值为非负数时，会开启状态缓存，并且设置检查间隔
 */
@property (nonatomic, class, nullable) double (^statusCacheConfigBlock)(void);
/**
 用于指定internetConnection单例的Notify RunLoop，不传表示默认为mainRunLoop
 */
@property (nonatomic, class, nullable) NSRunLoop *internetConnectionNotifyRunLoop;
/**
用于指定internetConnection单例的Notify RunLoop Mode，不传表示默认为NSDefaultRunLoopMode
*/
@property (nonatomic, class, nullable) NSRunLoopMode internetConnectionNotifyRunLoopMode;

@end

NS_ASSUME_NONNULL_END
