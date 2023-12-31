#ifndef STATE_LISTENER_H_
#define STATE_LISTENER_H_

#include <string>

namespace debugrouter {
namespace processor {

class StateListener {
public:
  virtual void onOpen() = 0;
  virtual void onClosed() = 0;
  virtual void onError(const std::string &error) = 0;
};

} // namespace processor
} // namespace debugrouter

#endif // STATE_LISTENER_H_
