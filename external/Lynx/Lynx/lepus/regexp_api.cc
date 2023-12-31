//
// Created by zhangye on 2020/8/19.
//
#include "lepus/regexp_api.h"

#include <string>
#include <vector>

namespace lynx {
namespace lepus {
static Value Test(Context* context) {
  long params_count = context->GetParamsSize();
  DCHECK(context->GetParam(params_count - 1)->IsRegExp());
  auto reg_exp = context->GetParam(params_count - 1)->RegExp();

  std::string pattern = reg_exp->get_pattern().str();
  std::string flags = reg_exp->get_flags().str();

  std::string input;
  size_t input_len = 0;
  if (params_count != 1) {
    DCHECK(params_count == 2);
    input = context->GetParam(0)->String()->str();
    input_len = input.length();
  } else {
    input = "undefined";
    input_len = 9;
  }

  std::vector<uint16_t> str_c;
  str_c.resize(input_len);
  bool has_unicode = false;
  GetUnicodeFromUft8(input.c_str(), strlen(input.c_str()), input_len,
                     has_unicode, str_c);

  uint8_t* bc;
  char error_msg[64];
  int len, ret;
  int re_flags = GetRegExpFlags(flags);
  bc = lre_compile(&len, error_msg, sizeof(error_msg), pattern.c_str(),
                   pattern.length(), re_flags, nullptr);
  DCHECK(bc);

  uint8_t* capture[CAPTURE_COUNT_MAX * 2];

  int shift = has_unicode ? 1 : 0;
  ret = lre_exec(capture, bc, reinterpret_cast<uint8_t*>(str_c.data()), 0,
                 static_cast<int>(input_len), shift, nullptr);
  // free bc
  free(bc);
  Value result = Value(static_cast<bool>(ret));
  return result;
}

void RegisterREGEXPPrototypeAPI(Context* ctx) {
  lynx::base::scoped_refptr<Dictionary> table = Dictionary::Create();
  RegisterTableFunction(ctx, table, "test", &Test);
  reinterpret_cast<VMContext*>(ctx)->SetRegexpPrototype(Value(table));
}
}  // namespace lepus
}  // namespace lynx
