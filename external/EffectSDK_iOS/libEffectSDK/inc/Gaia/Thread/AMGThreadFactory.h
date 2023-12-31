#ifndef AMGThreadFactory_H
#define AMGThreadFactory_H

#include "Gaia/AMGPrerequisites.h"
#include "Gaia/Thread/AMGThreadWrapper.h"
#include <functional>
#include <utility>
NAMESPACE_AMAZING_ENGINE_BEGIN

#define DEFAULT_STACK_SIZE 1024 * 1024

class GAIA_LIB_EXPORT ThreadFactory
{
public:
    template <class F, class... Args>
    static ThreadWrapper* createThread(int stackSize, F&& f, Args&&... args);

    template <class F, class... Args>
    static ThreadWrapper* createStdThread(F&& f, Args&&... args);

    template <class F, class... Args>
    static ThreadWrapper* createPThread(int stackSize, F&& f, Args&&... args);
};

template <class F, class... Args>
ThreadWrapper* ThreadFactory::createThread(int stackSize, F&& f, Args&&... args)
{
#if AMAZING_PLATFORM == AMAZING_WINDOWS
    return ThreadFactory::createStdThread(std::forward<F>(f), std::forward<Args>(args)...);
#else
    return ThreadFactory::createPThread(stackSize, std::forward<F>(f), std::forward<Args>(args)...);
#endif
}

GAIA_LIB_EXPORT ThreadWrapper* _threadWrapper_create_StdThread(std::function<void()>* task);

template <class F, class... Args>
ThreadWrapper* ThreadFactory::createStdThread(F&& f, Args&&... args)
{
    auto func = std::bind(std::forward<F>(f), std::forward<Args>(args)...);
    auto task = new std::function<void()>([myFunc = std::move(func)]
                                          { myFunc(); });
    return _threadWrapper_create_StdThread(task);
}

GAIA_LIB_EXPORT ThreadWrapper* _threadWrapper_create_PThread(int stackSize, std::function<void()>* task);

template <class F, class... Args>
ThreadWrapper* ThreadFactory::createPThread(int stackSize, F&& f, Args&&... args)
{
    auto func = std::bind(std::forward<F>(f), std::forward<Args>(args)...);
    auto task = new std::function<void()>([myFunc = std::move(func)]
                                          { myFunc(); });
    return _threadWrapper_create_PThread(stackSize, task);
}

NAMESPACE_AMAZING_ENGINE_END
#endif /* Thread_h */
