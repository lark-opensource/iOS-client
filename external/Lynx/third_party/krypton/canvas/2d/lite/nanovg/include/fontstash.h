//
// Copyright (c) 2009-2013 Mikko Mononen memon@inside.org
//
// This software is provided 'as-is', without any express or implied
// warranty.  In no event will the authors be held liable for any damages
// arising from the use of this software.
// Permission is granted to anyone to use this software for any purpose,
// including commercial applications, and to alter it and redistribute it
// freely, subject to the following restrictions:
// 1. The origin of this software must not be misrepresented; you must not
//    claim that you wrote the original software. If you use this software
//    in a product, an acknowledgment in the product documentation would be
//    appreciated but is not required.
// 2. Altered source versions must be plainly marked as such, and must not be
//    misrepresented as being the original software.
// 3. This notice may not be removed or altered from any source distribution.
//

#ifndef CANVAS_2D_LITE_NANOVG_INCLUDE_FONTSTASH_H_
#define CANVAS_2D_LITE_NANOVG_INCLUDE_FONTSTASH_H_

#if defined(__APPLE__)
#include <TargetConditionals.h>
#if TARGET_OS_MAC
    // for mac debug, we expect to select both freetype or coretext
      // #define FONS_USE_FREETYPE
#endif
#else
#define FONS_USE_FREETYPE
#endif

#if defined(FONS_USE_FREETYPE)
#include <ft2build.h>
#include FT_FREETYPE_H
#else
#include<CoreText/CTFont.h>
#include<CoreGraphics/CoreGraphics.h>
#endif
#include <map>
#include <vector>
#include <string>

namespace lynx {
namespace nanovg {

#define FONS_HASH_LUT_SIZE 64
#define FONS_MAX_FALLBACKS 4
#define FONS_INIT_GLYPHS 256

#define FONS_INIT_FONTS 4
#define FONS_INIT_ATLAS_NODES 256
#define FONS_VERTEX_COUNT 1024

#define FONS_INVALID -1
#define TYPEFACE_INVALID -1
#define DATA_SIZE_PRELOADED -1

// Complex layout switch, not enabled by default
// To support minor Indian languages, Arabic, etc., please set the following macros to 1 and recompile (additional libraries and code logic will be introduced)
#define FONS_SUPPORT_COMPLEX_LAYOUT 1

// Preferred language
enum FONSLangPrefer {
  FONS_LANGPREFER_DEFAULT = 0, // By default, Simplified Chinese is preferentially supported, and extended support for CJK, Latin, small languages, etc.
  FONS_LANGPREFER_LATIN,  // Latin is the first choice, and CJK supports it with lower priority (for example, when Latin fonts are not found, they will be searched from CJK fonts, etc.)
  FONS_LANGPREFER_TC, // Priority support for traditional Chinese, extended support for CJK, Latin, small languages, etc.
  FONS_LANGPREFER_JP, // Priority support for Japanese, extended support for CJK, Latin, minor languages, etc.
};
// ! ! ! ! Configure your preferred language here! ! !
static FONSLangPrefer FONS_LANGUAGE_PREFER = FONS_LANGPREFER_DEFAULT;

// List of languages ​​requiring additional support
enum FONSLanguages {
  FONS_LANG_ZERO = 0,  // ! ! ! ! Default 0! ! ! !
  FONS_LANG_BASIC = 1, // Basic Latin extensions, Unicode extensions, etc., supported by default
  FONS_LANG_SYMBOL = 2, // Various symbols, supported by default

  // --- Additional languages should be added below ---
  FONS_LANG_KOREAN,
  FONS_LANG_JAPANESE,
  FONS_LANG_DEVANAGARI, // Indian, Hindi, Haryana, Rajasthani, Bhojpuri etc.
  FONS_LANG_BENGALI, // Bangladesh, India
  FONS_LANG_GUJARATI, // India
  FONS_LANG_ORIYA, // India
  FONS_LANG_TAMIL, // India
  FONS_LANG_TELUGU, // India
  FONS_LANG_KANNADA, // India
  FONS_LANG_MALAYALAM, // India
  FONS_LANG_GURMUKHI, // Punjabi, India
  FONS_LANG_THAI,
  FONS_LANG_LAOS,
  FONS_LANG_TAGALOG, // Philippines, etc.
  FONS_LANG_KHMER, // Cambodia
  FONS_LANG_HEBREW, // Not currently supported
  FONS_LANG_ARABIC, // Not currently supported
  FONS_LANG_MYANMAR,

