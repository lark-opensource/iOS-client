//
// Created by zhangyeqi on 2019-12-02.
//

#ifndef CUTSAMEAPP_UNZIPFUNCTION_H
#define CUTSAMEAPP_UNZIPFUNCTION_H

#include <string>
#include "../stream/StreamFunction.h"

using asve::StreamFunction;
using std::string;
using std::pair;

namespace cut {

    /**
     * 功能：输入zip包路径，输出解压的文件夹路径
     * by 天
     *
     * 输入：pair<string, string> : 源zip文件路径，目标upZipFolder路径
     */
    class UnZipFunction
            : public StreamFunction<pair<string, string>, pair<string, string>> {
    protected:
        void run(pair<string, string>& sourceInfo) override;
    };
}


#endif //CUTSAMEAPP_UNZIPFUNCTION_H
