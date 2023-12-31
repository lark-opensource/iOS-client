//
//   ScriptResourceLoader.hpp
//   TemplateConsumer
//
//   Created  by ByteDance on 2021/6/21.
//   Copyright © 2021 ByteDance Ltd. All rights reserved.
//
    

#ifndef ScriptResourceLoader_hpp
#define ScriptResourceLoader_hpp

#include <vector>
#include <string>
#include <memory>

#ifdef __V_IPHONE_PLATFORM__
#include <NLEPlatform/NLEFeature.h>
#include <NLEPlatform/NLENode.h>
#include <NLEPlatform/NLENodeDecoder.h>
#include <NLEPlatform/NLESequenceNode.h>
#else
#include <NLEFeature.h>
#include <NLENode.h>
#include <NLENodeDecoder.h>
#include <NLESequenceNode.h>
#endif

#include "ScriptModel.h"

using cut::model::NLENode;
using cut::model::NLETimeSpaceNode;
using cut::model::NLENodeDecoder;
using cut::model::NLEFeature;
using cut::model::NLEValueProperty;
using cut::model::NLEObjectListProperty;
using cut::model::NLESegment;

namespace script::model {

    class NLE_EXPORT_CLASS ScriptDownloaderListener {
    public:
        ScriptDownloaderListener() = default;
        virtual ~ScriptDownloaderListener() = default;
        virtual void onResourceLoad(std::vector<std::shared_ptr<cut::model::NLEResourceNode>> nodes) = 0;
        virtual void onSegmentResourceLoad(std::vector<std::shared_ptr<cut::model::NLESegment>> segments) = 0;
    };

    class NLE_EXPORT_CLASS ScriptResourceLoader{


    public:
        ScriptResourceLoader();
        virtual ~ScriptResourceLoader();

        private:
        std::map<script::model::DownLoadType,std::shared_ptr<script::model::ScriptDownloaderListener>> _fetch_listeners;

    public:

        void fetchResources(const std::shared_ptr<script::model::ScriptModel> scriptModel);

        void registerLister(script::model::DownLoadType type,const std::shared_ptr<ScriptDownloaderListener> listener);

        void unRegisterLister(script::model::DownLoadType type);


    };
}

#endif /* ScriptResourceLoader_hpp */