  // --- Additional languages should be added above ---
  FONS_LANG_COUNT,  // ! ! ! ! The total number must be at the end! ! ! !
};

enum FONSflags {
  FONS_ZERO_TOPLEFT = 1,
  FONS_ZERO_BOTTOMLEFT = 2,
};

enum FONSalign {
  // Horizontal align
  FONS_ALIGN_LEFT = 1 << 0,    // Default
  FONS_ALIGN_CENTER = 1 << 1,
  FONS_ALIGN_RIGHT = 1 << 2,
  // Vertical align
  FONS_ALIGN_TOP = 1 << 3,
  FONS_ALIGN_MIDDLE = 1 << 4,
  FONS_ALIGN_BOTTOM = 1 << 5,
  FONS_ALIGN_BASELINE = 1 << 6, // Default
};

enum FONSglyphBitmap {
  FONS_GLYPH_BITMAP_OPTIONAL = 1,
  FONS_GLYPH_BITMAP_REQUIRED = 2,
  FONS_GLYPH_BITMAP_STROKE = 4,
};

enum FONSerrorCode {
  // Font atlas is full.
  FONS_ATLAS_FULL = 1,
  // Scratch memory used to render glyphs is full, requested size reported in 'val', you may need to bump up FONS_SCRATCH_BUF_SIZE.
  FONS_SCRATCH_FULL = 2,
  // Calls to fonsPushState has created too large stack, if you need deep state stack bump up FONS_MAX_STATES.
  FONS_STATES_OVERFLOW = 3,
  // Trying to pop too many states fonsPopState().
  FONS_STATES_UNDERFLOW = 4,
};

union FONSerrorParam {
  uint64_t raw = 0;
  struct Atlas { bool isTrueColor; int minWidthHeight; } atlas;
};
typedef void(*FONSerrCallbackFunc)(void *uptr, FONSerrorCode error, const FONSerrorParam &errParam);

#define FONS_TEX_WIDTH 512
#define FONS_TEX_HEIGHT 512
#define FONS_MAX_RENDER_GLYPH_SIZE 240

#define FONS_NOTEXT_COUNTDOWN 1500 // if no text rendered, count down to end, then shrink the text buffer
#define FONS_FORCEFLUSH_COUNTDOWN 2
#define FONS_MIN_TEX_RATIO 2 // do not change it
#define FONS_MAX_TEX_RATIO 16 // larger if we need more text texture caches (w=r/2 * FONS_TEX_WIDTH, h=(r-r/2)*FONS_TEX_HEIGHT)

// font weight,style and variant packaged
enum FONSWSV {
  FONS_WSV_NORMAL = 0,
  FONS_WEIGHT_BOLD,
  FONS_WEIGHT_BOLDER,
  FONS_WEIGHT_LIGHTER,
  FONS_WEIGHT_100,
  FONS_WEIGHT_200,
  FONS_WEIGHT_300,
  FONS_WEIGHT_400,
  FONS_WEIGHT_500,
  FONS_WEIGHT_600,
  FONS_WEIGHT_700,
  FONS_WEIGHT_800,
  FONS_WEIGHT_900,
  // style << 4
  FONS_STYLE_ITALIC = 16,
  FONS_STYLE_OBLIQUE = 32,
  // variant << 6
  FONS_VARIANT_SMALL_CAPS = 64,
};

typedef struct FONSquad {
  float x0, y0, s0, t0;
  float x1, y1, s1, t1;
} FONSquad;

struct FONSstate {
  int font;
  int align;
  float size;
  unsigned int color;
  float blur;
  float spacing;
  float strokeWidth;
  int lineJoin;
  int lineCap;
  unsigned short fontWSV;
};

typedef struct FONStextIter {
  FONSstate state;
  float x, y, nextx, nexty, spacing;
  unsigned int codepoint, utf8state;
  short isize, iblur;
  struct FONSfont *font;
  int prevGlyphIndex;
  const char *str, *cur, *end;
  FONSglyphBitmap bitmapOption;
  bool isTrueColor;
} FONStextIter;

typedef struct FONScontext FONScontext;

#if defined(FONS_USE_FREETYPE)
using FONSttFontImpl = FT_Face;
#else
using FONSttFontImpl = CGFontRef;
#endif

void fonsSetErrorCallback(FONScontext &s, FONSerrCallbackFunc callback, void *uptr);
int fonsResetAtlas(FONScontext &stash, bool enlarge, int minWH = 0); // Resets the whole stash.
int fonsResetAtlasTrueColor(FONScontext &stash, bool enlarge, int minWH = 0);
int fonsResetAllAtlasToDefault(FONScontext &stash);

enum FonsAddFontOpts {
  FONS_ADDFONT_NO_COMPLEX_LAYOUT = 0x01,
  FONS_ADDFONT_IS_SERIF = 0x02,
};
int fonsAddFont(FONScontext &s, const char *name, const char *path, int options = 0);
int fonsAddFontMem(FONScontext &s,
                   const char *name,
                   unsigned char *data,
                   int ndata,
                   int freeData,
                   int options = 0);
int fonsGetFontByName(FONScontext &s, const char *name);
int fonsFindOrAutoLoadSystemFontByName(FONScontext &s, const char *name);
int fonsAddFallbackFont(FONScontext &stash, int base, int fallback, bool deepCopy = false);
float fonsTextBounds(FONScontext &s,
                     const FONSstate &state,
                     float x,
                     float y,
                     const char *string,
                     const char *end,
                     float *bounds,
                     int* pMissingGlyphCount);
void fonsLineBounds(FONScontext &s, const FONSstate &state, float y, float *miny, float *maxy);

int fonsTextIterInit(FONScontext &stash,
                     const FONSstate &state,
                     FONStextIter *iter,
                     float x,
                     float y,
                     const char *str,
                     const char *end,
                     int bitmapOption);
int fonsTextIterNext(FONScontext &stash, FONStextIter *iter, struct FONSquad *quad);

void fonsFontRawMatricsInfo(FONScontext &stash,
                            const FONSstate &state,
                            int *rawAscender,
                            int *rawDescender,
                            int *unitPerEM);
struct FonsGlyphItem {
  int glyph;
  float x, y, adv;
  FonsGlyphItem(int g = 0) {
      glyph = g;
      x = y = adv = 0;
  }
};

struct GlyphContext {
  FONSglyphBitmap bitmapOption;
  bool isTrueColor = false;
  FONSfont *font;
  short isize;
  int codepoint, curLen;
  const char *cur, *end;
  int x, y, w, h, pad;
  float advance, ratio;
  FONSLanguages lang;
#if !defined(FONS_USE_FREETYPE)
  CTFontRef fontRef = NULL;
  inline ~GlyphContext() {
      if (fontRef) CFRelease(fontRef);
  }
#endif
};

template<typename T, int initial_capacity>
struct Pool {
  T *ptr = NULL;
  int length = 0;

