#ifndef NET_TTNET_FILE_SSL_SESSION_CACHE_MANAGER_H_
#define NET_TTNET_FILE_SSL_SESSION_CACHE_MANAGER_H_

#include <set>
#include <string>
#include <vector>
#include "base/files/file_path.h"
#include "base/memory/ref_counted.h"
#include "base/memory/singleton.h"
#include "net/base/host_port_pair.h"
#include "net/base/network_isolation_key.h"
#include "net/tt_net/route_selection/tt_server_config.h"
#include "third_party/boringssl/src/include/openssl/base.h"
#include "third_party/boringssl/src/include/openssl/ssl.h"
namespace net {
using IsolationKeyToSessionMap =
    std::map<std::string, bssl::UniquePtr<SSL_SESSION>>;
using HostToSessionStorageCacheMap =
    std::map<std::string, IsolationKeyToSessionMap>;
class TTFileSslSessionCacheManager : public TTServerConfigObserver {
 public:
  static TTFileSslSessionCacheManager* GetInstance();
  ~TTFileSslSessionCacheManager() override;

  void SetSslSession(const std::string& origin_host_port,
                     SSL_SESSION* session,
                     const NetworkIsolationKey& network_isolation_key);
  bssl::UniquePtr<SSL_SESSION> GetSslSession(
      const std::string& origin_host_port,
      const NetworkIsolationKey& network_isolation_key);
  void OnServerConfigChanged(
      const UpdateSource source,
      const base::Optional<base::Value>& tnc_config_value) override;
  void Start(const std::string& path);
  void HandleRemoteSessionConfig(SSL_SESSION* session,
                                 const HostPortPair& hostAndPort);

  void ClearEarlyData(const std::string& origin_host_port,
                      const NetworkIsolationKey& network_isolation_key);

  void RemoveSslSessionForClientCertificates(
      const std::string& origin_host_port);

 private:
#if BUILDFLAG(TTNET_IMPLEMENT_UNITTEST)
  friend class TTFileSslSessionCacheManagerTest;
  FRIEND_TEST_ALL_PREFIXES(TTFileSslSessionCacheManagerTest, SetSslSession);
  FRIEND_TEST_ALL_PREFIXES(TTFileSslSessionCacheManagerTest, LoadFileCache);
  FRIEND_TEST_ALL_PREFIXES(TTFileSslSessionCacheManagerTest, ReadFileCacheData);
  FRIEND_TEST_ALL_PREFIXES(TTFileSslSessionCacheManagerTest,
                           HandleRemoteSessionConfig);
  FRIEND_TEST_ALL_PREFIXES(TTFileSslSessionCacheManagerTest, ClearEarlyData);

  void SetNowForTesting(time_t now_for_testing) {
    now_for_testing_ = now_for_testing;
  }
  time_t now_for_testing_;
#endif
  friend struct base::DefaultSingletonTraits<TTFileSslSessionCacheManager>;
  TTFileSslSessionCacheManager();

  base::FilePath cache_path_;
  bool enable_file_cache_{false};
  std::set<std::string> file_cache_host_port_list_;
  std::vector<std::set<std::string>> file_cache_host_port_group_list_;

  int session_timeout_{2 * 60 * 60};
  size_t file_cache_timeout_limit_{60 * 60};

  bool init_finished_{false};
  bool start_executed_{false};

  // file_cache_: A map used to store sessions.
  // Example: HostToSessionStorageCacheMap[host] = IsolationKeyToSessionMap.
  // IsolationKeyToSessionMap[isolation_key] = session.
  // The HostToSessionStorageCacheMap is used to find out whether there is
  // session data corresponding to the host, and its data exists in the
  // IsolationKeyToSessionMap structure. The IsolationKeyToSessionMap is used to
  // find out whether there is an actual session corresponding to the
  // isolation_key.
  HostToSessionStorageCacheMap file_cache_;
  scoped_refptr<base::SingleThreadTaskRunner> file_task_runner_;
  scoped_refptr<base::SingleThreadTaskRunner> net_thread_task_runner_;

  // The following functions run on File thread.
  void SetFileCachePath(const std::string& path);
  void DeleteCacheData(const std::string& host_port,
                       const std::string& isolation_key,
                       bool isolation_key_ignored);
  void WriteCacheFile(const std::string& host_port,
                      unsigned char* data,
                      size_t len,
                      const std::string& isolation_key);
  void LoadFileCache(const std::set<std::string>& whitelist,
                     const std::vector<std::set<std::string>>& group_whitelist,
                     const std::string& path);
  // LoadFileCacheForHostPort：find out whether there is a corresponding session
  // cache based on the host_port.
  // The return value is a map. Example: map[isolation_key] = session.
  IsolationKeyToSessionMap LoadFileCacheForHostPort(
      const std::string& host_port);
  bssl::UniquePtr<SSL_SESSION> LoadFileCacheForKey(
      const std::string& host_port,
      const std::string& isolation_key,
      std::unique_ptr<base::DictionaryValue>& json_info);
  std::unique_ptr<base::DictionaryValue> ReadFileCacheData(
      const base::FilePath& cache_file);

  // The following functions run on IO thread.
  void InitDefaultConfig();
  void StartTaskCompletedOnNetworkThread(
      HostToSessionStorageCacheMap file_cache);

  // The following functions run on File thread or IO thread.
  void RemoveSslSession(const std::string& host_port,
                        const std::string& isolation_key,
                        bool isolation_key_ignored = false);
  bool IsExpired(SSL_SESSION* session, time_t now) const;
  std::string FormatTimeAsString(long timestamp) const;

  base::ThreadChecker network_thread_checker_;
  base::ThreadChecker file_thread_checker_;

  DISALLOW_COPY_AND_ASSIGN(TTFileSslSessionCacheManager);
};

}  // namespace net

#endif  // NET_TTNET_FILE_SSL_SESSION_CACHE_MANAGER_H_
