//
//  AllLoadCost.h
//  AllLoadCost
//
//  Created by CL7R on 2020/7/15.
//  Copyright © 2020 CL7R. All rights reserved.
//

#import <Foundation/Foundation.h>

//! Project version number for AllLoadCost.
FOUNDATION_EXPORT double AllLoadCostVersionNumber;

//! Project version string for AllLoadCost.
FOUNDATION_EXPORT const unsigned char AllLoadCostVersionString[];

// In this header, you should import all the public headers of your framework using statements like #import <AllLoadCost/PublicHeader.h>

@interface AllLoadCost: NSObject


/// 查询+load耗时
+ (NSDictionary *)queryAllLoadCost;
@end
