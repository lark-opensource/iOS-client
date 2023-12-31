//  Copyright 2022 The Lynx Authors. All rights reserved.

#ifndef KRYPTON_EFFECT_HOOKS_H_
#define KRYPTON_EFFECT_HOOKS_H_

#include "canvas/gpu/gl_context.h"

namespace lynx {
namespace canvas {
namespace effect {

GLContext** ThreadLocalAmazingContextPtr();

void MakeSureAmazingContextCreated();

// amazing hooks start
bool URLTranslate(const char* url, char* path, int* size, void* ctx);

void GLStateSave(void* ctx);

void GLStateRestore(void* ctx);

unsigned int GetTextureFunc(void* ctx, void* napi_js_texture);

void BeforeUpdateFunc(void* ctx, const unsigned int* input_texs,
                      unsigned long input_texs_len, unsigned int output_tex);

void AfterUpdateFunc(void* ctx, const unsigned int* input_texs,
                     unsigned long input_texs_len, unsigned int output_tex);

}  // namespace effect
}  // namespace canvas
}  // namespace lynx

#endif /* KRYPTON_EFFECT_HOOKS_H_ */
