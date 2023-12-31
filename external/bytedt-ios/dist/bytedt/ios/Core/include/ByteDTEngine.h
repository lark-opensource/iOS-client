//
// Created by tsao on 2020/6/18.
//

#ifndef BYTEDT_BYTEDTENGINE_H
#define BYTEDT_BYTEDTENGINE_H

#include <vector>
#include <string>

namespace bytedt {
    struct Output;
    struct Input;
    enum class ByteDTErrorCode : uint8_t;

    class ByteDT;

    enum class ModelType : uint8_t;
    enum class TreeRelation : uint8_t;
    namespace core {
        class ByteDTBaseModel;
    }

    namespace protobuf {
        class Model;
    }
}

namespace bytedt {

    enum class ByteDTDataType : uint8_t {
        UInt32 = 0,
        Float32 = 1
    };

    struct Output {
        Output(std::vector<float> &&data);

        Output(std::vector<uint32_t> &&data);

        const void *raw_data() const {
            return static_cast<const void *>(raw_data_.data());
        }

        ByteDTDataType data_type_;
        std::vector<char> raw_data_;
    };

    struct Input {
        void *buffer_;
        uint64_t length_;
        ByteDTDataType data_type_;

        Input() : buffer_(nullptr), length_(0), data_type_(ByteDTDataType::Float32) {};

        Input(void *raw_buf, uint64_t len, ByteDTDataType dtype = ByteDTDataType::Float32) : buffer_(raw_buf),
                                                                                             length_(len),
                                                                                             data_type_(dtype) {}
    };

    struct RunInfo {
        struct ModelInfo {
            uint32_t model_type_ = 0;           //Classification = 0, MultiLabelClassification = 1, Regression = 2
            uint32_t tree_relation_ = 0;        //Boosting = 0, Voting = 1
            uint32_t tree_size_ = 0;
            uint32_t max_depth_ = 0;
            uint32_t n_feature_ = 0;
            float load_time = 0;
            uint32_t load_from_type = 0;        //from path = 0, from buffer = 1, from cache = 2
        } model_info;
        float infer_time = 0;
        float train_time = 0;
        uint32_t threads_count = 0;
        std::string version_id;
    };

    enum class ByteDTErrorCode : uint8_t {
        NO_ERROR = 0,
        FILE_NOT_FOUND = 1,
        NOT_IMPLEMENTED = 2,
        ERR_UNEXPECTED = 3,
        ERR_DATANOMATCH = 4,
        INPUT_DATA_ERROR = 5,
        MODEL_PARSING_ERROR = 6,
    };

    class ByteDT {
    public:
        ByteDT();

        virtual ~ByteDT() {}

        static std::shared_ptr<ByteDT> create_engine();

        void load_model_from_buffer(void *model_buffer, uint64_t length, ByteDTErrorCode &err_code,
                                            RunInfo *run_info = nullptr);

        void load_model_from_path(const char *path, ByteDTErrorCode &err_code, RunInfo *run_info = nullptr);

        /*
         *  For both regression and classification tasks.
         *  - Boosting/Voting Classification
         *      vector size: 2
         *          Output @ 0 [Float]: Probability distribution of length:
         *              - n_row * n_class for multi-class
         *              - n_row for binary-class
         *          Output @ 1 [UInt32]: Class ids of length: n_row
         *
         *  - Boosting/Voting Multi-Label-Classification
         *      vector size: 2
         *          Output @ 0 [Float]: Probability distribution of length: n_row * n_class
         *          Output @ 1 [UInt32]: 1 or 0 means whether matches the class or not, of length: n_row * n_class
         *
         *  - Boosting/Voting Regression
         *      vector size: 1
         *      Output @ 0 [Float]: Score of length: n_row
         * */
        std::vector<Output> predict(Input, ByteDTErrorCode &err_code, RunInfo *run_info = nullptr);

        std::vector<float> predict_raw(Input input);

        /*
         *  For both regression and classification tasks.
         *  - Boosting/Voting Classification/Regression
         *      vector size: 1
         *          Output @ 0 [UInt32]: Leaf indexes of length: n_row * n_trees
         * */
        std::vector<Output> predict_leaf(Input, ByteDTErrorCode &err_code, RunInfo *run_info = nullptr);

    protected:
        std::shared_ptr<core::ByteDTBaseModel> backend_;
    };

    std::string get_version();

}


#endif //BYTEDT_BYTEDTENGINE_H
