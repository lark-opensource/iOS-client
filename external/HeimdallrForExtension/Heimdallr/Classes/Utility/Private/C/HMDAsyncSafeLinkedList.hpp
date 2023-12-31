//
//  HMDAsyncSafeLinkedList.hpp
//  Heimdallr
//
//  Created by yuanzhangjing on 2019/10/20.
//

#ifndef HMDAsyncSafeLinkedList_hpp
#define HMDAsyncSafeLinkedList_hpp

#include <os/lock.h>
#include <assert.h>
#include <atomic>
#include <pthread.h>

namespace hmd {
namespace async_safe {

template <typename V>
class linked_list {
   public:

    class node {
       public:
        friend class linked_list<V>;

        V value(void) {
            return _value;
        }

       private:
        node(V value) {
            _value = value;
            _prev = NULL;
            _next = NULL;
        }

        void reset(V value) {
            _value = value;
            _prev = NULL;
            _next = NULL;
        }

        V _value;

        volatile std::atomic<node *> _prev;

        volatile std::atomic<node *> _next;
    };

    linked_list(void);
    linked_list(bool lock_free);
    ~linked_list(void);

    void init_lock(void);
    bool trylock(void);
    void lock(void);
    void unlock(void);
    
    typedef void(*free_func)(V);

    node *append(V value);
    void remove(V value);
    void remove_node(node *node);
    void remove_node_safely(node *node);
    node *next(node *current);
    
    node *append_while_lock(V value);
    void remove_while_lock(V value);
    void remove_node_while_lock(node *node);
    void remove_node_safely_while_lock(node *node);
    node *next_while_lock(node *current);

    void set_reading(bool enable);
    void set_free_func(free_func f);

    typedef void (*callback_func)(V value,int index,bool *stop,void *ctx);
    typedef void (^callback_block)(V value,int index,bool *stop);
    void enumerate_node_with_lock(callback_block);
    void async_enumerate_node(callback_func, void *ctx);

   private:
    
    void free_value(V);
    void free_value(node *node);
    std::atomic<free_func> _free_func;
    void free_list(node *next);

    os_unfair_lock _unfair_lock;
    pthread_mutex_t _pthread_lock;

    volatile std::atomic<node *> _head;

    volatile std::atomic<node *> _tail;

    volatile std::atomic_int _refcount;
    
    int _list_length;

    int _free_list_length;
    node * _free;
    void clear_freelist(void);
    void append_freelist(node *node);

