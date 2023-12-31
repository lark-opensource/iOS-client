// Copyright 2022 The Lynx Authors. All rights reserved.

#ifndef LYNX_KRYPTON_AURUM_POOL_H_
#define LYNX_KRYPTON_AURUM_POOL_H_

namespace lynx {
namespace canvas {
namespace au {

template <typename T, int initial_capacity>
class Pool {
 public:
  struct Node {
    union {
      T value;
      Node *next;
    };
    bool released;
  };

  template <typename... Us>
  inline T &Alloc(Us... args) {
    Node &node = InternalAlloc();
    int id = IndexOf(node);
    new (&node.value) T(id, args...);
    node.released = false;
    return node.value;
  }

  template <typename... Us>
  inline int AllocId(Us... args) {
    Node &node = InternalAlloc();
    int id = IndexOf(node);
    new (&node.value) T(id, args...);
    node.released = false;
    return id;
  }

  inline T &operator[](int idx) { return Get(idx).value; }

  inline void Release(int idx) {
    Node &node = Get(idx);

    node.value.~T();
    node.released = true;
    node.next = free_list_;
    free_list_ = &node;
  }

  inline ~Pool() {
    for (int i = 0, N = initial_capacity; N <= capacity_; N <<= 1) {
      Node *start = ptr_[i];
      for (; i < N; i++) {
        Node &node = *ptr_[i];
        if (!node.released) {
          node.value.~T();
        }
      }
      ::free(start);
    }
    delete[] ptr_;
  }

  struct Iterator {
    inline T &operator*() { return pool[id]; }

    inline bool Next() {
      id = pool.Next(id + 1);
      return id < pool.capacity_;
    }
    inline Iterator(Pool &pool) : pool(pool) {}

    int id = -1;

   private:
    Pool &pool;
  };

  inline Iterator Begin() { return Iterator(*this); }

  inline void Clear() {
    Node **holder = &free_list_;
    for (int i = 0; i < capacity_; i++) {
      Node &node = Get(i);
      if (!node.released) {
        node.value.~T();
        node.released = true;
      }

      *holder = &node;
      holder = &node.next;
    }
    *holder = nullptr;
  }

 private:
  Node **ptr_ = nullptr;
  Node *free_list_ = nullptr;
  int capacity_ = 0;
  int ptr_lock_ = 0;

  inline Node &Get(int idx) {
    AU_LOCK(ptr_lock_);
    Node &node = *ptr_[idx];
    AU_UNLOCK(ptr_lock_);
    return node;
  }

  inline int Next(int id) {
    AU_LOCK(ptr_lock_);
    while (id < capacity_ && ptr_[id]->released) {
      id++;
    }
    AU_UNLOCK(ptr_lock_);
    return id;
  }

  inline int IndexOf(Node &node) {
    AU_LOCK(ptr_lock_);
    for (int head = 0, tail = initial_capacity; head < capacity_;) {
      if (ptr_[head] <= &node && &node <= ptr_[tail - 1]) {
        int ret = int(&node - ptr_[head]) + head;
        AU_UNLOCK(ptr_lock_);
        return ret;
      }
      head = tail;
      tail <<= 1;
    }
    AU_UNLOCK(ptr_lock_);
    return -1;
  }

  inline Node &InternalAlloc() {
    if (!free_list_) {
      // free_list_ is empty, alloc for more
      int new_capacity;
      if (!capacity_) {
        new_capacity = initial_capacity;
        // ptr_ is allocated in advance to prevent cross thread access
        // exceptions caused by frequent realloc
        ptr_ = new Node *[512];
      } else {
        new_capacity = capacity_ << 1;
        if (new_capacity > 512) {
          Node **new_ptr = new Node *[new_capacity];
          memcpy(new_ptr, ptr_, sizeof(Node *) * capacity_);

          AU_LOCK(ptr_lock_);
          Node **old_ptr = ptr_;
          ptr_ = new_ptr;
          delete[] old_ptr;  // Lock to prevent ptr_ from being released during
                             // access
          AU_UNLOCK(ptr_lock_);
        }
      }

      Node *new_nodes =
          (Node *)malloc(sizeof(Node) * (new_capacity - capacity_));

      Node **p = &free_list_;
      for (int i = capacity_; i < new_capacity; i++) {
        Node &node = new_nodes[i - capacity_];
        node.released = true;
        ptr_[i] = *p = &node;
        p = &node.next;
      }
      *p = nullptr;

      capacity_ = new_capacity;
    }

    Node &node = *free_list_;
    // node.released = false;
    free_list_ = node.next;
    return node;
  }
};
}  // namespace au
}  // namespace canvas
}  // namespace lynx

#endif  // LYNX_KRYPTON_AURUM_POOL_H_
