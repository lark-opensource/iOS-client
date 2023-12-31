//
//  pthread_extended.h
//  CoreFoundation
//
//  Created by sunrunwang on 2019/6/25.
//  Copyright © 2019 Bill Sun. All rights reserved.
//
//  注意 "pthread_extended.h" 头文件, 不可以和 <pthread.h> 在同一个文件中导入
//  如果的确是要同时导入, 请确保 "pthread_extended.h" 在 <pthread.h> 之后导入
//  "pthread_extended.h" 和原有 <pthread.h> 功能相同, 但是更加的安全

#ifndef pthread_extended_h
#define pthread_extended_h

#include <pthread.h>
#include <errno.h>
#include <stdio.h>

#ifndef PTHREAD_MUTEX_SAFE_CHECK_TYPE
#ifdef DEBUG
#define PTHREAD_MUTEX_SAFE_CHECK_TYPE PTHREAD_MUTEX_ERRORCHECK
#else
#define PTHREAD_MUTEX_SAFE_CHECK_TYPE PTHREAD_MUTEX_DEFAULT
#endif
#endif

#ifndef rwlock_init_shared
#define rwlock_init_shared(rwlock) {                                                              \
     pthread_rwlockattr_t attr;                                                                   \
    (pthread_rwlockattr_init)(&attr);                                                             \
    (pthread_rwlockattr_setpshared)(&attr, PTHREAD_PROCESS_SHARED);                               \
    (pthread_rwlock_init)(&(rwlock), &attr);                                                      \
    (pthread_rwlockattr_destroy)(&attr);                                                          \
}
#endif

#ifndef rwlock_init_private
#define rwlock_init_private(rwlock) {                                                             \
     pthread_rwlockattr_t attr;                                                                   \
    (pthread_rwlockattr_init)(&attr);                                                             \
    (pthread_rwlockattr_setpshared)(&attr, PTHREAD_PROCESS_PRIVATE);                              \
    (pthread_rwlock_init)(&(rwlock), &attr);                                                      \
    (pthread_rwlockattr_destroy)(&attr);                                                          \
}
#endif

#ifndef mutex_init_normal
#define mutex_init_normal(mtx) {                                                                  \
     pthread_mutexattr_t attr;                                                                    \
    (pthread_mutexattr_init)(&attr);                                                              \
    (pthread_mutexattr_settype)(&attr, PTHREAD_MUTEX_SAFE_CHECK_TYPE);                            \
    (pthread_mutex_init)(&(mtx), &attr);                                                          \
    (pthread_mutexattr_destroy)(&attr);                                                           \
}
#endif

#ifndef mutex_init_recursive
#define mutex_init_recursive(mtx) {                                                               \
     pthread_mutexattr_t attr;                                                                    \
    (pthread_mutexattr_init)(&attr);                                                              \
    (pthread_mutexattr_settype)(&attr, PTHREAD_MUTEX_RECURSIVE);                                  \
    (pthread_mutex_init)(&(mtx), &attr);                                                          \
    (pthread_mutexattr_destroy)(&attr);                                                           \
}
#endif

#ifndef wrlock_wrlock
#ifdef DEBUG
#define wrlock_wrlock(rwlock) {                                                                   \
    int value = (pthread_rwlock_wrlock)(&(rwlock));                                               \
    if(value != 0) {                                                                              \
        if(value == EBUSY)         fprintf(stdout, "[ERROR] rwlock_wrlock EBUSY\n");              \
        else if(value == EDEADLK)  fprintf(stdout, "[ERROR] rwlock_wrlock EDEADLK\n");            \
        else if(value == EINVAL)   fprintf(stdout, "[ERROR] rwlock_wrlock EINVAL\n");             \
        else if(value == ENOMEM)   fprintf(stdout, "[ERROR] rwlock_wrlock ENOMEM\n");             \
        else fprintf(stdout, "[ERROR] rwlock_wrlock UNKOWN ERROR return %d\n", value);            \
        __builtin_trap();                                                                         \
    }                                                                                             \
}
#else
#define wrlock_wrlock(rwlock) (pthread_rwlock_wrlock)(&(rwlock))
#endif
#endif

