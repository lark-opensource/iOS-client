#ifndef _AUTO_VECTOR_H_
#define _AUTO_VECTOR_H_
#include <algorithm>
template<typename _Tp, size_t fixed_size = 1024 / sizeof(_Tp) + 8> class AutoVector
{
public:
    typedef _Tp value_type;

    //! the default constructor
    explicit AutoVector();
    //! constructor taking the real buffer size
    explicit AutoVector(size_t _size);

    //! the copy constructor
    explicit  AutoVector(const AutoVector<_Tp, fixed_size>& buf);
    //! the assignment operator
    AutoVector<_Tp, fixed_size>& operator = (const AutoVector<_Tp, fixed_size>& buf);

    //! destructor. calls deallocate()
    ~AutoVector();

    //! resizes the buffer and preserves the content
    void resize(size_t _size);
    //! returns the current buffer size
    size_t capacity() const;

    size_t size() const;

    //! returns pointer to the real buffer, stack-allocated or head-allocated
//    operator _Tp* ();
    //! returns read-only pointer to the real buffer, stack-allocated or head-allocated
//    operator const _Tp* () const;

    _Tp &operator [](int index);

    _Tp &operator [](int index) const;

    void push_back(const value_type& v);
    void push_back(value_type&& v);

    void clear() {
        m_occupy = 0;
    }

    bool empty() const {
        return m_occupy == 0;
    }

    _Tp *begin() {
        return ptr;
    }

    _Tp *end() {
        return ptr + m_occupy;
    }

protected:
    //! allocates the new buffer of size _size. if the _size is small enough, stack-allocated buffer is used
    void allocate(size_t _size);
    //! deallocates the buffer if it was dynamically allocated
    void deallocate();

    void reallocate(size_t _size);

protected:
    //! pointer to the real buffer, can point to buf if the buffer is small enough
    _Tp* ptr;
    //! size of the real buffer
    size_t sz;
    //! pre-allocated buffer. At least 1 element to confirm C++ standard reqirements
    _Tp buf[(fixed_size > 0) ? fixed_size : 1];

    size_t m_occupy;
};

template<typename _Tp, size_t fixed_size> inline
AutoVector<_Tp, fixed_size>::AutoVector()
{
    ptr = buf;
    sz = fixed_size;
    m_occupy = 0;
}

template<typename _Tp, size_t fixed_size> inline
AutoVector<_Tp, fixed_size>::AutoVector(size_t _size)
{
    ptr = buf;
    sz = fixed_size;
    m_occupy = _size;
    allocate(_size);
}

template<typename _Tp, size_t fixed_size> inline
AutoVector<_Tp, fixed_size>::AutoVector(const AutoVector<_Tp, fixed_size>& abuf)
{
    ptr = buf;
    sz = fixed_size;
    allocate(abuf.size());
    for (size_t i = 0; i < sz; i++)
        ptr[i] = abuf.ptr[i];
    m_occupy = abuf.m_occupy;
}

template<typename _Tp, size_t fixed_size> inline AutoVector<_Tp, fixed_size>&
AutoVector<_Tp, fixed_size>::operator = (const AutoVector<_Tp, fixed_size>& abuf)
{
    if (this != &abuf)
    {
        deallocate();
        allocate(abuf.capacity());
        for (size_t i = 0; i < sz; i++) {
            ptr[i] = abuf.ptr[i];
        }
        m_occupy = abuf.m_occupy;
    }
    return *this;
}

template<typename _Tp, size_t fixed_size> inline
AutoVector<_Tp, fixed_size>::~AutoVector()
{
    deallocate();
}

template<typename _Tp, size_t fixed_size> inline void
AutoVector<_Tp, fixed_size>::allocate(size_t _size)
{
    if (_size <= sz)
    {
        sz = _size;
        return;
    }
    deallocate();
    sz = _size;
    if (_size > fixed_size)
    {
        ptr = new _Tp[_size];
    }
}

template<typename _Tp, size_t fixed_size> inline void
AutoVector<_Tp, fixed_size>::deallocate()
{
    if (ptr != buf)
    {
        delete[] ptr;
        ptr = buf;
        sz = fixed_size;
    }
}

template<typename _Tp, size_t fixed_size> inline void
AutoVector<_Tp, fixed_size>::resize(size_t _size)
{
    reallocate(_size);
    m_occupy = _size;
}

template<typename _Tp, size_t fixed_size> inline void
AutoVector<_Tp, fixed_size>::reallocate(size_t _size)
{
    if (_size <= sz)
    {
        sz = _size;
        return;
    }
    size_t i, prevsize = sz, minsize = std::min(prevsize, _size);
    _Tp* prevptr = ptr;

    ptr = _size > fixed_size ? new _Tp[_size] : buf;
    sz = _size;

    if (ptr != prevptr)
        for (i = 0; i < minsize; i++)
            ptr[i] = prevptr[i];
    for (i = prevsize; i < _size; i++)
        ptr[i] = _Tp();

    if (prevptr != buf)
        delete[] prevptr;
}

template<typename _Tp, size_t fixed_size> inline size_t
AutoVector<_Tp, fixed_size>::capacity() const
{
    return sz;
}


template<typename _Tp, size_t fixed_size> inline size_t
AutoVector<_Tp, fixed_size>::size() const
{
    return m_occupy;
}

//template<typename _Tp, size_t fixed_size> inline
//AutoVector<_Tp, fixed_size>::operator _Tp* ()
//{
//    return ptr;
//}
//
//template<typename _Tp, size_t fixed_size> inline
//AutoVector<_Tp, fixed_size>::operator const _Tp* () const
//{
//    return ptr;
//}

template<typename _Tp, size_t fixed_size> inline
void AutoVector<_Tp, fixed_size>::push_back(const value_type& v) {
    if (m_occupy >= sz) {
        reallocate(sz * 3 / 2);
    }
    ptr[m_occupy] = v;
    m_occupy++;
}

template<typename _Tp, size_t fixed_size> inline
void AutoVector<_Tp, fixed_size>::push_back(value_type&& v) {
    if (m_occupy >= sz) {
        reallocate(sz * 3 / 2);
    }
    ptr[m_occupy] = v;
    m_occupy++;
}

template<typename _Tp, size_t fixed_size> inline
_Tp &AutoVector<_Tp, fixed_size>::operator [](int index) {
    return ptr[index];
}
template<typename _Tp, size_t fixed_size> inline
_Tp &AutoVector<_Tp, fixed_size>::operator [](int index) const {
    return ptr[index];
}

#endif
