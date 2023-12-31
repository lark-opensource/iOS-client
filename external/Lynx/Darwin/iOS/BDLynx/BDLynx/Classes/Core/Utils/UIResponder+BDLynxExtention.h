//
//  UIResponder+BDLynxExtention.h
//  BDLynx
//
//  Created by  wanghanfeng on 2020/2/17.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface UIResponder (BDLynxExtention)

- (void)lynx_actionWithSel:(SEL)selector
                     param:(id)param
             completeBlock:(nullable void (^)(NSDictionary *completeDict))completeBlock;
- (id)lynx_getResultWithSel:(SEL)selector
                      param:(nullable id)param
              completeBlock:(nullable void (^)(NSDictionary *completeDict))completeBlock;

@end

NS_ASSUME_NONNULL_END
