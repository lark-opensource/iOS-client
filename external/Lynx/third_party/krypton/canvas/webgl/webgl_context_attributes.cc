//// Copyright 2021 The Lynx Authors. All rights reserved.
//
// #include "webgl_context_attributes.h"
//
// namespace lynx {
//    namespace canvas {
//
//        WebGLContextAttributes::WebGLContextAttributes() {}
//
//        Napi::Boolean WebGLContextAttributes::GetAlpha() {
//            return Napi::Boolean::New(Env(), alpha_);
//        }
//
//        void WebGLContextAttributes::SetAlpha(Napi::Boolean alpha) {
//            alpha_ = alpha;
//        }
//
//        Napi::Boolean WebGLContextAttributes::GetDepth() {
//            return Napi::Boolean::New(Env(), depth_);
//        }
//
//        void WebGLContextAttributes::SetDepth(Napi::Boolean depth) {
//            depth_ = depth;
//        }
//
//        Napi::Boolean WebGLContextAttributes::GetStencil() {
//            return Napi::Boolean::New(Env(), stencil_);
//        }
//
//        void WebGLContextAttributes::SetStencil(Napi::Boolean stencil) {
//            stencil_ = stencil;
//        }
//
//        Napi::Boolean WebGLContextAttributes::GetAntialias() {
//            return Napi::Boolean::New(Env(), antialias_);
//        }
//
//        void WebGLContextAttributes::SetAntialias(Napi::Boolean antialias) {
//            antialias_ = antialias;
//        }
//
//        Napi::Boolean WebGLContextAttributes::GetPremultipliedAlpha() {
//            return Napi::Boolean::New(Env(), premultipliedAlpha_);
//        }
//
//        void WebGLContextAttributes::SetPremultipliedAlpha(Napi::Boolean
//        premultipliedAlpha) {
//            premultipliedAlpha_ = premultipliedAlpha;
//        }
//
//        Napi::Boolean WebGLContextAttributes::GetPreserveDrawingBuffer() {
//            return Napi::Boolean::New(Env(), preserveDrawingBuffer_);
//        }
//
//        void WebGLContextAttributes::SetPreserveDrawingBuffer(Napi::Boolean
//        preserveDrawingBuffer) {
//            preserveDrawingBuffer_ = preserveDrawingBuffer;
//        }
//
//    }  // namespace canvas
//}  // namespace lynx
