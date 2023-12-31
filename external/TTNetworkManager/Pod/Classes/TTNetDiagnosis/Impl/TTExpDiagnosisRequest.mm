//
//  TTExpDiagnosisRequest.m
//  TTNetworkManager
//
//  Created by zhangzeming on 2021/6/14.
//  Copyright © 2021 bytedance. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <memory>

#include "components/cronet/ios/cronet_environment.h"
#include "net/net_buildflags.h"
#if !BUILDFLAG(TTNET_IMPLEMENT_DISABLE_NET_EXP)
#include "net/tt_net/net_detect/gsdk/tt_net_experience_manager.h"
#include "net/tt_net/net_detect/gsdk/tt_net_experience_manager_request.h"
#endif
#if BUILDFLAG(ENABLE_MULTINETWORK_ON_MOBILE)
#include "net/tt_net/multinetwork/utils/tt_multinetwork_utils.h"
#endif

#import "TTExpDiagnosisCallback.h"
#import "TTExpDiagnosisRequest.h"
#import "TTNetworkManagerChromium.h"
#import "TTNetworkManagerLog.h"

class TTCronetNetExpRequestDelegate : public base::RefCountedThreadSafe<TTCronetNetExpRequestDelegate> {
public:
    TTCronetNetExpRequestDelegate(dispatch_queue_t callback_queue,
                                  DiagnosisCallback callback,
                                  int request_type,
                                  const std::vector<std::string>& targets,
                                  int net_detect_actions,
                                  int multiNetAction,
                                  int64_t timeout_ms)
    : callback_queue_(callback_queue),
      callback_(callback),
      request_type_(request_type),
      targets_(targets),
      net_detect_actions_(net_detect_actions),
      multi_net_action_(multiNetAction),
      timeout_ms_(timeout_ms) {
        DETACH_FROM_THREAD(thread_checker_);
        LOGD(@"%s %p", __FUNCTION__, this);
      }
    
    ~TTCronetNetExpRequestDelegate() {
        LOGD(@"%s %p", __FUNCTION__, this);
    }

    void StartOnNetworkThread() {
        DCHECK_CALLED_ON_VALID_THREAD(thread_checker_);
        LOGD(@"%s %p", __FUNCTION__, this);
#if !BUILDFLAG(TTNET_IMPLEMENT_DISABLE_NET_EXP)
        auto config = std::make_unique<net::tt_exp::TTNetExperienceManager::RequestConfig>();
        config->request_type =
            static_cast<net::tt_exp::TTNetExperienceManager::RequestType>(request_type_);
        config->timeout_ms = timeout_ms_;
        switch (config->request_type) {
            case net::tt_exp::TTNetExperienceManager::REQ_TYPE_DNS_ONLY:
                config->dns.target = targets_[0];
                break;
            case net::tt_exp::TTNetExperienceManager::REQ_TYPE_RACE_ONLY:
                config->race.actions =
                    static_cast<net::TTNetworkDetectDispatchedManager::NetDetectAction>(net_detect_actions_);
                config->race.targets = targets_;
                break;
            case net::tt_exp::TTNetExperienceManager::REQ_TYPE_DNS_AND_RACE:
                config->acceleration.action =
                    static_cast<net::TTNetworkDetectDispatchedManager::NetDetectAction>(net_detect_actions_);
                config->acceleration.target = targets_[0];
                break;
            case net::tt_exp::TTNetExperienceManager::REQ_TYPE_DIAGNOSIS_V1:
                config->diagnosis_v1.target = targets_[0];
#if BUILDFLAG(ENABLE_MULTINETWORK_ON_MOBILE)
                config->diagnosis_v1.multi_net_action = static_cast<net::TTMultiNetworkUtils::MultiNetAction>(multi_net_action_);
#endif
                break;
            case net::tt_exp::TTNetExperienceManager::REQ_TYPE_DIAGNOSIS_V2:
                config->diagnosis_v2.target = targets_[0];
                break;
            case net::tt_exp::TTNetExperienceManager::REQ_TYPE_RAW_DETECT:
                for (const auto& it : targets_) {
                    net::tt_exp::TTNetExperienceManager::RequestConfig::RawDetect::Entry
                            entry;
                    entry.target = it;
                    entry.actions =
                            static_cast<net::TTNetworkDetectDispatchedManager::NetDetectAction>(
                                    net_detect_actions_);
                    config->raw_detect.entries.push_back(entry);
                }
            default:
                NOTREACHED() << "bad net exp request type: " << request_type_;
                break;
      }
      request_ = net::tt_exp::TTNetExperienceManager::GetInstance()->CreateRequest(
                std::move(config));
      request_->Start(base::BindOnce(&TTCronetNetExpRequestDelegate::OnRequestComplete, base::Unretained(this)));
#else
      OnRequestComplete(-1);
#endif
    }
    
