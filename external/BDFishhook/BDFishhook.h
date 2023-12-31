// Copyright (c) 2013, Facebook, Inc.
// All rights reserved.
// Redistribution and use in source and binary forms, with or without
// modification, are permitted provided that the following conditions are met:
//   * Redistributions of source code must retain the above copyright notice,
//     this list of conditions and the following disclaimer.
//   * Redistributions in binary form must reproduce the above copyright notice,
//     this list of conditions and the following disclaimer in the documentation
//     and/or other materials provided with the distribution.
//   * Neither the name Facebook nor the names of its contributors may be used to
//     endorse or promote products derived from this software without specific
//     prior written permission.
// THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
// AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
// IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
// DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE
// FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
// DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
// SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER
// CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY,
// OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
// OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

#ifndef BDFishhook_h
#define BDFishhook_h

#include <stddef.h>
#include <stdint.h>

#ifndef BDFISHHOOK_EXPORT
#define BDFISHHOOK_EXPORT
#endif //BDFISHHOOK_EXPORT

#if !defined(BDFISHHOOK_EXPORT)
#define BDFISHHOOK_VISIBILITY __attribute__((visibility("hidden")))
#else
#define BDFISHHOOK_VISIBILITY __attribute__((visibility("default")))
#endif

#ifdef __cplusplus
extern "C" {
#endif //__cplusplus

/*
 * A structure representing a particular intended rebinding from a symbol
 * name to its replacement
 */
struct bd_rebinding {
  const char * _Nonnull name;
  void * _Nonnull replacement;
  void * _Nonnull * _Nullable replaced;
};

struct bd_rebinding_fast {
    void * _Nonnull original;
    void * _Nonnull replacement;
    void * _Nonnull * _Nullable replaced;
};

/*
 * For each rebinding in rebindings, rebinds references to external, indirect
 * symbols with the specified name to instead point at replacement for each
 * image in the calling process as well as for all future images that are loaded
 * by the process. If rebind_functions is called more than once, the symbols to
 * rebind are added to the existing list of rebindings, and if a given symbol
 * is rebound more than once, the later rebinding will take precedence.
 */
BDFISHHOOK_VISIBILITY
int bd_rebind_symbols(struct bd_rebinding rebindings[_Nonnull], size_t rebindings_nel);

/*
 * Rebinds as above, but only in the specified image. The header should point
 * to the mach-o header, the slide should be the slide offset. Others as above.
 */
BDFISHHOOK_VISIBILITY
int bd_rebind_symbols_image(void * _Nonnull header,
                         intptr_t slide,
                         struct bd_rebinding rebindings[_Nonnull],
                         size_t rebindings_nel);


BDFISHHOOK_VISIBILITY
int bd_rebind_symbols_patch(struct bd_rebinding rebindings[_Nonnull], size_t rebindings_nel);

BDFISHHOOK_VISIBILITY
int bd_rebind_fast(struct bd_rebinding_fast rebindings[_Nonnull] , size_t rebindings_nel);

BDFISHHOOK_VISIBILITY
int bd_rebind_symbols_image_fast(void * _Nonnull header, intptr_t slide, struct bd_rebinding_fast[_Nonnull], size_t rebindings_nel);

void open_bdfishhook(void);

void close_bdfishhook(void);


/*
 * Async to serial queue in add image callback
 */
void open_bdfishhook_async_add_image_callback(void);

void close_bdfishhook_async_add_image_callback(void);


/*
 * hook patch table in dyld shared cache
 */
void open_bdfishhook_patch(void);

void close_bdfishhook_patch(void);

#ifdef __cplusplus
}
#endif //__cplusplus

#endif //BDFishhook_h
