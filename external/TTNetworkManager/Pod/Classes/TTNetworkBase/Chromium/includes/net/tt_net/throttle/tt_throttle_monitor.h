#ifndef NET_TTNET_THROTTLE_TT_THROTTLE_MONITOR_H_
#define NET_TTNET_THROTTLE_TT_THROTTLE_MONITOR_H_

#include <map>
#include <string>

#include "base/memory/singleton.h"
#include "base/observer_list.h"
#include "net/net_buildflags.h"
#if defined(OS_ANDROID) && BUILDFLAG(ENABLE_WEBSOCKETS)
#include "net/tt_net/ipc/ipc_message.h"
#endif

namespace net {

const int32_t kNoThrottle = -1;

class URLRequest;

class ThrottleMonitor {
 public:
  static ThrottleMonitor* GetInstance();
  ~ThrottleMonitor();

  enum StreamDirection {
    // For normal connection.
    UP_STREAM = 0x1,
    DOWN_STREAM = 0x2,
    // For persistent connection.
    PC_UP_STREAM = 0x4,
    PC_DOWN_STREAM = 0x8,
    // For clearing connection.
    ALL_STREAM = UP_STREAM | DOWN_STREAM | PC_UP_STREAM | PC_DOWN_STREAM
  };

  // Enumerations and struct for [Speed Throttle Feature II]
  enum ThrottleLevel {
    NONE = 0x1,
    LOW = 0x2,
    MEDIUM = 0x4,
    HIGH = 0x8,
    // For clearing throttles.
    ALL_LEVEL = NONE | LOW | MEDIUM | HIGH
  };
  enum ThrottleMode {
    TT_THROTTLE_MODE_UNSET = 1 << 1,
    TT_THROTTLE_MODE_IS_DOMAIN = 1 << 2,
    TT_THROTTLE_MODE_IS_REQUEST = 1 << 3
  };

  struct ThrottleGear {
    ThrottleGear();
    ThrottleGear(int32_t low_throttle,
                 int32_t medium_throttle,
                 int32_t high_throttle);

    bool operator==(const ThrottleGear& other) const;
    bool operator!=(const ThrottleGear& other) const;

    int32_t low_throttle;
    int32_t medium_throttle;
    int32_t high_throttle;
  };

  class Observer {
   public:
    virtual void OnThrottleChanged(
        const std::set<std::string>& hosts,
        StreamDirection direction,
        const int32_t bytes_per_sec,
        ThrottleLevel level = ThrottleLevel::ALL_LEVEL) = 0;

   protected:
    Observer();
    virtual ~Observer();

   private:
    DISALLOW_COPY_AND_ASSIGN(Observer);
  };

  class ThrottleObserver {
   public:
    virtual void OnStatistics(int32_t error,
                              const std::string& url,
                              const std::string& method,
                              int32_t actual_down_speed,
                              int32_t given_down_speed,
                              int32_t actual_up_speed,
                              int32_t given_up_speed) = 0;

    virtual void OnPCStatistics(const std::string& url,
                                int32_t pre_given_down_speed,
                                int32_t cur_given_down_speed,
                                int32_t pre_actual_down_speed,
                                int32_t pre_given_up_speed,
                                int32_t cur_given_up_speed,
                                int32_t pre_actual_up_speed) = 0;

   protected:
    ThrottleObserver();
    virtual ~ThrottleObserver();

   private:
    DISALLOW_COPY_AND_ASSIGN(ThrottleObserver);
  };

  void Init();

  void AddThrottle(const std::vector<std::string>& hosts,
                   StreamDirection direction,
                   uint32_t bytes_per_sec);

  void RemoveThrottle(const std::vector<std::string>& hosts,
                      StreamDirection direction);

  void ClearThrottles();

  bool IsDropThrottleRequest(base::WeakPtr<URLRequest> request);

  void RequestFinish(base::WeakPtr<URLRequest> request);

