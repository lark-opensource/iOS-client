//
//  BDPAppPage+TMAPullRefresh.h
//  Timor
//
//  Created by muhuai on 2018/1/18.
//  Copyright © 2018年 muhuai. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "BDPAppPage.h"
#import "UIScrollView+TMARefresh.h"

///  非BDPAppPage请勿调用这里的方法
@interface BDPAppPage (BDPPullRefresh)

- (void)bdp_enablePullToRefresh;
- (void)bap_registerPullToRefreshWithUniqueID:(OPAppUniqueID *)uniqueID;

@end
