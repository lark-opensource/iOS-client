#ifndef _PRIVATE_UTILS_PREDICTOR_H_
#define _PRIVATE_UTILS_PREDICTOR_H_

#include <mobilecv2/core.hpp>
#include <vector>
#include "espresso.h"
#include "internal_smash.h"
#include "predictor_base.h"

SMASH_NAMESPACE_OPEN
NAMESPACE_OPEN(private_utils)
NAMESPACE_OPEN(predict)

class Predictor {
 public:
  explicit Predictor();

  /**
   * @brief 初始化一个Predictor
   *
   * @param net_def 网络配置
   * @param weight  网络权重
   * @param weight_len  权重的长度
   * @param input_layer_names 输入的数据层，可能有多个，通常就为{"data"}
   * @param output_layer_names 需提取数据的层，可有多个。需要提前数据的层，必须在此提前指定
   * @param bits 网络的量化位数，当前仅支持 8 或 16 或者 32。注意，predict 调用输入必须为 uint8,
                 但其减去均值后，结果值可为 int8 或 int16，由 bits 指定
   * @param mean_val 输入需要减去的均值，默认为128
   * @return int
   */
  int Init(const std::string& net_def,
           const void* weight,
           int weight_len,
           const std::vector<std::string>& input_layer_names,
           const std::vector<std::string>& output_layer_names,
           int bits,
           int mean_val = 128);

  /**
   * @brief 跑网络前向inference
   *
   * @param image 输入的图像。大小需与网络输入一致
   * @note 输入的 image 无需减均值,此函数内部会做减均值 128 操作,image 仅支持 uint8 类型的矩阵
   * @return int
   */
  int Predict(const mobilecv2::Mat& image);

  /**
   * @brief reshape 输入大小，通常只是模型输入大小可动态设置的时候才调用
   *
   * @param net_w 输入宽度
   * @param net_h 输入高度
   * @return int
   */
  int NetReshape(int net_w, int net_h);

  /**
   * @brief Get the Raw Output object
   *
   * @param layer_name 指定需要提取的输出
   * @note 提取数据的层名，注意需在 Init 的 output_layer_names 中提前指定
   * @return ModelOutput
   */
  ModelOutput GetRawOutput(const std::string& layer_name);

  /**
   * @brief set numbers of thread
   *
   * @param nums 线程的个数
   * @note 
   * @return 
   */
  void setThreads(int nums);

  virtual ~Predictor();

 private:
  bool inited_;

  espresso::Thrustor* thrustor_;

  int bits_;
  int mean_val_;
  std::vector<std::string> input_layer_names_;
  std::vector<std::string> output_layer_names_;
};

NAMESPACE_CLOSE(predict)
NAMESPACE_CLOSE(private_utils)
SMASH_NAMESPACE_CLOSE

#endif  // _PRIVATE_UTILS_PREDICTOR_H_
