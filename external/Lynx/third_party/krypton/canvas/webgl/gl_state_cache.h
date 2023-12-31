#ifndef CANVAS_WEBGL_GL_STATE_CACHE_H_
#define CANVAS_WEBGL_GL_STATE_CACHE_H_

#include "canvas/util/js_object_pair.h"
#include "vertex_attrib_values.h"
#include "webgl_framebuffer.h"
#include "webgl_program.h"
#include "webgl_renderbuffer.h"
#include "webgl_vertex_array_object.h"

class WebGLRenderingContext;

namespace lynx {
namespace canvas {
struct GLStateCache {
  void Init(WebGLRenderingContext* context);

  /**
   * GL error
   */
  GLenum current_error_ = KR_GL_NO_ERROR;
  /**
   * webgl render
   */
  std::string render_str_;

  /**
   * webgl sl render
   */
  std::string render_sl_version_;

  /**
   * webgl version
   */
  std::string render_version_;

  /**
   * webgl vendor
   */
  std::string render_vendor_;

  /**
   * The WebGLRenderingContext.activeTexture() method of the WebGL API specifies
   * which texture unit to make active.
   * The texture unit to make active.
   * The value is a gl.TEXTUREI where I is within the range from
   * 0 to gl.MAX_COMBINED_TEXTURE_IMAGE_UNITS - 1
   */
  uint32_t active_texture_ = KR_GL_TEXTURE0;  // U

  uint32_t one_plus_max_non_default_texture_unit_ = 0;

  uint32_t depth_func_ = KR_GL_LESS;

  /**
   * The WebGLRenderingContext.blendColor() method of the WebGL API is
   * used to set the source and destination blending factors.
   */
  float blend_color_[4] = {0, 0, 0, 0};
  /**
   * The WebGLRenderingContext.ClearColor() method of the WebGL API is
   * used to set the color [red, green, blue, alpha]
   */
  float clear_color_[4] = {0, 0, 0, 0};
  float clear_depth_ = 1;

  bool color_write_mask_[4] = {true, true, true, true};

  bool depth_writemask_ = true;

  /**
   * The blend equation determines how a new pixel is
   * combined with a pixel already in the WebGLFramebuffer.
   */
  uint32_t blend_equation_rgb_mode_ = KR_GL_FUNC_ADD;
  uint32_t blend_equation_alpha_mode_ = KR_GL_FUNC_ADD;
  uint32_t blend_func_src_rgb_ = KR_GL_ONE;
  uint32_t blend_func_src_alpha_ = KR_GL_ONE;
  uint32_t blend_func_dst_rgb_ = KR_GL_ZERO;
  uint32_t blend_func_dst_alpha_ = KR_GL_ZERO;

  /**
   * The WebGLRenderingContext.cullFace() method of the WebGL API specifies
   * whether or not front- and/or back-facing polygons can be culled.
   */
  uint32_t cull_face_mode_ = KR_GL_BACK;

  /**
   * The WebGLRenderingContext.readBuffer() method of the WebGL API specifies
   */
  uint32_t read_buffer_mode_ = KR_GL_BACK;

  /**
   * The WebGLRenderingContext.frontFace() method of the WebGL API specifies
   * whether polygons are front- or back-facing by setting a winding
   * orientation.
   */
  uint32_t front_face_ = KR_GL_CCW;

  /**
   * GENERATE_MIPMAP_HINT: Quality of filtering when
   * generating mipmap images with WebGLRenderingContext.generateMipmap().
   */
  uint32_t generate_mipmap_hint_ = KR_GL_DONT_CARE;

  /**
   * GENERATE_MIPMAP_HINT: Quality of filtering when
   * generating mipmap images with WebGLRenderingContext.generateMipmap().
   */
  uint32_t fragment_shader_derivative_hint = KR_GL_DONT_CARE;

  /**
   * The WebGLRenderingContext.scissor() method of the WebGL API sets a scissor
   * box, which limits the drawing to a specified rectangle.
   */
  int scissor_[4] = {0, 0, -1, -1};

