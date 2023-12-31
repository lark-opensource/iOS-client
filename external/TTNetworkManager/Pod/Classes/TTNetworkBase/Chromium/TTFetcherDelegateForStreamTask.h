//
//  TTFetcherDelegateForStreamTask.h
//  Pods
//
//  Created by liuyichen on 2019/4/1.
//

#ifndef TTFetcherDelegateForStreamTask_h
#define TTFetcherDelegateForStreamTask_h

#import "TTHttpTaskChromium.h"

#include "net/base/io_buffer.h"
#include "net/url_request/url_fetcher_response_writer.h"

class TTStreamResponseWriter : public net::URLFetcherResponseWriter {
 public:
    class Delegate {
     public:
        virtual void OnResponseDataStarted() = 0;
        virtual int OnResponseDataReceived(net::IOBuffer* buffer, int num_bytes, net::CompletionOnceCallback callback) = 0;
        virtual void OnResponseDataFinished() = 0;
        
        virtual ~Delegate() {};
    };
    
    TTStreamResponseWriter(Delegate* delegate);
    ~TTStreamResponseWriter() override;
    
    int Initialize(const net::CompletionOnceCallback callback) override;
    
    int Write(net::IOBuffer* buffer,
              int num_bytes,
              net::CompletionOnceCallback callback) override;
    
    int Finish(int net_error, net::CompletionOnceCallback callback) override;

 private:
    // The URLFetcher own |this| must have short life than |TTFetcherDelegate|,
    // so use raw pointer is okay. Using |scoped_refptr| causes loop dependency.
    Delegate* delegate_;
    
    DISALLOW_COPY_AND_ASSIGN(TTStreamResponseWriter);
};

class TTFetcherDelegateForStreamTask : public TTFetcherDelegate,
                                       public TTStreamResponseWriter::Delegate {
 public:
    TTFetcherDelegateForStreamTask(__weak TTHttpTaskChromium *task, cronet::CronetEnvironment *engine);
    
    // URLFetcherDelegate methods:
    void OnURLResponseStarted(const net::URLFetcher* source) override;
    
    void OnURLFetchComplete(const net::URLFetcher* source) override;
       
    // TTStreamResponseWriter::Delegate method:
    void OnResponseDataStarted() override;
                            
    int OnResponseDataReceived(net::IOBuffer* buffer, int num_bytes, net::CompletionOnceCallback callback) override;
                                           
    void OnResponseDataFinished() override;
                                           
    // TTFetcherDelegate methods:
    void ReadDataWithLength(int minLength, int maxLength, double timeoutInSeconds, OnStreamReadCompleteBlock completionHandler) override;
    void OnTimeout() override;
    
 private:
    friend class base::RefCountedThreadSafe<TTFetcherDelegateForStreamTask>;
    ~TTFetcherDelegateForStreamTask() override;
             
    int CollectDataAndRunCallbacks(net::IOBuffer* callbackData, int callbackDataLength);
    void ReadDataWithLengthOnNetworkThread(int minLength, int maxLength, double timeoutInSeconds, OnStreamReadCompleteBlock completionHandler);
                                           
    inline int GetBufferedDataLength();

    // TTFetcherDelegate methods:
    void CreateURLFetcherOnNetThread() override;
    void CancelOnNetThread() override;

    OnStreamReadCompleteBlock completionHandler_;
    int minLengthForHandler_;
    int maxLengthForHandler_;
                           
    TTHttpResponseChromium* response_;
    
    // Save data less than the minLength required.
    NSMutableData* bufferedData_;
                                           
    NSError* error_;
    BOOL isEOF_;
                                           
    net::CompletionOnceCallback continueNetworkCallback_;
                                           
    DISALLOW_COPY_AND_ASSIGN(TTFetcherDelegateForStreamTask);
};


#endif /* TTFetcherDelegateForStreamTask_h */
