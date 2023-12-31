/**
 * @file AMGPrerequisites.h
 * @author fanjiaqi (fanjiaqi.837@bytedance.com)
 * @brief Pre define and macro for amazing engine.
 * @version 0.1
 * @date 2019-11-25
 *
 * @copyright Copyright (c) 2019
 *
 */
#ifndef _AMAZINGENGINE_PREREQUISITES_
#define _AMAZINGENGINE_PREREQUISITES_
#include "Gaia/AMGExport.h"
#include <string.h>
#include <stdlib.h>
#include <memory>
#include <memory.h>
#include <vector>
#include <string>

#include "Gaia/Platform/AMGPlatformDef.h"
#include "Gaia/STL/Sort.h"

#if defined(_MSC_VER)
#define AMAZING_DEPRECATED __declspec(deprecated)
#else
#define AMAZING_DEPRECATED __attribute__((deprecated))
// TODO(wangze.happy): 些文件中的宏与老引擎中的Prerequisites.h文件中的宏存在重名，
// 等老引擎下线后，"-Wmacro-redefined"编译警告即可解除
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wmacro-redefined"
#endif

#define NAMESPACE_AMAZING_ENGINE_BEGIN \
    namespace AmazingEngine            \
    {
#define NAMESPACE_AMAZING_ENGINE_END }

#define NAMESPACE_AMAZING_ENGINE_USING using namespace AmazingEngine;

// assert
#if AMAZING_PLATFORM_CONFIG == AMAZING_PLATFORM_DEBUG
#ifdef AMAZING_EDITOR_SDK
#define AEAssert_Return(cond, ret)                                                                 \
    do                                                                                             \
    {                                                                                              \
        if (!(cond))                                                                               \
        {                                                                                          \
            AELOGE(AE_GAME_TAG, "AEAssert_Return failed:%s, %s(%d)\n", #cond, __FILE__, __LINE__); \
            return ret;                                                                            \
        }                                                                                          \
    } while (0)
#define AEAssert(cond)                                                                      \
    do                                                                                      \
    {                                                                                       \
        if (!(cond))                                                                        \
        {                                                                                   \
            AELOGE(AE_GAME_TAG, "AEAssert failed:%s, %s(%d)\n", #cond, __FILE__, __LINE__); \
        }                                                                                   \
    } while (0)
#else
#include <assert.h>
#define AEAssert_Return(cond, ret) assert(cond)
#define AEAssert(cond) assert(cond)
#endif
#else
#define AEAssert_Return(cond, ret)                                                                 \
    do                                                                                             \
    {                                                                                              \
        if (!(cond))                                                                               \
        {                                                                                          \
            AELOGE(AE_GAME_TAG, "AEAssert_Return failed:%s, %s(%d)\n", #cond, __FILE__, __LINE__); \
            return ret;                                                                            \
        }                                                                                          \
    } while (0)
#define AEAssert(cond)                                                                      \
    do                                                                                      \
    {                                                                                       \
        if (!(cond))                                                                        \
        {                                                                                   \
            AELOGE(AE_GAME_TAG, "AEAssert failed:%s, %s(%d)\n", #cond, __FILE__, __LINE__); \
        }                                                                                   \
    } while (0)
#endif
//#define aeAssert(cond)          AEAssert_Return(cond,;)
#define aeAssert(cond) ((void)0)

// check
#define AECheck(cond, ret) \
    do                     \
    {                      \
        if (!(cond))       \
        {                  \
            return ret;    \
        }                  \
    } while (0)

#define AE_SAFE_DELETE(_PTR) \
    do                       \
    {                        \
        if (_PTR)            \
        {                    \
            delete _PTR;     \
            _PTR = nullptr;  \
        }                    \
    } while (false);
#define AE_SAFE_DELETE_ARRAY(_PTR) \
    do                             \
    {                              \
        if (_PTR)                  \
        {                          \
            delete[] _PTR;         \
            _PTR = nullptr;        \
        }                          \
    } while (false);

#ifdef AE_MODULIZATION

/**
 * @brief Alias of std::string
 *
 */
namespace AmazingEngine
{
using String = std::string;
}
#define AELOGE(tag, ...)
#define AELOGW(tag, ...)
#define AELOGS(tag, ...)
#define AELOGI(tag, ...)
//#if AE_DEBUG
#define AELOGD(tag, ...)
#define AELOGV(tag, ...)

#else

#if AMAZING_PLATFORM == AMAZING_WINDOWS
#define AE_INLINE inline
#undef min
#undef max
//为了阻止 min/max 被重新定义成获取最大最小值的宏
#define min min
#define max max
#else
#define AE_INLINE __attribute__((always_inline))
#endif
//// define the real number values to be used
//// default to use 'float' unless precompiler option set
//#if AE_DOUBLE_PRECISION == 1
///** Software floating point type.
// @note Not valid as a pointer to GPU buffers / parameters
// */
// typedef double Real;
//#else
///** Software floating point type.
// @note Not valid as a pointer to GPU buffers / parameters
// */
// typedef float Real;
//#endif

// bits operations
#define AEFlagOn(var, x)                       \
    do                                         \
    {                                          \
        *((uint32_t*)&(var)) |= (uint32_t)(x); \
    } while (0)
#define AEFlagOff(var, x)                         \
    do                                            \
    {                                             \
        *((uint32_t*)&(var)) &= ~((uint32_t)(x)); \
    } while (0)
#define AEFlagGet(var, x) (((uint32_t)(var)) & ((uint32_t)(x)))
#define AEFlagIs(var, x) (((uint32_t)(x)) && (AEFlagGet(var, x) == ((uint32_t)(x))))
#define AEFlagIsNot(var, x) (!AEFlagIs((var), (x)))

#define AEFlag64On(var, x)                       \
    do                                           \
    {                                            \
        *((uint64_t*)&(var)) |= ((uint64_t)(x)); \
    } while (0)
#define AEFlag64Off(var, x)                     \
    do                                          \
    {                                           \
        *((uint64_t)(var)) &= ~((uint64_t)(x)); \
    } while (0)
#define AEFlag64Is(var, x) (((uint64_t)(x)) && ((((uint64_t)(var)) & ((uint64_t)(x))) == ((uint64_t)(x))))
#define AEFlag64IsNot(var, x) (!AEFlag64Is((var), (x)))

#define AEBit(x) ((uint32_t)(1 << (x)))
#define AEBit64(x) ((uint64_t)(((uint64_t)1) << ((uint64_t)(x))))

#define AE_CALLBACK_0(__selector__, __target_, ...) std::bind(&__selector__, __target_, ##__VA_ARGS__)
#define AE_CALLBACK_1(__selector__, __target_, ...) std::bind(&__selector__, __target_, std::placeholders::_1, ##__VA_ARGS__)
#define AE_CALLBACK_2(__selector__, __target_, ...) std::bind(&__selector__, __target_, std::placeholders::_1, std::placeholders::_2, ##__VA_ARGS__)
#define AE_CALLBACK_3(__selector__, __target_, ...) std::bind(&__selector__, __target_, std::placeholders::_1, std::placeholders::_2, std::placeholders::_3, ##__VA_ARGS__)

#define AE_N_BYTE_ALIGN(_BYTE, _N) ((_BYTE + _N - 1) & (~(_N - 1)))

#define AE_NAME_PROPERTY                              \
protected:                                            \
    Name m_name;                                      \
                                                      \
public:                                               \
    void setName(const Name& name) { m_name = name; } \
    const Name& getName() const { return m_name; }

#define SINGLETON(TYPE)        \
    static TYPE* getInstance() \
    {                          \
        static TYPE singleton; \
        return &singleton;     \
    }

// log
#ifndef AE_LOG_MESSAGE_MAXSIZE
#define AE_LOG_MESSAGE_MAXSIZE 4096
#endif

#ifndef AE_FORMAT_BUFFER
#define AE_FORMAT_BUFFER 4096
#endif
/**
 * @brief Log level type.
 *
 */
enum class AMGLogLevelType
{
    AMGLOG_DISABLED = 0,
    AMGLOG_ERROR = 10,
    AMGLOG_WARNING = 20,
    AMGLOG_SYSTEM = 30,
    AMGLOG_INFO = 40,
    AMGLOG_DEBUG = 50,
    AMGLOG_VERBOSE = 60,
};
/**
 * @brief Log output target type.
 *
 */
enum class AMGLogOutType
{
    AMGLog_Console = 0,
    AMGLog_File = 1
};

#define TT(text) (text)
#define AE_GAME_TAG "AE_GAME_TAG"
#define AE_SCRIPT_TAG "AE_SCRIPT_TAG"
#define AE_ALGORITHM_TAG "AE_ALGORITHM_TAG"
#define AE_MEDIA_TAG "AE_MEDIA_TAG"
#define AE_EFFECT_TAG "AE_EFFECT_TAG"
#define AE_TEXT_TAG "AE_TEXT_TAG"
#define AE_PHYSICS_TAG "AE_PHYSICS_TAG"
#define AE_VFX_TAG "AE_VFX_TAG"
#define AE_NETWORK_TAG "AE_NETWORK_TAG"
#define AE_JSRUNTIME_TAG "AE_JSRUNTIME_TAG"

#define AELOGE(tag, ...) ::AmazingEngine::g_aeLogT(TT(__FILE__), __LINE__, static_cast<int>(AMGLogLevelType::AMGLOG_ERROR), (tag), __VA_ARGS__)
#define AELOGW(tag, ...) ::AmazingEngine::g_aeLogT(TT(__FILE__), __LINE__, static_cast<int>(AMGLogLevelType::AMGLOG_WARNING), (tag), __VA_ARGS__)
#define AELOGS(tag, ...) ::AmazingEngine::g_aeLogT(TT(__FILE__), __LINE__, static_cast<int>(AMGLogLevelType::AMGLOG_SYSTEM), (tag), __VA_ARGS__)
#define AELOGI(tag, ...) ::AmazingEngine::g_aeLogT(TT(__FILE__), __LINE__, static_cast<int>(AMGLogLevelType::AMGLOG_INFO), (tag), __VA_ARGS__)
//#if AE_DEBUG
#define AELOGD(tag, ...) ::AmazingEngine::g_aeLogT(TT(__FILE__), __LINE__, static_cast<int>(AMGLogLevelType::AMGLOG_DEBUG), (tag), __VA_ARGS__)
#define AELOGV(tag, ...) ::AmazingEngine::g_aeLogT(TT(__FILE__), __LINE__, static_cast<int>(AMGLogLevelType::AMGLOG_VERBOSE), (tag), __VA_ARGS__)
//#else
//#define AELOGD(tag, ...)
//#define AELOGV(tag, ...)
//#endif

#define AE_DEPRECATED(...)
#define AE_ENUM_DEPRECATED(...)

// If you want to use 'AssetModule' load texture and shader , set 'USING_ASSET_SYSTEM_SOLO' to 1
#ifndef USING_ASSET_SYSTEM_SOLO
#define USING_ASSET_SYSTEM_SOLO 0
#endif

// If you want to use 'AssetModule' cache, set 'USEING_ASSET_SYSTEM_CACHE' to 1
#ifndef USEING_ASSET_SYSTEM_CACHE
#define USEING_ASSET_SYSTEM_CACHE 0
#endif

#ifndef USING_ASSET_SYSTEM_PHYSIC
#define USING_ASSET_SYSTEM_PHYSIC 0
#endif

// If you set ‘USING_ASSET_SYSTEM_SOLO’ to 0, we need to close AC_CLOSE_XXX_SUPPORT
#if !USING_ASSET_SYSTEM_SOLO
#define AC_CLOSE_ZLIB_SUPPORT 1
#define AC_CLOSE_PNG_SUPPORT 1
#define AC_CLOSE_JPEG_SUPPORT 1
#else
//  We need to link library 'jpeg' ‘png’ 'zlib'
#endif

#define AE_FIND_FLAG(TARGET, FLAG) (TARGET && ((TARGET & FLAG) == FLAG))

#define MAX_JOINT_COUNT 48

namespace AmazingEngine
{
using String = std::string;

#if AE_ARCHITECTURE == AE_ARCH_64BIT
/**
 * @brief Alias of unsigned long long.
 *
 */
using GUID = unsigned long long;
#elif AE_ARCHITECTURE == AE_ARCH_32BIT
/**
 * @brief Alias of unsigned long.
 *
 */
using GUID = unsigned long;
#else
/**
 * @brief Alias of unsigned long.
 *
 */
using GUID = unsigned long;
#endif

class Viewer;
/**
 * @brief Alias of std::unique_ptr<Viewer>.
 *
 */
typedef std::unique_ptr<Viewer> ViewerPtr;
/**
 * @brief Alias of std::vector<ViewerPtr>.
 *
 */
typedef std::vector<ViewerPtr> ViewerList;

class View;
/**
 * @brief Alias of std::unique_ptr<View>.
 *
 */
typedef std::unique_ptr<View> ViewPtr;
/**
 * @brief Alias of std::vector<ViewPtr>.
 *
 */
typedef std::vector<ViewPtr> ViewList;

class Entity;
/**
 * @brief Alias of std::unique_ptr<Entity>.
 *
 */
typedef std::unique_ptr<Entity> EntityPtr;
/**
 * @brief Alias of std::vector<EntityPtr>.
 *
 */
typedef std::vector<EntityPtr> EntityList;
/**
 * @brief Alias of size_t.
 *
 */
typedef size_t EntityID;

/**
 * @brief Output log.
 *
 * @param pszFile File name.
 * @param dLine Line number of code.
 * @param dLevel Log level.
 * @param pszTag Log tag.
 * @param pszFormat Log string format.
 */
GAIA_LIB_EXPORT void g_aeLogT(const char* pszFile, int dLine, int dLevel, const char* pszTag, const char* pszFormat, ...);
} // namespace AmazingEngine

// TYPE DECLARE END.

#define AMAZING_IF_RELEASE_NULL(x) \
    do                             \
    {                              \
        if (x)                     \
        {                          \
            delete x;              \
            x = nullptr;           \
        }                          \
    } while (0)

#define AMAZING_SINGLETON_INIT(cls) \
    m_##cls = new cls;              \
    m_##cls->init()

#define AMAZING_SINGLETON_INIT_FUNC(cls, func) \
    m_##cls = func

#define AMAZING_SINGLETON_DEINIT(cls) \
    m_##cls->deinit();                \
    delete m_##cls;                   \
    m_##cls = nullptr

#define AMAZING_SINGLETON_DEF(cls)                    \
public:                                               \
    virtual cls* get##cls() const { return m_##cls; } \
                                                      \
private:                                              \
    cls* m_##cls = nullptr

#define AMAZING_RTTI_OPERATOR(t)      \
    template <>                       \
    struct GAIA_LIB_EXPORT _RTTIOf<t> \
    {                                 \
        RTTI* operator()();           \
    };

#define AMAZING_RTTI_OPERATOR_REBIND(t, r_t)            \
    template <>                                         \
    struct _RTTIOf<t>                                   \
    {                                                   \
        RTTI* operator()() { return _RTTIOf<r_t>()(); } \
    };

#define AMAZING_RTTI_ENUM_OPERATOR(t) \
    enum class t;                     \
    template <>                       \
    struct GAIA_LIB_EXPORT _RTTIOf<t> \
    {                                 \
        RTTI* operator()();           \
    };

#define AMAZING_MRT_COLOR_ATTACHMENT_MAX 4

/**
 * @brief Cast var to cls.
 *
 */
#define AE_OJBECT_CAST(var, cls) var.cast<cls>();

#endif

#if defined(_MSC_VER)
#else
#pragma clang diagnostic pop
#endif

#endif
