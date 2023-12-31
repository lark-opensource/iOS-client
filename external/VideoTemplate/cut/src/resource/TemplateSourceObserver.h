//
// Created by zhangyeqi on 2019-12-12.
//

#ifndef CUTSAMEAPP_TEMPLATESOURCEOBSERVER_H
#define CUTSAMEAPP_TEMPLATESOURCEOBSERVER_H

#include <TemplateConsumer/TemplateModel.h>
#include <memory>
#include <string>

using std::string;
using std::shared_ptr;

class TemplateSourceObserver {

public:

    /**
     * Project 对象创建成功，升级成功；未进行资源下载填充；
     * @param project
     */
    virtual void onCreatePreSuccess(const shared_ptr<CutSame::TemplateModel> &project) {}

    /**
     * Project 对象创建成功；并且所有资源都准备齐全
     */
    virtual void onCreateSuccess(const shared_ptr<CutSame::TemplateModel> &project) {}

    /**
     * 创建进度  progress : 0 ~ 1000
     * progress 0 表示刚开始，500表示进行了一半，progress 1000 表示完成
     */
    virtual void onCreateProgress(int64_t progress) {}

    /**
     * Project 对象创建失败
     */
    virtual void onCreateFailed(int32_t errorCode, int32_t subErrorCode, string errorMsg) {}

};


#endif //CUTSAMEAPP_TEMPLATESOURCEOBSERVER_H
