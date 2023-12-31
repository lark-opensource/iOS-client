//
//  DispathMaterialFunction.hpp
//  VideoTemplate
//
//  Created by luochaojing on 2020/1/22.
//

#ifndef DispathMaterialFunction_hpp
#define DispathMaterialFunction_hpp

#include <string>
#include "../stream/StreamFunction.h"
#include <TemplateConsumer/TemplateModel.h>


namespace cut {

class DispatchMatrialFunction: public asve::StreamFunction<shared_ptr<CutSame::TemplateModel>, shared_ptr<CutSame::TemplateModel>> {
    
public:
    DispatchMatrialFunction(bool needDispatch);
    void run(shared_ptr<CutSame::TemplateModel>& in) override;

    static void dispatchMaterial(shared_ptr<CutSame::TemplateModel>& project);
private:
    bool _needDispath = false;
};

}

#endif /* DispathMaterialFunction_hpp */
