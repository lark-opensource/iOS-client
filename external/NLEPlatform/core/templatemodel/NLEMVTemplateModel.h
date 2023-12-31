//
//  NLEMVTemplateModel.hpp
//  NLEPlatform
//
//  Created by Lemonior on 2021/10/28.
//

#ifndef NLEMVTemplateModel_hpp
#define NLEMVTemplateModel_hpp

//#ifdef __V_IPHONE_PLATFORM__
//#include <NLEPlatform/NLENodeDecoder.h>
//#include <NLEPlatform/NLENode.h>
//#include <NLEPlatform/NLESequenceNode.h>
//#else
//#include <NLENodeDecoder.h>
//#include <NLENode.h>
//#include <NLESequenceNode.h>
//#endif

#include "NLENodeDecoder.h"
#include "NLENode.h"
#include "NLESequenceNode.h"

#include "NLETemplateModel.h"

namespace cut::model {
    class MVInfoModel;
    /**
     *  模版的统一数据模型
     */
    class NLE_EXPORT_CLASS NLEMVTemplateModel: public NLETemplateModel {
    public:
        /*
         * @param mvURS MV资源包路径
         * @param mvInfoJSON VE获取到MV资源包内部的完整JSON
         * @param zipFolder 导出模型zip包文件夹路径
         * @return 返回zip包完整路径
         */
        static std::string createTemplateModelFromMVInfo(const std::string &mvURS, const std::string &mvInfoJSON, const std::string &zipFolder);
        
    private:
        static std::shared_ptr<NLEMVTemplateModel> tranformMVJSONToModel(const std::string &mvInfoJSON);
        static std::shared_ptr<NLEMVTemplateModel> createMVTemplateModelFromMVInfoModel(const MVInfoModel &infoModel);
    };
}

#endif /* NLEMVTemplateModel_hpp */
