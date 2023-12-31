//
// Created by zhangyeqi on 2019-12-06.
//

#ifndef CUTSAMEAPP_RESOURCESTREAMCONTEXT_H
#define CUTSAMEAPP_RESOURCESTREAMCONTEXT_H

#include "../stream/StreamFunction.h"
#include <string>

using asve::StreamContext;
using std::string;

namespace cut {
    class ResourceStreamContext : public StreamContext {
    public:
        ResourceStreamContext(const string &workspaceFolderPath) : workspaceFolderPath(
                workspaceFolderPath) {}

        const string getWorkspaceFolderPath() const {
            return workspaceFolderPath;
        }

    private:
        const string workspaceFolderPath;
    };
}

#endif //CUTSAMEAPP_RESOURCESTREAMCONTEXT_H
