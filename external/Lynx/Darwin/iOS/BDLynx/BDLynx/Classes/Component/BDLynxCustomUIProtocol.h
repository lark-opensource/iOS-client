//
//  BDLynxCustomUIProtocol.h
//  BDLynx
//
//  Created by  wanghanfeng on 2020/2/17.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@protocol BDLynxCustomUIProtocol <NSObject>

- (void)lynx_actionWithSel:(SEL)selector
                     param:(id)param
             completeBlock:(void (^)(NSDictionary *completeDict))completeBlock;
- (id)lynx_getResultWithSel:(SEL)selector
                      param:(nullable id)param
              completeBlock:(void (^)(NSDictionary *completeDict))completeBlock;

@end

NS_ASSUME_NONNULL_END
