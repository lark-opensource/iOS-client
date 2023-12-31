//
//  Created by bytedance on 2020/12/28.
//  @author: xiebo.88
//

#include "DAVThread.h"
#include <sys/types.h>
#include <sys/ipc.h>
#include <pthread.h>
#include <unistd.h>
#include <sys/time.h>
#include <errno.h>
#include <string.h>

using davinci::executor::DAVMutex;
using davinci::executor::DAVEvent;
using davinci::executor::DAVThread;

DAVMutex::DAVMutex() {
    memset(&m_hMutex, 0, sizeof(pthread_mutex_t));
}

DAVMutex::~DAVMutex() {
    pthread_mutex_destroy((pthread_mutex_t *) &m_hMutex);
}

void DAVMutex::Create(std::string strName, bool isRecursive /*= V_TRUE*/) {
    //m_hMutex = 0;
    pthread_mutexattr_t attr;
    pthread_mutexattr_init(&attr);
    if (isRecursive) {
        pthread_mutexattr_settype(&attr, PTHREAD_MUTEX_RECURSIVE);
    } else {
        pthread_mutexattr_settype(&attr, PTHREAD_MUTEX_NORMAL);
    }

    pthread_mutex_init((pthread_mutex_t *) &m_hMutex, &attr);
}

bool DAVMutex::Lock(uint64_t uiWaiting) {
    if (uiWaiting == V_INFINITY_WAIT) {
        while (pthread_mutex_trylock((pthread_mutex_t *) &m_hMutex) != 0) {
            //MONITORLOG_VERBOSE(ENGINE_TAG, "CVMutex::Lock wait(infinity) sleep = 10");
            sleep(10);
        }

        return true;
    } else {
        uint64_t iWaiting = uiWaiting;

        while (pthread_mutex_trylock((pthread_mutex_t *) &m_hMutex) != 0) {
            iWaiting -= 10;

            if (iWaiting < 0)
                return false;
            sleep(10);
        }

        return true;
    }
}

bool DAVMutex::Unlock() {
    pthread_mutex_unlock((pthread_mutex_t *) &m_hMutex);
    return true;
}

void *DAVMutex::GetHandle() {
    // Todo: @wangchengyi.1
    return nullptr;
//    return (void *) m_hMutex.__sig;
}

typedef struct tagLinuxEvent {
    int iEventID;        // 信号
    int bManualReset;    // 是否自动复位
    pthread_mutex_t mMutex;            // 互斥体
    pthread_cond_t cCond;            // 状态变量

} LinuxEvent;

DAVEvent::DAVEvent() {
    m_hEvent = nullptr;
}

DAVEvent::~DAVEvent() {
    CloseEvent();
}

bool DAVEvent::CloseEvent() {
    if (m_hEvent) {
        LinuxEvent *pLinuxEvent = (LinuxEvent *) m_hEvent;
        if (&(pLinuxEvent->mMutex) == nullptr) {
            return false;
        }
        pthread_mutex_lock(&(pLinuxEvent->mMutex));

        if (!pLinuxEvent->iEventID) {
            pthread_cond_broadcast(&(pLinuxEvent->cCond));
        }

        pthread_mutex_unlock(&(pLinuxEvent->mMutex));
        int iResult = pthread_mutex_destroy(&(pLinuxEvent->mMutex));

        if (iResult > 0) {
            sleep(1);
        }

        pthread_cond_destroy(&(pLinuxEvent->cCond));
        delete ((LinuxEvent *) m_hEvent);
        m_hEvent = nullptr;
        return true;
    }

    return false;
}

bool DAVEvent::CreateEvent(bool bManualReset, std::string strName) {
    if (m_hEvent)
        CloseEvent();

    m_hEvent = new LinuxEvent();

    if (!m_hEvent)
        return false;

    LinuxEvent *pLinuxEvent = (LinuxEvent *) m_hEvent;
    pLinuxEvent->bManualReset = bManualReset;
    pLinuxEvent->iEventID = false;

    if (pthread_mutex_init(&pLinuxEvent->mMutex, nullptr) || pthread_cond_init(&pLinuxEvent->cCond, nullptr)) {
        CloseEvent();
        return false;
    }

    return true;
}

void *DAVEvent::GetHandle() {
    return m_hEvent;
}

bool DAVEvent::SetEvent() {
    if (m_hEvent) {
        LinuxEvent *pLinuxEvent = (LinuxEvent *) m_hEvent;
        if (&(pLinuxEvent->mMutex) == nullptr) {
            return false;
        }
        pthread_mutex_lock(&pLinuxEvent->mMutex);
        //设置状态变量为true，对应有信号
        pLinuxEvent->iEventID = true;

        //重新激活所有在等待cCond变量的线程
        if (pthread_cond_broadcast(&pLinuxEvent->cCond)) {
            pthread_mutex_unlock(&pLinuxEvent->mMutex);
        }
        pthread_mutex_unlock(&pLinuxEvent->mMutex);
        return true;
    }
    return false;
}

bool DAVEvent::ResetEvent() {
    if (m_hEvent) {
        LinuxEvent *pLinuxEvent = (LinuxEvent *) m_hEvent;
        pthread_mutex_lock(&pLinuxEvent->mMutex);
        //设置状态变量为false，对应无信号
        pLinuxEvent->iEventID = false;

        //重新激活所有在等待cCond变量的线程
        if (pthread_cond_broadcast(&pLinuxEvent->cCond)) {
            pthread_mutex_unlock(&pLinuxEvent->mMutex);
        }

        pthread_mutex_unlock(&pLinuxEvent->mMutex);
        return true;
    }
    return false;
}

