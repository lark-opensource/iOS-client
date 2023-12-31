//
//  TMAVideoLockButton.h
//  OPPluginBiz
//
//  Created by zhujingcheng on 2/8/23.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface TMAVideoLockButton : UIButton

@property (nonatomic, assign) BOOL locked;
@property (nonatomic, copy) void(^tapAction)(BOOL isLocked);

- (void)hideTextTip;

@end

NS_ASSUME_NONNULL_END
