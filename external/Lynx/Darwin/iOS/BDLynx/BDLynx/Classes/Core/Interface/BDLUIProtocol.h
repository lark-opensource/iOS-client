//
//  BDLUIProtocol.h
//  AFgzipRequestSerializer
//
//  Created by zys on 2020/2/16.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@protocol BDLUIProtocol <NSObject>

/**
 * 显示Toast
 * @param model toast的信息
 */
- (void)showToastWithTitle:(NSString *)title icon:(NSString *)icon;

/**
 * 隐藏Toast
 */
- (void)hideToast;

@end

NS_ASSUME_NONNULL_END
