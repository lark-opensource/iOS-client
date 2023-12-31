//// Copyright 2021 The Lynx Authors. All rights reserved.
//
// #ifndef LYNX_CANVAS_WEBGL_CONTEXT_ATTRIBUTES_H
// #define LYNX_CANVAS_WEBGL_CONTEXT_ATTRIBUTES_H
//
// #include "jsbridge/bindings/canvas2/base.h"
//
// namespace lynx {
//    namespace canvas {
//
//        class WebGLContextAttributes : public ImplBase {
//        public:
//            WebGLContextAttributes();
//            Napi::Boolean GetAlpha();
//            void SetAlpha(Napi::Boolean alpha);
//            Napi::Boolean GetDepth();
//            void SetDepth(Napi::Boolean depth);
//            Napi::Boolean GetStencil();
//            void SetStencil(Napi::Boolean stencil);
//            Napi::Boolean GetAntialias();
//            void SetAntialias(Napi::Boolean antialias);
//            Napi::Boolean GetPremultipliedAlpha();
//            void SetPremultipliedAlpha(Napi::Boolean premultipliedAlpha);
//            Napi::Boolean GetPreserveDrawingBuffer();
//            void SetPreserveDrawingBuffer(Napi::Boolean
//            preserveDrawingBuffer);
//
//        private:
//            bool alpha_;
//            bool depth_;
//            bool stencil_;
//            bool antialias_;
//            bool premultipliedAlpha_;
//            bool preserveDrawingBuffer_;
//        };
//
//    }  // namespace canvas
//}  // namespace lynx
//
// #endif //LYNX_CANVAS_WEBGL_CONTEXT_ATTRIBUTES_H
