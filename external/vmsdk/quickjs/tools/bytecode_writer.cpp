#include "quickjs/tools/bytecode_writer.h"

using namespace quickjs::bytecode;

const uint32_t BCSection::INVALID_NUM = std::numeric_limits<uint32_t>::max();

std::string BytecodeWriter::write() {
  // 1. prepare the data struct of BC
  BCFmt BC;
  writeHeader(BC);
  writeSections(BC);

  // 2. write to memory
  DataBuffer DS(BC.calcSz());
  BC.write(DS);

  return DS.getStrData();
}

void BytecodeWriter::writeHeader(BCFmt &BC) {
  BC.header.magic = QUICKJS_SHUFFLE_MAGIC_NUM;
  BC.header.version = config.version;
  // need to repatch secNum
}

void BytecodeWriter::writeSections(BCFmt &BC) {
  // 1. write version
  std::string verContent = std::to_string((uint32_t)SecType::ST_VERSION);
  BC.sections.emplace_back(SecType::ST_VERSION, BCSection::INVALID_NUM,
                           verContent.size() + 1);
  BC.secContents.emplace_back(verContent);

  // 2. write js bytecode
  BC.sections.emplace_back(SecType::ST_JS_BYTECODE, BCSection::INVALID_NUM,
                           bytecode.size() + 1);
  BC.secContents.emplace_back(bytecode);

  // 3. shuffle mode
  std::string shuffleContent = std::to_string(config.shuffleMode);
  BC.sections.emplace_back(SecType::ST_SHUFFLE, BCSection::INVALID_NUM,
                           shuffleContent.size() + 1);
  BC.secContents.emplace_back(shuffleContent);
}
