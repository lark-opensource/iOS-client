//
//  ByteViewMTLLayerRenderer.h
//  ByteViewRTCRenderer
//
//  Created by liujianlong on 2022/7/28.
//

#ifndef ByteViewMTLLayerRenderer_hpp
#define ByteViewMTLLayerRenderer_hpp

#include <CoreVideo/CoreVideo.h>
#include <memory>
#include <functional>

namespace byteview {


struct PixelBufferDeleter {
    void operator ()(CVPixelBufferRef ptr) {
        CVPixelBufferRelease(ptr);
    }
};

using PixelBufferPtr = std::unique_ptr<std::remove_pointer<CVPixelBufferRef>::type, PixelBufferDeleter>;

struct PixelBufferWrapper {
    PixelBufferPtr buffer;
    // 顺时针旋转角度
    enum Rotation {
        Rotation_0 = 0,
        Rotation_90 = 1,
        Rotation_180 = 2,
        Rotation_270 = 3,
    };
    // 变化顺序: crop -> flip -> rotation
    float crop_x;
    float crop_y;
    float crop_width;
    float crop_height;
    Rotation rotation;
    bool horizontal_flip;
};

class PixelBufferRenderer {
public:
    using CompletionCallback = std::function<void(bool success)>;
    virtual void renderPixelBuffer(PixelBufferWrapper buffer, CompletionCallback completion) = 0;
};

}


#endif /* ByteViewMTLLayerRenderer_h */
