#ifndef QUICKJS_TOOLS_CINTERFACE_H
#define QUICKJS_TOOLS_CINTERFACE_H

#include <string>

#include "base_export.h"
#include "quickjs/tools/bytecode_fmt.h"

QJS_EXPORT std::string encoding(const std::string &jsContent,
                                quickjs::bytecode::BCRWConfig &jsonObj);

#endif