  /**
   * The WebGLRenderingContext.enable() method of the
   * WebGL API enables specific WebGL capabilities for this context.
   */
  bool enable_blend_ = false;
  bool enable_cull_face_ = false;
  bool enable_depth_test_ = false;
  bool enable_dither_ = true;
  bool enable_polygon_offset_fill_ = false;
  bool enable_sample_alpha_to_coverage_ = false;
  bool enable_coverage_ = false;
  bool enable_scissor_test_ = false;
  bool enable_stencil_test_ = false;
  bool enable_rasterizer_discard = false;

  /**
   * The WebGLRenderingContext.sampleCoverage() method of the WebGL
   * API specifies multi-sample coverage parameters for anti-aliasing effects.
   */
  float sample_coverage_value_ = 1.0f;
  bool sample_coverage_invert_ = false;

  /**
   * The WebGLRenderingContext.lineWidth()
   * method of the WebGL API sets the line width of rasterized lines.
   */
  float line_width_ = 1.0f;

  /**
   * The WebGLRenderingContext.polygonOffset() method of the
   * WebGL API specifies the scale factors and units to calculate depth values.
   *
   * The offset is added before the depth test is
   * performed and before the value is written into the depth buffer.
   */
  float polygon_offset_factor_ = 0, polygon_offset_units_ = 0;

  int32_t clear_stencil_ = 0;

  /**
   * The WebGLRenderingContext.stencilFunc() method of the
   * WebGL API sets the front and back function and reference value for stencil
   * testing.
   *
   * Stencilling enables and disables drawing on a per-pixel basis.
   * It is typically used in multipass rendering to achieve special effects.
   */
  uint32_t front_face_stencil_func_ = KR_GL_ALWAYS;
  int front_face_stencil_func_ref_ = 0;
  uint32_t front_face_stencil_func_mask_ = 0xFFFFFFFF;
  uint32_t back_face_stencil_func_ = KR_GL_ALWAYS;
  int back_face_stencil_func_ref_ = 0;
  uint32_t back_face_stencil_func_mask_ = 0xFFFFFFFF;

  /**
   * The WebGLRenderingContext.stencilOp() method of the
   * WebGL API sets both the front and back-facing stencil test actions.
   */
  uint32_t front_stencil_op_fail_ = KR_GL_KEEP;
  uint32_t front_stencil_op_z_fail_ = KR_GL_KEEP;
  uint32_t front_stencil_op_z_pass_ = KR_GL_KEEP;
  uint32_t back_stencil_op_fail_ = KR_GL_KEEP;
  uint32_t back_stencil_op_z_fail_ = KR_GL_KEEP;
  uint32_t back_stencil_op_z_pass_ = KR_GL_KEEP;

  /**
   * The WebGLRenderingContext.stencilMaskSeparate()
   */
  uint32_t stencil_front_mask_ = 0xFFFFFFFF;
  uint32_t stencil_back_mask_ = 0xFFFFFFFF;

  /**
   * The WebGLRenderingContext.pixelStorei()
   * method of the WebGL API specifies the pixel storage modes.
   */
  uint32_t pack_alignment_ = 4, unpack_alignment_ = 4;  // 1,2,4,8
  uint32_t unpack_colorspace_conversion_webgl_ = KR_GL_BROWSER_DEFAULT_WEBGL;
  bool unpack_premul_alpha_webgl_ = false;
  bool unpack_filp_y_webgl_ = false;
  // webgl2.0
  uint32_t pack_row_length_ = 0, unpack_row_length_ = 0;
  uint32_t pack_skip_pixels_ = 0, unpack_skip_pixels_ = 0;
  uint32_t pack_skip_rows_ = 0, unpack_skip_rows_ = 0;
  uint32_t unpack_skip_images_ = 0, unpack_image_height_ = 0;

