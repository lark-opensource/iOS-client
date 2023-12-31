#ifndef NET_TT_NET_TUDP_BIS_STREAM_H_
#define NET_TT_NET_TUDP_BIS_STREAM_H_

#include "base/callback.h"
#include "base/containers/queue.h"
#include "base/memory/weak_ptr.h"
#include "net/net_buildflags.h"

namespace base {
class Value;
}

namespace net {

static constexpr size_t kQueueSizeHighWaterMark = 20000;
static constexpr size_t kQueueSizeLowWaterMark = 1000;

class IOBuffer;

class BisStream {
 public:
  BisStream(uint32_t id, int32_t priority, const std::string& early_data);
  virtual ~BisStream();

  typedef base::OnceCallback<void(int rv, uint32_t stream_id)>
      StreamOnceCallback;

  virtual void InitStream(StreamOnceCallback callback);

  virtual void CloseStream(StreamOnceCallback callback);

  virtual bool IsStreamReady() const = 0;

  virtual int WriteData(const std::string& data,
                        StreamOnceCallback callback) = 0;

  virtual int ReadData(StreamOnceCallback callback) = 0;

  virtual bool fin_received() const = 0;

  virtual char* data() const;

  uint32_t id() const { return stream_id_; }

  int32_t priority() const { return priority_; }

  const std::string early_data() const { return early_data_; }

  std::string& early_data() { return early_data_; }

  size_t read_buffer_size() const;

  static const uint32_t kInitStreamId;

  virtual void OnIOComplete(int rv);

  uint64_t sent_bytes() const { return sent_bytes_; }

  uint64_t received_bytes() const { return received_bytes_; }

#if BUILDFLAG(TTNET_IMPLEMENT_UNITTEST)
  virtual void SetUTInfoForTesting(uint32_t case_id);
#endif

 protected:
  void RunLoop(int result);
  int DoLoop(int result);
  void DoCallback(int rv);

  enum State {
    STATE_NONE,
    STATE_INIT_STREAM,
    STATE_INIT_STREAM_COMPLETE,
    STATE_SEND_EARLY_DATA,
    STATE_SEND_EARLY_DATA_COMPLETE,
    STATE_CLOSE_STREAM,
    STATE_CLOSING_STREAM,
    STATE_CLOSE_STREAM_COMPLETE,
  };

  State next_state_;
  const uint32_t stream_id_;
  int32_t priority_;
  std::string early_data_;
  scoped_refptr<IOBuffer> read_buffer_;
  StreamOnceCallback callback_;
  StreamOnceCallback write_callback_;
  StreamOnceCallback read_callback_;
  base::queue<std::string> pending_data_queue_;
  uint64_t sent_bytes_{0};
  uint64_t received_bytes_{0};

 private:
  virtual void ProcessResult(int rv);

  virtual int DoInitStream() = 0;

  virtual int DoInitStreamComplete(int rv) = 0;

  virtual int DoCloseStream();

  virtual int DoClosingStream();

  virtual int DoCloseStreamComplete(int rv);

  virtual int DoSendEarlyData() = 0;

  virtual int DoSendEarlyDataComplete(int rv) = 0;

  virtual void Close() = 0;

  base::WeakPtrFactory<BisStream> weak_factory_;

  DISALLOW_COPY_AND_ASSIGN(BisStream);
};

}  // namespace net

#endif  // NET_TT_NET_TUDP_BIS_STREAM_H_
