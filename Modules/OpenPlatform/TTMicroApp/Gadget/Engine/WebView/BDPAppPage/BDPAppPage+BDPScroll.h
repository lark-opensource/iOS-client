//
//  BDPAppPage+BDPScroll.h
//  Timor
//
//  Created by liuxiangxin on 2019/4/15.
//

#import "BDPAppPage.h"

NS_ASSUME_NONNULL_BEGIN

///  非BDPAppPage请勿调用这里的方法
@interface BDPAppPage (BDPScroll)

- (void)bdp_setupPageObserver;
- (void)bdp_removePageObserver;

@end

NS_ASSUME_NONNULL_END
