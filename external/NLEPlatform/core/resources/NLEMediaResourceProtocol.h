
#ifndef NLEMediaResourceProtocol_hpp
#define NLEMediaResourceProtocol_hpp

#include "nle_export.h"
#include <string>
#include "NLEResourceProtocol.h"

namespace nle {
    namespace resource {
        class NLE_EXPORT_CLASS NLEMediaResourceProtocol : public NLEResourceProtocol {
        public:
            static const std::string PLATFORM_STRING;

            static const std::string KEY_MEDIA_ID;

            static const std::string KEY_STORE_ID;

            static const std::string EXTRA_PARAM_MEDIA_ITEM;

            static const std::string EXTRA_PARAM_CHANNEL_ID;

            static const std::string EXTRA_PARAM_SOURCE_PATH;

            static const std::string EXTRA_PARAM_DELETE_REMOTE_RES;

            static const std::string EXTRA_PARAM_DELETE_LOCAL_RES;

            static const std::string EXTRA_PARAM_DELETE_LOCAL_RES_RECORD;

            static const std::string EXTRA_PARAM_CACHE_DIR;

            static const std::string EXTRA_FILE_URL;

            static const std::string EXTRA_MD5;

            static const std::string EXTRA_EXTRA_INFO;

            static const std::string EXTRA_MEDIA_EXTENSION;

            static const std::string EXTRA_AUTO_UNZIP;

            explicit NLEMediaResourceProtocol(std::string mediaId);

            NLEMediaResourceProtocol(std::string mediaId, std::string storeId);

            std::string getSourceFrom() override;

            std::unordered_map<std::string, std::string> getParameters() override;

            static bool isMediaResource(const resource::NLEResourceId &resourceId);

        private:
            std::string mediaId;
            std::string storeId;
        };
    }
}


#endif //NLEMediaResourceProtocol_hpp
