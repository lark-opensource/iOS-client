//
//  NLECutsameResourceProtocol.hpp
//  NLEPlatform
//
//  Created by Lemonior on 2021/9/14.
//

#ifndef NLECutsameResourceProtocol_hpp
#define NLECutsameResourceProtocol_hpp

#include "nle_export.h"
#include <string>
#include "NLEResourceProtocol.h"

namespace nle {
    namespace resource {
        class NLE_EXPORT_CLASS NLECutsameResourceProtocol : public nle::resource::NLEResourceProtocol {
        public:
            static const std::string PLATFORM_STRING;
            static const std::string PARAM_CUTSAME_ID;
            static const std::string PARAM_CUTSAME_RELATIVE_PATH;
            static const std::string EXTRA_PARAM_CUTSAME_SAVE_PATH;

            explicit NLECutsameResourceProtocol(std::string cutsameId);
            NLECutsameResourceProtocol(std::string cutsameId, std::string relativePath);

            std::string getSourceFrom() override;

            std::unordered_map<std::string, std::string> getParameters() override;

            static bool isCutsameResource(const nle::resource::NLEResourceId &resourceId);

        private:
            std::string cutsameId;
            std::string relativePath;
        };

    }
}

#endif /* NLECutsameResourceProtocol_hpp */
