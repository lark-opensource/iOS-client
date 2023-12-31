#ifndef NET_TT_NET_TUDP_BIS_HTTP2_STREAM_H_
#define NET_TT_NET_TUDP_BIS_HTTP2_STREAM_H_

#include "net/spdy/spdy_stream.h"
#include "net/tt_net/tudp/bis_client.h"
#include "net/tt_net/tudp/bis_stream.h"
#include "net/url_request/url_fetcher_delegate.h"

namespace net {

class HttpNetworkSession;
class SpdySession;
class URLFetcher;

class BisHttp2Stream : public BisStream,
                       public URLFetcherDelegate,
                       public SpdyStream::Delegate {
 public:
  BisHttp2Stream(uint32_t stream_id,
                 int32_t priority,
                 const std::string& early_data,
                 const BisClient::ConnConfig& config);
  ~BisHttp2Stream() override;

  // BisStream implementations:
  bool IsStreamReady() const override;
  int WriteData(const std::string& data, StreamOnceCallback callback) override;
  int ReadData(StreamOnceCallback callback) override;
  bool fin_received() const override;

 private:
#if BUILDFLAG(TTNET_IMPLEMENT_UNITTEST)
  friend class BisHttp2ClientTest;
#endif

  // BisStream implementations:
  void Close() override;
  int DoInitStream() override;
  int DoInitStreamComplete(int rv) override;
  int DoSendEarlyData() override;
  int DoSendEarlyDataComplete(int rv) override;

  // URLFetcherDelegate implementations:
  void OnURLFetchComplete(const URLFetcher* source) override;
  void OnURLResponseStarted(const URLFetcher* source) override;

  // SpdyStream::Delegate implementations:
  void OnHeadersSent() override;
  void OnHeadersReceived(
      const spdy::SpdyHeaderBlock& response_headers,
      const spdy::SpdyHeaderBlock* pushed_request_headers) override;
  void OnDataReceived(std::unique_ptr<SpdyBuffer> buffer) override;
  void OnDataSent() override;
  void OnTrailers(const spdy::SpdyHeaderBlock& trailers) override;
  void OnClose(int status) override;
  NetLogSource source_dependency() const override;
  bool CanGreaseFrameType() const override;

  void DidCompleteRead(int rv);
  void DidCompleteWrite(int rv);
  int WriteDataInternal();

  std::unique_ptr<URLFetcher> fetcher_;
  HttpNetworkSession* const session_;
  NetworkTrafficAnnotationTag traffic_annotation_;
  base::WeakPtr<SpdyStream> stream_;
  base::WeakPtr<SpdySession> spdy_session_;
  uint32_t ping_period_;
  size_t previous_data_size_;
  bool can_send_data_;
  bool has_recv_response_;
  SpdyStream::Delegate* origin_delegate_;

  base::WeakPtrFactory<BisHttp2Stream> weak_factory_;

  DISALLOW_COPY_AND_ASSIGN(BisHttp2Stream);
};

}  // namespace net
#endif  // NET_TT_NET_TUDP_BIS_HTTP2_STREAM_H_
