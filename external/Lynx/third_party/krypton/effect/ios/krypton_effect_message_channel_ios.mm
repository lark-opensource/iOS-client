// Copyright 2022 The Lynx Authors. All rights reserved.

#import "krypton_effect_message_channel_ios.h"
#import <EffectSDK_iOS/RenderMsgDelegate.h>
#import <Foundation/Foundation.h>
#import <mutex>

namespace lynx {
namespace canvas {

static bool __msgProc(void *userdata, unsigned int msg_id, int arg1, int arg2, const char *arg3) {
  auto cb = reinterpret_cast<EffectMessageCallbackType *>(userdata);
  (*cb)(msg_id, arg1, arg2, arg3 ? arg3 : "");
  return true;
}
}  // namespace canvas
}  // namespace lynx

@interface KryptonEffectMessageChannel : NSObject
@end

@implementation KryptonEffectMessageChannel {
  bef_render_msg_delegate_manager manager;
  lynx::canvas::EffectMessageCallbackType *callback;
}

- (id)init {
#if TARGET_IPHONE_SIMULATOR
  return nullptr;
#endif
  if ((self = [super init]) != nil) {
    self->manager = (__bridge void *)[[IRenderMsgDelegateManager alloc] init];
    bef_render_msg_delegate_manager_init(&(self->manager));
  }
  return self;
}

- (bool)addCallback:(lynx::canvas::EffectMessageCallbackType *)cb {
#if TARGET_IPHONE_SIMULATOR
  return NO;
#endif
  self->callback = cb;
  return bef_render_msg_delegate_manager_add(manager, (void *)cb, lynx::canvas::__msgProc);
}

- (bool)removeCallback {
#if TARGET_IPHONE_SIMULATOR
  return NO;
#endif
  return bef_render_msg_delegate_manager_remove(manager, (void *)callback, lynx::canvas::__msgProc);
}

- (void)destroy {
#if TARGET_IPHONE_SIMULATOR
  return;
#endif
  bef_render_msg_delegate_manager_destroy(&manager);
  manager = nil;
}

- (void)dealloc {
#if TARGET_IPHONE_SIMULATOR
  return;
#endif
  if (manager != nil) {
    bef_render_msg_delegate_manager_destroy(&manager);
    manager = nil;
  }
}

@end

namespace lynx {
namespace canvas {

#ifdef OS_IOS
EffectMessageChannel *EffectMessageChannel::CreateInstance() {
  return new EffectMessageChannelIOS();
}
#endif

EffectMessageChannelIOS::EffectMessageChannelIOS() {
#if TARGET_IPHONE_SIMULATOR
  message_channel_ = nullptr;
#else
  message_channel_ = [[KryptonEffectMessageChannel alloc] init];
#endif
}

EffectMessageChannelIOS::~EffectMessageChannelIOS() {
  if (!message_channel_) {
    return;
  }

  [message_channel_ removeCallback];
  [message_channel_ destroy];
}

bool EffectMessageChannelIOS::AddEventCallback(EffectMessageCallbackType *sticker_msg_cb) {
  if (!message_channel_) {
    return false;
  }

  return [message_channel_ addCallback:sticker_msg_cb];
}

bool EffectMessageChannelIOS::RemoveEventCallback() {
  if (!message_channel_) {
    return false;
  }

  return [message_channel_ removeCallback];
}

}  // namespace canvas
}  // namespace lynx
