//
//  TTFetcherDelegateForCommonTask.mm
//  Pods
//
//  Created by liuyichen on 2019/3/31.
//
#import "TTFetcherDelegateForCommonTask.h"

#import "TTNetworkManagerChromium.h"
#import "TTNetworkDefine.h"
#import "TTNetworkUtil.h"
#import "TTNetworkManagerLog.h"

#include "base/strings/sys_string_conversions.h"
#include "base/bind.h"
#include "base/threading/sequenced_task_runner_handle.h"
#include "base/strings/sys_string_conversions.h"
#include "base/timer/timer.h"
#include "components/cronet/ios/cronet_environment.h"
#include "net/base/io_buffer.h"
#include "net/base/net_errors.h"
#include "net/base/load_flags.h"
#include "net/http/http_request_headers.h"
#include "net/http/http_response_headers.h"
#include "net/tt_net/config/tt_init_config.h"

@interface TTNetworkManagerChromium ()

- (BOOL)hasTaskIdInMap:(UInt64)taskId;

@end

TTChunkedResponseWriter::TTChunkedResponseWriter(TTChunkedResponseWriter::Delegate* delegate) : delegate_(delegate) {
}

TTChunkedResponseWriter::~TTChunkedResponseWriter() {
}
    
int TTChunkedResponseWriter::Initialize(net::CompletionOnceCallback callback) {
    // Do nothing.
    return net::OK;
}
    
int TTChunkedResponseWriter::Write(net::IOBuffer* buffer,
                                   int num_bytes,
                                   net::CompletionOnceCallback callback) {
    delegate_->OnResponseDataReceived(buffer, num_bytes);
    return num_bytes;
}
    
int TTChunkedResponseWriter::Finish(int net_error, net::CompletionOnceCallback callback) {
    // invoke 0 byte callback to indicate the completion of chunked body in dataBlock
    // to handle request which doesn't have Content-Length
    delegate_->OnResponseDataReceived(nullptr, 0);
    return net::OK;
}

TTFetcherDelegateForCommonTask::TTFetcherDelegateForCommonTask(__weak TTHttpTaskChromium *task, cronet::CronetEnvironment *engine, bool is_chunked_task)
    : TTFetcherDelegate(task, engine), is_chunked_task_(is_chunked_task), is_upload_callback_needed_(task.uploadProgressBlock != nil), is_download_callback_needed_(task.downloadProgressBlock != nil) {}

TTFetcherDelegateForCommonTask::~TTFetcherDelegateForCommonTask() {}

void TTFetcherDelegateForCommonTask::OnURLResponseStarted(const net::URLFetcher* source) {
    if (is_complete_) {
        return;
    }
        
    if (task_.headerBlock) {
        timeout_timer_->Stop();
            
        if (task_.dataBlock && task_.readDataTimeout > 0) {
            timeout_timer_->Start(FROM_HERE, base::TimeDelta::FromSecondsD(task_.readDataTimeout),
                                  base::Bind(&TTFetcherDelegate::OnTimeout, this));
        } else {
            // Default way is to use global timeout settings.
            timeout_timer_->Start(FROM_HERE, base::TimeDelta::FromSecondsD(task_.request.timeoutInterval),
                                  base::Bind(&TTFetcherDelegate::OnTimeout, this));
        }
            
        [task_ onResponseStarted:source];
    } else if (task_.dataBlock && task_.readDataTimeout > 0) {
        timeout_timer_->Stop();
        timeout_timer_->Start(FROM_HERE, base::TimeDelta::FromSecondsD(task_.readDataTimeout),
                              base::Bind(&TTFetcherDelegate::OnTimeout, this));
    } else {
        // Covers the following conditions:
        // 1. No header callback nor data callback.
        // 2. No header callback and no read data timeout but have data callback.
        timeout_timer_->Reset();
    }
}
    
void TTFetcherDelegateForCommonTask::OnURLFetchComplete(const net::URLFetcher* source) {
    if (!is_complete_) {
        is_complete_ = true;
            
        timeout_timer_.reset();
            
        if ([(TTNetworkManagerChromium *)[TTNetworkManager shareInstance] hasTaskIdInMap:taskId_]) {
            [task_ onURLFetchComplete:source];
        } else {
            LOGE(@"task_ of TTFetcherDelegateForCommonTask has been released!");
        }
    }
}
    
