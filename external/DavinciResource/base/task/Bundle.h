//
// Created by wangchengyi.1 on 2021/5/10.
//

#ifndef DAVINCIRESOURCEDEMO_BUNDLE_H
#define DAVINCIRESOURCEDEMO_BUNDLE_H

#include <memory>
#include <string>
#include <unordered_map>
#include <mutex>

namespace davinci {
    namespace task {
        class BaseModel {
        public:
            BaseModel() = default;
            virtual ~BaseModel() = default;
        };

        class Bundle {

        public:
            Bundle();

            void putString(const std::string &key, const std::string &value);

            std::string getString(const std::string &key, const std::string &defaultValue = "") const;

            void putModel(const std::string &key, const std::shared_ptr<BaseModel> &value);

            std::shared_ptr<BaseModel> getModel(const std::string &key, const std::shared_ptr<BaseModel> &defaultValue = nullptr) const;

        private:
            std::recursive_mutex mutex;
            std::unordered_map<std::string, std::string> stringMap;
            std::unordered_map<std::string, std::shared_ptr<BaseModel>> modelMap;
        };
    }
}



#endif //DAVINCIRESOURCEDEMO_BUNDLE_H