#ifndef wrlock_rdlock
#ifdef DEBUG 
#define wrlock_rdlock(rwlock) {                                                                   \
    int value = (pthread_rwlock_rdlock)(&(rwlock));                                               \
    if(value != 0) {                                                                              \
        if(value == EBUSY)         fprintf(stdout, "[ERROR] rwlock_rdlock EBUSY\n");              \
        else if(value == EDEADLK)  fprintf(stdout, "[ERROR] rwlock_rdlock EDEADLK\n");            \
        else if(value == EAGAIN)   fprintf(stdout, "[ERROR] rwlock_rdlock EAGAIN\n");             \
        else if(value == EINVAL)   fprintf(stdout, "[ERROR] rwlock_rdlock EINVAL\n");             \
        else if(value == ENOMEM)   fprintf(stdout, "[ERROR] rwlock_rdlock ENOMEM\n");             \
        else fprintf(stdout, "[ERROR] rwlock_rdlock UNKOWN ERROR return %d\n", value);            \
        __builtin_trap();                                                                         \
    }                                                                                             \
}
#else
#define wrlock_rdlock(rwlock) (pthread_rwlock_rdlock)(&(rwlock))
#endif
#endif

#ifndef wrlock_unlock
#ifdef DEBUG
#define wrlock_unlock(rwlock) {                                                                   \
    int value = (pthread_rwlock_unlock)(&(rwlock));                                               \
    if(value != 0) {                                                                              \
        if(value == EINVAL)        fprintf(stdout, "[ERROR] rwlock_unlock EINVAL\n");             \
        else if(value == EPERM)    fprintf(stdout, "[ERROR] rwlock_unlock EPERM\n");              \
        else fprintf(stdout, "[ERROR] rwlock_unlock UNKOWN ERROR return %d\n", value);            \
        __builtin_trap();                                                                         \
    }                                                                                             \
}
#else
#define wrlock_unlock(rwlock) (pthread_rwlock_unlock)(&(rwlock))
#endif
#endif

#ifndef wrlock_destroy
#ifdef DEBUG
#define wrlock_destroy(rwlock) {                                                                  \
    int value = (pthread_rwlock_destroy)(&(rwlock));                                              \
    if(value != 0) {                                                                              \
        if(value == EPERM)         fprintf(stdout, "[ERROR] rwlock_destroy EPERM\n");             \
        else if(value == EBUSY)    fprintf(stdout, "[ERROR] rwlock_destroy EBUSY\n");             \
        else if(value == EINVAL)   fprintf(stdout, "[ERROR] rwlock_destroy EINVAL\n");            \
        else fprintf(stdout, "[ERROR] rwlock_destroy UNKOWN ERROR return %d\n", value);           \
        __builtin_trap();                                                                         \
    }                                                                                             \
}
#else
#define wrlock_destroy(rwlock) (pthread_rwlock_destroy)(&(rwlock))
#endif
#endif

#ifndef mutex_destroy
#ifdef DEBUG
#define mutex_destroy(mtx) {                                                                      \
    int value = (pthread_mutex_destroy)(&(mtx));                                                  \
    if(value != 0) {                                                                              \
        if(value == EBUSY)         fprintf(stdout, "[ERROR] mutex_destroy EBUSY\n");              \
        else if(value == EINVAL)   fprintf(stdout, "[ERROR] mutex_destroy EINVAL\n");             \
        else fprintf(stdout, "[ERROR] mutex_destroy UNKOWN ERROR return %d\n", value);            \
        __builtin_trap();                                                                         \
    }                                                                                             \
}
#else
#define mutex_destroy(mtx) (pthread_mutex_destroy)(&(mtx))
#endif
#endif

#ifndef mutex_lock
#ifdef DEBUG
#define mutex_lock(mtx) {                                                                         \
    int value = (pthread_mutex_lock)(&(mtx));                                                     \
    if(value != 0) {                                                                              \
        if(value == EDEADLK)       fprintf(stdout, "[ERROR] mutex_lock EDEADLK\n");               \
        else if(value == EINVAL)   fprintf(stdout, "[ERROR] mutex_lock EINVAL\n");                \
        else fprintf(stdout, "[ERROR] mutex_lock UNKOWN ERROR return %d\n", value);               \
        __builtin_trap();                                                                         \
    }                                                                                             \
}
#else
#define mutex_lock(mtx) (pthread_mutex_lock)(&(mtx))
#endif
#endif

