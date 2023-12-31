//
//  BDCompressor.hpp
//  BDALog
//
//  Created by kilroy on 2021/11/20.
//

#ifndef BDCompressor_hpp
#define BDCompressor_hpp

#include <stdio.h>
#include "zlib.h"

namespace BDALog {

class BDCompressor final {
  public:
    BDCompressor();//init & create
    ~BDCompressor(); //destroy
    bool Reset();
    bool Compress(const void* input,
                  size_t input_len,
                  void* output,
                  size_t output_len,
                  size_t& compressed_len,
                  bool finish);
    
  private:
    bool Init();
    z_stream cstream_;
    //ZSTD_CCtx *z = nullptr;
};

}
#endif /* BDCompressor_hpp */
