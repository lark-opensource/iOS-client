//
//  Log.h
//  TangramLayoutKit
//
//  Created by qihongye on 2021/4/6.
//

#pragma once

#include <stdio.h>
#include "TLNode.h"
#include "Macros.h"

namespace TangramLayoutKit {
namespace Log {

TL_ENUM_DEF(LogLevel, Info, Warning, Error, Fatal)

int DefaultLog(TLNodeConstRef node,
               LogLevel level,
               const char* format,
               va_list args);
int DefaultLogInfo(TLNodeConstRef node, const char* format, va_list args);
int DefaultLogWarning(TLNodeConstRef node, const char* format, va_list args);
int DefaultLogError(TLNodeConstRef node, const char* format, va_list args);
int DefaultLogFatal(TLNodeConstRef node, const char* format, va_list args);

void Log(TLNodeConstRef node, LogLevel level, const char* format, ...) noexcept;

}
}

void assertWithLogicMessage(const char* message);
