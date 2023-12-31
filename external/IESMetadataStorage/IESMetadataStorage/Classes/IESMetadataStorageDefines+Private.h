//
//  IESMetadataStorageDefines+Private.h
//  Pods
//
//  Created by 陈煜钏 on 2021/1/26.
//

#ifndef IESMetadataStorageDefines_Private_h
#define IESMetadataStorageDefines_Private_h

#pragma clang diagnostic push
#pragma clang diagnostic ignored"-Wunused-function"
static void metadataBlockCleanUp(__strong void(^_Nonnull* _Nonnull cleanupBlock)(void));
NS_INLINE void metadataBlockCleanUp(__strong void(^_Nonnull* _Nonnull cleanupBlock)(void))
{
    (*cleanupBlock)();
}
#pragma clang diagnostic pop

#define MD_MUTEX_LOCK(lock)     \
pthread_mutex_lock(&(lock));    \
__strong void(^block)(void) __attribute__((cleanup(metadataBlockCleanUp), unused)) = ^{ \
pthread_mutex_unlock(&(lock));  \
};                              \

#endif /* IESMetadataStorageDefines_Private_h */
