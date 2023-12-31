// Copyright 2021 The Lynx Authors. All rights reserved.

#ifndef CANVAS_GPU_GL_DEVICE_ATTRIBUTES_H_
#define CANVAS_GPU_GL_DEVICE_ATTRIBUTES_H_

#include <set>
#include <string>
#include <vector>

namespace lynx {
namespace canvas {
class GLDeviceAttributes final {
 public:
  int32_t max_texture_size_ = -1;
  int32_t max_levels_from_2d_size_ = -1;
  int32_t max_3d_texture_size_;
  int32_t max_levels_from_3d_size_ = -1;
  int32_t max_array_texture_layers_;
  float aliased_line_width_range_[2] = {-1.f, -1.f};
  float aliased_point_size_range_[2] = {-1.f, -1.f};
  float depth_range_[2] = {-1.f, -1.f};
  int32_t max_color_attachments_;
  int32_t max_combined_texture_image_units_ = -1;
  int32_t max_cube_map_texture_size_ = -1;
  int32_t max_fragment_uniform_vectors_ = -1;
  int32_t max_renderbuffer_size_ = -1;
  int32_t max_texture_image_units_ = -1;
  int32_t max_varying_vectors_ = -1;
  int32_t max_vertex_attribs_ = -1;
  int32_t max_vertex_texture_image_units_ = -1;
  int32_t max_vertex_uniform_vectors_ = -1;
  int32_t max_viewport_size_[2] = {(int32_t)-1, (int32_t)-1};
  int32_t subpixel_bits_ = -1;
  int32_t max_draw_buffers_ = -1;
  struct ShaderPrecision {
    int range_min, range_max, precision;
  };
  ShaderPrecision vs_l_f_, vs_m_f_, vs_h_f_;
  ShaderPrecision vs_l_i_, vs_m_i_, vs_h_i_;
  ShaderPrecision fs_l_f_, fs_m_f_, fs_h_f_;
  ShaderPrecision fs_l_i_, fs_m_i_, fs_h_i_;

  std::string gpu_vendor;
  std::string gpu_renderer;
  bool need_workaround_finish_per_frame = false;
  bool need_workaround_egl_sync_after_resize = false;

  std::set<std::string> supportd_extensions_;

  /// extension
  int32_t max_texture_max_anisotropy_ = 1;  /// EXT_texture_filter_anisotropic
  std::vector<std::string>
      astc_support_profiles_;  /// WEBGL_compressed_texture_astc

  // compressed texture format
  int32_t compressed_texture_format_nums_ = 0;
  std::vector<int32_t> compressed_texture_format_;

 public:
  void Init();

  bool ExtensionEnabled(const char* ext) const;

 private:
  int32_t LevelsFromSize(int32_t size);
  void DumpES3Supports(std::set<std::string>& voSet);
  void DumpExtensionDependsOnDevice(std::set<std::string>& voSet);
  void HandleGPUWorkaround();
};

}  // namespace canvas
}  // namespace lynx

#endif  // CANVAS_GPU_GL_DEVICE_ATTRIBUTES_H_