void TTFetcherDelegateForCommonTask::OnURLFetchDownloadProgress(const net::URLFetcher* source,
                                                                int64_t current,
                                                                int64_t total,
                                                                int64_t current_network_bytes) {
    if (!is_complete_) {
        timeout_timer_->Reset();
        if (is_download_callback_needed_) {
          [task_ onURLFetchDownloadProgress:source current:current total:total current_network_bytes:current_network_bytes];
        }
    }
}
    
void TTFetcherDelegateForCommonTask::OnURLFetchUploadProgress(const net::URLFetcher* source,
                                                              int64_t current,
                                                              int64_t total) {
    if (!is_complete_) {
        timeout_timer_->Reset();
        if (is_upload_callback_needed_) {
          [task_ onURLFetchUploadProgress:source current:current total:total];
        }
    }
}
    
void TTFetcherDelegateForCommonTask::OnURLRedirectReceived(const net::URLFetcher* source,
                                                           const net::RedirectInfo& redirect_info,
                                                           const net::HttpResponseInfo& response_info) {
    if (!is_complete_) {
        timeout_timer_->Reset();
        [task_ onURLRedirectReceived:source redirect_info:redirect_info response_info:response_info];
    }
}

void TTFetcherDelegateForCommonTask::OnResponseDataReceived(net::IOBuffer* buffer, int num_bytes) {
    // Similiar to |NSURLSession|, the timeout incadiates each networked callback.
    // Reset the countdown.
    timeout_timer_->Reset();
        
    DVLOG(1) << "OnResponseDataReceived num_bytes = " << num_bytes;
    NSMutableData* data = [[NSMutableData alloc] init];
    if (buffer) {
        [data increaseLengthBy:num_bytes];
        memcpy(reinterpret_cast<char*>([data mutableBytes]), buffer->data(), num_bytes);
    }
    task_runner_->PostTask(FROM_HERE, base::Bind(&TTFetcherDelegateForCommonTask::DispatchResponseDataInternal, this, data));
};

void TTFetcherDelegateForCommonTask::DispatchResponseDataInternal(NSMutableData* data) {
    if (!is_complete_) {
        [task_ onReadResponseData:data];
    }
}

void TTFetcherDelegateForCommonTask::CreateURLFetcherOnNetThread() {
    TTFetcherDelegate::CreateURLFetcherOnNetThread();
    if (is_complete_ || !task_ || !fetcher_) {
        return;
    }
    if (is_chunked_task_) {
        fetcher_->SaveResponseWithWriter(std::make_unique<TTChunkedResponseWriter>(this));
    } else {
        if (task_.fileDestinationURL) {
            std::string fileDestinationURL = base::SysNSStringToUTF8([task_.fileDestinationURL path]);
            base::FilePath file_path(fileDestinationURL);
            if (task_.isFileAppend) {
                fetcher_->SaveResponseToFileAtPathByAppend(file_path, engine_->GetFileThreadRunnerForTesting());
            } else {
                fetcher_->SaveResponseToFileAtPath(file_path, engine_->GetFileThreadRunnerForTesting());
            }
        }
    }
    
    fetcher_->Start();
    
    if (task_.headerBlock && task_.recvHeaderTimeout > 0) {
        timeout_timer_->Start(FROM_HERE, base::TimeDelta::FromSecondsD(task_.recvHeaderTimeout),
                              base::Bind(&TTFetcherDelegate::OnTimeout, this));
    } else {
        // Default way is to use global timeout settings.
        // same 15 seconds timeout as AFNetworking
        __strong TTHttpRequestChromium *request = task_.request;
        NSTimeInterval timeout = request.timeoutInterval;
        if (task_.timeoutInterval > 0) {
            timeout = task_.timeoutInterval;
        }
        timeout_timer_->Start(FROM_HERE, base::TimeDelta::FromSecondsD(timeout),
                              base::Bind(&TTFetcherDelegate::OnTimeout, this));
    }
}

void TTFetcherDelegateForCommonTask::CancelOnNetThread() {
    if (!is_complete_) {
        is_complete_ = true;
        
        timeout_timer_.reset();
        if (task_.isFileAppend) {
            GetResponseAsFilePathFromFetcher();
        }
        NSString* requestLog = @"";
        if (fetcher_) {
            fetcher_->Cancel(-999);
            requestLog = @(fetcher_->GetRequestLog().c_str());
        }
        fetcher_.reset();
        
        [task_ onCancel:requestLog];
    }
}
