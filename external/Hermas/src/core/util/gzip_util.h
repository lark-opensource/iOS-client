//
//  gzip_util.hpp
//  hermas
//
//  Created by xuzhi on 2021/6/29.
//

#pragma once

#include <stdint.h>
#include <string>


namespace hermas {
    struct gzip_block_t {
        char            *block_data;
        uint32_t        block_length;
        uint32_t        data_length;
    };

    /*
        Create a Gzip data block
     */
    struct gzip_block_t* gzip_create_block();
    /*
        Destroy the Gzip data block
    */
    void gzip_release_block(struct gzip_block_t* block);

    /*
        Compress the input string with gzip
        Return the length of the output string
    */
    int gzip( const char* input_str, uint32_t length, struct gzip_block_t* pblock );

    /*
        Decompress the input string with gzip
        Return the length of the output string
    */
    int gunzip( const char* input_str, uint32_t length, struct gzip_block_t* pblock );

    // Gzip Data
    std::string gzip_data( const char* input_str, uint32_t length );
    std::string gzip_data( const std::string& input_str );

    // GUnzip Data
    std::string gunzip_data( const char* input_str, uint32_t length );
    std::string gunzip_data( const std::string& input_str );
}