    void CancelOnNetworkThread() {
        DCHECK_CALLED_ON_VALID_THREAD(thread_checker_);
        LOGD(@"%s %p", __FUNCTION__, this);
#if !BUILDFLAG(TTNET_IMPLEMENT_DISABLE_NET_EXP)
        request_->Cancel();
#endif
    }
    
    void DoExtraCommandOnNetworkThread(const std::string& command, const std::string& extra_message) {
        DCHECK_CALLED_ON_VALID_THREAD(thread_checker_);
        LOGD(@"%s %p", __FUNCTION__, this);
#if !BUILDFLAG(TTNET_IMPLEMENT_DISABLE_NET_EXP)
        request_->DoExtraCommand(command, extra_message);
#endif
    }

    void OnRequestComplete(int result) {
        DCHECK_CALLED_ON_VALID_THREAD(thread_checker_);
        LOGD(@"%s %p result: %d", __FUNCTION__, this, result);
#if !BUILDFLAG(TTNET_IMPLEMENT_DISABLE_NET_EXP)
        NSString* report_out = nil;
        if (request_) {
            const auto& report = request_->GetReport();
            report_out = [NSString stringWithCString:report.c_str() encoding:[NSString defaultCStringEncoding]];
        }
#else
        NSString* report_out = @"Not Implement Net Experience.";
#endif
        dispatch_async(callback_queue_, ^{
            if (callback_) {
                callback_(report_out);
            }
        });
    }
private:
    
    dispatch_queue_t callback_queue_;
    
    DiagnosisCallback callback_;
    
    int request_type_;

    std::vector<std::string> targets_;

    int net_detect_actions_;

    int multi_net_action_;

    int64_t timeout_ms_;

#if !BUILDFLAG(TTNET_IMPLEMENT_DISABLE_NET_EXP)
    std::unique_ptr<net::tt_exp::TTNetExperienceManager::Request> request_;
#endif
};

@interface TTExpDiagnosisRequest () {
    scoped_refptr<TTCronetNetExpRequestDelegate> request;
}

// Called by user's thread.
@property (nonatomic, strong) dispatch_queue_t requestQueue;
// Called by Network thread.
@property (nonatomic, assign) int reqType;
@property (nonatomic, strong) NSArray<NSString*>* targets;
@property (nonatomic, assign) int netDetectType;
@property (nonatomic, assign) int multiNetAction;
@property (nonatomic, assign) int64_t timeoutMs;
@property (nonatomic, copy) DiagnosisCallback callback;
@property (nonatomic, assign) UInt64 reqId;
@property (atomic, assign) BOOL started;
@property (atomic, assign) BOOL canceled;
@property (atomic, copy) NSString* extraInfo;

@end


@implementation TTExpDiagnosisRequest

- (instancetype)initWithRequestQueue:(dispatch_queue_t)requestQueue
                             reqType:(int)reqType
                              target:(NSString*)target
                       netDetectType:(int)netDetectType
                      multiNetAction:(int)multiNetAction
                           timeoutMs:(int64_t)timeoutMs
                               reqId:(UInt64)reqId
                            callback:(DiagnosisCallback)callback {
    NSArray<NSString*>* targets = [NSArray arrayWithObjects:target, nil];
    return [self initWithRequestQueue:requestQueue
                              reqType:reqType
                              targets:targets
                        netDetectType:netDetectType
                       multiNetAction:multiNetAction
                            timeoutMs:timeoutMs
                                reqId:reqId
                             callback:callback];
}

