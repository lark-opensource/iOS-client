//
//  BDPAppPageAnimatedTransitioning.h
//  Timor
//
//  Created by MacPu on 2019/6/21.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface BDPAppPageAnimatedTransitioning : NSObject <UIViewControllerAnimatedTransitioning>

@property (nonatomic, assign) UINavigationControllerOperation operation;

@end

NS_ASSUME_NONNULL_END
