//
//  CJPayLynxViewPlugin.h
//  Aweme
//
//  Created by wangxiaohong on 2023/3/2.
//

#import <Foundation/Foundation.h>
#import "CJPayBaseLynxView.h"

NS_ASSUME_NONNULL_BEGIN

@protocol CJPayLynxViewPlugin <NSObject>

- (UIView *)createLynxCardWithScheme:(NSString *)scheme
                               frame:(CGRect)frame
                      initialDataStr:(NSString *)dataStr
                            delegate:(nullable id<CJPayLynxViewDelegate>)delegate;

- (NSString *)getContainerIdWithView:(UIView *)view;

- (void)loadLynxView:(UIView *)view;

- (void)publishEvent:(NSString *)event data:(NSDictionary *)params;

@end

NS_ASSUME_NONNULL_END