    bool _lock_free;
};

template <typename V>
linked_list<V>::linked_list(bool lock_free) {
    _lock_free = lock_free;
    _head = NULL;
    _tail = NULL;
    _free = NULL;
    _refcount = 0;
    _free_list_length = 0;
    _list_length = 0;
    init_lock();
}

template <typename V>
linked_list<V>::linked_list(void) {
    _lock_free = false;
    _head = NULL;
    _tail = NULL;
    _free = NULL;
    _refcount = 0;
    _free_list_length = 0;
    _list_length = 0;
    init_lock();
}


template <typename V>
linked_list<V>::~linked_list(void) {
    if (_head != NULL) free_list(_head);

    clear_freelist();
}

template <typename V>
void linked_list<V>::init_lock(void) {
    if (_lock_free) {
        return;
    }
    
    if (__builtin_available(iOS 10.0, *)) {
        _unfair_lock = OS_UNFAIR_LOCK_INIT;
    } else {
        pthread_mutexattr_t attr;
        pthread_mutexattr_init(&attr);
        pthread_mutexattr_settype(&attr, PTHREAD_MUTEX_NORMAL);
        pthread_mutex_init(&_pthread_lock, &attr);
        pthread_mutexattr_destroy(&attr);
    }
}

template <typename V>
void linked_list<V>::lock(void) {
    if (_lock_free) {
        return;
    }
    
    if (__builtin_available(iOS 10.0, *)) {
        os_unfair_lock_lock(&_unfair_lock);
    } else {
        pthread_mutex_lock(&_pthread_lock);
    }
}

template <typename V>
bool linked_list<V>::trylock(void) {
    if (_lock_free) {
        return false;
    }
    
    if (__builtin_available(iOS 10.0, *)) {
        return os_unfair_lock_trylock(&_unfair_lock);
    } else {
        return pthread_mutex_trylock(&_pthread_lock) == 0;
    }
}

template <typename V>
void linked_list<V>::unlock(void) {
    if (_lock_free) {
        return;
    }
    if (__builtin_available(iOS 10.0, *)) {
        os_unfair_lock_unlock(&_unfair_lock);
    } else {
        pthread_mutex_unlock(&_pthread_lock);
    }
}

template <typename V>
typename linked_list<V>::node * linked_list<V>::append(V value) {
    /* Lock the list from other writers. */
    node *new_node = NULL;
    lock();
    {
        new_node = append_while_lock(value);
    }
    unlock();
    return new_node;
}

template <typename V>
void linked_list<V>::set_free_func(free_func f) {
    std::atomic_store_explicit(&_free_func, f, std::memory_order_release);
}

template <typename V>
void linked_list<V>::free_value(V value) {
    free_func f = std::atomic_load_explicit(&_free_func, std::memory_order_acquire);
    if (f) {
        f(value);
    }
}

template <typename V>
void linked_list<V>::free_value(node *node) {
    if (node == NULL) {
        return;
    }
    free_value(node->_value);
}

/**
 * Find and remove the first entry node with @a value. Direct '==' equality checking
 * is performed.
 *
 * @param value The value to search for.
 *
 * @warning This method is not async safe.
 */
template <typename V>
void linked_list<V>::remove(V value) {
    lock();
    {
        remove_while_lock(value);
    }
    unlock();
}

/**
 * Remove a specific entry node from the list.
 *
 * @param deleted_node The node to be removed.
 *
 * @warning This method is not async safe.
 */
template <typename V>
void linked_list<V>::remove_node(node *deleted_node) {
    /* Lock the list from other writers. */
    lock();
    {
        remove_node_while_lock(deleted_node);
    }
    unlock();
}

template <typename V>
void linked_list<V>::remove_node_safely(node *deleted_node) {
    /* Lock the list from other writers. */
    lock();
    {
        remove_node_safely_while_lock(deleted_node);
    }
    unlock();
}

template <typename V>
typename linked_list<V>::node * linked_list<V>::append_while_lock(V value) {
    node *new_node = new node(value);

    /* Issue a memory barrier to ensure a consistent view of the value. */
    std::atomic_thread_fence(std::memory_order_acq_rel);

    /* If this is the first entry, initialize the list. */
    if (_tail == NULL) {
        /* Update the list tail. This need not be done atomically, as tail is never accessed by a lockless reader.
         */
        _tail = new_node;

        /* Atomically update the list head; this will be iterated upon by lockless readers. */
        node *expected = NULL;
        if (!std::atomic_compare_exchange_strong(&_head, &expected, new_node)) {
#ifdef DEBUG
            throw "async linked list atomi exchange error";
#endif
        }
    }

    /* Otherwise, append to the end of the list */
    else {
        /* Atomically slot the new record into place; this may be iterated on by a lockless reader. */
        node *expected = NULL;
        node *tail = _tail;
        if (!std::atomic_compare_exchange_strong(&tail->_next, &expected, new_node)) {
#ifdef DEBUG
            throw "async linked list atomi exchange error";
#endif
        }

        /* Update the prev and tail pointers. This is never accessed without a lock, so no additional barrier
         * is required here. */
        new_node->_prev = _tail;
        _tail = new_node;
    }
    
    _list_length++;
    
    if (_refcount == 0) {
        clear_freelist();
    }
    return new_node;
}

template <typename V>
void linked_list<V>::remove_while_lock(V value) {
    node *n = NULL;
    node *target = NULL;
    while ((n = next_while_lock(n)) != NULL) {
        if (n->value() == value) {
            target = n;
            break;
        }
    }
    if (target) {
        remove_node_while_lock(target);
    }
}

template <typename V>
void linked_list<V>::remove_node_while_lock(node *deleted_node) {
    node *item = deleted_node;

    /*
     * Atomically make the item unreachable by readers.
     *
     * This serves as a synchronization point -- after the CAS, the item is no longer reachable via the list.
     */
    if (item == _head) {
        node *next = std::atomic_load(&item->_next);
        std::atomic_store(&_head, next);
    } else {
        node *next = item->_next;
        node *prev = item->_prev;
        if (!std::atomic_compare_exchange_strong(&prev->_next, &item, next)) {
#ifdef DEBUG
            throw "async linked list atomi exchange error";
#endif
        }
    }

    /* Now that the item is unreachable, update the prev/tail pointers. These are never accessed without a lock,
     * and need not be updated atomically. */
    if (item->_next != NULL) {
        /* Item is not the tail (otherwise next would be NULL), so simply update the next item's prev pointer. */
        node *next = item->_next;
        next->_prev = item->_prev;
    } else {
        /* Item is the tail (next is NULL). Simply update the tail record. */
        _tail = item->_prev;
    }

    /* If a reader is active, place the node on the free list. The item is unreachable here when readers
     * aren't active, so if we have a 0 refcount, we can safely delete the item, and be sure that no
     * reader holds a reference to it. */
    if (_refcount > 0) {
        append_freelist(item);
    } else {
        clear_freelist();
        free_value(item);
        delete item;
    }
    
    _list_length--;
}

template <typename V>
void linked_list<V>:: remove_node_safely_while_lock(node *deleted_node) {
    /* Find the record. */
    node *item = _head;
    while (item != NULL) {
        if (item == deleted_node) break;

        item = item->_next;
    }

    /* If not found, nothing to do */
    if (item == NULL) {
        return;
    }
    
    remove_node_while_lock(item);
}

template <typename V>
typename linked_list<V>::node *linked_list<V>::next_while_lock(node *current) {
    if (current != NULL) return current->_next;

    return _head;
}



/**
 * Retain or release the list for reading. This method is async-safe.
 *
 * This must be issued prior to attempting to iterate the list, and must called again once reads have completed.
 *
 * @param enable If true, the list will be retained. If false, released.
 */
template <typename V>
void linked_list<V>::set_reading(bool enable) {
    if (enable) {
        /* Increment and issue a barrier. Once issued, no items will be deallocated while a reference is held. */
        std::atomic_fetch_add(&_refcount,1);
    } else {
        /* Increment and issue a barrier. Once issued, items may again be deallocated. */
        std::atomic_fetch_sub(&_refcount,1);
    }
}

/**
 * Iterate over list nodes. This method is async-safe. If no additional nodes are available, will return NULL.
 *
 * The list must be marked for reading before iteration is performed.
 *
 * @param current The current list node, or NULL to start iteration.
 */
template <typename V>
typename linked_list<V>::node *linked_list<V>::next(node *current) {
#if DEBUG
    assert(_refcount > 0);
#endif
    if (current != NULL) return current->_next;

    return _head;
}



template <typename V>
void linked_list<V>::enumerate_node_with_lock(callback_block block) {
    if (block == NULL) {
        return;
    }
    lock();
    int index = 0;
    bool stop = false;
    node *node = NULL;
    while ((node = next_while_lock(node)) != NULL) {
        block(node->value(),index,&stop);
        index++;
        if (stop) {
            break;
        }
    }
    unlock();
}

template <typename V>
void linked_list<V>::async_enumerate_node(callback_func func, void *ctx) {
    if (func == NULL) {
        return;
    }
    set_reading(true);
    int index = 0;
    bool stop = false;
    node *node = NULL;
    while ((node = next(node)) != NULL) {
        func(node->value(),index,&stop,ctx);
        index++;
        if (stop) {
            break;
        }
    }
    set_reading(false);
}

/*
 * @internal
 *
 * Free all items in @a next list.
 *
 * @param next The head of the list to deallocate.
 *
 * @warning This method is not async-safe, and must only be called with the write lock held, or
 * from the deconstructor.
 */
template <typename V>
void linked_list<V>::free_list(node *next) {
    while (next != NULL) {
        /* Save the current pointer and fetch the next pointer. */
        node *cur = next;
        next = cur->_next;

        /* Deallocate the current item. */
        free_value(cur);
        delete cur;
    }
}

template <typename V>
void linked_list<V>::append_freelist(node *node) {
    if (node == NULL) {
        return;
    }
    node->_prev = _free;
    _free = node;
    _free_list_length++;
}

/* non async safe , in free list use prev pointer only,  */
template <typename V>
void linked_list<V>::clear_freelist() {
    if (_free == NULL) {
        return;
    }
    node *head = _free;
    _free = NULL;
    _free_list_length = 0;
    while (head != NULL) {
        node *cur = head;
        head = cur->_prev;

        free_value(cur);
        delete cur;
    }
}

}  // namespace async
}  // namespace hmd


#endif /* HMDAsyncSafeLinkedList_hpp */
