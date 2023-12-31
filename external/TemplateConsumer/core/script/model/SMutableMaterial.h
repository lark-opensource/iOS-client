
#ifndef SCRIPTMODEL_MODEL_MUTABLEMATERIAL_H
#define SCRIPTMODEL_MODEL_MUTABLEMATERIAL_H


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

#include "SceneConfig.h"


using cut::model::NLENode;
using cut::model::NLEStyText;
using cut::model::NLETimeSpaceNode;
using cut::model::NLENodeDecoder;
using cut::model::NLEFeature;
using cut::model::NLEValueProperty;
using cut::model::NLEResType;
using cut::model::NLEObjectListProperty;

namespace script::model {
    class NLE_EXPORT_CLASS SMutableMaterial :public cut::model::NLEResourceAV {

        NLENODE_RTTI(SMutableMaterial);
        KEY_FUNCTION_DEC_OVERRIDE(SMutableMaterial)

        NLE_PROPERTY_DEC(SMutableMaterial, CoverPath, std::string, "", NLEFeature::E)
        NLE_PROPERTY_DEC(SMutableMaterial, StartTime, int64_t , 0, NLEFeature::E)
        NLE_PROPERTY_DEC(SMutableMaterial, EndTime,  int64_t, -1, NLEFeature::E)

    public:
        SMutableMaterial();
        virtual ~SMutableMaterial();

        private:


    public:
        virtual std::string getPath() const;

        virtual void setPath(const std::string &value);


        virtual uint32_t getResWidth() const;

        virtual void setResWidth(const uint32_t &value);

        virtual uint32_t getResHeight() const;

        virtual void setResHeight(const uint32_t &value);

        virtual NLEResType getNLEResType() const;
        virtual void setNLEResType(const NLEResType &type) ;

        virtual std::string getResName() const;

        virtual void setResName(const std::string &value);

        virtual std::shared_ptr<nlohmann::json> toJson() const override;



    };



    class SubTitle {
    private:
        std::string subTitle;
        int64_t startTime = 0;
        int64_t endTime = 0;
        float tranX = 0;
        float tranY = 0;
        float  scale = 1;
        std::shared_ptr<NLEStyText> styleText;

    public:

        const std::string &getSubTitle() const;

        void setSubTitle(const std::string &subTitle);

        int64_t getStartTime() const;

        void setStartTime(int64_t startTime);

        int64_t getEndTime() const;

        void setEndTime(int64_t endTime);

        float getTranX() const;

        void setTranX(float tranX);

        float getTranY() const;

        void setTranY(float tranY);

        float getScale() const;

        void setScale(float scale);


        const std::shared_ptr<NLEStyText> &getStyleText() const;

        void setStyleText(const std::shared_ptr<NLEStyText> &styleText);


    };


}
#endif //SCRIPTMODEL_MODEL_MUTABLEMATERIAL_H

