#include <pthread.h>

#include "basic/threading/thread_local.h"

namespace vmsdk {
namespace general {
namespace internal {

// static
void ThreadLocalPlatform::AllocateSlot(SlotType *slot) {
  pthread_key_create(slot, NULL);
}

// static
void ThreadLocalPlatform::FreeSlot(SlotType slot) { pthread_key_delete(slot); }

// static
void *ThreadLocalPlatform::GetValueFromSlot(SlotType slot) {
  return pthread_getspecific(slot);
}

// static
void ThreadLocalPlatform::SetValueInSlot(SlotType slot, void *value) {
  pthread_setspecific(slot, value);
}

}  // namespace internal
}  // namespace general
}  // namespace vmsdk
