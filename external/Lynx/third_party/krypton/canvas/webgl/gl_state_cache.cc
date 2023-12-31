// Copyright 2022 The Lynx Authors. All rights reserved.

#include "gl_state_cache.h"

#include "webgl_rendering_context.h"

namespace lynx {
namespace canvas {
void GLStateCache::Init(WebGLRenderingContext* context) {
  vertex_attrib_values_.resize(context->MaxVertexAttribs());

  unsigned max_combined_texture_image_units =
      context->MaxCombinedTextureImageUnits();
  texture_2d_bind_.resize(max_combined_texture_image_units);
  texture_cube_bind_.resize(max_combined_texture_image_units);
  texture_3d_bind_.resize(max_combined_texture_image_units);
  texture_2d_array_bind_.resize(max_combined_texture_image_units);
}
}  // namespace canvas
}  // namespace lynx
