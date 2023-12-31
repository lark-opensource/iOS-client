//
//  DVELoading.h
//  NLEEditor
//
//  Created by Lincoln on 2022/1/20.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface DVELoading : NSObject

/// 优先注入再默认实现
+ (void)showLoadingOnWindow;

/// 优先注入再默认实现
+ (void)updateLoadingLabelWithText:(NSString *)text;

/// 优先注入再默认实现
+ (void)dismissLoadingOnWindow;

@end

NS_ASSUME_NONNULL_END
