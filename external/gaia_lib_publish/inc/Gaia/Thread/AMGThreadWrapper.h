#ifndef AMGThreadWrapper_H
#define AMGThreadWrapper_H

#include "Gaia/AMGPrerequisites.h"
NAMESPACE_AMAZING_ENGINE_BEGIN

class GAIA_LIB_EXPORT ThreadWrapper
{
public:
    ThreadWrapper() {}
    virtual void start() = 0;
    virtual void join() = 0;
    virtual bool joinable() = 0;
    virtual bool isCurrent() = 0;
    virtual void setThreadName(const char* name) = 0;
    virtual ~ThreadWrapper() {}
};

NAMESPACE_AMAZING_ENGINE_END
#endif
