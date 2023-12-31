#ifndef NET_TT_NET_IDC_TT_MULTI_IDC_MANAGER_H_
#define NET_TT_NET_IDC_TT_MULTI_IDC_MANAGER_H_

#include <map>
#include <string>

#include "base/memory/singleton.h"
#include "base/timer/timer.h"
#include "net/tt_net/route_selection/tt_server_config.h"

namespace base {
class DictionaryValue;
}

namespace net {

class URLRequest;

class TTMultiIdcManager : public TTServerConfigObserver {
 public:
  static TTMultiIdcManager* GetInstance();

  // TNC
  struct TNCServerConfig {
    size_t
        tnc_local_strategy_enable;  //是否开启TNC本地判断策略(0关闭，1开启)，默认开启
    size_t tnc_probe_enable;  //是否开启TNC探针策略(0关闭，1开启)，默认开启

    size_t tnc_local_strategy_offline_enable;
    size_t tnc_probe_offline_enable;

    std::map<std::string, std::string>
        host_replace_map;  //最终需要替换的域名映射
    std::map<std::string, uint64_t>
        local_host_filter_map;  //需要执行本地判断策略的域名列表

    size_t req_error_count;
    size_t req_error_api_count;
    size_t req_error_ip_count;
    size_t req_error_host_count;
    size_t tnc_update_interval;      //单位: s秒
    size_t tnc_update_random_range;  //单位: s秒

    size_t all_http_error_code;
    std::map<int, int> http_error_code;

    size_t filt_write_method = 0;  // PUT,POST请求不调度

    TNCServerConfig(const TNCServerConfig& node);
    TNCServerConfig();
    ~TNCServerConfig();
  };

  void OnServerConfigChanged(
      const UpdateSource source,
      const base::Optional<base::Value>& tnc_config_value) override;
  bool ParseJsonResult(const base::Optional<base::Value>& tnc_config_value);

  // TNC多机房容灾
  //请求结果处理：TNC
  void HandleRequestResult(net::URLRequest* url_request, int net_error);
  bool HandleTNCHostReplace(std::string& original_url,
                            const std::string& be_replaced_str,
                            const std::string& scheme,
                            const std::string& method);
  void NotifyProbeUpdateSucc(int64_t probe_version, int64_t probe_cmd);
  void UpdateRemoteTNCConfig(const UpdateSource& source,
                             bool random,
                             int64_t probe_version = 0,
                             int64_t probe_cmd = 0);
#if BUILDFLAG(TTNET_IMPLEMENT_UNITTEST)
  int GetTncDrReqErrorCountForTesting() const {
    return tnc_dr_req_error_count_;
  }
  void ResetTNCStatesForTesting() { ResetTNCControlStates(); }
#endif

 private:
  friend struct base::DefaultSingletonTraits<TTMultiIdcManager>;
#if BUILDFLAG(TTNET_IMPLEMENT_UNITTEST)
  friend class TTNetworkDelegateTest;
  FRIEND_TEST_ALL_PREFIXES(TTMultiIdcManagerTest, ForceUpdateNetworkType);
#endif
  TTMultiIdcManager();
  ~TTMultiIdcManager() override;
  DISALLOW_COPY_AND_ASSIGN(TTMultiIdcManager);

#if defined(OS_ANDROID) || BUILDFLAG(TTNET_IMPLEMENT_UNITTEST)
  int64_t last_force_update_network_type_time_{0};
#endif

  /* TNC config */
  TNCServerConfig tnc_server_config_;
  std::map<std::string, uint64_t> local_host_filter_map_default_;
  base::OneShotTimer update_config_delay_timer_;
  void handleParseTNCConfig(const base::DictionaryValue* dict);
  void SetDefaultTNCConfig();
  void InitTNCLocalHostFilterMap();
  void GetJsonNodeAsSize_t(const base::DictionaryValue* json_dict,
                           std::string name,
                           size_t* aim_constant,
                           size_t default_value);

  /* TNC容灾控制参数 */
  /* DS: disaster recovery */
  /* THR: thredshold */
  // TNC容灾策略： 请求失败场景控制参数
  size_t tnc_dr_req_error_count_{0};
  std::map<std::string, uint64_t> tnc_dr_req_error_api_map_;
  std::map<std::string, uint64_t> tnc_dr_req_error_conn_map_;
  std::map<std::string, uint64_t> tnc_dr_req_error_host_map_;

  // TNC触发GETDOMAIN频率控制
  base::Time tnc_dr_last_update_time_;
  // //调用handleReqRslt4TNC方法需加锁
  // std::mutex tnc_dr_handle_mutex_;
  bool tnc_task_pending_{false};

  // TNC探针协议处理
  void HandleTNCProbe(net::URLRequest* url_request);
  void ResetTNCControlStates();
  void DoUpdateRemoteTNCConfig(const UpdateSource& source,
                               int64_t probe_version = 0,
                               int64_t probe_cmd = 0,
                               int delay = 0);
#if defined(OS_ANDROID) || BUILDFLAG(TTNET_IMPLEMENT_UNITTEST)
  bool ForceUpdateNetworkTypeIfOfflineButRequestSuccess(int net_error);
#endif
};

}  // namespace net

#endif  // NET_TT_NET_IDC_TT_MULTI_IDC_MANAGER_H_
