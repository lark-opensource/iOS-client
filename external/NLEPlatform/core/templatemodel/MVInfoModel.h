//
//  MVInfoModel.hpp
//  NLEPlatform
//
//  Created by Lemonior on 2021/10/31.
//

#ifndef MVInfoModel_hpp
#define MVInfoModel_hpp

#include "nlohmann/json.hpp"

namespace cut {
    namespace model {
        // 背景音乐
        class Audio {
        public:
            std::string content;
            float start;
            float end;
            int type;
        };
        // 分辨率
        class Resolution {
        public:
            int height;
            int width;
        };
        // 资源
        class Resource {
        public:
            std::string content;
            std::string fill_mode;
            bool fromUser;
            int height;
            int width;
            bool isVideoMuted;
            std::string logicName;
            bool isLoop;
            int rid;
            float sourceStart;
            float sourceEnd;
            float targetStart;
            float targetEnd;
            int timeMode;
            std::string type;
        };
        // 文本
        class ReplaceText {
        public:
            std::vector<std::string> defaultContent;
            std::string prefix;
        };
    
        // MV模型
        class MVInfoModel {
        public:
            Audio audio;
            Resolution resolution;
            std::vector<Resource> resources;
            std::vector<ReplaceText> texts;
            int fps;
        };
        
        void from_json(const nlohmann::json &j, cut::model::MVInfoModel &mvModel);
        void from_json(const nlohmann::json &j, cut::model::Resource &resource);
        void from_json(const nlohmann::json &j, cut::model::Audio &audio);
        void from_json(const nlohmann::json &j, cut::model::Resolution &resolution);
        void from_json(const nlohmann::json &j, cut::model::ReplaceText &text);
    }
}


#endif /* MVInfoModel_hpp */
