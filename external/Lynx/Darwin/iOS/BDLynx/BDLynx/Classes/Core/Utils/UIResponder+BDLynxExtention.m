//
//  UIResponder+BDLynxExtention.m
//  BDLynx
//
//  Created by  wanghanfeng on 2020/2/17.
//

#import "UIResponder+BDLynxExtention.h"

@implementation UIResponder (BDLynxExtention)

- (void)lynx_actionWithSel:(SEL)selector
                     param:(id)param
             completeBlock:(void (^)(NSDictionary* _Nonnull))completeBlock {
  [[self nextResponder] lynx_actionWithSel:selector param:param completeBlock:completeBlock];
}

- (id)lynx_getResultWithSel:(SEL)selector
                      param:(id)param
              completeBlock:(void (^)(NSDictionary* _Nonnull))completeBlock {
  return [[self nextResponder] lynx_getResultWithSel:selector
                                               param:param
                                       completeBlock:completeBlock];
}

@end
