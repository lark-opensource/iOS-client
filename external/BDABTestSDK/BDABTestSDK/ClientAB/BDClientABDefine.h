//
//  BDClientABDefine.h
//  ABTest
//
//  Created by ZhangLeonardo on 16/1/24.
//  Copyright © 2016年 ZhangLeonardo. All rights reserved.
//

#import <Foundation/Foundation.h>

#ifndef BDClientABDefine_h
#define BDClientABDefine_h

#ifndef isEmptyString_forABManager
#define isEmptyString_forABManager(str) (!str || ![str isKindOfClass:[NSString class]] || str.length == 0)
#endif

/**
 *  版本比较
 */
typedef NS_ENUM(NSUInteger, BDClientABVersionCompareType) {
    /**
     *  左边的版本号小于右边的版本号
     */
    BDClientABVersionCompareTypeLessThan,
    /**
     *  左边的版本号等于右边的版本号
     */
    BDClientABVersionCompareTypeEqualTo,
    /**
     *  左边的版本号大于右边的版本号
     */
    BDClientABVersionCompareTypeGreateThan
};


#endif
