
#include "es_state_query_manage.h"

#include "canvas/base/log.h"
namespace lynx {
namespace canvas {

bool EsStateQueryManage::CreateItems(uint32_t size, int* ret_arr) {
  if (0 < size && nullptr != ret_arr) {
    for (uint32_t i = 0; i < size; ++i) {
      auto _id = ++id_dispatcher_;
      pools_[_id] = std::make_shared<EsStateQuery>((int)_id);
      ret_arr[i] = _id;
    }
  }
  return true;
}

bool EsStateQueryManage::DeleteItems(uint32_t size, int* arr) {
  if (0 < size && nullptr != arr) {
    for (uint32_t i = 0; i < size; ++i) {
      auto iter = pools_.find(arr[i]);
      if (pools_.end() != iter) {
        DCHECK(iter->second);
        iter->second->Destory();
        pools_.erase(iter);
      }
    }
  }
  return true;
}

bool EsStateQueryManage::IsAvaliable(int i) {
  return pools_.find(i) != pools_.end();
}

std::shared_ptr<EsStateQuery> EsStateQueryManage::Get(int index) {
  auto iter = pools_.find(index);
  if (pools_.end() != iter) {
    return iter->second;
  }
  return nullptr;
}
}  // namespace canvas
}  // namespace lynx
