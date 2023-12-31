//
//  ACCLynxWindowContext.h
//  Indexer
//
//  Created by wanghongyu on 2021/11/9.
//

#import <Foundation/Foundation.h>

@interface ACCLynxWindowContext : NSObject

+ (instancetype)sharedInstance;

- (void)addContianer:(UIViewController *)contianer;

- (void)showViewController:(nullable UIViewController *)vc;
- (void)showViewController:(nullable UIViewController *)vc frame:(CGRect)frame;
- (void)showViewController:(nullable UIViewController *)vc dismissAction:(nullable dispatch_block_t)dismissAction;

- (void)dismiss;

@end

