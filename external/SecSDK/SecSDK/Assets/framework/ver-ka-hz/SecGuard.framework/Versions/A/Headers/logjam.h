#ifndef LOGJAM_H
#define LOGJAM_H

#if defined(__LINUX__) || defined(__APPLE__)
#if 0
    #define LOGV(...) printf(__VA_ARGS__)
    #define LOGD(...) printf(__VA_ARGS__)
    #define LOGI(...) printf(__VA_ARGS__)
    #define LOGW(...) printf(__VA_ARGS__)
    #define LOGE(...) printf(__VA_ARGS__)
#else
    #define LOGV(...)
    #define LOGD(...)
    #define LOGI(...)
    #define LOGW(...)
    #define LOGE(...)
#endif
#endif

#ifdef SP_SECTION
#define BCF \
__attribute__((section (".atext"))) \
__attribute__((__annotate__(("fla")))) \
__attribute__((__annotate__(("sub")))) \
__attribute__((__annotate__(("bcf")))) \

#define NOBCF \
__attribute__((section (".atext"))) \
__attribute__((__annotate__(("fla")))) \
__attribute__((__annotate__(("sub")))) \
__attribute__((__annotate__(("nobcf")))) \

#else
#define BCF
#define NOBCF
#endif

#endif
