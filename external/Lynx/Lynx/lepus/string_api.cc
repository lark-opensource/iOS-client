//
// Created by zhangye on 2020/8/19.
//

#include "lepus/string_api.h"

#include <utility>
namespace lynx {
namespace lepus {
int GetRegExpFlags(std::string flags) {
  int re_flags = 0;
  int mask = 0;
  for (char flag : flags) {
    switch (flag) {
      case 'g':
        mask = LRE_FLAG_GLOBAL;
        break;
      case 'i':
        mask = LRE_FLAG_IGNORECASE;
        break;
      case 'm':
        mask = LRE_FLAG_MULTILINE;
        break;
      case 's':
        mask = LRE_FLAG_DOTALL;
        break;
      case 'u':
        mask = LRE_FLAG_UTF16;
        break;
      case 'y':
        mask = LRE_FLAG_STICKY;
        break;
      default:
        break;
    }
    re_flags |= mask;
  }
  return re_flags;
}

void GetUnicodeFromUft8(const char* buf, size_t buf_len, size_t& unicode_len,
                        bool& has_unicode, std::vector<uint16_t>& result) {
  uint16_t* buf_tmp = new uint16_t[buf_len];
  DCHECK(result.size() >= buf_len);
  memcpy(buf_tmp, buf, buf_len);
  const uint8_t *p, *p_end, *p_start;

  // check is no contain unicode
  const uint8_t *p_check, *p_check_end, *p_check_start;
  p_check_start = reinterpret_cast<const uint8_t*>(buf_tmp);
  p_check = p_check_start;
  p_check_end = p_check_start + buf_len;
  while (p_check < p_check_end && *p_check < 128) {
    p_check++;
  }

  if (p_check == p_check_end) {
    has_unicode = false;
    memcpy(result.data(), buf_tmp, buf_len);
  } else {
    has_unicode = true;
    p_start = reinterpret_cast<const uint8_t*>(buf_tmp);
    p = p_start;
    p_end = p_start + buf_len;
    unicode_len = 0;
    for (size_t i = 0; i < buf_len && p < p_end; i++) {
      result[i] = unicode_from_utf8(p, UTF8_CHAR_LEN_MAX, &p);
      unicode_len++;
    }
  }
  delete[] buf_tmp;
}

// ref
// https://developer.mozilla.org/zh-CN/docs/Web/JavaScript/Reference/Global_Objects/String/replace#%E4%BD%BF%E7%94%A8%E5%AD%97%E7%AC%A6%E4%B8%B2%E4%BD%9C%E4%B8%BA%E5%8F%82%E6%95%B0
std::string GetReplaceStr(const std::string& data,
                          const std::string& need_to_replace_str,
                          const std::string& replace_to_str, int32_t position) {
  std::string string_to_replace = "";
  for (size_t i = 0; i < replace_to_str.length();) {
    char ch = replace_to_str[i];
    if (ch == '$' && i < replace_to_str.length() - 1) {
      switch (replace_to_str[i + 1]) {
        case '$': {
          // char '$'
          i += 2;
          string_to_replace.push_back('$');
          break;
        }
        case '&': {
          // string need to be replaced
          i += 2;
          string_to_replace.insert(string_to_replace.end(),
                                   need_to_replace_str.begin(),
                                   need_to_replace_str.end());
          break;
        }
        case '`': {
          // left content of the matched substring
          i += 2;
          std::string match_substr_before = data.substr(0, position);
          string_to_replace.insert(string_to_replace.end(),
                                   match_substr_before.begin(),
                                   match_substr_before.end());
          break;
        }
        case '\'': {
          // right content of the matched substring
          i += 2;
          std::string match_substr_after = data.substr(position + 1);
          string_to_replace.insert(string_to_replace.end(),
                                   match_substr_after.begin(),
                                   match_substr_after.end());
          break;
        }
        default: {
          string_to_replace.push_back(ch);
          i++;
          break;
        }
      }
    } else {
      string_to_replace.push_back(ch);
      i++;
    }
  }
  return string_to_replace;
}

std::string GetReplaceStr(const std::string& param2_str,
                          const Value& array_global, const int& match_index,
                          const String& input, uint8_t* bc,
                          const bool& global_mode) {
  std::string string_to_replace;
  for (size_t i = 0; i < param2_str.size();) {
    char ch = param2_str[i];
    if (ch == '$' && i < param2_str.size() - 1) {
      switch (param2_str[i + 1]) {
        case '$': {
          i += 2;
          string_to_replace.push_back('$');
          break;
        }
        case '&': {
          i += 2;
          std::string match_substr = array_global.Array()
                                         ->get(match_index)
                                         .Array()
                                         ->get(1)
                                         .String()
                                         ->str();
          string_to_replace.insert(string_to_replace.end(),
                                   match_substr.begin(), match_substr.end());
          break;
        }
        case '`': {
          i += 2;
          int ret;
          int find_match_inner = 0;

          size_t start_search_index = 0;
          size_t input_len = input.length();

          std::vector<uint16_t> str_c(input_len);
          bool has_unicode = false;
          GetUnicodeFromUft8(input.c_str(), input.length(), input_len,
                             has_unicode, str_c);
          int shift = has_unicode ? 1 : 0;
          while (start_search_index <= input_len) {
            uint8_t* capture[CAPTURE_COUNT_MAX * 2];
            ret =
                lre_exec(capture, bc, reinterpret_cast<uint8_t*>(str_c.data()),
                         static_cast<int>(start_search_index),
                         static_cast<int>(input_len), shift, nullptr);
            if (ret == 0 || ret == -1) {
              break;
            }
            DCHECK(capture[0] && capture[1]);

            size_t match_start =
                (capture[0] - reinterpret_cast<uint8_t*>(str_c.data())) >>
                shift;
            size_t match_end =
                (capture[1] - reinterpret_cast<uint8_t*>(str_c.data())) >>
                shift;
            std::string str_to_replace;

            if (find_match_inner == match_index) {
              std::string match_substr_before;
              if (has_unicode) {
                size_t match_start_C = UTF8IndexToCIndex(
                    input.c_str(), input.length(), match_start);
                match_substr_before = input.str().substr(0, match_start_C);
              } else {
                match_substr_before = input.str().substr(0, match_start);
              }
              string_to_replace.insert(string_to_replace.end(),
                                       match_substr_before.begin(),
                                       match_substr_before.end());
              break;
            } else {
              find_match_inner++;
              if (global_mode) {
                start_search_index = match_end;
              } else {
                start_search_index = input_len + 1;
              }
            }
          }
          break;
        }
        case '\'': {
          i += 2;
          int ret;
          size_t start_search_index = 0;
          size_t input_len = input.length();
          int find_match_inner = 0;
          std::vector<uint16_t> str_c(input_len);
          bool has_unicode = false;
          GetUnicodeFromUft8(input.c_str(), input.length(), input_len,
                             has_unicode, str_c);
          int shift = has_unicode ? 1 : 0;
          while (start_search_index <= input_len) {
            uint8_t* capture[CAPTURE_COUNT_MAX * 2];
            ret =
                lre_exec(capture, bc, reinterpret_cast<uint8_t*>(str_c.data()),
                         static_cast<int>(start_search_index),
                         static_cast<int>(input_len), shift, nullptr);
            if (ret == 0 || ret == -1) {
              break;
            }
            DCHECK(capture[0] && capture[1]);

            size_t match_end =
                (capture[1] - reinterpret_cast<uint8_t*>(str_c.data())) >>
                shift;
            std::string str_to_replace;

            if (find_match_inner == match_index) {
              std::string match_substr_after;
              if (has_unicode) {
                size_t match_end_C =
                    UTF8IndexToCIndex(input.c_str(), input.length(), match_end);
                match_substr_after = input.str().substr(match_end_C);
              } else {
                match_substr_after = input.str().substr(match_end);
              }
              string_to_replace.insert(string_to_replace.end(),
                                       match_substr_after.begin(),
                                       match_substr_after.end());
              break;
            } else {
              find_match_inner++;
              if (global_mode) {
                start_search_index = match_end;
              } else {
                start_search_index = input_len + 1;
              }
            }
          }
          break;
        }
        default: {
          int param_num = 0;
          size_t j = i + 1;
          for (; j < param2_str.size(); j++) {
            if (param2_str[j] >= '0' && param2_str[j] <= '9') {
              param_num = param_num * 10 + (param2_str[j] - '0');
            } else {
              break;
            }
          }
          i = j;

          std::string parentheses_str = array_global.Array()
                                            ->get(match_index)
                                            .Array()
                                            ->get(1 + param_num * 3)
                                            .String()
                                            ->c_str();
          string_to_replace.insert(string_to_replace.end(),
                                   parentheses_str.begin(),
                                   parentheses_str.end());
          break;
        }
      }
    } else {
      string_to_replace.push_back(ch);
      i++;
    }
  }
  return string_to_replace;
}

static void GetReplaceResult(std::string& str_to_replace, std::string& result,
                             bool has_unicode, bool& str_to_replace_has_unicode,
                             size_t& str_to_replace_unicode_len,
                             size_t match_start, size_t match_end) {
  std::vector<uint16_t> str_to_replace_ctr(str_to_replace.length());
  GetUnicodeFromUft8(str_to_replace.c_str(), str_to_replace.length(),
                     str_to_replace_unicode_len, str_to_replace_has_unicode,
                     str_to_replace_ctr);
  if (has_unicode) {
    size_t match_start_C =
        UTF8IndexToCIndex(result.c_str(), result.length(), match_start);
    size_t match_end_C =
        UTF8IndexToCIndex(result.c_str(), result.length(), match_end);
    result = result.replace(match_start_C, match_end_C - match_start_C,
                            str_to_replace.c_str(), str_to_replace.length());
  } else {
    result = result.replace(match_start, match_end - match_start,
                            str_to_replace.c_str(), str_to_replace.length());
  }
}

static void GetRegExecuteResult(const int& capture_count, uint8_t** capture,
                                const int& shift, const std::string& result,
                                uint16_t* str_c, size_t& match_start,
                                size_t& match_end, const bool& has_unicode,
                                Value& array_global) {
  Value array_data = Value(CArray::Create());
  array_data.Array()->push_back(Value(StringImpl::Create(result)));
  for (int i = 0; i < capture_count; i++) {
    if (capture[2 * i] == nullptr || capture[2 * i + 1] == nullptr) continue;
    size_t start =
        (capture[2 * i] - reinterpret_cast<uint8_t*>(str_c)) >> shift;
    size_t end =
        (capture[2 * i + 1] - reinterpret_cast<uint8_t*>(str_c)) >> shift;
    if (i == 0) {
      match_start = start;
      match_end = end;
    }

    if (has_unicode) {
      size_t match_start_C =
          UTF8IndexToCIndex(result.c_str(), result.length(), start);
      size_t match_end_C =
          UTF8IndexToCIndex(result.c_str(), result.length(), end);
      array_data.Array()->push_back(Value(StringImpl::Create(
          result.substr(match_start_C, match_end_C - match_start_C))));
    } else {
      array_data.Array()->push_back(
          Value(StringImpl::Create(result.substr(start, end - start))));
    }
    array_data.Array()->push_back(Value(static_cast<int32_t>(start)));
    array_data.Array()->push_back(Value(static_cast<int32_t>(end)));
  }
  array_global.Array()->push_back(array_data);
}

static Value Search(Context* context) {
  long params_count = context->GetParamsSize();
  DCHECK(context->GetParam(params_count - 1)->IsString());
  String str = context->GetParam(params_count - 1)->String();
  size_t input_len = str.length();

  lynx::base::scoped_refptr<lepus::RegExp> reg_exp;
  if (params_count != 1) {
    DCHECK(params_count == 2);
    if (context->GetParam(0)->IsRegExp()) {
      reg_exp = context->GetParam(0)->RegExp();
    } else {
      DCHECK(context->GetParam(0)->IsString());
      reg_exp = RegExp::Create(context->GetParam(0)->String()->str());
    }
  } else {
    // no param
    Value result = Value(static_cast<int64_t>(0));
    return result;
  }

  const char* pattern = reg_exp->get_pattern().c_str();
  std::string flags = reg_exp->get_flags().str();

  // search function
  uint8_t* bc;
  char error_msg[64];
  int len, ret;
  int re_flags = GetRegExpFlags(flags);
  bc = lre_compile(&len, error_msg, sizeof(error_msg), pattern, strlen(pattern),
                   re_flags, nullptr);

  if (bc == nullptr) {
    context->ReportError("SyntaxError: Invalid regular expression: /" +
                         reg_exp->get_pattern().str() + "/:" + error_msg);
    return Value();
  }

  std::vector<uint16_t> str_c(input_len);
  bool has_unicode = false;
  GetUnicodeFromUft8(str.c_str(), str.length(), input_len, has_unicode, str_c);
  int shift = has_unicode ? 1 : 0;
  uint8_t* capture[CAPTURE_COUNT_MAX * 2];
  ret = lre_exec(capture, bc, reinterpret_cast<uint8_t*>(str_c.data()), 0,
                 static_cast<int>(str.length()), shift, nullptr);
  // free bc
  free(bc);

  int64_t start = -1;
  if (ret == 1 && capture[0]) {
    start = (capture[0] - reinterpret_cast<uint8_t*>(str_c.data())) >> shift;
  }

  Value result = Value(start);
  return result;
}

static Value Trim(Context* context) {
  long params_count = context->GetParamsSize();
  DCHECK(params_count == 1);
  DCHECK(context->GetParam(0)->IsString());
  auto str = context->GetParam(0)->String();
  return Value(StringImpl::Create(str->get_trim()));
}

static Value CharAt(Context* context) {
  long params_count = context->GetParamsSize();
  DCHECK(context->GetParam(params_count - 1)->IsString());
  auto str = context->GetParam(params_count - 1)->String();
  size_t pos = 0;
  if (params_count != 1) {
    DCHECK(params_count == 2);
    DCHECK(context->GetParam(0)->IsNumber());
    pos = static_cast<size_t>(
        static_cast<int64_t>(context->GetParam(0)->Number()));
  }
  if (pos >= 0 && pos < str->str().length())
    return Value(StringImpl::Create(str->str().substr(pos, 1)));
  else
    return Value(StringImpl::Create(""));
}

static Value Match(Context* context) {
  long params_count = context->GetParamsSize();
  DCHECK(context->GetParam(params_count - 1)->IsString());
  Value result = Value(CArray::Create());
  result.Array()->SetIsMatchResult();
  String str = context->GetParam(params_count - 1)->String();

  // no params
  if (params_count == 1) {
    Value a = Value(StringImpl::Create(""));
    result.Array()->push_back(a);

    Value index_value = Value(0);
    result.Array()->push_back(index_value);

    Value input_value = Value(StringImpl::Create(str.str()));
    result.Array()->push_back(input_value);

    Value groups_value = Value();
    result.Array()->push_back(groups_value);
    return result;
  }

  size_t input_len = str.length();

  DCHECK(params_count == 2);

  std::string pattern;
  std::string flags;
  Value* param;
  int re_flags = 0;

  // handle param:
  param = context->GetParam(0);
  if (param->IsRegExp()) {
    auto reg_exp = context->GetParam(0)->RegExp();
    pattern = reg_exp->get_pattern().str();
    flags = reg_exp->get_flags().str();
    re_flags = GetRegExpFlags(flags);
  } else {
    if (param->IsString()) {
      pattern = param->String()->c_str();
    } else if (param->IsNil()) {
      pattern = "null";
    } else if (param->IsNumber()) {
      switch (param->Type()) {
        case Value_Int64:
        case Value_UInt64: {
          pattern = std::to_string(param->Int64());
          break;
        }
        case Value_Int32:
        case Value_UInt32: {
          pattern = std::to_string(param->Int32());
          break;
        }
        case Value_Double: {
          pattern = std::to_string(param->Number());
        }
        default:
          break;
      }
    }
  }

  // match function
  uint8_t* bc;
  char error_msg[64];
  int len, ret;
  bc = lre_compile(&len, error_msg, sizeof(error_msg), pattern.c_str(),
                   pattern.length(), re_flags, nullptr);

  if (bc == nullptr) {
    context->ReportError("SyntaxError: Invalid regular expression: /" +
                         pattern + "/: " + error_msg);
    return Value();
  }

  bool global_mode = false;
  if (flags.find('g') != std::string::npos) {
    global_mode = true;
  }

  std::vector<uint16_t> str_c(input_len);
  bool has_unicode = false;
  GetUnicodeFromUft8(str.c_str(), str.length(), input_len, has_unicode, str_c);
  int shift = has_unicode ? 1 : 0;

  size_t start_search_index = 0;
  int capture_count = -1;
  int match_num = 0;
  while (start_search_index <= input_len) {
    uint8_t* capture[CAPTURE_COUNT_MAX * 2];
    ret = lre_exec(capture, bc, reinterpret_cast<uint8_t*>(str_c.data()),
                   static_cast<int>(start_search_index),
                   static_cast<int>(input_len), shift, nullptr);
    if (ret == 0 || ret == -1) {
      if (match_num == 0) {
        result = Value();
      }
      break;
    }
    DCHECK(capture[0] && capture[1]);
    if (!global_mode) {
      capture_count = lre_get_capture_count(bc);
    }

    size_t match_start = 0;
    size_t match_end = 0;
    std::string substr;
    if (global_mode) {
      match_start =
          (capture[0] - reinterpret_cast<uint8_t*>(str_c.data())) >> shift;
      match_end =
          (capture[1] - reinterpret_cast<uint8_t*>(str_c.data())) >> shift;
      if (has_unicode) {
        size_t match_start_C =
            UTF8IndexToCIndex(str.c_str(), str.str().length(), match_start);
        size_t match_end_C =
            UTF8IndexToCIndex(str.c_str(), str.str().length(), match_end);
        substr = str.str().substr(match_start_C, match_end_C - match_start_C);
      } else {
        substr = str.str().substr(match_start, match_end - match_start);
      }
      result.Array()->push_back(Value(StringImpl::Create(substr)));
    } else {
      for (int i = 0; i < capture_count; i++) {
        if (!capture[2 * i] || !capture[2 * i + 1]) {
          // console.log('https'.match(/http(s)??/));
          Value a = Value();
          result.Array()->push_back(a);
          continue;
        }
        size_t start =
            (capture[2 * i] - reinterpret_cast<uint8_t*>(str_c.data())) >>
            shift;
        size_t end =
            (capture[2 * i + 1] - reinterpret_cast<uint8_t*>(str_c.data())) >>
            shift;
        if (i == 0) {
          match_start = start;
          match_end = end;
        }

        if (has_unicode) {
          size_t match_start_C =
              UTF8IndexToCIndex(str.c_str(), str.str().length(), start);
          size_t match_end_C =
              UTF8IndexToCIndex(str.c_str(), str.str().length(), end);
          substr = str.str().substr(match_start_C, match_end_C - match_start_C);
        } else {
          substr = str.str().substr(start, end - start);
        }
        result.Array()->push_back(Value(StringImpl::Create(substr)));
      }
      Value index_value = Value(static_cast<int32_t>(match_start));
      result.Array()->push_back(index_value);

      Value input_value = Value(StringImpl::Create(str.str()));
      result.Array()->push_back(input_value);

      std::string group = "undefined";
      Value groups_value = Value(StringImpl::Create(group));
      result.Array()->push_back(groups_value);
    }
    if (global_mode) {
      start_search_index = match_end;
    } else {
      start_search_index = input_len + 1;
    }
    match_num++;
  }

  if (global_mode) {
    result.Array()->push_back(Value());
    result.Array()->push_back(Value());
    result.Array()->push_back(Value());
  }
  free(bc);
  return result;
}

static Value Replace(Context* context) {
  long params_count = context->GetParamsSize();
  DCHECK(context->GetParam(params_count - 1)->IsString());
  String str = context->GetParam(params_count - 1)->String();
  std::string result = str.str();
  if (params_count != 1) {
    DCHECK(params_count == 3);
  }

  size_t input_len = str.length();
  std::vector<uint16_t> str_c(input_len);
  bool has_unicode = false;
  std::string flags;
  int re_flags = 0;
  Value* param1 = context->GetParam(0);
  DCHECK(param1->IsRegExp() || param1->IsString());
  Value* param2 = context->GetParam(1);
  std::string param2_str = "";
  switch (param2->Type()) {
    case Value_String: {
      param2_str = param2->String()->str();
      break;
    }
    case Value_Nil: {
      param2_str = "null";
      break;
    }
    case Value_Undefined: {
      param2_str = "undefined";
      break;
    }
    default: {
      param2_str = "";
      break;
    }
  }

  if (param1->IsString()) {
    // if the pattern is a string, just replace the first matched substring
    std::string need_to_replace = param1->String()->str();
    if (!param2->IsClosure()) {
      std::string str_to_replace = "";
      result = str.str();
      auto position = result.find(need_to_replace);
      if (position != std::string::npos) {
        if (param2_str.find('$') == std::string::npos) {
          str_to_replace = param2_str;
        } else {
          str_to_replace = GetReplaceStr(result, need_to_replace, param2_str,
                                         static_cast<int32_t>(position));
        }

        if (str_to_replace == "") {
          result.erase(position, need_to_replace.length());
        } else {
          result.replace(position, need_to_replace.length(), str_to_replace, 0,
                         str_to_replace.length());
        }
      }
    }
  } else if (param1->IsRegExp()) {
    // if the pattern is a reg exp, use lre_compile and lre_exe function to
    // get the result
    auto& pattern = param1->RegExp()->get_pattern();
    flags = param1->RegExp()->get_flags().str();
    re_flags = GetRegExpFlags(flags);

    uint8_t* bc;
    char error_msg[64];
    int len, ret;
    bc = lre_compile(&len, error_msg, sizeof(error_msg), pattern.c_str(),
                     pattern.length(), re_flags, nullptr);

    if (bc == nullptr) {
      context->ReportError("SyntaxError: Invalid regular expression: / " +
                           pattern.str() + "/: " + error_msg);
      return Value();
    }

    size_t start_search_index = 0;
    int shift = has_unicode ? 1 : 0;
    int find_match = 0;

    // array_global:
    // 0: whole string
    // for every match:
    // 0: match str, 1: match_start_index, 2: match_end_index.
    // for every parentheses match:
    // 0: match str, 1: match_start_index, 2: match_end_index.ß
    Value array_global = Value(CArray::Create());

    bool global_mode = flags.find('g') != std::string::npos;
    while (start_search_index <= input_len && input_len > 0) {
      std::vector<uint16_t> str_c;
      str_c.resize(result.length());
      GetUnicodeFromUft8(result.c_str(), result.length(), input_len,
                         has_unicode, str_c);
      shift = has_unicode ? 1 : 0;
      uint8_t* capture[CAPTURE_COUNT_MAX * 2];
      ret = lre_exec(capture, bc, reinterpret_cast<uint8_t*>(str_c.data()),
                     static_cast<int>(start_search_index),
                     static_cast<int>(input_len), shift, nullptr);
      if (ret == 0 || ret == -1) {
        break;
      }
      DCHECK(capture[0] && capture[1]);

      size_t match_start = 0;
      size_t match_end = 0;
      std::string str_to_replace;
      bool str_to_replace_has_unicode = false;
      size_t str_to_replace_unicode_len = 0;

      if (!param2->IsClosure() && param2_str.find('$') == std::string::npos) {
        match_start =
            (capture[0] - reinterpret_cast<uint8_t*>(str_c.data())) >> shift;
        match_end =
            (capture[1] - reinterpret_cast<uint8_t*>(str_c.data())) >> shift;
        str_to_replace = param2_str;
        str_to_replace_unicode_len = str_to_replace.length();
        GetReplaceResult(str_to_replace, result, has_unicode,
                         str_to_replace_has_unicode, str_to_replace_unicode_len,
                         match_start, match_end);
        str_c.resize(result.length());
        GetUnicodeFromUft8(result.c_str(), result.length(), input_len,
                           has_unicode, str_c);
      } else {
        int capture_count = lre_get_capture_count(bc);
        GetRegExecuteResult(capture_count, capture, shift, result, str_c.data(),
                            match_start, match_end, has_unicode, array_global);

        if (param2->IsClosure()) {
          Value* call_function = param2;
          int param_len = -1;
          Value* this_obj = context->GetParam(params_count - 1);
          Value* match = this_obj + (++param_len);
          *match = Value(
              array_global.Array()->get(find_match).Array()->get(1).String());
          size_t parentheses_match_size =
              (array_global.Array()->get(find_match).Array()->size() - 1) / 3 -
              1;
          for (size_t i = 0; i < parentheses_match_size; i++) {
            Value* p = this_obj + (++param_len);
            *p = Value(array_global.Array()
                           ->get(find_match)
                           .Array()
                           ->get(3 * i + 4)
                           .String());
          }

          Value* offset = this_obj + (++param_len);
          offset->SetNumber(static_cast<int64_t>(
              array_global.Array()->get(find_match).Array()->get(2).Number()));
          Value* string = this_obj + (++param_len);
          *string = Value(
              array_global.Array()->get(find_match).Array()->get(0).String());
          Value call_function_ret;
          static_cast<VMContext*>(context)->CallFunction(
              call_function, param_len + 1, &call_function_ret);
          find_match++;
          str_to_replace = call_function_ret.String()->str();
          str_to_replace_unicode_len = str_to_replace.length();
          GetReplaceResult(str_to_replace, result, has_unicode,
                           str_to_replace_has_unicode,
                           str_to_replace_unicode_len, match_start, match_end);
        } else {
          str_to_replace = GetReplaceStr(param2_str, array_global, find_match,
                                         str, bc, global_mode);
          str_to_replace_unicode_len = str_to_replace.length();
          find_match++;
          GetReplaceResult(str_to_replace, result, has_unicode,
                           str_to_replace_has_unicode,
                           str_to_replace_unicode_len, match_start, match_end);
        }
      }
      input_len = result.length();
      if (global_mode) {
        if (str_to_replace_has_unicode) {
          start_search_index = match_end + (str_to_replace_unicode_len -
                                            (match_end - match_start));
        } else {
          start_search_index =
              match_end + (str_to_replace.length() - (match_end - match_start));
        }
      } else {
        start_search_index = input_len + 1;
      }
    }
    free(bc);
  }
  Value re = Value(StringImpl::Create(result));
  return Value(re);
}

static Value Slice(Context* context) {
  auto params_count = context->GetParamsSize();
  DCHECK(params_count == 1 || params_count == 2 || params_count == 3);

  std::string str = context->GetParam(params_count - 1)->String()->str();
  if (params_count == 1) {
    return Value(StringImpl::Create(str));
  }

  int64_t startIndex = static_cast<int64_t>(context->GetParam(0)->Number());
  if (startIndex < 0) {
    size_t size_c = CIndexToUTF8Index(str.c_str(), str.length(), str.size());
    startIndex = size_c + startIndex;
  }
  size_t start_index = UTF8IndexToCIndex(str.c_str(), str.length(),
                                         static_cast<size_t>(startIndex));
  size_t strIndex = start_index >= str.size() ? str.size() : start_index;

  if (params_count == 2) {
    return Value(StringImpl::Create(str.substr(strIndex)));
  } else {
    int64_t endIndex = static_cast<int64_t>(context->GetParam(1)->Number());
    if (endIndex < 0) {
      size_t size_c = CIndexToUTF8Index(str.c_str(), str.length(), str.size());
      endIndex = size_c + endIndex;
    }
    size_t end_index = UTF8IndexToCIndex(str.c_str(), str.length(),
                                         static_cast<size_t>(endIndex));
    if (start_index >= end_index) {
      return Value(StringImpl::Create(""));
    }
    return Value(
        StringImpl::Create(str.substr(start_index, end_index - start_index)));
  }
}

static Value SubString(Context* context) {
  auto params_count = context->GetParamsSize();
  DCHECK(context->GetParam(params_count - 1)->IsString());
  std::string str = context->GetParam(params_count - 1)->String()->str();
  DCHECK(params_count == 2 || params_count == 3);
  DCHECK(context->GetParam(0)->IsNumber());

  int32_t start = static_cast<int32_t>(context->GetParam(0)->Number());
  if (params_count == 2) {
    start = start < 0 ? 0 : start;
    start = static_cast<size_t>(start) > str.size()
                ? static_cast<int32_t>(str.size())
                : start;
    size_t start_index = UTF8IndexToCIndex(str.c_str(), str.length(), start);
    return Value(StringImpl::Create(str.substr(start_index)));
  } else {
    DCHECK(context->GetParam(1)->IsNumber());
    int32_t end = static_cast<int32_t>(context->GetParam(1)->Number());
    if (start > end) {
      std::swap(start, end);
    }
    start = start < 0 ? 0 : start;
    start = static_cast<size_t>(start) > str.size()
                ? static_cast<int32_t>(str.size())
                : start;
    size_t start_index = UTF8IndexToCIndex(str.c_str(), str.length(), start);

    end = end < 0 ? 0 : end;
    end = static_cast<size_t>(end) > str.size()
              ? static_cast<int32_t>(str.size())
              : end;
    size_t end_index = UTF8IndexToCIndex(str.c_str(), str.length(), end);
    return Value(
        StringImpl::Create(str.substr(start_index, end_index - start_index)));
  }
}

static Value IndexOf(Context* context) {
  long params_count = context->GetParamsSize();
  DCHECK(params_count > 1);
  Value* this_obj = context->GetParam(0);
  Value* arg = context->GetParam(1);
  long index = params_count == 2 ? 0 : context->GetParam(2)->Number();

  if (this_obj->IsString() && arg->IsString()) {
    std::size_t result = this_obj->String()->find(*arg->String(), index);
    if (result != std::string::npos) {
      return Value(static_cast<uint32_t>(CIndexToUTF8Index(
          this_obj->String()->c_str(), this_obj->String()->length(), result)));
    }
  }
  return Value(-1);
}

static Value Length(Context* context) {
  DCHECK(context->GetParam(0)->IsString());
  auto str = context->GetParam(0)->String();
  return Value(static_cast<uint32_t>(SizeOfUtf8(str->c_str(), str->length())));
}

// substr(start[, length])
static Value SubStr(Context* context) {
  long params_count = context->GetParamsSize();
  DCHECK(params_count == 3 || params_count == 2);
  DCHECK(context->GetParam(0)->IsString());
  DCHECK(context->GetParam(1)->IsNumber());
  auto str = context->GetParam(0)->String();

  int64_t start = static_cast<int64_t>(context->GetParam(1)->Number());
  size_t utf8_start_index = static_cast<size_t>(
      start < 0 ? (static_cast<size_t>(abs(start)) > str->size()
                       ? 0
                       : static_cast<int64_t>(str->size()) + start)
                : start);
  size_t start_index =
      UTF8IndexToCIndex(str->c_str(), str->length(), utf8_start_index);
  if (params_count == 3) {
    DCHECK(context->GetParam(2)->IsNumber());
    int64_t length = static_cast<int64_t>(context->GetParam(2)->Number());
    if (length <= 0) {
      return Value(StringImpl::Create(""));
    }
    size_t end_index =
        UTF8IndexToCIndex(str->c_str(), str->length(),
                          utf8_start_index + static_cast<size_t>(length));
    return Value(StringImpl::Create(
        str->str().substr(start_index, end_index - start_index)));
  } else {
    return Value(StringImpl::Create(str->str().substr(start_index)));
  }
}

static Value Split(Context* context) {
  auto params_count = context->GetParamsSize();
  DCHECK(params_count == 1 || params_count == 2 || params_count == 3);

  std::string str = context->GetParam(params_count - 1)->String()->str();
  std::string pattern = context->GetParam(0)->String()->str();

  size_t pattern_length = pattern.length(), str_length = str.length();
  Value res = Value(CArray::Create()), temp;
  auto array_res = res.Array();
  size_t max_size = 0, size = 0;
  bool max_flag = false;
  if (params_count == 3) {
    max_size = static_cast<size_t>(context->GetParam(1)->Number());
    max_flag = true;
  } else if (params_count == 1) {
    temp = Value(StringImpl::Create(str));
    array_res->push_back(temp);
    return res;
  }
  if (str_length == 0) {
    if (pattern_length != 0) {
      if (max_size || !max_flag) {
        temp = Value(StringImpl::Create(""));
        array_res->push_back(temp);
      }
    }
  } else if (pattern_length == 0) {
    for (size_t i = 0; i < str_length;) {
      if (max_flag && size == max_size) break;
      size_t cur_length = InlineUTF8SequenceLength(str[i]);
      temp = Value(StringImpl::Create(&str[i], cur_length));
      i += cur_length;
      array_res->push_back(temp);
      size++;
    }
    std::cout << std::endl;
  } else {
    std::string strs = str + pattern;
    size_t pos = strs.find(pattern);
    while (pos != strs.npos) {
      if (max_flag && size == max_size) break;
      std::string temp_string = strs.substr(0, pos);
      temp = Value(StringImpl::Create(temp_string));
      array_res->push_back(temp);
      size++;
      strs = strs.substr(pos + pattern_length, strs.size());
      pos = strs.find(pattern);
    }
  }
  return res;
}

void RegisterStringAPI(Context* ctx) {
  lynx::base::scoped_refptr<Dictionary> table = Dictionary::Create();
  RegisterTableFunction(ctx, table, "indexOf", &IndexOf);
  RegisterTableFunction(ctx, table, "length", &Length);
  RegisterTableFunction(ctx, table, "substr", &SubStr);
  RegisterFunctionTable(ctx, "String", table);
}

void RegisterStringPrototypeAPI(Context* ctx) {
  lynx::base::scoped_refptr<Dictionary> table = Dictionary::Create();
  RegisterTableFunction(ctx, table, "split", &Split);
  RegisterTableFunction(ctx, table, "trim", &Trim);
  RegisterTableFunction(ctx, table, "charAt", &CharAt);
  RegisterTableFunction(ctx, table, "search", &Search);
  RegisterTableFunction(ctx, table, "match", &Match);
  RegisterTableFunction(ctx, table, "replace", &Replace);
  RegisterTableFunction(ctx, table, "slice", &Slice);
  RegisterTableFunction(ctx, table, "substring", &SubString);
  reinterpret_cast<VMContext*>(ctx)->SetStringPrototype(Value(table));
}

}  // namespace lepus
}  // namespace lynx
