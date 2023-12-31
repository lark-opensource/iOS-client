//
//  TTFetcherDelegateForCommonTask.h
//  Pods
//
//  Created by liuyichen on 2019/3/31.
//

#ifndef TTFetcherDelegateForCommonTask_h
#define TTFetcherDelegateForCommonTask_h

#import "TTHttpTaskChromium.h"

#include "net/url_request/url_fetcher_response_writer.h"

class TTChunkedResponseWriter : public net::URLFetcherResponseWriter {
 public:
    class Delegate {
     public:
        virtual void OnResponseDataReceived(net::IOBuffer* buffer, int num_bytes) = 0;
        
        virtual ~Delegate() {};
    };
    
    TTChunkedResponseWriter(Delegate* delegate);
    ~TTChunkedResponseWriter() override;
    
    int Initialize(net::CompletionOnceCallback callback) override;
    
    int Write(net::IOBuffer* buffer,
              int num_bytes,
              net::CompletionOnceCallback callback) override;
    
    int Finish(int net_error, net::CompletionOnceCallback callback) override;

 private:
    // The URLFetcher own |this| must have short life than |TTFetcherDelegate|,
    // so use raw pointer is okay. Using |scoped_refptr| causes loop dependency.
    Delegate* delegate_;
    
    DISALLOW_COPY_AND_ASSIGN(TTChunkedResponseWriter);
};

class TTFetcherDelegateForCommonTask : public TTFetcherDelegate,
                                       public TTChunkedResponseWriter::Delegate {
 public:
    TTFetcherDelegateForCommonTask(__weak TTHttpTaskChromium *task, cronet::CronetEnvironment *engine, bool is_chunked_task);
    
    // URLFetcherDelegate methods:
    void OnURLResponseStarted(const net::URLFetcher* source) override;
    
    void OnURLFetchComplete(const net::URLFetcher* source) override;
    
    void OnURLFetchDownloadProgress(const net::URLFetcher* source,
                                    int64_t current,
                                    int64_t total,
                                    int64_t current_network_bytes) override;
    
    void OnURLFetchUploadProgress(const net::URLFetcher* source,
                                  int64_t current,
                                  int64_t total) override;
    
    void OnURLRedirectReceived(const net::URLFetcher* source,
                               const net::RedirectInfo& redirect_info,
                               const net::HttpResponseInfo& response_info) override;
    
    // TTChunkedResponseWriter::Delegate method:
    void OnResponseDataReceived(net::IOBuffer* buffer, int num_bytes) override;
    
 private:
    friend class base::RefCountedThreadSafe<TTFetcherDelegateForCommonTask>;
    ~TTFetcherDelegateForCommonTask() override;
                                           
    void CreateURLFetcherOnNetThread() override;
    void CancelOnNetThread() override;
    
    void DispatchResponseDataInternal(NSMutableData* data);
                                           
    bool is_chunked_task_;
    bool is_upload_callback_needed_;
    bool is_download_callback_needed_;
                                           
    DISALLOW_COPY_AND_ASSIGN(TTFetcherDelegateForCommonTask);
};


#endif /* TTFetcherDelegateForCommonTask_h */
