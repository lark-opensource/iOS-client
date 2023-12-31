// Copyright 2021 The Lynx Authors. All rights reserved.

#include "scoped_gl_reset_restore.h"

#include "canvas/base/log.h"

namespace lynx {
namespace canvas {
ScopedGLResetRestore::ScopedGLResetRestore(GLenum target) {
  switch (target) {
    case GL_FRAMEBUFFER_BINDING: {
      GLint rfb, dfb;
      GL::GetIntegerv(GL_READ_FRAMEBUFFER_BINDING, &rfb);
      GL::GetIntegerv(GL_DRAW_FRAMEBUFFER_BINDING, &dfb);
      reset_fn_ = [rfb, dfb] {
        GL::BindFramebuffer(GL_READ_FRAMEBUFFER, rfb);
        GL::BindFramebuffer(GL_DRAW_FRAMEBUFFER, dfb);
      };
      break;
    }
    case GL_READ_FRAMEBUFFER_BINDING: {
      GLint fb;
      GL::GetIntegerv(GL_READ_FRAMEBUFFER_BINDING, &fb);
      reset_fn_ = [fb] { GL::BindFramebuffer(GL_READ_FRAMEBUFFER, fb); };
      break;
    }
    case GL_RENDERBUFFER_BINDING: {
      GLint rb;
      GL::GetIntegerv(GL_RENDERBUFFER_BINDING, &rb);
      reset_fn_ = [rb] { GL::BindRenderbuffer(GL_RENDERBUFFER, rb); };
      break;
    }
#ifdef ANDROID
    case GL_TEXTURE_BINDING_EXTERNAL_OES: {
      GLint tex;
      GL::GetIntegerv(GL_TEXTURE_BINDING_EXTERNAL_OES, &tex);
      reset_fn_ = [tex] { GL::BindTexture(GL_TEXTURE_EXTERNAL_OES, tex); };
      break;
    }
#endif
    case GL_TEXTURE_BINDING_2D: {
      GLint tex;
      GL::GetIntegerv(GL_TEXTURE_BINDING_2D, &tex);
      reset_fn_ = [tex] { GL::BindTexture(GL_TEXTURE_2D, tex); };
      break;
    }
    case GL_CURRENT_PROGRAM: {
      GLint p;
      GL::GetIntegerv(GL_CURRENT_PROGRAM, &p);
      reset_fn_ = [p] {
        // TODO(luchengxuan) workaround, need handle this situation by refcount
        if (p == GL_NONE) {
          GL::UseProgram(GL_NONE);
        } else {
          if (GL::IsProgram(p)) {
            GLint linked;
            GL::GetProgramiv(p, GL_LINK_STATUS, &linked);
            if (linked == GL_TRUE) {
              GL::UseProgram(p);
            } else {
              // maybe shader is detached
              GL::UseProgram(GL_NONE);
              KRYPTON_LOGW("ScopedGLState restore but program is not linked.");
            }
          } else {
            GL::UseProgram(GL_NONE);
            KRYPTON_LOGW(
                "ScopedGLState restore but stored program is invalid.");
          }
        }
      };
      break;
    }
    case GL_VERTEX_ARRAY_BINDING: {
      GLint vao;
      GL::GetIntegerv(GL_VERTEX_ARRAY_BINDING, &vao);
      reset_fn_ = [vao] { GL::BindVertexArray(vao); };
      break;
    }
    case GL_ARRAY_BUFFER_BINDING: {
      GLint vbo;
      GL::GetIntegerv(GL_ARRAY_BUFFER_BINDING, &vbo);
      reset_fn_ = [vbo] { GL::BindBuffer(GL_ARRAY_BUFFER, vbo); };
      break;
    }
    case GL_ELEMENT_ARRAY_BUFFER_BINDING: {
      GLint ebo;
      GL::GetIntegerv(GL_ELEMENT_ARRAY_BUFFER_BINDING, &ebo);
      reset_fn_ = [ebo] { GL::BindBuffer(GL_ELEMENT_ARRAY_BUFFER, ebo); };
      break;
    }
    case GL_ACTIVE_TEXTURE: {
      GLint tex;
      GL::GetIntegerv(GL_ACTIVE_TEXTURE, &tex);
      reset_fn_ = [tex] { GL::ActiveTexture(tex); };
      break;
    }
    case GL_VIEWPORT: {
      GLint viewport[4];
      GL::GetIntegerv(GL_VIEWPORT, viewport);
      reset_fn_ = [viewport] {
        GL::Viewport(viewport[0], viewport[1], viewport[2], viewport[3]);
      };
      break;
    }
    case GL_COLOR_CLEAR_VALUE: {
      GLfloat clear_color[4];
      GL::GetFloatv(GL_COLOR_CLEAR_VALUE, clear_color);
      reset_fn_ = [clear_color] {
        GL::ClearColor(clear_color[0], clear_color[1], clear_color[2],
                       clear_color[3]);
      };
      break;
    }
    case GL_STENCIL_CLEAR_VALUE: {
      GLint stencil;
      GL::GetIntegerv(GL_STENCIL_CLEAR_VALUE, &stencil);
      reset_fn_ = [stencil]() { GL::ClearStencil(stencil); };
      break;
    }
    case GL_DEPTH_CLEAR_VALUE: {
      GLclampf depth;
      GL::GetFloatv(GL_DEPTH_CLEAR_VALUE, &depth);
      reset_fn_ = [depth]() { GL::ClearDepthf(depth); };
      break;
    }
    case GL_DEPTH_WRITEMASK: {
      GLboolean mask;
      GL::GetBooleanv(GL_DEPTH_WRITEMASK, &mask);
      reset_fn_ = [mask]() { GL::DepthMask(mask); };
      break;
    }
    case GL_COLOR_WRITEMASK: {
      GLboolean mask[4];
      GL::GetBooleanv(GL_COLOR_WRITEMASK, mask);
      reset_fn_ = [mask]() {
        GL::ColorMask(mask[0], mask[1], mask[2], mask[3]);
      };
      break;
    }
    case GL_STENCIL_WRITEMASK: {
      GLint stencil_mask;
      GL::GetIntegerv(GL_STENCIL_WRITEMASK, &stencil_mask);
      reset_fn_ = [stencil_mask]() { GL::StencilMask(stencil_mask); };
      break;
    }
    case GL_BLEND:
    case GL_CULL_FACE:
    case GL_SCISSOR_TEST:
    case GL_STENCIL_TEST:
    case GL_DEPTH_TEST: {
      GLint enabled;
      GL::GetIntegerv(target, &enabled);
      reset_fn_ = [target, enabled] {
        if (enabled) {
          GL::Enable(target);
        } else {
          GL::Disable(target);
        }
      };
      break;
    }
    default:
      // do No thing
      abort();
      break;
  }
}

ScopedGLResetRestore::~ScopedGLResetRestore() { reset_fn_(); }
}  // namespace canvas
}  // namespace lynx
