#ifndef VMSDK_QUICKJS_TOOLS_BYTECODEWRITER_H
#define VMSDK_QUICKJS_TOOLS_BYTECODEWRITER_H

#include "quickjs/tools/bytecode_fmt.h"

namespace quickjs {
namespace bytecode {

class BytecodeWriter {
 public:
  BytecodeWriter(const BCRWConfig &config, const std::string &bytecode)
      : config(config), bytecode(bytecode) {}

  inline BCShuffleMode getShuffleMode() const { return config.shuffleMode; }
  std::string write();

 private:
  void writeHeader(BCFmt &BC);
  void writeSections(BCFmt &BC);

 private:
  const BCRWConfig &config;
  const std::string &bytecode;
};

}  // namespace bytecode
}  // namespace quickjs

#endif
