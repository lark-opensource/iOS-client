//
//  BDPOfflineZipManager.h
//  Pods
//
//  Created by laichengfeng on 2019/8/1.
//

@interface BDPOfflineZipManager : NSObject

/**
* 安装本地内置离线包
*/
+ (void)setupDefaultOfflineZipIfNeed;

/**
 * 更新离线包
 */
+ (void)updateOfflineZipIfNeed;

@end
