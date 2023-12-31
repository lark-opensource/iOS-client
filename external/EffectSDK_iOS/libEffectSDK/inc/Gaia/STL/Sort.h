#ifndef Sort_h
#define Sort_h

#include <algorithm>
#include <functional>
#include <cstdint>

namespace AmazingEngine
{

namespace algorithm
{

struct IteratorProxy
{
    struct Table
    {
        void (&swap)(const void* self, const void* that) noexcept;
        void (&assign)(const void* self, const void* that) noexcept;
        void* (&construct)(const void* that) noexcept;
        void (&destruct)(const void* self) noexcept;
    } const* vtable;

    void* valueptr;

    inline IteratorProxy& operator=(IteratorProxy&& that) noexcept
    {
        vtable->assign(this->valueptr, that.valueptr);
        return *this;
    }

    friend void swap(IteratorProxy& x, IteratorProxy& y) noexcept
    {
        x.vtable->swap(x.valueptr, y.valueptr);
    }

    ~IteratorProxy()
    {
        vtable->destruct(valueptr);
        free(valueptr);
    }

    inline IteratorProxy(IteratorProxy&& that) noexcept
    {
        vtable = that.vtable;
        valueptr = vtable->construct(that.valueptr);
    }

private:
    struct EmptyDestructor
    {
        static void destruct(const void* valueptr) noexcept
        {
        }
    };

    template <typename T, bool = std::is_trivially_destructible<T>::value>
    struct Destructor;

    template <typename T>
    struct Destructor<T, true> : public EmptyDestructor
    {
    };

    template <typename T>
    struct Destructor<T, false>
    {
        static void destruct(const void* valueptr) noexcept
        {
            ((T*)valueptr)->~T();
        }
    };

    template <size_t Size>
    struct TriviallyStructor : public EmptyDestructor
    {
        static void assign(const void* dst, const void* src) noexcept
        {
            struct value_type
            {
                uint8_t data[Size];
            };
            *(value_type*)dst = std::move(*(value_type*)src);
        }

        static void* construct(const void* that) noexcept
        {
            void* valueptr = malloc(Size);
            assign(valueptr, that);
            return valueptr;
        }

        static void swap(const void* dst, const void* src) noexcept
        {
            struct value_type
            {
                uint8_t data[Size];
            };
            std::swap(*(value_type*)dst, *(value_type*)src);
        }

        static const Table& get()
        {
            static const Table value =
                {
                    .swap = TriviallyStructor<Size>::swap,
                    .assign = TriviallyStructor<Size>::assign,
                    .construct = TriviallyStructor<Size>::construct,
                    .destruct = TriviallyStructor<Size>::destruct,
                };
            return value;
        }
    };

public:
    template <typename T, bool = std::is_trivially_destructible<T>::value&& std::is_trivially_move_constructible<T>::value&& std::is_trivially_move_assignable<T>::value>
    struct VirtualTable;

    template <typename T>
    struct VirtualTable<T, false> : public Destructor<T>
    {
        static void* construct(const void* that) noexcept
        {
            T* valueptr = (T*)malloc(sizeof(T));
            new (valueptr) T(std::move(*(T*)that));
            return valueptr;
        }

        static void assign(const void* dst, const void* src) noexcept
        {
            *(T*)dst = std::move(*(T*)src);
        }

        static void swap(const void* dst, const void* src) noexcept
        {
            std::swap(*(T*)dst, *(T*)src);
        }

        static const Table& get()
        {
            static const Table value =
                {
                    .swap = VirtualTable<T>::swap,
                    .assign = VirtualTable<T>::assign,
                    .construct = VirtualTable<T>::construct,
                    .destruct = VirtualTable<T>::destruct,
                };
            return value;
        }
    };

    template <typename T>
    struct VirtualTable<T, true> : public TriviallyStructor<sizeof(T)>
    {
    };
};

struct ProxyComparator
{
    template <typename T, class Comp>
    static inline ProxyComparator create(const Comp& comp)
    {
        return ProxyComparator((const void*)&comp, Function<T, Comp>);
    }

    bool operator()(const IteratorProxy& left, const IteratorProxy& right) const noexcept
    {
        return func(comp, left.valueptr, right.valueptr);
    }

private:
    template <typename T, class Comp>
    static bool Function(const void* comp, const void* left, const void* right)
    {
        return (*(Comp*)comp)(*(T*)left, *(T*)right);
    };

    typedef bool Func(const void* comp, const void* left, const void* right);

    ProxyComparator(const void* comp, Func& func) noexcept
        : comp(comp)
        , func(func)
    {
    }

    const void* const comp;
    Func& func;
};

template <class RandomIt, class Comp>
inline void sort(RandomIt first, RandomIt last, const Comp& comp, void (&sortor)(IteratorProxy*, IteratorProxy*, const ProxyComparator&))
{
    using value_type = typename std::iterator_traits<RandomIt>::value_type;
    size_t count = last - first;
    if (count > 1)
    {
        const IteratorProxy::Table& table = IteratorProxy::VirtualTable<value_type>::get();
        IteratorProxy* buffer = (IteratorProxy*)malloc(sizeof(IteratorProxy) * count);
        for (size_t i = 0; i < count; ++i)
        {
            buffer[i].vtable = &table;
            buffer[i].valueptr = &first[i];
        }
        sortor(buffer, buffer + count, ProxyComparator::create<value_type, Comp>(comp));
        free(buffer);
    }
}

} // namespace algorithm

template <class RandomIt, class Comp>
inline void sort(RandomIt first, RandomIt last, Comp comp)
{
    return algorithm::sort(first, last, comp, std::sort<algorithm::IteratorProxy*, const algorithm::ProxyComparator&>);
}

template <class RandomIt>
inline void sort(RandomIt first, RandomIt last)
{
    using value_type = typename std::iterator_traits<RandomIt>::value_type;
    return AmazingEngine::sort(first, last, std::less<value_type>());
}

template <class RandomIt, class Comp>
inline void stable_sort(RandomIt first, RandomIt last, Comp comp)
{
    return algorithm::sort(first, last, comp, std::stable_sort<algorithm::IteratorProxy*, const algorithm::ProxyComparator&>);
}

template <class RandomIt>
inline void stable_sort(RandomIt first, RandomIt last)
{
    using value_type = typename std::iterator_traits<RandomIt>::value_type;
    return AmazingEngine::stable_sort(first, last, std::less<value_type>());
}

} // namespace AmazingEngine

#endif //Sort_h
