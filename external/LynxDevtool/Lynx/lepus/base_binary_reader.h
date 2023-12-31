//  Copyright 2022 The Lynx Authors. All rights reserved.

#ifndef LYNX_LEPUS_BASE_BINARY_READER_H_
#define LYNX_LEPUS_BASE_BINARY_READER_H_

#include <memory>
#include <string>
#include <unordered_map>
#include <utility>
#include <vector>

#include "base/ref_counted.h"
#include "lepus/binary_reader.h"
#include "lepus/function.h"
#include "lepus/regexp.h"
#include "lepus/value.h"
#include "tasm/compile_options.h"

namespace lynx {
namespace lepus {

#define DECODE_VALUE(name) \
  lepus::Value name;       \
  ERROR_UNLESS(DecodeValue(&name))

#define DECODE_VALUE_HEADER(name) \
  lepus::Value name;              \
  ERROR_UNLESS(DecodeValue(&name, true))

#define DECODE_STR(name)                                             \
  base::scoped_refptr<lepus::StringImpl> name = CreateLepusString(); \
  ERROR_UNLESS(DecodeUtf8Str(name))

#define DECODE_STDSTR(name) \
  std::string name;         \
  ERROR_UNLESS(DecodeUtf8Str(&name))

#define DECODE_DICTIONARY(name, is_header)                                  \
  lynx::base::scoped_refptr<lepus::Dictionary> name = Dictionary::Create(); \
  ERROR_UNLESS(DecodeTable(name, is_header))

#define DECODE_CLOSURE(name)                                           \
  base::scoped_refptr<lepus::Closure> name = Closure::Create(nullptr); \
  ERROR_UNLESS(DecodeClosure(name))

#define DECODE_ARRAY(name)                                    \
  base::scoped_refptr<lepus::CArray> name = CArray::Create(); \
  ERROR_UNLESS(DecodeArray(name))

#define DECODE_DATE(name)                                   \
  base::scoped_refptr<lepus::CDate> name = CDate::Create(); \
  ERROR_UNLESS(DecodeDate(name))

#define DECODE_REGEXP(name)                                   \
  base::scoped_refptr<lepus::RegExp> name = RegExp::Create(); \
  ERROR_UNLESS(DecodeRegExp(name))

#define DECODE_U32LEB(name) \
  uint32_t name = 0;        \
  ERROR_UNLESS(ReadU32Leb128(&name))

#define DECODE_S32LEB(name) \
  int32_t name = 0;         \
  ERROR_UNLESS(ReadS32Leb128(&name))

#define DECODE_U64LEB(name) \
  uint64_t name = 0;        \
  ERROR_UNLESS(ReadU64Leb128(&name))

#define DECODE_U8(name) \
  uint8_t name = 0;     \
  ERROR_UNLESS(ReadU8(&name))

#define DECODE_U32(name) \
  uint32_t name = 0;     \
  ERROR_UNLESS(ReadU32(&name))

#define DECODE_DOUBLE(name) \
  double name = 0.0;        \
  ERROR_UNLESS(ReadD64Leb128(&name))

#define DECODE_BOOL(name)             \
  [[maybe_unused]] bool name = false; \
  do {                                \
    uint8_t value = 0;                \
    ERROR_UNLESS(ReadU8(&value));     \
    name = (bool)value;               \
  } while (0)

#define DECODE_FUNCTION(parent, name)                                    \
  base::scoped_refptr<lepus::Function> name = lepus::Function::Create(); \
  ERROR_UNLESS(DeserializeFunction(parent, name))

class InputStream;
class Closure;
class Dictionary;
class CArray;
class Value;
class CDate;
class Function;
class Context;

class BaseBinaryReader : public BinaryReader {
 public:
  BaseBinaryReader(std::unique_ptr<InputStream> stream)
      : BinaryReader(std::move(stream)) {}

#if !ENABLE_JUST_LEPUSNG
  bool DeserializeFunction(base::scoped_refptr<Function>& parent,
                           base::scoped_refptr<Function>& function);
  bool DeserializeGlobal(
      std::unordered_map<lepus::String, lepus::Value>& global);
  bool DeserializeTopVariables(
      std::unordered_map<lepus::String, long>& top_level_variables);
  bool DecodeClosure(base::scoped_refptr<Closure>&);
  bool DecodeRegExp(base::scoped_refptr<RegExp>& reg);
  bool DecodeDate(base::scoped_refptr<CDate>&);
#endif

  // String section
  bool DeserializeStringSection();

  bool DecodeUtf8Str(lynx::base::scoped_refptr<lepus::StringImpl>&);
  bool DecodeUtf8Str(std::string*);
  bool DecodeTable(lynx::base::scoped_refptr<Dictionary>&, bool = false);
  bool DecodeArray(base::scoped_refptr<CArray>&);
  bool DecodeValue(Value*, bool = false);

  base::scoped_refptr<lepus::StringImpl> CreateLepusString();

 protected:
#if !ENABLE_JUST_LEPUSNG
  // for serialize/deserialize
  std::unordered_map<lynx::base::scoped_refptr<Function>, int> func_map;
  std::vector<lynx::base::scoped_refptr<Function>> func_vec;
#endif

  uint32_t string_list_count_{0};
  std::vector<lepus::String> string_list_{};
  tasm::CompileOptions compile_options_;
};

}  // namespace lepus
}  // namespace lynx

#endif  // LYNX_LEPUS_BASE_BINARY_READER_H_
