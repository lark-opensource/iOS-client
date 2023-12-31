//
// Created by bytedance on 3/25/21.
//


#ifndef CUT_ANDROID_MOVIESTUDIOCONSUMER_H
#define CUT_ANDROID_MOVIESTUDIOCONSUMER_H

#include <memory>
#include <string>

namespace CutSame {
    class TemplateModel;
}

namespace cut::model {
    class NLEModel;
}

namespace TemplateConsumer {

    const int32_t CONVERT_SUCCESS = 0;
    const int32_t CONVERT_ERROR = -1;

    class MovieStudioConsumer {
    public:
        static int32_t coverJsonToNLEModel(
                const std::shared_ptr<cut::model::NLEModel> &nModel,
                const std::string &configString);

    };
}

#endif //CUT_ANDROID_MOVIESTUDIOCONSUMER_H
