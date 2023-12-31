#ifndef CANVAS_GPU_VIRTUALIZATION_ES_STATE_QUERY_MANAGE_H_
#define CANVAS_GPU_VIRTUALIZATION_ES_STATE_QUERY_MANAGE_H_

#include <memory>
#include <unordered_map>

#include "es_state_query.h"
#include "third_party/krypton/canvas/gpu/gl/gl_include.h"

namespace lynx {
namespace canvas {
class EsStateQueryManage final {
 public:
  bool CreateItems(uint32_t, int*);
  bool DeleteItems(uint32_t, int*);
  bool IsAvaliable(int);
  std::shared_ptr<EsStateQuery> Get(int);

 private:
  int id_dispatcher_ = 0;
  std::unordered_map<int, std::shared_ptr<EsStateQuery>> pools_;
};

}  // namespace canvas
}  // namespace lynx

#endif  // CANVAS_GPU_VIRTUALIZATION_ES_STATE_QUERY_MANAGE_H_
