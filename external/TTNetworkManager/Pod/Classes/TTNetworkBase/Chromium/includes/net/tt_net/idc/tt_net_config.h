#ifndef NET_TTNET_ROUTE_SELECTION_TT_CONFIG_H_
#define NET_TTNET_ROUTE_SELECTION_TT_CONFIG_H_

#include <map>
#include <memory>
#include <string>
#include "base/memory/singleton.h"
#include "base/single_thread_task_runner.h"
#include "base/time/time.h"
#include "base/timer/timer.h"
#include "net/net_buildflags.h"

/* TTNetConfig缓存key值定义*/
#ifndef TT_NET_CONFIG_TNC_CMD_
#define TT_NET_CONFIG_TNC_CMD_

extern const char TT_NET_CONFIG_TNC_CMD[];
extern const char TT_NET_CONFIG_TNC_VERSION[];
extern const char TT_NET_CONFIG_DEVICE_ID[];

extern const char TT_NET_TNC_ETAG[];
extern const char TT_NET_TNC_CANARY[];
extern const char TT_NET_TNC_ABTEST[];
extern const char TT_NET_TNC_CONFIG[];
extern const char RECEIVED_TNC_REGION_CONFIG[];

#endif  //_TT_NET_CONFIG_TNC_CMD_

namespace base {
class ImportantFileWriter;
}

namespace net {

// TTNetConfig 通用本地配置key-value存储类
// 后续包含掉ttserverconfig内容，只存在一个
class TTNetConfig {
 public:
  static TTNetConfig* GetInstance();
  ~TTNetConfig();

  void InitTTNetConfig(
      const std::string& config_file_path,
      scoped_refptr<base::SingleThreadTaskRunner> file_task_runner);
  // string为最基础的类型，基于string拓展出其他类型的配置接口
  //仅修改内存缓存
  std::string GetStringConfig(const std::string& name);
  void SetStringConfig(const std::string& name, const std::string& value);

  int GetIntConfig(const std::string& name, const int& default_value);
  void SetIntConfig(const std::string& name, const int& value);

  size_t GetSizeTConfig(const std::string& name, const size_t& default_value);
  void SetSizeTConfig(const std::string& name, const size_t& value);

  int64_t GetInt64Config(const std::string& name, const int64_t& default_value);
  void SetInt64Config(const std::string& name, const int64_t& value);

  void RemoveConfig(const std::string& name);
  //同步内存缓存至文件
  void SaveConfig();
  //收敛高频save调用，delay时间内，新的调用不触发
  void SaveConfigDelay(int64_t Milliseconds);

#if BUILDFLAG(TTNET_IMPLEMENT_UNITTEST)
  void ClearCacheForTesting() { config_cache_.clear(); }
#endif

 private:
  friend struct base::DefaultSingletonTraits<TTNetConfig>;
  friend class RouteSelectionManager;
#if BUILDFLAG(TTNET_IMPLEMENT_UNITTEST)
  FRIEND_TEST_ALL_PREFIXES(TTNetConfigTest, LoadConfigFromEmptyFile);
  FRIEND_TEST_ALL_PREFIXES(ClientKeyManagerTest, ClientKeySignUnabled);
#endif

  TTNetConfig();

  bool LoadConfig();
  bool LoadConfigFromFile(std::string& content);
  void WriteConfig(const std::string& data) const;

  std::map<std::string, std::string> config_cache_;
  std::string config_file_path_;
  scoped_refptr<base::SingleThreadTaskRunner> file_task_runner_;
  std::unique_ptr<base::ImportantFileWriter> writer_;

  base::OneShotTimer delay_save_timer_;

#if defined(OS_IOS)
  base::TimeTicks net_config_init_time_;
#endif

  DISALLOW_COPY_AND_ASSIGN(TTNetConfig);
};

}  // namespace net

#endif  // NET_TTNET_ROUTE_SELECTION_TT_CONFIG_H_
