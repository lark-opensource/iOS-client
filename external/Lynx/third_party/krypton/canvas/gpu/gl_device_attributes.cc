// Copyright 2021 The Lynx Authors. All rights reserved.

#include "gl_device_attributes.h"

#include <regex>
#include <unordered_map>

#include "canvas/base/log.h"
#include "canvas/gpu/gl/gl_api.h"
#include "canvas/gpu/gl_constants.h"
#include "canvas/util/string_utils.h"

namespace lynx {
namespace canvas {

void GLDeviceAttributes::Init() {
  GL::GetIntegerv(KR_GL_MAX_3D_TEXTURE_SIZE, &max_3d_texture_size_);
  GL::GetIntegerv(KR_GL_MAX_TEXTURE_SIZE, &max_texture_size_);
  GL::GetIntegerv(KR_GL_MAX_ARRAY_TEXTURE_LAYERS, &max_array_texture_layers_);
  GL::GetFloatv(KR_GL_ALIASED_LINE_WIDTH_RANGE, aliased_line_width_range_);
  GL::GetFloatv(KR_GL_ALIASED_POINT_SIZE_RANGE, aliased_point_size_range_);
  GL::GetFloatv(KR_GL_DEPTH_RANGE, depth_range_);
  GL::GetIntegerv(KR_GL_MAX_COLOR_ATTACHMENTS, &max_color_attachments_);
  GL::GetIntegerv(KR_GL_MAX_COMBINED_TEXTURE_IMAGE_UNITS,
                  &max_combined_texture_image_units_);
  GL::GetIntegerv(KR_GL_MAX_CUBE_MAP_TEXTURE_SIZE, &max_cube_map_texture_size_);
  GL::GetIntegerv(KR_GL_MAX_FRAGMENT_UNIFORM_VECTORS,
                  &max_fragment_uniform_vectors_);
  GL::GetIntegerv(KR_GL_MAX_TEXTURE_IMAGE_UNITS, &max_texture_image_units_);
  GL::GetIntegerv(KR_GL_MAX_RENDERBUFFER_SIZE, &max_renderbuffer_size_);
  GL::GetIntegerv(KR_GL_MAX_VARYING_VECTORS, &max_varying_vectors_);
  GL::GetIntegerv(KR_GL_MAX_VERTEX_ATTRIBS, &max_vertex_attribs_);
  GL::GetIntegerv(KR_GL_MAX_VERTEX_TEXTURE_IMAGE_UNITS,
                  &max_vertex_texture_image_units_);
  GL::GetIntegerv(KR_GL_MAX_VERTEX_UNIFORM_VECTORS,
                  &max_vertex_uniform_vectors_);
  GL::GetIntegerv(KR_GL_MAX_VIEWPORT_DIMS, max_viewport_size_);
  GL::GetIntegerv(KR_GL_SUBPIXEL_BITS, &subpixel_bits_);
  GL::GetIntegerv(KR_GL_MAX_DRAW_BUFFERS, &max_draw_buffers_);
  max_levels_from_2d_size_ = LevelsFromSize(max_texture_size_);
  max_levels_from_3d_size_ = LevelsFromSize(max_3d_texture_size_);

  int range[2] = {0}, precision = 0;

  GL::GetShaderPrecisionFormat(KR_GL_VERTEX_SHADER, KR_GL_LOW_FLOAT, range,
                               &precision);
  vs_l_f_.range_min = range[0];
  vs_l_f_.range_max = range[1];
  vs_l_f_.precision = precision;
  GL::GetShaderPrecisionFormat(KR_GL_VERTEX_SHADER, KR_GL_MEDIUM_FLOAT, range,
                               &precision);
  vs_m_f_.range_min = range[0];
  vs_m_f_.range_max = range[1];
  vs_m_f_.precision = precision;
  GL::GetShaderPrecisionFormat(KR_GL_VERTEX_SHADER, KR_GL_HIGH_FLOAT, range,
                               &precision);
  vs_h_f_.range_min = range[0];
  vs_h_f_.range_max = range[1];
  vs_h_f_.precision = precision;

  GL::GetShaderPrecisionFormat(KR_GL_VERTEX_SHADER, KR_GL_LOW_INT, range,
                               &precision);
  vs_l_i_.range_min = range[0];
  vs_l_i_.range_max = range[1];
  vs_l_i_.precision = precision;
  GL::GetShaderPrecisionFormat(KR_GL_VERTEX_SHADER, KR_GL_MEDIUM_INT, range,
                               &precision);
  vs_m_i_.range_min = range[0];
  vs_m_i_.range_max = range[1];
  vs_m_i_.precision = precision;
  GL::GetShaderPrecisionFormat(KR_GL_VERTEX_SHADER, KR_GL_HIGH_INT, range,
                               &precision);
  vs_h_i_.range_min = range[0];
  vs_h_i_.range_max = range[1];
  vs_h_i_.precision = precision;

  GL::GetShaderPrecisionFormat(KR_GL_FRAGMENT_SHADER, KR_GL_LOW_FLOAT, range,
                               &precision);
  fs_l_f_.range_min = range[0];
  fs_l_f_.range_max = range[1];
  fs_l_f_.precision = precision;
  GL::GetShaderPrecisionFormat(KR_GL_FRAGMENT_SHADER, KR_GL_MEDIUM_FLOAT, range,
                               &precision);
  fs_m_f_.range_min = range[0];
  fs_m_f_.range_max = range[1];
  fs_m_f_.precision = precision;
  GL::GetShaderPrecisionFormat(KR_GL_FRAGMENT_SHADER, KR_GL_HIGH_FLOAT, range,
                               &precision);
  fs_h_f_.range_min = range[0];
  fs_h_f_.range_max = range[1];
  fs_h_f_.precision = precision;

  GL::GetShaderPrecisionFormat(KR_GL_FRAGMENT_SHADER, KR_GL_LOW_INT, range,
                               &precision);
  fs_l_i_.range_min = range[0];
  fs_l_i_.range_max = range[1];
  fs_l_i_.precision = precision;
  GL::GetShaderPrecisionFormat(KR_GL_FRAGMENT_SHADER, KR_GL_MEDIUM_INT, range,
                               &precision);
  fs_m_i_.range_min = range[0];
  fs_m_i_.range_max = range[1];
  fs_m_i_.precision = precision;
  GL::GetShaderPrecisionFormat(KR_GL_FRAGMENT_SHADER, KR_GL_HIGH_INT, range,
                               &precision);
  fs_h_i_.range_min = range[0];
  fs_h_i_.range_max = range[1];
  fs_h_i_.precision = precision;

  DumpES3Supports(supportd_extensions_);
  DumpExtensionDependsOnDevice(supportd_extensions_);
  HandleGPUWorkaround();
}

bool GLDeviceAttributes::ExtensionEnabled(const char* ext) const {
  return supportd_extensions_.find(ext) != supportd_extensions_.end();
}

int32_t GLDeviceAttributes::LevelsFromSize(int32_t size) {
  int32_t levels = 0;
  while ((size >> levels) > 0) {
    ++levels;
  }
  return levels;
}

void GLDeviceAttributes::DumpES3Supports(std::set<std::string>& voSet) {
  voSet.insert(std::string("ANGLE_instanced_arrays"));
  voSet.insert(std::string("EXT_blend_minmax"));
  voSet.insert(std::string("OES_texture_float"));       // TODO pass testcase
  voSet.insert(std::string("OES_texture_half_float"));  // TODO pass testcase
  voSet.insert(std::string("OES_vertex_array_object"));
  voSet.insert(std::string("WEBGL_depth_texture"));
  voSet.insert(std::string("WEBGL_compressed_texture_etc"));
  voSet.insert(std::string("OES_element_index_uint"));
  voSet.insert(std::string("EXT_sRGB"));
  /// Table 3.13 in OpenGL ES 3.0 defines all legal texture formats, and all
  /// half float texture formats are texture-filterable, indicating that all
  /// half float format textures can be used with linear sampling modes.
  /// However, on iPhone devices, getExtension does not return the
  /// OES_texture_half_float_linear extension, even though ES3 actually supports
  /// this capability by default. Therefore, we should treat this extension
  /// enabled default in WebGL. References:
  /// -
  /// https://registry.khronos.org/OpenGL/extensions/OES/OES_texture_float_linear.txt
  /// - Table 3.13 from https://registry.khronos.org/OpenGL-Refpages/es3.0/
  voSet.insert(std::string("OES_texture_half_float_linear"));
  voSet.insert(std::string("OES_fbo_render_mipmap"));

  // krypton only
  voSet.insert(std::string("EXT_tex_image_3d_KR"));
}

void GLDeviceAttributes::DumpExtensionDependsOnDevice(
    std::set<std::string>& voSet) {
  const unsigned char* _cur = GL::GetString(KR_GL_EXTENSIONS);
  if (!_cur) {
    KRYPTON_LOGE("getExtension return nullptr");
    return;
  }
  std::string actual_extensions = (char*)_cur;
  std::unordered_map<std::string, std::string> ext_gles_to_webgl;
  ext_gles_to_webgl["GL_EXT_texture_filter_anisotropic"] =
      "EXT_texture_filter_anisotropic";
  ext_gles_to_webgl["GL_OES_compressed_ETC1_RGB8_texture"] =
      "WEBGL_compressed_texture_etc1";
  ext_gles_to_webgl["GL_OES_texture_float_linear"] =
      "OES_texture_float_linear";  // TODO pass testcase
  ext_gles_to_webgl["texture_compression_astc"] =
      "WEBGL_compressed_texture_astc";
  ext_gles_to_webgl["GL_EXT_color_buffer_half_float"] =
      "EXT_color_buffer_half_float";
  ext_gles_to_webgl["GL_EXT_color_buffer_float"] = "WEBGL_color_buffer_float";
  ext_gles_to_webgl["GL_EXT_shader_texture_lod"] = "EXT_shader_texture_lod";
#if OS_IOS
  ext_gles_to_webgl["GL_IMG_texture_compression_pvrtc"] =
      "WEBKIT_WEBGL_compressed_texture_pvrtc";
#elif OS_ANDROID
  ext_gles_to_webgl["GL_IMG_texture_compression_pvrtc"] =
      "WEBGL_compressed_texture_pvrtc";
#endif
  ext_gles_to_webgl["GL_EXT_texture_compression_s3tc_srgb"] =
      "WEBGL_compressed_texture_s3tc_srgb";
  ext_gles_to_webgl["GL_EXT_texture_compression_bptc"] =
      "EXT_texture_compression_bptc";
  ext_gles_to_webgl["GL_EXT_texture_compression_rgtc"] =
      "EXT_texture_compression_rgtc";
  ext_gles_to_webgl["GL_OES_standard_derivatives"] = "OES_standard_derivatives";
  ext_gles_to_webgl["GL_EXT_frag_depth"] = "EXT_frag_depth";
  ext_gles_to_webgl["GL_EXT_float_blend"] = "EXT_float_blend";

  for (auto i = ext_gles_to_webgl.begin(); i != ext_gles_to_webgl.end(); i++) {
    if (actual_extensions.find(i->first) != std::string::npos) {
      supportd_extensions_.insert(i->second);
    }
  }

  if (voSet.find("EXT_texture_filter_anisotropic") != voSet.end()) {
    GL::GetIntegerv(GL_MAX_TEXTURE_MAX_ANISOTROPY_EXT,
                    &max_texture_max_anisotropy_);
  }

  if (voSet.find("WEBGL_compressed_texture_astc") != voSet.end()) {
    if (actual_extensions.find("GL_KHR_texture_compression_astc_hdr") !=
        std::string::npos) {
      astc_support_profiles_.push_back("hdr");
    }

    if (actual_extensions.find("GL_KHR_texture_compression_astc_ldr") !=
        std::string::npos) {
      astc_support_profiles_.push_back("ldr");
    }
  }

  // for compressed texture
  GL::GetIntegerv(GL_NUM_COMPRESSED_TEXTURE_FORMATS,
                  &compressed_texture_format_nums_);
  if (compressed_texture_format_nums_ > 0) {
    compressed_texture_format_.resize(compressed_texture_format_nums_);
    GL::GetIntegerv(GL_COMPRESSED_TEXTURE_FORMATS,
                    compressed_texture_format_.data());
  }
}

void GLDeviceAttributes::HandleGPUWorkaround() {
  const GLubyte* vendor = GL::GetString(KR_GL_VENDOR);
  const GLubyte* renderer = GL::GetString(KR_GL_RENDERER);

  KRYPTON_LOGI("HandleGPUWorkaround");

  if (vendor == nullptr || renderer == nullptr) {
    return;
  }

  KRYPTON_LOGI("vendor is \"")
      << vendor << "\" renderer is \"" << renderer << "\"";

  gpu_vendor = reinterpret_cast<const char*>(vendor);
  gpu_renderer = reinterpret_cast<const char*>(renderer);

  gpu_vendor = TrimString(gpu_vendor);
  gpu_renderer = TrimString(gpu_renderer);

  KRYPTON_LOGI("after trim vendor is \"")
      << gpu_vendor << "\""
      << " renderer is \"" << gpu_renderer << "\"";

  auto* gpu_vendor_cstr = gpu_vendor.c_str();
  auto* gpu_renderer_cstr = gpu_renderer.c_str();

  if (std::strcmp(gpu_vendor_cstr, "Imagination Technologies") == 0) {
    if (std::strcmp(gpu_renderer_cstr, "PowerVR Rogue GE8320") == 0 ||
        std::strcmp(gpu_renderer_cstr, "PowerVR Rogue GE8322") == 0) {
      need_workaround_finish_per_frame = true;
      need_workaround_egl_sync_after_resize = true;
      KRYPTON_LOGW(
          "need_workaround_finish_per_frame / "
          "need_workaround_egl_sync_after_resize enabled by vendor ")
          << vendor << " and renderer " << gpu_renderer;
    }
  }
  KRYPTON_LOGI("need_workaround_finish_per_frame ")
      << need_workaround_finish_per_frame
      << " need_workaround_egl_sync_after_resize "
      << need_workaround_egl_sync_after_resize;
}

}  // namespace canvas
}  // namespace lynx