bool DAVEvent::Wait(uint64_t uiWaiting) {
    if (m_hEvent == NULL) {
        return false;
    }
    LinuxEvent *pLinuxEvent = (LinuxEvent *) m_hEvent;

    if (pLinuxEvent == nullptr) {
        return false;
    }

    if (pthread_mutex_lock(&pLinuxEvent->mMutex)) {
        return false;
    }

    uint64_t iMilliseconds = uiWaiting;
    int rc = 0;

    if (iMilliseconds == V_INFINITY_WAIT) {
        while (pLinuxEvent->iEventID == false) {
            //对互斥体进行原子的解锁工作,然后等待状态信号
            if (pthread_cond_wait(&pLinuxEvent->cCond, &pLinuxEvent->mMutex)) {
                pthread_mutex_unlock(&pLinuxEvent->mMutex);
                return false;
            }
        }

        if (pLinuxEvent->bManualReset)
            pLinuxEvent->iEventID = false;
    } else {
        struct timespec abstime;
        struct timeval tv;
        gettimeofday(&tv, nullptr);
        abstime.tv_sec = tv.tv_sec + iMilliseconds / 1000;
        abstime.tv_nsec = tv.tv_usec * 1000 + (iMilliseconds % 1000) * 1000000;

        if (abstime.tv_nsec >= 1000000000) {
            abstime.tv_nsec -= 1000000000;
            abstime.tv_sec++;
        }

        while (pLinuxEvent->iEventID == false) {
            //自动释放互斥体并且等待m_cond状态,并且限制了最大的等待时间
            if ((rc = pthread_cond_timedwait(&pLinuxEvent->cCond, &pLinuxEvent->mMutex, &abstime))) {
                if (rc == ETIMEDOUT) break;

                pthread_mutex_unlock(&pLinuxEvent->mMutex);
                return false;
            }
        }

        if (rc == 0 && pLinuxEvent->bManualReset)
            pLinuxEvent->iEventID = false;
    }

    pthread_mutex_unlock(&pLinuxEvent->mMutex);
    return rc == 0;
}

// 线程对象
typedef struct tagLinuxThread {
    pthread_t threadID;
    pthread_attr_t threadAtt;    // 线程属性
} LinuxThread;

DAVThread::DAVThread() {
    m_hThread = nullptr;
    m_unStackSize = 0;
}

DAVThread::~DAVThread() {
    if (m_hThread != nullptr) {
        LinuxThread *pThread = nullptr;
        pThread = (LinuxThread *) m_hThread;
        delete (pThread);
        pThread = nullptr;
        m_hThread = nullptr;
    }
}

typedef void *(*LinuxThreadFunction)(void *pParam);

bool DAVThread::CreateThread(DAVThreadFunction pfnRoute, void *pParam) {
    if (m_hThread)
        return false;

    LinuxThread *res = new LinuxThread();
    //struct sched_param schedparam;
    pthread_attr_init(&res->threadAtt);

    if (m_unStackSize != 0) pthread_attr_setstacksize(&res->threadAtt, m_unStackSize);

    if (pthread_create((pthread_t *) &(res->threadID), &res->threadAtt, ((LinuxThreadFunction) pfnRoute), pParam) !=
        0) {
        delete (res);
        return false;
    }

    m_hThread = (void *) res;
    return true;
}

bool DAVThread::SetThreadPriority(int iPriority) {
    return false;
}

int DAVThread::GetThreadPriority() {
    return 1;
}

bool DAVThread::SetThreadStackSize(int iStackSize) {
    if (iStackSize <= 0) return false;
    m_unStackSize = iStackSize;
    return true;
}

int DAVThread::GetThreadStackSize() {
    if (!m_hThread) return 0;
    LinuxThread *res = (LinuxThread *) m_hThread;
    size_t stack_size;
    pthread_attr_getstacksize(&res->threadAtt, &stack_size);
    return (int) stack_size;
}

void *DAVThread::GetHandle() {
    return m_hThread;
}

bool DAVThread::TerminateThread(unsigned long ulCode) {
    if (m_hThread != nullptr) {
        LinuxThread *pThread = nullptr;
        pThread = (LinuxThread *) m_hThread;
        delete (pThread);
        pThread = nullptr;

        m_hThread = nullptr;
        return true;
    }
    return false;
}

void DAVThread::Join() {
    LinuxThread *pThread = (LinuxThread *) m_hThread;
    pthread_join(pThread->threadID, nullptr);
}

void DAVThread::TerminateSelf() {
    pthread_detach(pthread_self());
    pthread_exit((void *) 0);
}

int DAVThread::SetName(std::string strName) {
    // iOS暂时不用
    //return prctl(PR_SET_NAME, ulName);
#ifdef __linux__
    int nRetFlag = pthread_setname_np(pthread_self(), strName.c_str());
#else
    int nRetFlag = pthread_setname_np((const char *) strName.c_str());
#endif
    if (nRetFlag == 0) {
        return 0;
    }
    return -1;
}

std::shared_ptr<DAVThread> DAVThread::GetCurrentThread() {
    LinuxThread *res = new LinuxThread();
    res->threadID = pthread_self();

    std::shared_ptr<DAVThread> thread = std::make_shared<DAVThread>();
    thread->m_hThread = (void *) res;

    return thread;
}

bool DAVThread::ThreadIsEqual(const DAVThread &oneThread, const DAVThread &anotherThread) {
    LinuxThread *trd1 = (LinuxThread *) oneThread.m_hThread;
    LinuxThread *trd2 = (LinuxThread *) anotherThread.m_hThread;
    if (trd1 == nullptr || trd2 == nullptr) {
        return false;
    }

    return pthread_equal(trd1->threadID, trd2->threadID);
}