#ifndef mutex_trylock
#ifdef DEBUG
#define mutex_trylock(mtx) ({                                                                     \
    int value = (pthread_mutex_trylock)(&(mtx));                                                  \
    if(value != 0 && value != EBUSY) {                                                            \
        if(value == EINVAL)        fprintf(stdout, "[ERROR] mutex_trylock EINVAL\n");             \
        else fprintf(stdout, "[ERROR] mutex_trylock UNKOWN ERROR return %d\n", value);            \
        __builtin_trap();                                                                         \
    }                                                                                             \
    value;                                                                                        \
})
#else
#define mutex_trylock(mtx) (pthread_mutex_trylock)(&(mtx))
#endif
#endif

#ifndef mutex_unlock
#ifdef DEBUG
#define mutex_unlock(mtx) {                                                                       \
    int value = (pthread_mutex_unlock)(&(mtx));                                                   \
    if(value != 0) {                                                                              \
        if(value == EINVAL)        fprintf(stdout, "[ERROR] mutex_unlock EINVAL\n");              \
        else if(value == EPERM)    fprintf(stdout, "[ERROR] mutex_unlock EPERM\n");               \
        else fprintf(stdout, "[ERROR] mutex_unlock UNKOWN ERROR return %d\n", value);             \
        __builtin_trap();                                                                         \
    }                                                                                             \
}
#else
#define mutex_unlock(mtx) (pthread_mutex_unlock)(&(mtx))
#endif
#endif

#ifndef pthread_rwlock_destroy
#ifdef DEBUG
#define pthread_rwlock_destroy(rwlock_p) ({                                                       \
    int value = pthread_rwlock_destroy(rwlock_p);                                                 \
    if(value != 0) {                                                                              \
        if(value == EPERM)         fprintf(stdout, "[ERROR] pthread_rwlock_destroy EPERM\n");     \
        else if(value == EBUSY)    fprintf(stdout, "[ERROR] pthread_rwlock_destroy EBUSY\n");     \
        else if(value == EINVAL)   fprintf(stdout, "[ERROR] pthread_rwlock_destroy EINVAL\n");    \
        else fprintf(stdout, "[ERROR] pthread_rwlock_destroy UNKOWN ERROR return %d\n", value);   \
        __builtin_trap();                                                                         \
    }                                                                                             \
    value;                                                                                        \
})
#else
#define pthread_rwlock_destroy(rwlock_p) pthread_rwlock_destroy(rwlock_p)
#endif
#else
#warning pthread_rwlock_destroy predefined macro extension check may not work properly
#endif

#ifndef pthread_rwlock_init
#ifdef DEBUG
#define pthread_rwlock_init(rwlock_p, attr_p) ({                                                  \
    int value = pthread_rwlock_init(rwlock_p, attr_p);                                            \
    if(value != 0) {                                                                              \
        if(value == EAGAIN)        fprintf(stdout, "[ERROR] pthread_rwlock_init EAGAIN\n");       \
        else if(value == ENOMEM)   fprintf(stdout, "[ERROR] pthread_rwlock_init ENOMEM\n");       \
        else if(value == EBUSY)    fprintf(stdout, "[ERROR] pthread_rwlock_init EBUSY\n");        \
        else if(value == EINVAL)   fprintf(stdout, "[ERROR] pthread_rwlock_init EINVAL\n");       \
        else fprintf(stdout, "[ERROR] pthread_rwlock_init UNKOWN ERROR return %d\n", value);      \
        __builtin_trap();                                                                         \
    }                                                                                             \
    value;                                                                                        \
})
#else
#define pthread_rwlock_init(rwlock_p, attr_p) pthread_rwlock_init(rwlock_p, attr_p)
#endif
#else
#warning pthread_rwlock_init predefined macro extension check may not work properly
#endif

#ifndef pthread_rwlock_rdlock
#ifdef DEBUG
#define pthread_rwlock_rdlock(rwlock_p) ({                                                        \
    int value = pthread_rwlock_rdlock(rwlock_p);                                                  \
    if(value != 0) {                                                                              \
        if(value == EAGAIN)        fprintf(stdout, "[ERROR] pthread_rwlock_rdlock EAGAIN\n");     \
        else if(value == EDEADLK)  fprintf(stdout, "[ERROR] pthread_rwlock_rdlock EDEADLK\n");    \
        else if(value == EINVAL)   fprintf(stdout, "[ERROR] pthread_rwlock_rdlock EINVAL\n");     \
        else if(value == ENOMEM)   fprintf(stdout, "[ERROR] pthread_rwlock_rdlock ENOMEM\n");     \
        else fprintf(stdout, "[ERROR] pthread_rwlock_rdlock UNKOWN ERROR return %d\n", value);    \
        __builtin_trap();                                                                         \
    }                                                                                             \
    value;                                                                                        \
})
#else
#define pthread_rwlock_rdlock(rwlock_p) pthread_rwlock_rdlock(rwlock_p)
#endif
#else
#warning pthread_rwlock_rdlock predefined macro extension check may not work properly
#endif