  int64_t GetThrottle(const std::string& host,
                      StreamDirection direction,
                      base::WeakPtr<URLRequest> request = nullptr) const;

  void InitObserver(ThrottleObserver* observer);

  void ResetObserver();

  bool HasInitObserver() const;

  void Notify(int32_t error,
              const std::string& url,
              const std::string& method,
              int32_t actual_down_speed,
              int32_t given_down_speed,
              int32_t actual_up_speed,
              int32_t given_up_speed);

  void PCNotify(const std::string& url,
                int32_t pre_given_down_speed,
                int32_t cur_given_down_speed,
                int32_t pre_actual_down_speed,
                int32_t pre_given_up_speed,
                int32_t cur_given_up_speed,
                int32_t pre_actual_up_speed);

  void AddObserver(Observer* observer);

  void RemoveObserver(Observer* observer);

  static ThrottleMonitor::ThrottleLevel StringToEnum(const std::string& level);
  static ThrottleLevel GetThrottleLevelFromIsolationKey(
      const std::string& isolation_key);
  // Public functions for [Speed Throttle II]
  int GetThrottleMode() const { return throttle_mode_; }
  void AddThrottle(const std::vector<std::string>& hosts,
                   StreamDirection direction,
                   int32_t low_throttle,
                   int32_t medium_throttle,
                   int32_t high_throttle);

 private:
  friend struct base::DefaultSingletonTraits<ThrottleMonitor>;
  ThrottleMonitor();

  struct ThrottleKey {
    ThrottleKey();
    ThrottleKey(const std::string& host, StreamDirection direction);

    bool operator<(const ThrottleKey& other) const;
    bool operator==(const ThrottleKey& other) const;
    bool operator!=(const ThrottleKey& other) const;

    std::string host;
    StreamDirection direction{UP_STREAM};
  };

  void AdjustSpeedForRequests(const std::string& host,
                              StreamDirection direction,
                              int32_t given_speed,
                              ThrottleLevel level = ThrottleLevel::ALL_LEVEL);
  void RemoveDomainThrottle(const std::vector<std::string>& hosts,
                            StreamDirection direction);
  void ShutdownThrottle(const std::string& host, StreamDirection direction);

  std::set<std::string> FindHitHostsNotInSpecificList(
      StreamDirection direction);

  // The value of |bytes_per_sec| only be -1, 0 or a positive number
  // greater than 20KB.
  // The value of -1 represents the throttle for hosts in list is canceled.
  void NotifyObserversOfCurrentThrottle(
      const std::set<std::string>& hosts,
      StreamDirection direction,
      int32_t bytes_per_sec,
      ThrottleLevel level = ThrottleLevel::ALL_LEVEL);

  // Private functions and variables for [Speed Throttle Feature II].
  void RemoveRequestThrottle(const std::vector<std::string>& hosts,
                             StreamDirection direction);
#if defined(OS_ANDROID) && BUILDFLAG(ENABLE_WEBSOCKETS)
 public:
  void OnIPCMessageReceived(const Message& message);

 private:
  void NotifySubProcesses(
      const std::map<ThrottleKey, ThrottleGear>& level_throttles);
  void UpdateConfigInSubProcess(const Message& message);
#endif

  ThrottleMode throttle_mode_{TT_THROTTLE_MODE_UNSET};
  std::map<ThrottleKey, ThrottleGear> level_throttles_;

  std::map<ThrottleKey, uint32_t> specific_throttles_;
  std::map<StreamDirection, uint32_t> generic_throttles_;
  // Not own ThrottleObserver.
  ThrottleObserver* observer_{nullptr};

  base::ObserverList<Observer>::Unchecked observer_list_;
  std::vector<base::WeakPtr<URLRequest>> requests_list_;

  DISALLOW_COPY_AND_ASSIGN(ThrottleMonitor);
};

}  // namespace net

#endif  // NET_TTNET_THROTTLE_TT_THROTTLE_MONITOR_H_
