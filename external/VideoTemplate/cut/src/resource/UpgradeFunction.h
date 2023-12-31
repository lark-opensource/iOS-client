//
// Created by Tian on 2020-01-05.
//

#ifndef CUT_ANDROID_UPGRADEFUNCTION_H
#define CUT_ANDROID_UPGRADEFUNCTION_H

#include <string>
#include "../stream/StreamFunction.h"
#include <TemplateConsumer/TemplateModel.h>
namespace cut {
    /**
     * 负责project升级
     */
class UpgradeFunction : public asve::StreamFunction<shared_ptr<CutSame::TemplateModel>, shared_ptr<CutSame::TemplateModel>> {
    public:
    void run(shared_ptr<CutSame::TemplateModel> &project) override;
    private:
        void upgradeTo30000(shared_ptr<CutSame::TemplateModel> &project);

        void upgradeTo50000(shared_ptr<CutSame::TemplateModel> &project);

        void upgradeTo60000(shared_ptr<CutSame::TemplateModel> &project);

        void upgradeTo80000(shared_ptr<CutSame::TemplateModel> &project);
    };
}


#endif //CUT_ANDROID_UPGRADEFUNCTION_H
