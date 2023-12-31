//
//  NLEArtistResourceProtocol.hpp
//  NLEPlatform
//
//  Created by Lemonior on 2021/9/16.
//

#ifndef NLEArtistResourceProtocol_hpp
#define NLEArtistResourceProtocol_hpp

#include "nle_export.h"
#include <string>
#include "NLEResourceProtocol.h"

namespace nle {
    namespace resource {
    class NLE_EXPORT_CLASS NLEArtistResourceProtocol : public nle::resource::NLEResourceProtocol {
        public:
            static const std::string PLATFORM_STRING;
            static const std::string PARAM_RESOURCE_ID;

            explicit NLEArtistResourceProtocol(std::string resourceId);

            std::string getSourceFrom() override;

            std::unordered_map<std::string, std::string> getParameters() override;

            static bool isArtistResource(const nle::resource::NLEResourceId &resourceId);

        private:
            std::string resourceId;
        };
    }
}

#endif /* NLEArtistResourceProtocol_hpp */
