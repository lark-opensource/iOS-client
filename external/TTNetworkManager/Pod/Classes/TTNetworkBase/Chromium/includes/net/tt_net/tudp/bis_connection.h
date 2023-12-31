#ifndef NET_TT_NET_TUDP_BIS_CONNECTION_H_
#define NET_TT_NET_TUDP_BIS_CONNECTION_H_

#include "net/base/completion_once_callback.h"
#include "net/base/host_port_pair.h"
#include "net/proxy_resolution/proxy_info.h"

namespace base {
class Value;
}

namespace net {

class BisConnection {
 public:
  BisConnection(const HostPortPair& destination, uint32_t timeout);
  virtual ~BisConnection();

  virtual void InitConnection(CompletionOnceCallback callback) = 0;

  virtual void CloseConnection(CompletionOnceCallback callback) = 0;

  virtual bool IsConnected() const = 0;

  virtual std::unique_ptr<base::Value> GetExtraInfo() = 0;

  bool IsConnecting() const { return next_state_ == STATE_INIT_CONNECTING; }

  std::string final_host() const { return final_destination_.host(); }

  static const uint32_t kConnectionId = 0;

 protected:
  void RunLoop(int rv);
  int DoLoop(int rv);

  std::unique_ptr<base::Value> ConstructBaseBlock() const;

  enum State {
    STATE_NONE,
    STATE_RESOLVE_PROXY,
    STATE_RESOLVE_PROXY_COMPLETE,
    STATE_INIT_CONNECTION,
    STATE_INIT_CONNECTING,
    STATE_INIT_CONNECTION_COMPLETE,
    STATE_CLOSE_CONNECTION,
    STATE_CLOSE_CONNECTION_COMPLETE,
  };

  HostPortPair final_destination_;
  const HostPortPair destination_;
  State next_state_;
  uint32_t conn_timeout_;
  int result_;
  base::TimeTicks start_time_;
  base::TimeTicks end_time_;
  ProxyInfo proxy_info_;

 private:
  virtual void ProcessResult(int rv);

  virtual int DoResolveProxy() = 0;

  virtual int DoResolveProxyComplete(int rv) = 0;

  virtual int DoInitConnection() = 0;

  virtual int DoInitConnecting(int rv) = 0;

  virtual int DoInitConnectionComplete(int rv) = 0;

  virtual int DoCloseConnection() = 0;

  virtual int DoCloseConnectionComplete(int rv) = 0;
};

}  // namespace net

#endif  // NET_TT_NET_TUDP_BIS_CONNECTION_H_
