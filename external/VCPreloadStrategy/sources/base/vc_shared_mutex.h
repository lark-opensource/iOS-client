#pragma once

#ifndef PRELOAD_VC_SHARED_MUTEX_H
#define PRELOAD_VC_SHARED_MUTEX_H

#include "vc_exception.h"
#include <cassert>
#include <cerrno>
#include <memory>
#include <mutex>
#include <pthread.h>
#include <system_error>

#include "vc_base.h"

VC_NAMESPACE_BEGIN

class shared_mutex {
private:
    pthread_rwlock_t mLock = PTHREAD_RWLOCK_INITIALIZER;

public:
    shared_mutex() = default;

    ~shared_mutex() = default;

    VC_DISALLOW_COPY_AND_ASSIGN(shared_mutex);

    void lock() {
        int ret = pthread_rwlock_wrlock(&mLock);
        if (ret == EDEADLK) {
            // throw std::system_error(ret, std::generic_category());
            VCThrowRuntimeError(
                    string_format("ret:%d, category:%s",
                                  ret,
                                  std::generic_category().message(0).c_str()));
        }
        assert(ret == 0);
    }

    bool try_lock() {
        int ret = pthread_rwlock_trywrlock(&mLock);
        if (ret == EBUSY) {
            return false;
        }
        assert(ret == 0);
        return true;
    }

    void unlock() {
        int ret = pthread_rwlock_unlock(&mLock);
        assert(ret == 0);
    }

    void lock_shared() {
        int ret;
        do {
            ret = pthread_rwlock_rdlock(&mLock);
        } while (ret == EAGAIN);
        if (ret == EDEADLK) {
            // throw std::system_error(ret, std::generic_category());
            VCThrowRuntimeError(
                    string_format("ret:%d, category:%s",
                                  ret,
                                  std::generic_category().message(0).c_str()));
        }
        assert(ret == 0);
    }

    bool try_lock_shared() {
        int ret = pthread_rwlock_tryrdlock(&mLock);
        if (ret == EAGAIN || ret == EBUSY) {
            return false;
        }
        assert(ret == 0);
        return true;
    }

    void unlock_shared() {
        unlock();
    }
};

template <typename Mutex>
class shared_lock {
private:
    Mutex *mMutex;
    bool mOwnsLock;

public:
    using mutex_type = Mutex;

    shared_lock() noexcept : mMutex(nullptr), mOwnsLock(false) {}

    explicit shared_lock(mutex_type &mutex) :
            mMutex(std::addressof(mutex)), mOwnsLock(true) {
        mutex.lock_shared();
    }

    shared_lock(mutex_type &mutex, std::defer_lock_t) :
            mMutex(std::addressof(mutex)), mOwnsLock(false) {}

    shared_lock(mutex_type &mutex, std::try_to_lock_t) :
            mMutex(std::addressof(mutex)), mOwnsLock(mutex.try_lock_shared()) {}

    shared_lock(mutex_type &mutex, std::adopt_lock_t) :
            mMutex(std::addressof(mutex)), mOwnsLock(true) {}

    ~shared_lock() {
        if (mOwnsLock) {
            mMutex->unlock_shared();
        }
    }

    VC_DISALLOW_COPY_AND_ASSIGN(shared_lock);

    shared_lock(shared_lock &&other) noexcept : shared_lock() {
        swap(other);
    }

    shared_lock &operator=(shared_lock &&other) noexcept {
        // why not just swap(other)?
        shared_lock(std::move(other)).swap(*this);
        return *this;
    }

    void swap(shared_lock &other) noexcept {
        std::swap(mMutex, other.mMutex);
        std::swap(mOwnsLock, other.mOwnsLock);
    }

    void lock() {
        check_lockable();
        mMutex->lock_shared();
        mOwnsLock = true;
    }

    bool try_lock() {
        check_lockable();
        return mOwnsLock = mMutex->try_lock_shared();
    }

    void unlock() {
        if (!mOwnsLock) {
            // throw
            // std::system_error(std::make_error_code(std::errc::operation_not_permitted));
            VCThrowRuntimeError(string_format(
                    "code:%s",
                    std::make_error_code(std::errc::operation_not_permitted)
                            .message()
                            .c_str()));
        } else {
            mMutex->unlock_shared();
            mOwnsLock = false;
        }
    }

    mutex_type *release() noexcept {
        mOwnsLock = false;
        auto ret = mMutex;
        mMutex = nullptr;
        return ret;
    }

    bool owns_lock() const noexcept {
        return mOwnsLock;
    }

    explicit operator bool() const noexcept {
        return mOwnsLock;
    }

    mutex_type *mutex() const noexcept {
        return mMutex;
    }

private:
    void check_lockable() const {
        if (mMutex == nullptr) {
            // throw
            // std::system_error(std::make_error_code(std::errc::operation_not_permitted));
            VCThrowRuntimeError(string_format(
                    "code:%s",
                    std::make_error_code(std::errc::operation_not_permitted)
                            .message()
                            .c_str()));
        }
        if (mOwnsLock) {
            // throw
            // std::system_error(std::make_error_code(std::errc::resource_deadlock_would_occur));
            VCThrowRuntimeError(string_format(
                    "code:%s",
                    std::make_error_code(
                            std::errc::resource_deadlock_would_occur)
                            .message()
                            .c_str()));
        }
    }
};

VC_NAMESPACE_END

#endif // PRELOAD_VC_SHARED_MUTEX_H
