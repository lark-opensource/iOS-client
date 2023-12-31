//
//  NLETemplateZipProgressHandler.h
//  NLEPlatform
//
//  Created by Lincoln on 2021/11/10.
//

#ifndef NLETemplateZipProgressHandler_h
#define NLETemplateZipProgressHandler_h

#include <functional>
#include <utility>
#include "nle_export.h"

namespace cut::model {

// For Java
class NLE_EXPORT_CLASS NLEBaseTemplateZipProgressHandler {

    public:
        NLEBaseTemplateZipProgressHandler() = default;

        virtual ~NLEBaseTemplateZipProgressHandler() = default;

        virtual void invoke(float progress) {};
};

// For iOS
class NLE_EXPORT_CLASS NLETemplateZipProgressHandler : public NLEBaseTemplateZipProgressHandler {

public:
    NLETemplateZipProgressHandler() = default;

    virtual ~NLETemplateZipProgressHandler() = default;
    NLETemplateZipProgressHandler(std::function<void(float)> h) : progressHandler(std::move(h)) {}

    void invoke(float progress) override {
        progressHandler(progress);
    }

private:
    std::function<void(float)> progressHandler;
};

}

#endif /* NLETemplateZipProgressHandler_h */
