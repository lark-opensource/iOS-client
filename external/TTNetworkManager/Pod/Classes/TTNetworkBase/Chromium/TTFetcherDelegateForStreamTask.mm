//
//  TTFetcherDelegateForStreamTask.h
//  Pods
//
//  Created by liuyichen on 2019/4/1.
//
#import "TTFetcherDelegateForStreamTask.h"

#import "TTNetworkDefine.h"
#import "TTNetworkUtil.h"

#include "base/bind.h"
#include "base/callback_helpers.h"
#include "base/strings/sys_string_conversions.h"
#include "base/threading/sequenced_task_runner_handle.h"
#include "base/timer/timer.h"
#include "components/cronet/ios/cronet_environment.h"
#include "net/base/io_buffer.h"
#include "net/base/net_errors.h"
#include "net/base/load_flags.h"
#include "net/http/http_request_headers.h"
#include "net/http/http_response_headers.h"

@interface TTHttpResponseChromium ()

- (instancetype)initWithURLFetcher:(const net::URLFetcher *)fetcher;

@end

TTStreamResponseWriter::TTStreamResponseWriter(TTStreamResponseWriter::Delegate* delegate) : delegate_(delegate) {
}

TTStreamResponseWriter::~TTStreamResponseWriter() {
}
    
int TTStreamResponseWriter::Initialize(net::CompletionOnceCallback callback) {
    return net::OK;
}
    
int TTStreamResponseWriter::Write(net::IOBuffer* buffer,
                                   int num_bytes,
                                   net::CompletionOnceCallback callback) {
  return delegate_->OnResponseDataReceived(buffer, num_bytes, std::move(callback));
}
    
int TTStreamResponseWriter::Finish(int net_error, net::CompletionOnceCallback callback) {
    delegate_->OnResponseDataFinished();
    return net::OK;
}

TTFetcherDelegateForStreamTask::TTFetcherDelegateForStreamTask(__weak TTHttpTaskChromium *task, cronet::CronetEnvironment *engine)
    : TTFetcherDelegate(task, engine),
      completionHandler_(nil),
      minLengthForHandler_(0),
      maxLengthForHandler_(0),
      response_(nil),
      bufferedData_(nil),
      error_(nil),
      isEOF_(NO) {}

TTFetcherDelegateForStreamTask::~TTFetcherDelegateForStreamTask() {}

void TTFetcherDelegateForStreamTask::OnURLResponseStarted(const net::URLFetcher* source) {
    if (is_complete_) {
        return;
    }
    
    response_ = [[TTHttpResponseChromium alloc] initWithURLFetcher:source];
    
    CollectDataAndRunCallbacks(nullptr, 0);
}
    
void TTFetcherDelegateForStreamTask::OnURLFetchComplete(const net::URLFetcher* source) {
    // If the response header is not return before the error, init it.
    if (!response_) {
        response_ = [[TTHttpResponseChromium alloc] initWithURLFetcher:source];
    }

    int error_num = source->GetError();
    if (error_num != net::OK) {
        std::string error_string = net::ErrorToShortString(error_num);
        if (error_num == net::ERR_ABORTED) {
            error_num = NSURLErrorCancelled;
            error_string = "the request was cancelled programatically";
        }

        NSDictionary *userInfo = @{kTTNetSubErrorCode : @(error_num),
                                NSLocalizedDescriptionKey : @(error_string.c_str()),
                                NSURLErrorFailingURLErrorKey : [NSURL URLWithString:base::SysUTF8ToNSString(
                                                                               source->GetOriginalURL().possibly_invalid_spec())]};
        error_ = [NSError errorWithDomain:kTTNetworkErrorDomain code:error_num userInfo:userInfo];
    }


    CollectDataAndRunCallbacks(nullptr, 0);
    
    if (!is_complete_) {
        is_complete_ = true;
            
        timeout_timer_.reset();
            
        [task_ onURLFetchComplete:source];
    }
}

void TTFetcherDelegateForStreamTask::OnResponseDataStarted() {

}

int TTFetcherDelegateForStreamTask::OnResponseDataReceived(net::IOBuffer* buffer,
                                                           int num_bytes,
                                                           net::CompletionOnceCallback callback) {
    if (is_complete_) {
        return net::ERR_ABORTED;
    }
    
    // If the callback data is too few to satisify the |minLengthForHandler_|, save the data to a temporary buffer.
    int bufferedDataLength = GetBufferedDataLength();
    if (bufferedDataLength + num_bytes < minLengthForHandler_) {
        if (!bufferedData_) {
            bufferedData_ = [[NSMutableData alloc] initWithCapacity:minLengthForHandler_];
        }
        [bufferedData_ appendBytes:buffer->data() length:num_bytes];
        
        VLOG(1) << __FUNCTION__ << " response buffered " << num_bytes
                << " pushed into buffer, and buffer length = " << GetBufferedDataLength();
        
        return num_bytes;
    }
    
    int bytes_consumed = CollectDataAndRunCallbacks(buffer, num_bytes);
    if (bytes_consumed == net::ERR_IO_PENDING) {
      continueNetworkCallback_ = std::move(callback);
    }
    return bytes_consumed;
};

