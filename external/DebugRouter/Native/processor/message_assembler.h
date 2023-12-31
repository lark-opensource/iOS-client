#ifndef message_assembler_h_
#define message_assembler_h_

#include <string>
#include <unordered_map>

namespace debugrouter {
namespace processor {

class MessageAssembler {
public:
  static std::string AssembleDispatchDocumentUpdated();
  static std::string AssembleDispatchFrameNavigated(std::string url);
  static std::string AssembleDispatchScreencastVisibilityChanged(bool status);
  static std::string AssembleScreenCastFrame(
      int session_id, const std::string &data,
      const std::unordered_map<std::string, float> &metadata);
};

} // namespace processor
} // namespace debugrouter

#endif /* message_assembler_h_ */
