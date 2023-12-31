//
//  CJPayPayCancelLynxRetainViewController.h
//  CJPaySandBox
//
//  Created by ByteDance on 2023/4/2.
//
#import "CJPayFullPageBaseViewController.h"

NS_ASSUME_NONNULL_BEGIN

typedef void(^CJPayPayCancelLynxEvent)(NSString *event, NSDictionary *data);

@interface CJPayPayCancelLynxRetainViewController :CJPayFullPageBaseViewController

@property (nonatomic, copy) CJPayPayCancelLynxEvent eventBlock;

- (instancetype)initWithRetainInfo:(NSDictionary * __nullable)postFEParams schema:(NSString *)schema;

@end

NS_ASSUME_NONNULL_END