  /**
   * The WebGLRenderingContext.viewport() method of the WebGL API sets the
   * viewport, which specifies the affine transformation of x and y from
   * normalized device coordinates to window coordinates.
   */
  // https://source.chromium.org/chromium/chromium/src/+/main:gpu/command_buffer/client/client_context_state.h;l=36;drc=0ec17e4452120719f6bf5f86f50c781123ee8f5d;bpv=1;bpt=1
  // initial value is {0, 0, 0, 0}
  int viewport_[4] = {0, 0, 0, 0};

  /**
   * The WebGLRenderingContext.bindBuffer() method of the WebGL API binds a
   * given WebGLBuffer to a target. must have the same life cycle
   */
  JsObjectPair<WebGLBuffer> array_buffer_bind_;
  WebGLVertexArrayObjectOES* default_vertex_array_object_{nullptr};
  JsObjectPair<WebGLVertexArrayObjectOES>
      bound_vertex_array_object_;  // need to be replaced by pair to support
                                   // webgl2, but..
  std::vector<VertexAttribValues> vertex_attrib_values_;

  WebGLVertexArrayObjectOES* ValidVertexArrayObject() const {
    return bound_vertex_array_object_ ? bound_vertex_array_object_.native_obj()
                                      : default_vertex_array_object_;
  }

  JsObjectPair<WebGLBuffer> copy_read_buffer_bind_;
  JsObjectPair<WebGLBuffer> copy_write_buffer_bind_;
  JsObjectPair<WebGLBuffer> pixel_pack_buffer_bind_;
  JsObjectPair<WebGLBuffer> pixel_unpack_buffer_bind_;
  //  /* uniform block buffer */
  JsObjectPair<WebGLBuffer> ub_buffer_bind_;
  JsObjectPair<WebGLBuffer> tf_buffer_bind_;

  /**
   * The WebGLRenderingContext.bindFramebuffer() method of the WebGL API
   * binds a given WebGLFramebuffer to a target.
   * must have the same life cycle
   */
  JsObjectPair<WebGLFramebuffer> read_framebuffer_bind_;
  JsObjectPair<WebGLFramebuffer> draw_framebuffer_bind_;

  /**
   * The WebGLRenderingContext.bindRenderbuffer() method of the WebGL API
   * binds a given WebGLRenderbuffer to a target, which must be gl.RENDERBUFFER.
   * must have the same life cycle
   */
  JsObjectPair<WebGLRenderbuffer> renderbuffer_bind_;

  /**
   * The WebGLRenderingContext.bindTexture() method of the WebGL API
   * binds a given WebGLTexture to a target (binding point).
   * must have the same life cycle
   * magic number: 16 == max_vertex_texture_image_units_
   */
  std::vector<JsObjectPair<WebGLTexture>> texture_2d_bind_;
  std::vector<JsObjectPair<WebGLTexture>> texture_cube_bind_;
  // ES3.0
  std::vector<JsObjectPair<WebGLTexture>> texture_3d_bind_;
  std::vector<JsObjectPair<WebGLTexture>> texture_2d_array_bind_;

  /**
   * The WebGLRenderingContext2.bindSampler() method of the WebGL API
   * binds a given WebGLSampler to a unit (binding point).
   * must have the same life cycle
   */
  // ES3.0
  //  Napi::ObjectReference sampler_bind_[32];
  //  webgl_sampler_napi* inner_sampler_bind_[32] = {nullptr};
  //  webgl_object<webgl_sampler_napi> bound_sampler_bind_[32];
  /**
   * The WebGLRenderingContext.useProgram() method of the WebGL API
   * sets the specified WebGLProgram as part of the current rendering state.
   * must have the same life cycle
   */
  JsObjectPair<WebGLProgram> current_program_;

  //  // ES3.0
  std::vector<int32_t> vertex_attrib_divisors_;
};

}  // namespace canvas
}  // namespace lynx

#endif  // CANVAS_WEBGL_GL_STATE_CACHE_H_
