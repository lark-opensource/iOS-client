//
//  TMAVideoFullScreenViewController.h
//  OPPluginBiz
//
//  Created by tujinqiu on 2019/11/5.
//

#import <UIKit/UIKit.h>
#import "TMAPlayerView.h"

NS_ASSUME_NONNULL_BEGIN

@interface TMAVideoFullScreenViewController : UIViewController

@property (nonatomic, weak) TMAPlayerView *targetView;

+ (instancetype)new NS_UNAVAILABLE;
- (instancetype)init NS_UNAVAILABLE;
- (instancetype)initWithTragetView:(TMAPlayerView *)targetView orientation:(UIInterfaceOrientation)orientation dismissCompletion:(dispatch_block_t)dismissCompletion;
- (void)enter;
- (void)exitWithCompletion:(dispatch_block_t)completion;

@end

NS_ASSUME_NONNULL_END