void TTFetcherDelegateForStreamTask::OnResponseDataFinished() {
    isEOF_ = YES;
}

void TTFetcherDelegateForStreamTask::CreateURLFetcherOnNetThread() {
    TTFetcherDelegate::CreateURLFetcherOnNetThread();
    if (is_complete_ || !task_ || !fetcher_) {
        return;
    }
    fetcher_->SaveResponseWithWriter(std::make_unique<TTStreamResponseWriter>(this));
    fetcher_->Start();
}

void TTFetcherDelegateForStreamTask::CancelOnNetThread() {
    if (!is_complete_) {
        timeout_timer_->Stop();
        fetcher_->Cancel(net::ERR_ABORTED);
        OnURLFetchComplete(fetcher_.get());
    }
}

void TTFetcherDelegateForStreamTask::ReadDataWithLength(int minLength,
                                                        int maxLength,
                                                        double timeoutInSeconds,
                                                        OnStreamReadCompleteBlock callback) {
    engine_->GetURLRequestContextGetter()->GetNetworkTaskRunner()->PostTask(
                FROM_HERE, base::Bind(&TTFetcherDelegateForStreamTask::ReadDataWithLengthOnNetworkThread,
                                      this, minLength, maxLength, timeoutInSeconds, callback));
}

void TTFetcherDelegateForStreamTask::ReadDataWithLengthOnNetworkThread(int minLength,
                                                                       int maxLength,
                                                                       double timeoutInSeconds,
                                                                       OnStreamReadCompleteBlock completionHandler) {
    if (completionHandler_) {
        return;
    }
    
    completionHandler_ = completionHandler;
    minLengthForHandler_ = minLength;
    maxLengthForHandler_ = maxLength;
    
    if (timeout_timer_) {
        timeout_timer_->Start(FROM_HERE, base::TimeDelta::FromSecondsD(timeoutInSeconds),
                              base::Bind(&TTFetcherDelegateForStreamTask::OnTimeout, this));
    }
    
    CollectDataAndRunCallbacks(nullptr, 0);
}

int TTFetcherDelegateForStreamTask::CollectDataAndRunCallbacks(net::IOBuffer* callbackData, int callbackDataLength) {
    if (!completionHandler_ || !response_) {
        VLOG(1) << __FUNCTION__ << " return ERR_IO_PENDING because !completionHandler_ = "
                                << !completionHandler_ << " !response_ " << !response_;
        return net::ERR_IO_PENDING;
    }

    int bufferDataLength = GetBufferedDataLength();
    int byteConsumed = 0;
    VLOG(1) <<  __FUNCTION__ << " bufferDataLength = " << bufferDataLength << " callbackDataLength = " << callbackDataLength
            << " minLengthForHandler_ = " << minLengthForHandler_ << " maxLengthForHandler_ = " << maxLengthForHandler_;
    if (bufferDataLength + callbackDataLength > minLengthForHandler_ || isEOF_ || error_) {
        if (timeout_timer_) {
            timeout_timer_->Stop();
        }
        
        NSMutableData* data = nil;
        if (bufferedData_) {
            data = bufferedData_;
        } else {
            data = [[NSMutableData alloc] init];
        }
        
        if (callbackDataLength > 0) {
            byteConsumed = maxLengthForHandler_ - bufferDataLength < callbackDataLength ?
                                maxLengthForHandler_ - bufferDataLength :
                                callbackDataLength;
            [data appendBytes:callbackData->data() length:byteConsumed];
        }
        
        completionHandler_(data, isEOF_, error_, response_);
        completionHandler_ = nil;
        bufferedData_ = nil;
        minLengthForHandler_ = 0;
        maxLengthForHandler_ = 0;
    }
    
    if (!continueNetworkCallback_.is_null()) {
        // Continue the network response write with 0 byte consumed last time.
      std::move(continueNetworkCallback_).Run(0);
    }
    VLOG(1) << __FUNCTION__ << " return " << byteConsumed;
    return byteConsumed;
}

int TTFetcherDelegateForStreamTask::GetBufferedDataLength() {
    return static_cast<int>([bufferedData_ length]);
}

void TTFetcherDelegateForStreamTask::OnTimeout() {
    // If the response header is not return before the error, init it.
    if (!response_) {
        response_ = [[TTHttpResponseChromium alloc] initWithURLFetcher:fetcher_.get()];
    }

    NSDictionary *userInfo = @{kTTNetSubErrorCode : @(NSURLErrorTimedOut),
                               NSLocalizedDescriptionKey : @"the request was timeout",
                               NSURLErrorFailingURLErrorKey : [response_ URL] ? [[response_ URL] absoluteString] : @"nil response URL"};
    error_ = [NSError errorWithDomain:kTTNetworkErrorDomain code:NSURLErrorTimedOut userInfo:userInfo];

    CollectDataAndRunCallbacks(nullptr, 0);
    
    TTFetcherDelegate::OnTimeout();
}
