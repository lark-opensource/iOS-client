//
//  BDLynxUIATag.m
//  BDLynx
//
//  Created by  wanghanfeng on 2020/2/17.
//

#import "BDLynxUIATag.h"
#import "BDLUtils.h"
#import "LynxPropsProcessor.h"
#import "UIResponder+BDLynxExtention.h"

@implementation BDLynxUIATag

- (UIView *)createView {
  UIView *view = [[UIView alloc] init];
  view.clipsToBounds = YES;
  // Disable AutoLayout
  [view setTranslatesAutoresizingMaskIntoConstraints:YES];
  UITapGestureRecognizer *tapGesturRecognizer =
      [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(openHref)];
  [view addGestureRecognizer:tapGesturRecognizer];
  return view;
}

- (void)openHref {
  if (self.href) {
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wundeclared-selector"
    [self.view lynx_actionWithSel:@selector(trackClickUIAtag:) param:self completeBlock:nil];
#pragma clang diagnostic pop

    void (^invokBlock)(void) = ^() {
      [BDLUtils openSchema:self.href];
    };
    if ([NSThread isMainThread]) {
      invokBlock();
    } else {
      dispatch_sync(dispatch_get_main_queue(), invokBlock);
    }
  }
}

/**
 * 点击跳转schema
 */
LYNX_PROP_SETTER("href", setHref, NSString *) { _href = value; }

/**
 * 发送点击事件所需的参数，json格式的字符串
 */
LYNX_PROP_SETTER("paramsString", setParamsString, NSString *) { _paramsString = value; }

/**
 * 发送点击事件所需的参数
 */
LYNX_PROP_SETTER("params", setParams, NSDictionary *) { _params = value; }

/**
 * 点击事件label，对应event label，
 */
LYNX_PROP_SETTER("label", setLabel, NSString *) { _label = value; }

/**
 * 用于唯一区分事件，标识事件业务方
 */
LYNX_PROP_SETTER("identifier", setIdentifier, NSString *) { _identifier = value; }

/**
 * 点击的view在同层级中所有可点击的view中所处的位置，从0开始，主要是用于某些特殊的逻辑所添加
 */
LYNX_PROP_SETTER("index", setIndex, NSInteger) { _index = value; }

@end