#ifndef pthread_rwlock_tryrdlock
#ifdef DEBUG
#define pthread_rwlock_tryrdlock(rwlock_p) ({                                                     \
    int value = pthread_rwlock_tryrdlock(rwlock_p);                                               \
    if(value != 0 && value != EBUSY) {                                                            \
        if(value == EAGAIN)          fprintf(stdout, "[ERROR] pthread_rwlock_tryrdlock EAGAIN\n");\
        else if(value == EDEADLK)   fprintf(stdout, "[ERROR] pthread_rwlock_tryrdlock EDEADLK\n");\
        else if(value == EINVAL)   fprintf(stdout, "[ERROR] pthread_rwlock_tryrdlock EINVAL\n");  \
        else if(value == ENOMEM)   fprintf(stdout, "[ERROR] pthread_rwlock_tryrdlock ENOMEM\n");  \
        else fprintf(stdout, "[ERROR] pthread_rwlock_tryrdlock UNKOWN ERROR return %d\n", value); \
        __builtin_trap();                                                                         \
    }                                                                                             \
    value;                                                                                        \
})
#else
#define pthread_rwlock_tryrdlock(rwlock_p) pthread_rwlock_tryrdlock(rwlock_p)
#endif
#else
#warning pthread_rwlock_tryrdlock predefined macro extension check may not work properly
#endif

#ifndef pthread_rwlock_trywrlock
#ifdef DEBUG
#define pthread_rwlock_trywrlock(rwlock_p) ({                                                     \
    int value = pthread_rwlock_trywrlock(rwlock_p);                                               \
    if(value != 0 && value != EBUSY) {                                                            \
        if(value == EDEADLK)   fprintf(stdout, "[ERROR] pthread_rwlock_trywrlock EDEADLK\n");     \
        else if(value == EINVAL)   fprintf(stdout, "[ERROR] pthread_rwlock_trywrlock EINVAL\n");  \
        else if(value == ENOMEM)   fprintf(stdout, "[ERROR] pthread_rwlock_trywrlock ENOMEM\n");  \
        else fprintf(stdout, "[ERROR] pthread_rwlock_trywrlock UNKOWN ERROR return %d\n", value); \
        __builtin_trap();                                                                         \
    }                                                                                             \
    value;                                                                                        \
})
#else
#define pthread_rwlock_trywrlock(rwlock_p) pthread_rwlock_trywrlock(rwlock_p)
#endif
#else
#warning pthread_rwlock_trywrlock predefined macro extension check may not work properly
#endif

#ifndef pthread_rwlock_wrlock
#ifdef DEBUG
#define pthread_rwlock_wrlock(rwlock_p) ({                                                        \
    int value = pthread_rwlock_wrlock(rwlock_p);                                                  \
    if(value != 0) {                                                                              \
        if(value == EDEADLK)   fprintf(stdout, "[ERROR] pthread_rwlock_wrlock EDEADLK\n");        \
        else if(value == EINVAL)   fprintf(stdout, "[ERROR] pthread_rwlock_wrlock EINVAL\n");     \
        else if(value == ENOMEM)   fprintf(stdout, "[ERROR] pthread_rwlock_wrlock ENOMEM\n");     \
        else fprintf(stdout, "[ERROR] pthread_rwlock_wrlock UNKOWN ERROR return %d\n", value);    \
        __builtin_trap();                                                                         \
    }                                                                                             \
    value;                                                                                        \
})
#else
#define pthread_rwlock_wrlock(rwlock_p) pthread_rwlock_wrlock(rwlock_p)
#endif
#else
#warning pthread_rwlock_wrlock predefined macro extension check may not work properly
#endif

