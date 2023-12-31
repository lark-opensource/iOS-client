//
//  TTMpaService.h
//  TTNetworkManager
//
//  Created by changxing on 2021/9/28.
//

#define DISABLE_NET_MPA

#import <Foundation/Foundation.h>

#include "base/logging.h"
#include "components/cronet/ios/cronet_environment.h"
#ifndef DISABLE_NET_MPA
#include "net/tt_net/multinetwork/mpa/tt_mpa_service.h"
#endif

#import "TTMpaService.h"
#import "TTNetworkManagerChromium.h"
#import "TTNetworkManagerLog.h"

class TTNetMpaServiceDelegate :
#ifndef DISABLE_NET_MPA
    public net::tt_mpa::TTMpaService::Delegate,
#endif
    public base::RefCountedThreadSafe<TTNetMpaServiceDelegate> {
 public:
  TTNetMpaServiceDelegate() { LOGD(@"%s %p", __FUNCTION__, this); }

  ~TTNetMpaServiceDelegate() { LOGD(@"%s %p", __FUNCTION__, this); }

  void SetInitCallback(ICallback callback) { init_callback_ = callback; }

  void SetAccAddressCallback(ICallback callback) {
    set_acc_address_callback_ = callback;
  }

  void InitOnNetworkThread() {
#ifndef DISABLE_NET_MPA
    if (!mpa_service_) {
      mpa_service_ = std::make_unique<net::tt_mpa::TTMpaService>(this);
    }
    mpa_service_->Init();
#endif
  }

  void SetAccAddressOnNetworkThread(const std::vector<std::string>& address) {
#ifndef DISABLE_NET_MPA
    if (mpa_service_) {
      mpa_service_->SetAccAddress(address);
    }
#endif
  }

  void StartOnNetworkThread() {
#ifndef DISABLE_NET_MPA
    if (mpa_service_) {
      mpa_service_->Start();
    }
#endif
  }

  void StopOnNetworkThread() {
#ifndef DISABLE_NET_MPA
    if (mpa_service_) {
      mpa_service_->Stop();
    }
#endif
  }

  void CommandOnNetworkThread(const std::string& command,
                              const std::string& extraMessage) {
#ifndef DISABLE_NET_MPA
    if (mpa_service_) {
      mpa_service_->Command(command, extraMessage);
    }
#endif
  }

 private:
  void OnInitFinish(bool is_success, const std::string& extra_msg) {
    NSString* extraMsg =
        [NSString stringWithCString:extra_msg.c_str()
                           encoding:[NSString defaultCStringEncoding]];
    dispatch_async(
        dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
          if (init_callback_) {
            init_callback_(is_success, extraMsg);
            init_callback_ = nil;
          }
        });
  }

  void OnSetAccAddressFinish(bool is_success, const std::string& extra_msg) {
    NSString* extraMsg =
        [NSString stringWithCString:extra_msg.c_str()
                           encoding:[NSString defaultCStringEncoding]];
    dispatch_async(
        dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
          if (set_acc_address_callback_) {
            set_acc_address_callback_(is_success, extraMsg);
            set_acc_address_callback_ = nil;
          }
        });
  }

#ifndef DISABLE_NET_MPA
  std::unique_ptr<net::tt_mpa::TTMpaService> mpa_service_;
#endif
  ICallback init_callback_;
  ICallback set_acc_address_callback_;
};

@implementation TTMpaService {
  scoped_refptr<TTNetMpaServiceDelegate> delegate;
}

+ (instancetype)shareInstance {
  static id singleton = nil;
  static dispatch_once_t onceToken;
  dispatch_once(&onceToken, ^{
    singleton = [[self alloc] init];
  });
  return singleton;
}

- (id)init {
  self = [super init];
  if (self) {
    delegate = nil;
  }
  return self;
}

- (void)init:(ICallback)callback {
  NSAssert(callback != nil, @"initCallback is nil");
  if (![self checkTTNetIsInitialized]) {
    callback(false, @"TTNet is not initalized");
    return;
  }

  delegate->SetInitCallback(callback);
  const auto task =
      base::Bind(&TTNetMpaServiceDelegate::InitOnNetworkThread, delegate);
  [self postTaskToNetworkThread:FROM_HERE task:task];
}

- (BOOL)checkTTNetIsInitialized {
  if (delegate) {
    return TRUE;
  }
  TTNetworkManagerChromium* networkManager =
      (TTNetworkManagerChromium*)[TTNetworkManager shareInstance];
  if ([networkManager ensureEngineStarted]) {
    LOGE(@"TTNet is not initalized");
    return FALSE;
  }
  delegate = new TTNetMpaServiceDelegate();
  return TRUE;
}

- (void)setAccAddress:(NSArray<NSString*>*)address
             callback:(ICallback)callback {
  if (address == nil || address.count <= 0) {
    if (callback) {
        callback(false, @"Address error");
    }
    return;
  }
  std::vector<std::string> address_list;
  for (NSString* addr in address) {
    address_list.push_back(base::SysNSStringToUTF8(addr));
  }
  if (delegate) {
    delegate->SetAccAddressCallback(callback);
    const auto task =
        base::Bind(&TTNetMpaServiceDelegate::SetAccAddressOnNetworkThread,
                   delegate, address_list);
    [self postTaskToNetworkThread:FROM_HERE task:task];
  } else if (callback) {
    callback(false, @"Delegate is null");
  }
}

- (void)start:(NSString*)userLog {
  if (delegate) {
    const auto task =
        base::Bind(&TTNetMpaServiceDelegate::StartOnNetworkThread, delegate);
    [self postTaskToNetworkThread:FROM_HERE task:task];
    [self command:@"begin_user_log" extraMessage:userLog];
  }
}

- (void)stop:(NSString*)userLog {
  if (delegate) {
    [self command:@"end_user_log" extraMessage:userLog];
    const auto task =
        base::Bind(&TTNetMpaServiceDelegate::StopOnNetworkThread, delegate);
    [self postTaskToNetworkThread:FROM_HERE task:task];
  }
}

- (void)command:(NSString*)command extraMessage:(NSString*)extraMessage {
  if (command == nil || extraMessage == nil) {
    LOGE(@"command error :command%@ extraMessage:%@", command, extraMessage);
    return;
  }

  if (delegate) {
    const auto task =
        base::Bind(&TTNetMpaServiceDelegate::CommandOnNetworkThread, delegate,
                   [command cStringUsingEncoding:NSUTF8StringEncoding],
                   [extraMessage cStringUsingEncoding:NSUTF8StringEncoding]);
    [self postTaskToNetworkThread:FROM_HERE task:task];
  }
}

- (void)postTaskToNetworkThread:(const base::Location&)from_here
                           task:(const base::Closure&)task {
  cronet::CronetEnvironment* engine = (cronet::CronetEnvironment*)[(
      TTNetworkManagerChromium*)[TTNetworkManager shareInstance] getEngine];
  if (!engine || !engine->GetURLRequestContextGetter() ||
      !engine->GetURLRequestContextGetter()->GetNetworkTaskRunner()) {
    LOGE(@"engine in bad state");
    return;
  }
  engine->GetURLRequestContextGetter()->GetNetworkTaskRunner()->PostTask(
      from_here, task);
}
@end
