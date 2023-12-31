//
//  BDPAppPageController+BDPSafeArea.h
//  Timor
//
//  Created by changrong on 2020/9/2.
//

#import <Foundation/Foundation.h>
#import "BDPAppPageController.h"

NS_ASSUME_NONNULL_BEGIN

@interface BDPNaviBarSafeArea : NSObject
@property (nonatomic, readonly) CGFloat left;
@property (nonatomic, readonly) CGFloat right;
@property (nonatomic, readonly) CGFloat top;
@property (nonatomic, readonly) CGFloat bottom;
@property (nonatomic, readonly) CGFloat width;
@property (nonatomic, readonly) CGFloat height;
@end

@interface BDPAppPageController (BDPSafeArea)

- (BDPNaviBarSafeArea * _Nullable)getNavigationBarSafeArea;

@end

NS_ASSUME_NONNULL_END
