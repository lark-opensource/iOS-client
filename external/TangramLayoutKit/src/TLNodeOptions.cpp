//
//  TLNodeOptions.cpp
//  TangramLayoutKit
//
//  Created by qihongye on 2021/4/6.
//

#include "TLNodeOptions.h"
#include "public.h"
#include "Macros.h"
#include <stdlib.h>

TL_LOCAL
static int _globalNodeCounter = 0;

TLNodeOptions::TLNodeOptions(float pointScaleFactor,
                             TLLogger info,
                             TLLogger warning,
                             TLLogger error,
                             TLLogger fatal) {
    this->pointScaleFactor = pointScaleFactor;
    _info = info;
    _warning = warning;
    _error = error;
    _fatal = fatal;
}

TLNodeOptions::TLNodeOptions(TLLogger info, TLLogger warning, TLLogger error, TLLogger fatal)
: _info(info), _warning(warning), _error(error), _fatal(fatal), pointScaleFactor(1) {}

TLNodeOptions::TLNodeOptions(const TLNodeOptions& options) {
    pointScaleFactor = options.pointScaleFactor;
    _warning = options._warning;
    _info = options._info;
    _error = options._error;
    _fatal = options._fatal;
}

void TLNodeOptions::logInfo(TLNodeConstRef node, const char* format, va_list args) {
    if (_info) {
        _info(node, format, args);
    }
}

void TLNodeOptions::logWarning(TLNodeConstRef node, const char* format, va_list args) {
    if (_warning) {
        _warning(node, format, args);
    }
}

void TLNodeOptions::logError(TLNodeConstRef node, const char* format, va_list args) {
    if (_error) {
        _error(node, format, args);
    }
}

void TLNodeOptions::logFatal(TLNodeConstRef node, const char* format, va_list args) {
    if (_fatal) {
        _fatal(node, format, args);
    }
    abort();
}

void TLNodeOptions::increaseGlobalNodeCounter() {
#if DEBUG
    _globalNodeCounter++;
#endif
}

void TLNodeOptions::decreaseGlobalNodeCounter() {
#if DEBUG
    _globalNodeCounter--;
#endif
}

bool TLNodeOptions::operator==(const TLNodeOptions & r) const {
    return pointScaleFactor == r.pointScaleFactor
    && _info == r._info
    && _warning == r._warning
    && _error == r._error
    && _fatal == r._fatal;
}

bool TLNodeOptionsEqual(const TLNodeOptions& l, const TLNodeOptions& r) {
    return l == r;
}

int TLNodeGetGlobalCounter() {
    return _globalNodeCounter;
}
