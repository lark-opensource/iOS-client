//
//  DAVThread.h
//  PiexlPaltform
//
//  Created by bytedance on 2020/12/29.
//  @author: xiebo.88
//

#ifndef DAVThread_h
#define DAVThread_h

#include <stdio.h>
#include <string>
#include <memory>

#ifndef __V_WINDOWS_PLATFORM__

#include <pthread.h>

#endif

#ifdef __V_IPHONE_PLATFORM__
#include <dispatch/dispatch.h>
#elif defined(__V_ANDROID_PLATFORM__)
#include <semaphore.h>
#endif

#ifdef __V_WINDOWS_PLATFORM__
#include <memory>
#include <mutex>
#endif

#define V_INFINITY_WAIT 0
/*
 *	类名: DAVMutex, DAVEvent, DAVThread
 *	功能: 线程互斥体, 事件,线程
 */

// 互斥对象
namespace davinci {
    namespace executor {
        class DAVMutex {
        public:

            DAVMutex();

            virtual ~DAVMutex();

        public:

            /**
             * 用指定的的名称创建一个新的互斥区
             *		@param strName [in] 互斥区名称
             */
            void Create(std::string strName, bool isRecursive = true);

            /**
             * 锁定DAVMutex对象
             *		@param uiWaiting [in] 等待时间(单位:毫秒)
             *
             *		@return 成功返回true, 否则返回false.
             */
            bool Lock(uint64_t uiWaiting = V_INFINITY_WAIT);

            /**
             * 释放DAVMutex对象
             *		@return 成功返回true, 否则返回false.
             */
            bool Unlock();

            /**
             * 得到DAVMutex的句柄
             *	@return 事件的句柄
             */
            void *GetHandle();

        public:
            /// 区间锁
            class ScopedLock {
            public:
                ScopedLock(DAVMutex &mtx) : m_Mtx(mtx) {
                    m_Mtx.Lock();
                }

                ~ScopedLock() {
                    m_Mtx.Unlock();
                }

            private:
                DAVMutex &m_Mtx;
            };

        protected:
#ifdef __V_WINDOWS_PLATFORM__
            std::mutex			m_hMutex;					// 指向虚拟平台的Event句柄
#else
            pthread_mutex_t m_hMutex;                    // linux下需要此结构体
#endif // __V_WINDOWS_PLATFORM__
        };

// 事件对象
        class DAVEvent {
        public:

            DAVEvent();

            virtual ~DAVEvent();

        public:

            /**
             * 设置事件的状态为真
             *		@return 设置成功返回true, 否则返回false.
             */
            bool SetEvent();

            /**
             * 创建一个事件(默认创建自动恢复状态模式)
             *		@param bManualReset [in] 指定是否手工控制
             *		@param	strName	[in] 要创建的事件的名称
             *
             *		@return	成功返回true, 否则返回false.
             */
            bool CreateEvent(bool bManualReset = false, std::string strName = "");

            /**
             * 重新设置信号
             *		@return 设置成功返回true, 否则返回false.
             */
            bool ResetEvent();

            /**
             * 关闭句柄
             *		@return 关闭成功返回true,否则返回false.
             */
            bool CloseEvent();

            /**
             * 得到事件的句柄
             *	@return 事件的句柄
             */
            void *GetHandle();

            /**
             * 在指定时间内等待Event对象是否被设置为有效状态
             *		@param uiWaiting [in] 等待时间(单位:毫秒)
             *
             *		@return 成功返回true, 否则返回false.
             *		@notes
             *			(1) 如果Event对象是自动恢复模式,则等待成功后自动被置为无效状态；
             *			(2) 该接口用于线程处理例程等待某种系统事件时使用；
             */
            bool Wait(uint64_t uiWaiting = V_INFINITY_WAIT);

        protected:

            void *m_hEvent;                // 指向虚拟平台的Event句柄
        };

#ifdef __V_WINDOWS_PLATFORM__
        // 线程对象
typedef struct tagThread
{
    std::thread _thread;
} StdThread;
#endif

        typedef unsigned long (*DAVThreadFunction)(void *pParam);

// 线程对象
        class DAVThread {
        public:

            DAVThread();

            virtual ~DAVThread();

        public:

            /**
             * 生成一个虚拟平台的线程对象
             *		@param pfnRoute [in] 线程处理函数
             *		@param pParam	[in] 线程处理函数的参数
             *
             *		@return 成功返回true,否则返回false.
             */
            bool CreateThread(DAVThreadFunction pfnRoute, void *pParam);

            /**
             * 得到线程的句柄
             *	@return 线程的句柄
             */
            void *GetHandle();

            /**
             * 设置线程DAVThread的优先级
             *		@param iPriority [in] 线程优先级
             *
             *		@return 成功返回true,否则返回false.
             */
            bool SetThreadPriority(int iPriority);

            /** 检索DAVThread的优先级
             *		@return 成功返回线程的优先级；失败返回THREAD_PRIORITY_ERROR_RETURN
             */
            int GetThreadPriority();

            /**
             * 设置线程DAVThread的栈大小
             *		@param iStackSize [in] 栈大小
             *
             *		@return 成功返回true,否则返回false.
             */
            bool SetThreadStackSize(int iStackSize);

            /** 获取DAVThread的栈大小
             *		@return 成功返回线程的栈大小
             */
            int GetThreadStackSize();

            /**
             * 强制终止DAVThread
             *		@param ulCode [in] 退出码
             *
             *		@return 成功返回true,否则返回false.
             */
            bool TerminateThread(unsigned long ulCode);

            /**
             * 等待线程结束
             *
             *		return 无.
             */
            void Join();

            /**
             * 终止当前线程
             *
             *		return
             */
            static void TerminateSelf();

            /**
             * 设置当前线程名字
             *		@param strName [in] 线程名字
             *
             *		@return 成功时返回0，错误时返回-1，并设置相应的错误号。
             */
            static int SetName(std::string strName);

            /**
             * 获得当前线程
             *
             *        return
             */
            static std::shared_ptr<DAVThread> GetCurrentThread();

            /**
             * 判断两个线程是否一样
             *        @param oneThread [in] 线程对象
             *        @param anotherThread [in] 线程对象
             *
             *        @return 成功时返回true，错误时返回false
             */
            static bool ThreadIsEqual(const DAVThread &oneThread, const DAVThread &anotherThread);

        protected:
#ifdef __V_WINDOWS_PLATFORM__
            std::shared_ptr<StdThread>	m_threadPtr;
    unsigned int                m_unStackSize;              // 线程栈大小
#else
            void *m_hThread;                    // 指向虚拟平台的Thread句柄
            unsigned int m_unStackSize;              // 线程栈大小
#endif
        };

    }
}

#endif /* DAVThread_h */
