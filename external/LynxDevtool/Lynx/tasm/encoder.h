#ifndef LYNX_TASM_ENCODER_H_
#define LYNX_TASM_ENCODER_H_
#include <string>
#include <vector>

#include "tasm/generator/base_struct.h"

namespace lynx {
namespace tasm {
enum EncodeSSRError {
  ERR_MIX_DATA = 101,
  ERR_DECODE,
  ERR_NOT_SSR,
  ERR_BUF,
  ERR_DATA_EMPTY
};

lynx::tasm::EncodeResult encode(const std::string& options_str);
std::string quickjsCheck(const std::string& source);
lynx::tasm::EncodeResult encode_ssr(const uint8_t* ptr, size_t buf_len,
                                    const std::string& mixin_data);

}  // namespace tasm
}  // namespace lynx

#endif  // LYNX_TASM_ENCODER_H_
