//
//  BDPRootNavigationController.h
//  Timor
//
//  Created by MacPu on 2019/2/2.
//

#import "BDPPresentAnimation.h"

@class BDPBaseContainerController;

NS_ASSUME_NONNULL_BEGIN

@interface BDPRootNavigationController : UINavigationController

@property (nonatomic, copy, readonly) NSArray<BDPBaseContainerController *> *allApps;
@property (nonatomic, strong) BDPPresentAnimation *animation;

@end

NS_ASSUME_NONNULL_END
