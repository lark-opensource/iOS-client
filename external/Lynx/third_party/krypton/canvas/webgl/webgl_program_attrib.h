// Copyright 2021 The Lynx Authors. All rights reserved.

#ifndef CANVAS_WEBGL_WEBGL_PROGRAM_ATTRIB_H_
#define CANVAS_WEBGL_WEBGL_PROGRAM_ATTRIB_H_

#include <string>

namespace lynx {
namespace canvas {

class WebGLProgramAttrib {
 public:
  WebGLProgramAttrib(const std::string& name, int32_t loc, uint32_t type,
                     uint32_t size)
      : name_(name), type_(type), size_(size) {}
  WebGLProgramAttrib() = default;

 public:
  std::string name_;
  uint32_t type_ = 0;
  uint32_t size_ = 0;
  int32_t location_ = -1;
};

}  // namespace canvas
}  // namespace lynx

#endif  // CANVAS_WEBGL_WEBGL_PROGRAM_ATTRIB_H_
