//
// Created by 沈彦昊 on 2021/1/27.
//

#ifndef BYTEDT_BYTEDTTRAINENGINE_H
#define BYTEDT_BYTEDTTRAINENGINE_H

#include "ByteDTEngine.h"

namespace bytedt {

    class ByteDTTrain : public ByteDT {
    public:
        ~ByteDTTrain() override = default;

        static std::shared_ptr<ByteDTTrain> create_engine();

        void load_model_from_buffer(void *model_buffer, uint64_t length, ByteDTErrorCode &err_code,
                                    RunInfo *run_info = nullptr);

        void load_model_from_path(const char *path, ByteDTErrorCode &err_code, RunInfo *run_info = nullptr);

        bytedt::protobuf::Model get_pb_model();

        /*
         * Train a DT model from input, and save it to train_model_path
         * Args:
         *     param_list_buffer: (allows the following parameters, seperated by comma)
         *         n_feature (required)             特征数（不包括标签值）
         *         n_iteration (required)           迭代次数
         *         eta = 0.3                        学习率
         *         lambda = 1                       树结构目标稀释
         *         gamma = 4                        分裂gain最小收益值
         *         max_depth = 3                    树最大深度
         *         min_child_weight = 4             叶子节点最小权重
         *         pos_scale_balance = 0            是否开启正负样本均衡（二分类），0:否，1:是
         *         missing_to_left = -1             -1:需要比较 0:left 1:right
         *         column_sampling_threshold = -1   开启列抽样的特征数量阈值，-1:不开启列抽样
         *         tree_method = 0                  构造树的算法 0:分位点算法 1:精确算法
         *         sketch_eps = 0.1                 0<sketch_eps<=1，越小越接近精准算法
         *         verbose = 1                      (WIP)是否打印训练日志
         *         n_threads = 0                    训练线程数，默认0全开
         * */
        bool train(const Input input, const std::string &train_model_path, const std::string &param_list_buffer,
                   ByteDTErrorCode &err_code, RunInfo *run_info = nullptr);
    };
}

#endif //BYTEDT_BYTEDTTRAINENGINE_H
