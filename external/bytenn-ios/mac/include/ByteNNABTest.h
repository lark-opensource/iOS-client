#ifndef BYTENN_AB_TEST
#define BYTENN_AB_TEST

#ifdef __cplusplus

#if defined(BYTENN_ENABLE_ABTEST)
#define BYTENN_ABTEST_CONFIG_VALUE(v)    BYTENN::ABTest::ConfigValue(v)
namespace BYTENN { namespace ABTest {
void ConfigValue(const char*);
}}
#else
#define BYTENN_ABTEST_CONFIG_VALUE(v)    void(0)
#endif

#endif

#endif
