#ifndef __TT_MODEL_PACKAGE_API_H__
#define __TT_MODEL_PACKAGE_API_H__

#include <cstring>
#include <map>
#include <string>
#include <vector>

namespace smash {
namespace package {

struct ModelMeta {
  std::string version;
  int count;
  std::vector<std::string> names;
  std::vector<std::string> configs;
  std::vector<std::string> parameters;
};

class ModelPackage {
 public:
  /**
   * @brief Construct a new Model Package object
   *
   * @param auth_code 标识符，在生成模型的时候给出
   */
  explicit ModelPackage(const std::string &auth_code);
  ~ModelPackage();

  /**
   * @brief 初始化模型
   *
   * @param model_path 模型路径
   * @return int
   *          0  success
   *         -1  not success
   */
  int InitFromPath(const std::string &model_path);

  /**
   * @brief 初始化模型
   *
   * @param model_buf 模型buf
   * @param handle
   * @return int
   *          0  success
   *         -1  not success
   */
  int InitFromBuf(const std::string &model_buf);

  /**
   * @brief 初始化模型
   *
   * @param model_buf 模型buf
   * @param model_len 模型长度
   * @param auth_code  标识符
   * @return int
   *          0  success
   *         -1  not success
   */
  int InitFromBuf(const char *model_buf, int model_len);


  /**
   * @brief 返回当前模型的版本号
   *
   * @param output_version
   * @return int
   *          0  success
   *         -1  not success
   */
  int GetVersion(std::string &output_version);


  /**
   * @brief 解析模型
   *
   * @param name
   * @param outputs
   *     supported key: {"config", "weight"}
   * @return int
   */
  int Extract(const std::string &name,
              std::map<std::string, std::string> &outputs);


  /**
   * @brief 获取浮点类型配置参数
   *
   * @param outputs
   * @return int
   */
  int Extract(std::map<std::string, float> &outputs);


  /**
   * @brief 获取定点类型配置参数
   *
   * @param outputs
   * @return int
   */
  int Extract(std::map<std::string, int> &outputs);
  /**
   * @brief 释放内存
   *
   */
  int Release();

  /**
   * @brief Get the Model Meta object
   * @note FOR DEBUG ONLY
   * @return int
   */
  int GetModelMeta(ModelMeta &meta);

 private:
  void *handle_;
};

}  // namespace package
}  // namespace smash
#endif
