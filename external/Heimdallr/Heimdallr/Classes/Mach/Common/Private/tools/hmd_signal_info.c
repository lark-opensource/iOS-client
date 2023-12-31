//
//  hmd_signal_info.c
//
//
//  Heimdallr
//
//  Created by 谢俊逸 on 2019/2/19.
//

#include "hmd_signal_info.h"

#include <signal.h>

typedef struct {
    const int code;
    const char* const name;
} HMDSignalCodeInfo;

typedef struct {
    const int sigNum;
    const char* const name;
    const HMDSignalCodeInfo* const codes;
    const int numCodes;
} HMDSignalInfo;

#define ENUM_NAME_MAPPING(A) \
    { A, #A }

static const HMDSignalCodeInfo g_sigIllCodes[] = {
#ifdef ILL_NOOP
    ENUM_NAME_MAPPING(ILL_NOOP),
#endif
    ENUM_NAME_MAPPING(ILL_ILLOPC), ENUM_NAME_MAPPING(ILL_ILLTRP), ENUM_NAME_MAPPING(ILL_PRVOPC),
    ENUM_NAME_MAPPING(ILL_ILLOPN), ENUM_NAME_MAPPING(ILL_ILLADR), ENUM_NAME_MAPPING(ILL_PRVREG),
    ENUM_NAME_MAPPING(ILL_COPROC), ENUM_NAME_MAPPING(ILL_BADSTK),
};

static const HMDSignalCodeInfo g_sigTrapCodes[] = {
    ENUM_NAME_MAPPING(0),
    ENUM_NAME_MAPPING(TRAP_BRKPT),
    ENUM_NAME_MAPPING(TRAP_TRACE),
};

static const HMDSignalCodeInfo g_sigFPECodes[] = {
#ifdef FPE_NOOP
    ENUM_NAME_MAPPING(FPE_NOOP),
#endif
    ENUM_NAME_MAPPING(FPE_FLTDIV), ENUM_NAME_MAPPING(FPE_FLTOVF), ENUM_NAME_MAPPING(FPE_FLTUND),
    ENUM_NAME_MAPPING(FPE_FLTRES), ENUM_NAME_MAPPING(FPE_FLTINV), ENUM_NAME_MAPPING(FPE_FLTSUB),
    ENUM_NAME_MAPPING(FPE_INTDIV), ENUM_NAME_MAPPING(FPE_INTOVF),
};

static const HMDSignalCodeInfo g_sigBusCodes[] = {
#ifdef BUS_NOOP
    ENUM_NAME_MAPPING(BUS_NOOP),
#endif
    ENUM_NAME_MAPPING(BUS_ADRALN),
    ENUM_NAME_MAPPING(BUS_ADRERR),
    ENUM_NAME_MAPPING(BUS_OBJERR),
};

static const HMDSignalCodeInfo g_sigSegVCodes[] = {
#ifdef SEGV_NOOP
    ENUM_NAME_MAPPING(SEGV_NOOP),
#endif
    ENUM_NAME_MAPPING(SEGV_MAPERR),
    ENUM_NAME_MAPPING(SEGV_ACCERR),
};

#define SIGNAL_INFO(SIGNAL, CODES) \
    { SIGNAL, #SIGNAL, CODES, sizeof(CODES) / sizeof(*CODES) }
#define SIGNAL_INFO_NOCODES(SIGNAL) \
    { SIGNAL, #SIGNAL, 0, 0 }

static const HMDSignalInfo hmd_fatalSignalData[] = {
    SIGNAL_INFO_NOCODES(SIGABRT),       SIGNAL_INFO(SIGBUS, g_sigBusCodes),   SIGNAL_INFO(SIGFPE, g_sigFPECodes),
    SIGNAL_INFO(SIGILL, g_sigIllCodes), SIGNAL_INFO_NOCODES(SIGPIPE),         SIGNAL_INFO(SIGSEGV, g_sigSegVCodes),
    SIGNAL_INFO_NOCODES(SIGSYS),        SIGNAL_INFO(SIGTRAP, g_sigTrapCodes),
};
static const int hmd_fatalSignalsCount = sizeof(hmd_fatalSignalData) / sizeof(*hmd_fatalSignalData);

// Note: Dereferencing a NULL pointer causes SIGILL, ILL_ILLOPC on i386
//       but causes SIGTRAP, 0 on arm.
static const int hmd_fatalSignals[] = {
    SIGABRT, SIGBUS, SIGFPE, SIGILL, SIGPIPE, SIGSEGV, SIGSYS, SIGTRAP,
};

const char* hmdsignal_signalName(const int sigNum) {
    for (int i = 0; i < hmd_fatalSignalsCount; i++) {
        if (hmd_fatalSignalData[i].sigNum == sigNum) {
            return hmd_fatalSignalData[i].name;
        }
    }
    return "SIG_DEFAULT";
}

const char* hmdsignal_signalCodeName(const int sigNum, const int code) {
    for (int si = 0; si < hmd_fatalSignalsCount; si++) {
        if (hmd_fatalSignalData[si].sigNum == sigNum) {
            for (int ci = 0; ci < hmd_fatalSignalData[si].numCodes; ci++) {
                if (hmd_fatalSignalData[si].codes[ci].code == code) {
                    return hmd_fatalSignalData[si].codes[ci].name;
                }
            }
        }
    }
    return "SIG_CODE_DEFAULT";
}

const int* hmdsignal_fatalSignals(void) { return hmd_fatalSignals; }

int hmdsignal_numFatalSignals(void) { return hmd_fatalSignalsCount; }
