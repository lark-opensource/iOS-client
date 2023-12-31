#ifndef LYNX_LEPUS_LEPUS_DATE_API_H_
#define LYNX_LEPUS_LEPUS_DATE_API_H_

#include <string>
#include <vector>

#include "config/config.h"

#if !ENABLE_JUST_LEPUSNG

#include "lepus/builtin.h"
#include "lepus/lepus_date.h"
#include "lepus/table.h"
#include "lepus/vm_context.h"

namespace lynx {
namespace lepus {

void RegisterLepusDateAPI(Context* ctx);

void RegisterLepusDatePrototypeAPI(Context* ctx);

const std::vector<std::string>& DateContent();

}  // namespace lepus
}  // namespace lynx
#endif  // ENABLE_JUST_LEPUSNG
#endif  // LYNX_LEPUS_LEPUS_DATE_API_H_
