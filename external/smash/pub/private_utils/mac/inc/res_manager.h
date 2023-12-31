#ifndef _SMASH_PRIVATE_UTILS_H_
#define _SMASH_PRIVATE_UTILS_H_

#include <string>
#include <thread>
#include "ResParser.h"
#include "internal_smash.h"
#include "smash_base.h"
#include "tt_common.h"

SMASH_NAMESPACE_OPEN
NAMESPACE_OPEN(private_utils)

// ResourceManager - 处理资源文件
// 使用样例:
//   auto& res_manager_ = std::make_shared<ResourceManager>("tt_sample_v1.0",
//   2); res_manager_->LoadResource(model_path); // model_path 是资源文件的路径
//   void* source = nullptr;
//   int source_len = 0;
//   res_manager_->GetResourceWithBlockNum(1, &source, source_len);
class ResourceManager {
 public:
  // 参数:
  //   version  : 资源文件的版本号
  //   block_num: 资源文件里存储了几个区域块
  explicit ResourceManager(std::string&& version, int block_num);

  ~ResourceManager() {
      if(manager_)
      {
          delete manager_;
      }
  }

  // 从文件加载模型文件
  int LoadResource(const char* model_path);

  // 从内存加载模型文件
  int LoadResource(const char* mem_model, int size);

  // 得到每一个区域的资源地址和资源长度
  int GetResourceWithBlockNum(int block, void*& resource, int& res_len);

 private:
  std::string version_;
  int block_num_;
  bool model_loaded_;
  unsigned char** param_vec_;
  unsigned int* param_len_vec_;
  MultiNetRes* manager_=nullptr;
};

NAMESPACE_CLOSE(private_utils)
SMASH_NAMESPACE_CLOSE

#endif  // _SMASH_PRIVATE_UTILS_H_
