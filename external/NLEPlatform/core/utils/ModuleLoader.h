//
// Created by 34988 on 2020/6/12.
//

#ifndef NLEPLATFORM_UTILS_MODULELOADER_H
#define NLEPLATFORM_UTILS_MODULELOADER_H

#if defined(_WIN32)
#include <windows.h>
typedef HMODULE MODULE_HANDLE;
#else
#include <dlfcn.h>
typedef void * MODULE_HANDLE;
#endif

namespace cut::utils {
        class ModuleLoader {
        public:
            static MODULE_HANDLE MLOpen(const char * moduleName);
            static void MLClose(MODULE_HANDLE handle);
            static void * MLGetProc(MODULE_HANDLE handle, const char * lpProcName);
            static void MLGetLastErrorMsg(char *p, int size);
        };
    }

#endif //NLEPLATFORM_UTILS_MODULELOADER_H
