// Copyright 2019 The Lynx Authors. All rights reserved.

#import "LynxInspectorOwner.h"

#include <string>
#include "base/mouse_event.h"

NS_ASSUME_NONNULL_BEGIN

@interface LynxInspectorOwner ()

- (void)emulateTouch:(std::shared_ptr<lynxdev::devtool::MouseEvent>)input;

- (void)sendResponse:(std::string)response;

- (void)DispatchMessageToJSEngine:(std::string)message;

@end

NS_ASSUME_NONNULL_END
