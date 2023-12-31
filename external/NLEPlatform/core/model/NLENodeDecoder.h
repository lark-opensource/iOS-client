#ifndef NLENODEDECODER_H
#define NLENODEDECODER_H

#include <memory>
#include <string>
#include <unordered_map>
#include <functional>
#include "json_forward.hpp"
#include <functional>
#include "nle_export.h"

namespace cut::model {

    class NLENode;
    class DeserialContext;

    using NLENodeCreateFunc = std::function<NLENode *()>;

    class NLE_EXPORT_CLASS NLENodeDecoder {
    public:
        static std::shared_ptr<NLENodeDecoder> get();

        void registerCreateFunc(const std::string &name, NLENodeCreateFunc func);
        NLENodeCreateFunc findCreateFunc(const std::string &name) const;

        std::shared_ptr<NLENode> decode(DeserialContext &context, const std::string &objectKey);

    private:
        std::unordered_map<std::string, NLENodeCreateFunc> funcs;
    };

#ifndef NLENODE_CREATE_FUNC
#define NLENODE_CREATE_FUNC(__CLASS_NAME) \
        private: \
            static __CLASS_NAME* _create() { \
                return std::make_unique<__CLASS_NAME>(); \
            } \
        public: \
            static void registerCreateFunc() { \
                NLENodeDecoder::get()->registerCreateFunc(#__CLASS_NAME, _create); \
            }
#endif
}

#endif // NLENODEDECODER_H