- (instancetype)initWithRequestQueue:(dispatch_queue_t)requestQueue
                             reqType:(int)reqType
                             targets:(NSArray<NSString*>*)targets
                       netDetectType:(int)netDetectType
                      multiNetAction:(int)multiNetAction
                           timeoutMs:(int64_t)timeoutMs
                               reqId:(UInt64)reqId
                            callback:(DiagnosisCallback)callback {
    self = [super init];
    if (self) {
        self.requestQueue = requestQueue;
        self.reqType = reqType;
        self.targets = targets;
        self.netDetectType = netDetectType;
        self.multiNetAction = multiNetAction;
        self.timeoutMs = timeoutMs;
        self.reqId = reqId;
        self.callback = callback;
        self.started = NO;
        self.canceled = NO;
        self.extraInfo = nil;
    }
    return self;
}


- (void)start {
    if (self.started) {
        return;
    }
    __block std::vector<std::string> targets;
    [self.targets enumerateObjectsUsingBlock:^(NSString * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        auto target = [obj UTF8String];
        targets.push_back(target);
    }];
    request = new TTCronetNetExpRequestDelegate(self.requestQueue, self.callback, self.reqType, targets, self.netDetectType, self.multiNetAction, self.timeoutMs);
    __weak typeof(self) wself = self;
    dispatch_async(self.requestQueue, ^{
        __strong typeof(wself) sself = wself;
        if (sself) {
            const auto task = base::Bind(&TTCronetNetExpRequestDelegate::StartOnNetworkThread, sself->request);
            [sself postTaskToNetworkThread:FROM_HERE task:task];
        }
    });
    self.started = YES;
    if (self.extraInfo != nil) {
        [self doExtraCommand:@"extra_info" extraMessage:self.extraInfo];
    }
}

- (void)cancel {
    if (!self.started || self.canceled) {
        return;
    }
    __weak typeof(self) wself = self;
    dispatch_async(self.requestQueue, ^{
        __strong typeof(wself) sself = wself;
        if (sself) {
            const auto task = base::Bind(&TTCronetNetExpRequestDelegate::CancelOnNetworkThread, sself->request);
            [sself postTaskToNetworkThread:FROM_HERE task:task];
        }
    });
    self.canceled = YES;
}

- (void)doExtraCommand:(NSString*)command
          extraMessage:(NSString*)extraMessage {
    if (!self.started) {
        return;
    }

    if (command == nil || extraMessage == nil) {
        LOGE(@"invalid params");
        return;
    }
    __weak typeof(self) wself = self;
    dispatch_async(self.requestQueue, ^{
        __strong typeof(wself) sself = wself;
        if (sself) {
            std::string command_str = [command cStringUsingEncoding:NSUTF8StringEncoding];
            std::string extra_message_str = [extraMessage cStringUsingEncoding:NSUTF8StringEncoding];
            const auto task = base::Bind(&TTCronetNetExpRequestDelegate::DoExtraCommandOnNetworkThread, sself->request, command_str, extra_message_str);
            [sself postTaskToNetworkThread:FROM_HERE task:task];
        }
    });
}

- (void)setUserExtraInfo:(NSString*)extraInfo {
    self.extraInfo = extraInfo;
    [self doExtraCommand:@"extra_info" extraMessage:self.extraInfo];
}

- (void)postTaskToNetworkThread:(const base::Location&)from_here
                           task:(const base::Closure&)task {
    cronet::CronetEnvironment* engine = (cronet::CronetEnvironment*)[(TTNetworkManagerChromium *)[TTNetworkManager shareInstance] getEngine];
    if (!engine || !engine->GetURLRequestContextGetter() || !engine->GetURLRequestContextGetter()->GetNetworkTaskRunner()) {
      LOGE(@"engine in bad state");
      return;
    }
    engine->GetURLRequestContextGetter()->GetNetworkTaskRunner()->PostTask(from_here, task);
}

@end