  inline T &operator[](int index) {
      return ptr[index];
  }

  inline T &alloc() {
      if (length == size) {
          size = size ? size << 1 : initial_capacity;
          ptr = (T *) realloc(ptr, sizeof(T) * size);
          if (ptr == NULL) {
              size = 0;
          }
      }
      return ptr[length++];
  }

  inline ~Pool() {
      if (ptr) {
          for (int i = 0; i < length; i++) ptr[i].~T();
          free(ptr);
      }
  }

 private:
  int size = 0;
};

struct FONSfallbackglyph {
  unsigned int codepoint;
  unsigned int fallbackIndex;
  int next;

  FONSfallbackglyph() {
      codepoint = fallbackIndex = 0;
      next = 0;
  }
};

struct FONSglyph {
  unsigned int codepoint;
  int index;
  int next;
  short size, blur;
  FONSglyphBitmap bitmapOption;
  short x0, y0, x1, y1;
  short xadv, xoff, yoff, xend, yend;
  unsigned short fixedStrokeWidth;
  int lineCap;
  int lineJoin;
  bool isTrueColor;
  unsigned short fontWSV;
};

template<typename T, int initial_capacity>
struct FONSGlyphCache {
  Pool<T, initial_capacity> glyphs;
  int16_t lut[FONS_HASH_LUT_SIZE];

