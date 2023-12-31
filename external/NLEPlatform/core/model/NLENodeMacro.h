#ifndef NLENODEMACRO_H
#define NLENODEMACRO_H

#include <cassert>

#ifndef NLE_DEBUG
#define NLE_DEBUG
#endif

#ifndef NLE_ASSERT_TRUE
#ifdef NLE_DEBUG
#define NLE_ASSERT_TRUE(__condition) \
    assert(__condition)
#else
#define NLE_ASSERT_TRUE(__condition)
#endif
#endif

#ifndef NLE_ASSERT_NOT_NULL
#ifdef NLE_DEBUG
#define NLE_ASSERT_NOT_NULL(__condition) \
    assert(((__condition) != nullptr))
#else
#define NLE_ASSERT_NOT_NULL(__condition)
#endif
#endif

#ifndef NLE_ASSERT_FALSE
#ifdef NLE_DEBUG
#define NLE_ASSERT_FALSE(__condition) \
    assert(!(__condition))
#else
#define NLE_ASSERT_FALSE(__condition)
#endif
#endif


#endif // NLENODEMACRO_H
