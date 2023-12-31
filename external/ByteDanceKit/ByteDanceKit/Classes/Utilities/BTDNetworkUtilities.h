//
//  Created by David Alpha Fox on 3/8/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <Foundation/Foundation.h>

/**
 * @file NetworkUtilites
 * @author David<gaotianpo@songshulin.net>
 *
 * @brief 网络辅助工具
 * 
 * @details 网络辅助工具
 * 
 */

typedef NS_OPTIONS(NSInteger, BTDNetworkFlags) {
    BTDNetworkFlagWifi   = 1,
    BTDNetworkFlag4G     = 1 << 1,
    BTDNetworkFlag3G     = 1 << 2,
    BTDNetworkFlag2G     = 1 << 3,
    BTDNetworkFlagMobile = 1 << 4
};

extern BTDNetworkFlags BTDNetworkGetFlags(void);

/**
 * @brief 当前网络是否联通的
 */
BOOL BTDNetworkConnected(void);

/**
 * @brief 是否是通过wifi链接的
 */
BOOL BTDNetworkWifiConnected(void);

/**
 * @brief 是否是通过蜂窝网链接的
 */
BOOL BTDNetworkCellPhoneConnected(void);

/**
 @brief 仅对 ios >= 7.0有效，对于ios <= 6.0, 返回 SSNetowrkCellPhoneConnected(void)
 */
BOOL BTDNetwork2GConnected(void);

/**
 @brief 仅对 ios >= 7.0有效，对于ios <= 6.0, 返回 NO
 */
BOOL BTDNetwork3GConnected(void);

/**
 @brief 仅对 ios >= 7.0有效，对于ios <= 6.0, 返回 NO
 */
BOOL BTDNetwork4GConnected(void);

/**
 *@brief 开启、关闭网络状态观察
 *
 */
void BTDNetworkStartNotifier(void);
void BTDNetworkStopNotifier(void);


@interface BTDNetworkUtilities : NSObject

+ (BOOL)is2GConnected NS_AVAILABLE_IOS(7_0);
+ (BOOL)is3GConnected NS_AVAILABLE_IOS(7_0);
+ (BOOL)is4GConnected NS_AVAILABLE_IOS(7_0);
+ (NSString*)connectMethodName;
+ (NSString*)addressOfHost:(NSString*)host;

@end
