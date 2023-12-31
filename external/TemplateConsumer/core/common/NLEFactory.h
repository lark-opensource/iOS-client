//
// Created by Steven on 2021/1/22.
//

#ifndef TEMPLATECONSUMERAPP_NLEFACTORY_H
#define TEMPLATECONSUMERAPP_NLEFACTORY_H

#include <memory>
#include <string>


namespace cut::model {
    class NLEResourceNode;
    enum class NLEResType;
}

namespace TemplateConsumer {
    class NLEFactory {
    public:
        static std::shared_ptr<cut::model::NLEResourceNode>
        createNLEResourceNode(cut::model::NLEResType type, const std::string &file, const std::string &resId = "");
    };
}

#endif //TEMPLATECONSUMERAPP_NLEFACTORY_H
