//
//  TLNodeOptions.h
//  TangramLayoutKit
//
//  Created by qihongye on 2021/4/6.
//

#pragma once

#include <stdio.h>
#include "Types.h"
#include "Macros.h"

struct TL_EXPORT TLNodeOptions {
private:
    TLLogger _info;
    TLLogger _warning;
    TLLogger _error;
    TLLogger _fatal;

public:
    float pointScaleFactor = 1.0;

    TLNodeOptions(float pointScaleFactor, TLLogger info, TLLogger warning, TLLogger error, TLLogger fatal);
    TLNodeOptions(TLLogger info, TLLogger warning, TLLogger error, TLLogger fatal);
    TLNodeOptions(const TLNodeOptions& options);
    ~TLNodeOptions() = default;

    void logInfo(TLNodeConstRef, const char*, va_list);
    void logWarning(TLNodeConstRef, const char*, va_list);
    void logError(TLNodeConstRef, const char*, va_list);
    void logFatal(TLNodeConstRef, const char*, va_list);

    void increaseGlobalNodeCounter();
    void decreaseGlobalNodeCounter();

    bool operator ==(const TLNodeOptions& r) const;
};

TL_EXPORT
bool TLNodeOptionsEqual(const TLNodeOptions& l, const TLNodeOptions& r);
