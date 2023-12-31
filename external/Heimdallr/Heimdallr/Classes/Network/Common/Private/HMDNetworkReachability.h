//
//  HMDNetworkReachability.h
//  Heimdallr
//
//  Created by fengyadong on 2018/1/26.
//

#import <Foundation/Foundation.h>

typedef NS_OPTIONS(NSInteger, HMDNetworkFlags) {
    HMDNetworkFlagWifi   = 1,
    HMDNetworkFlag4G     = 1 << 1,
    HMDNetworkFlag3G     = 1 << 2,
    HMDNetworkFlag2G     = 1 << 3,
    HMDNetworkFlagMobile = 1 << 4
};

extern HMDNetworkFlags HMDNetworkGetFlags(void);

@interface HMDNetworkReachability : NSObject

/**
 * @brief 当前网络是否联通的
 */
+ (BOOL)isConnected;

/**
 * @brief 是否是通过wifi链接的
 */
+ (BOOL)isWifiConnected;

/**
 * @brief 是否有蜂窝网络连接，注: 此方法与是否有 wifi 连接并不互斥，即用户移动网络和 wifi 都连接的情况下，此方法也会返回 YES
 */
+ (BOOL)isCellPhoneConnected;

/**
 @brief 仅对 ios >= 7.0有效，对于ios <= 6.0, 返回 TTNetowrkCellPhoneConnected(void)
 */
+ (BOOL)is2GConnected;

/**
 @brief 仅对 ios >= 7.0有效，对于ios <= 6.0, 返回 NO
 */
+ (BOOL)is3GConnected;

/**
 @brief 仅对 ios >= 7.0有效，对于ios <= 6.0, 返回 NO
 */
+ (BOOL)is4GConnected;

/**
5G网络是否连通，仅主卡
@warning 对于双卡设备，如果用户选择了蜂窝数据网络为副卡且主卡不可用，此接口永远返回为NO（苹果旧版API行为也如此），但实际上可以进行网络请求，建议针对双卡设备单独适配（通过currentAvailableServices和新接口组合使用）

@return 是否连通
*/
+ (BOOL)is5GConnected;

/**
 检查 App 是否关闭了蜂窝数据网络权限
 对于国行 iPhone，如果设置成 关闭无线局域网和蜂窝数据网络，也认为关闭了蜂窝数据网络权限
 
 注：Apple 未提供 App 网络权限状态的 API，HMDNetworkIsCellularDisabled() 和
 HMDNetworkIsCellularAndWLANDisabled() 都是通过排除法确定是否关闭了权限，
 仅在 App 无法联网时方便上层业务逻辑给用户相应提示。
 
 @return 返回 YES 表示准确检测出 App 关闭了权限，返回 NO 表示无法准确检测，不代表 App 没有关闭权限
 */
+ (BOOL)isCellularDisabled;

/**
 检查 App 是否关闭了无线局域网和蜂窝数据网络权限（国行 iPhone 特供功能）
 
 @return 返回 YES 表示准确检测出 App 关闭了权限，返回 NO 表示无法准确检测，不代表 App 没有关闭权限
 */
+ (BOOL)isCellularAndWLANDisabled;

/**
 *@brief 两个特殊函数，这个将有queue使用
 *       注意回调函数要线程安全处理。
 */
+ (void)startNotifier;
+ (void)stopNotifier;

@end