#ifndef pthread_rwlock_unlock
#ifdef DEBUG
#define pthread_rwlock_unlock(rwlock_p) ({                                                        \
    int value = pthread_rwlock_unlock(rwlock_p);                                                  \
    if(value != 0) {                                                                              \
        if(value == EINVAL)        fprintf(stdout, "[ERROR] pthread_rwlock_unlock EINVAL\n");     \
        else if(value == EPERM)    fprintf(stdout, "[ERROR] pthread_rwlock_unlock EPERM\n");      \
        else fprintf(stdout, "[ERROR] pthread_rwlock_unlock UNKOWN ERROR return %d\n", value);    \
        __builtin_trap();                                                                         \
    }                                                                                             \
    value;                                                                                        \
})
#else
#define pthread_rwlock_unlock(rwlock_p) pthread_rwlock_unlock(rwlock_p)
#endif
#else
#warning pthread_rwlock_unlock predefined macro extension check may not work properly
#endif

#ifndef pthread_mutex_destroy
#ifdef DEBUG
#define pthread_mutex_destroy(mtx_p) ({                                                           \
    int value = pthread_mutex_destroy(mtx_p);                                                     \
    if(value != 0) {                                                                              \
        if(value == EBUSY)         fprintf(stdout, "[ERROR] pthread_mutex_destroy EBUSY\n");      \
        else if(value == EINVAL)   fprintf(stdout, "[ERROR] pthread_mutex_destroy EINVAL\n");     \
        else fprintf(stdout, "[ERROR] pthread_mutex_destroy UNKOWN ERROR return %d\n", value);    \
        __builtin_trap();                                                                         \
    }                                                                                             \
    value;                                                                                        \
})
#else
#define pthread_mutex_destroy(mtx_p) pthread_mutex_destroy(mtx_p)
#endif
#else
#warning pthread_mutex_destroy predefined macro extension check may not work properly
#endif

#ifndef pthread_mutex_init
#ifdef DEBUG
#define pthread_mutex_init(mtx_p, attr_p) ({                                                      \
    int value = pthread_mutex_init(mtx_p, attr_p);                                                \
    if(value != 0) {                                                                              \
        if(value == EBUSY)         fprintf(stdout, "[ERROR] pthread_mutex_init EBUSY\n");         \
        else if(value == EINVAL)   fprintf(stdout, "[ERROR] pthread_mutex_init EINVAL\n");        \
        else fprintf(stdout, "[ERROR] pthread_mutex_init UNKOWN ERROR return %d\n", value);       \
        __builtin_trap();                                                                         \
    }                                                                                             \
    value;                                                                                        \
})
#else
#define pthread_mutex_init(mtx_p, attr_p) pthread_mutex_init(mtx_p, attr_p)
#endif
#else
#warning pthread_mutex_init predefined macro extension check may not work properly
#endif

#ifndef pthread_mutex_lock
#ifdef DEBUG
#define pthread_mutex_lock(mtx_p) ({                                                              \
    int value = pthread_mutex_lock(mtx_p);                                                        \
    if(value != 0) {                                                                              \
        if(value == EDEADLK)       fprintf(stdout, "[ERROR] pthread_mutex_lock EDEADLK\n");       \
        else if(value == EINVAL)   fprintf(stdout, "[ERROR] pthread_mutex_lock EINVAL\n");        \
        else fprintf(stdout, "[ERROR] pthread_mutex_lock UNKOWN ERROR return %d\n", value);       \
        __builtin_trap();                                                                         \
    }                                                                                             \
    value;                                                                                        \
})
#else
#define pthread_mutex_lock(mtx_p) pthread_mutex_lock(mtx_p)
#endif
#else
#warning pthread_mutex_lock predefined macro extension check may not work properly
#endif

#ifndef pthread_mutex_unlock
#ifdef DEBUG
#define pthread_mutex_unlock(mtx_p) ({                                                            \
    int value = pthread_mutex_unlock(mtx_p);                                                      \
    if(value != 0) {                                                                              \
        if(value == EINVAL)        fprintf(stdout, "[ERROR] pthread_mutex_unlock EINVAL\n");      \
        else if(value == EPERM)    fprintf(stdout, "[ERROR] pthread_mutex_unlock EPERM\n");       \
        else fprintf(stdout, "[ERROR] pthread_mutex_unlock UNKOWN ERROR return %d\n", value);     \
        __builtin_trap();                                                                         \
    }                                                                                             \
    value;                                                                                        \
})
#else
#define pthread_mutex_unlock(mtx_p) pthread_mutex_unlock(mtx_p)
#endif
#else
#warning pthread_mutex_unlock predefined macro extension check may not work properly
#endif

#endif /* pthread_extended_h */