  T *insertNewGlyph(int h) {
      T &glyph = glyphs.alloc();
      if (glyphs.ptr == NULL) return NULL;

      glyph.next = lut[h];
      lut[h] = glyphs.length - 1;
      return &glyph;
  }

  void clear() {
      glyphs.length = 0;
      memset(lut, -1, sizeof(lut));
  }

  FONSGlyphCache() {
      clear();
  }
};

enum FONSfontFlag {
  FONT_TRUE_COLOR = (1 << 0),
  FONT_BITMAP_ONLY = (1 << 1),
  FONT_NONE_UNICODE = (1 << 2),
  FONT_SERIF = (1 << 3),
  FONT_SUPPORT_COMPLEX_LAYOUT = (1 << 4),
  FONT_TO_RELEASE_IMP = (1 << 5),
};

struct FONSfont {
  FONSttFontImpl font;
  int flags; // or FONSfontFlag
  char name[64];
  unsigned char *data = NULL;
  int dataSize;
  unsigned char freeData = 0;
  float ascender, descender, lineh;
  FONSGlyphCache<FONSglyph, FONS_INIT_GLYPHS> glyphCache;
  FONSGlyphCache<FONSfallbackglyph, 4> fallbackCache;
  int fallbacks[FONS_MAX_FALLBACKS];
  int nfallbacks;
  int rawAscender, rawDescender, unitPerEM;

  inline ~FONSfont() {
      if (freeData) free(data);
      if (hasFlag(FONT_TO_RELEASE_IMP)) {
#ifndef FONS_USE_FREETYPE
          CGFontRelease(font);
#endif
      }
  }
  inline bool hasFlag(int val) const { return (flags & val) != 0; }
  inline void setFlag(int val) { flags |= val; }
};

struct FonsSysLoadResult {
  FONSttFontImpl sans = NULL, sansBak = NULL, serif = NULL, serifBak = NULL, monospace = NULL,
      emoji = NULL, language = NULL, symbol = NULL;
  struct LangImps { FONSttFontImpl sans = nullptr, serif = nullptr; };
  std::map<FONSLanguages, LangImps> mapLang;
  bool autoLoad();
  struct LangImps autoLoadForLanguage(FONSLanguages lang);
  FONSttFontImpl autoLoadWithName(const char *name);
};

extern bool fons__tt_loadFont(FONScontext &context,
                              FONSfont *font,
                              unsigned char *data,
                              int dataSize);

extern void fons__tt_getFontVMetrics(FONSttFontImpl font,
                                     int *ascent,
                                     int *descent,
                                     int *lineGap,
                                     int *unitPerEM);

extern int fons__tt_getGlyphIndex(FONSfont *font, int codepoint);

extern bool fons__tt_getGlyphBounds(const FONSstate &state,
                                    FONSttFontImpl font,
                                    int glyph,
                                    GlyphContext &ctx);

extern bool fons__tt_buildGlyphBitmap(const FONSstate &state,
                                      FONSttFontImpl font,
                                      int glyph,
                                      uint8_t *output,
                                      size_t outStride,
                                      const GlyphContext &ctx);
extern bool fons__tt_buildBitmapForGlyphs(const FONSstate &state,
                                          FONSttFontImpl font,
                                          const FonsGlyphItem *glyphs,
                                          int count,
                                          uint8_t *output,
                                          size_t stride,
                                          const GlyphContext &ctx);

extern int fons__tt_getGlyphKernAdvance(FONSttFontImpl font, int glyph1, int glyph2);

inline int fons__weightFromWsv(unsigned int fontWSV) {
  static const short stepArr[] = {0, 7, 9, 2, 1, 2, 3, 0, 5, 6, 7, 8, 9, 0, 0, 0};
  return stepArr[fontWSV & 0x0F];
}
} // namespace nanovg
} // namespace lynx

#endif  // CANVAS_2D_LITE_NANOVG_INCLUDE_FONTSTASH_H_
