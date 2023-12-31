//
//  NLETemplateEditor.hpp
//  NLEPlatform
//
//  Created by Charles on 2021/11/16.
//

#ifndef NLETemplateEditor_hpp
#define NLETemplateEditor_hpp

#include "NLEEditor.h"

namespace cut::model {

    class NLE_EXPORT_CLASS NLETemplateEditor: public NLEEditor {

    public:
        NLETemplateEditor();
    protected:
        void modelClassesRegister() override;
        bool featureSupport(const std::unordered_set<TNLEFeature> &features) override;
        std::shared_ptr<NLEModel> createModelInstance() override;
        std::shared_ptr<NLEEditor> createEditorInstance() const override;
    };
}


#endif /* NLETemplateEditor_hpp */
