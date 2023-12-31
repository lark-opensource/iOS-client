//
// Created by zhangyeqi on 2020-02-14.
//

#ifndef CUT_ANDROID_PROJECTPRESUCCESSFUNCTION_H
#define CUT_ANDROID_PROJECTPRESUCCESSFUNCTION_H

#include <TemplateConsumer/TemplateModel.h>
#include "../stream/StreamFunction.h"

class ProjectPreSuccessFunction : public asve::StreamFunction<shared_ptr<CutSame::TemplateModel>, shared_ptr<CutSame::TemplateModel>> {
public:
    ProjectPreSuccessFunction(function<void(const shared_ptr<CutSame::TemplateModel>)> callback);

protected:
    void run(shared_ptr<CutSame::TemplateModel> &in) override;

private:
    const std::function<void(const shared_ptr<CutSame::TemplateModel>)> callback;

};


#endif //CUT_ANDROID_PROJECTPRESUCCESSFUNCTION_H
