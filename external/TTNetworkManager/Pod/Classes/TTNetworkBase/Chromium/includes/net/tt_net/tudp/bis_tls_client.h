#ifndef NET_TT_NET_TUDP_BIS_TLS_CLIENT_H_
#define NET_TT_NET_TUDP_BIS_TLS_CLIENT_H_

#include "base/containers/queue.h"
#include "base/memory/weak_ptr.h"
#include "net/tt_net/tudp/bis_client.h"

namespace net {

class IOBuffer;
class StreamSocket;

class BisTlsClient : public BisClient {
 public:
  BisTlsClient(Delegate* delegate, const ConnConfig& config);
  ~BisTlsClient() override;

  // BisClient implemenations:
  void CreateStream(uint32_t stream_id,
                    int32_t priority,
                    const std::string& early_data) override;
  bool IsStreamReady(uint32_t stream_id) const override;
  void SendData(uint32_t stream_id, const std::string& data) override;
  void CloseStream(uint32_t stream_id) override;

 private:
#if BUILDFLAG(TTNET_IMPLEMENT_UNITTEST)
  friend class BisTlsClientTest;
#endif

  struct StreamInfo {
    StreamInfo();
    StreamInfo(int32_t priority, const std::string& early_data);
    StreamInfo(const StreamInfo&);
    ~StreamInfo();

    int32_t priority;
    std::string early_data;
    bool queue_full;
  };

  // BisClient implemenations:
  void CreateStreamInternal(uint32_t stream_id,
                            int32_t priority,
                            const std::string& early_data) override;
  void OnStreamComplete(int rv, uint32_t stream_id) override;
  void OnReadComplete(int rv, uint32_t stream_id) override;
  void OnConnectionComplete(int rv) override;

  int WriteData(uint32_t stream_id, const std::string& data);
  int WriteDataInternal(const std::string& data);
  void DidCompleteWrite(int rv);

  int ReadData();
  void DidCompleteRead(int rv);

 private:
  bool can_send_data_{true};
  bool can_read_data_{true};
  StreamSocket* socket_{nullptr};

  base::queue<std::string> pending_data_queue_;

  std::map<uint32_t, StreamInfo> stream_info_;

  scoped_refptr<IOBuffer> read_buffer_;

  base::WeakPtrFactory<BisTlsClient> weak_factory_;

  DISALLOW_COPY_AND_ASSIGN(BisTlsClient);
};

}  // namespace net

#endif  // NET_TT_NET_TUDP_BIS_TLS_CLIENT_H_
