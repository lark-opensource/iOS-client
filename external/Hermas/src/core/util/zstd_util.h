//
//  zstd_util.hpp
//  Hermas
//
//  Created by 崔晓兵 on 10/2/2022.
//

#pragma once

#include <stdint.h>
#include <string>

#define ZSTD_CLEVEL_CUSTOM 15

namespace hermas {
    std::string zstd_compress_data(const char* input_str, size_t length, int compress_level = ZSTD_CLEVEL_CUSTOM);
    std::string zstd_compress_data(const std::string& input_str, int compress_level = ZSTD_CLEVEL_CUSTOM);
    std::string zstd_compress_data_usingDic(const char* input_str, size_t length, const char* cdict_str, size_t cdict_str_length, int compress_level = ZSTD_CLEVEL_CUSTOM);
    std::string zstd_compress_data_usingDic(const std::string& input_str, const std::string& cdict_str, int compress_level = ZSTD_CLEVEL_CUSTOM);

//    std::string zstd_decompress_data(const char* input_str, size_t length);
//    std::string zstd_decompress_data(const std::string& input_str);
//    std::string zstd_decompress_data_usingDic(const char* input_str, size_t length, const char* ddict_str, size_t ddict_str_length);
//    std::string zstd_decompress_data_usingDic(const std::string& input_str, const std::string& ddict_str);
}

