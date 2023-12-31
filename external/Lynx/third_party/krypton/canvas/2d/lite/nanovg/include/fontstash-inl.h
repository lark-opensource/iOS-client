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

#ifndef CANVAS_2D_LITE_NANOVG_INCLUDE_FONTSTASH_INL_H_
#define CANVAS_2D_LITE_NANOVG_INCLUDE_FONTSTASH_INL_H_

#include "fontstash.h"

namespace lynx {
namespace nanovg {
static unsigned int fons__hashint(unsigned int a) {
    a += ~(a << 15);
    a ^= (a >> 10);
    a += (a << 3);
    a ^= (a >> 6);
    a += ~(a << 11);
    a ^= (a >> 16);
    return a;
}

static int fons__mini(int a, int b) {
    return a < b ? a : b;
}

static int fons__maxi(int a, int b) {
    return a > b ? a : b;
}

struct FONSatlasNode {
  short x, y, width;
};

struct FONSatlas {
  int width, height;
  Pool<FONSatlasNode, FONS_INIT_ATLAS_NODES> nodes;
  int dirtyRect[4];

  inline FONSatlas() {
      nodes.alloc();
      width = height = 0;
      reset(0, 0);
  }

  inline void reset(int w, int h) {
      if (w < width && h < height) {
          // for shrink, clear the Pool buffer size
          nodes = Pool<FONSatlasNode, FONS_INIT_ATLAS_NODES>();
          nodes.alloc();
      }

      width = w;
      height = h;

      // Init root node.
      nodes[0].x = 0;
      nodes[0].y = 0;
      nodes[0].width = width;
      nodes.length = 1;

      dirtyRect[0] = width;
      dirtyRect[1] = height;
      dirtyRect[2] = 0;
      dirtyRect[3] = 0;
  }
};

struct FONScacheTex {
  bool isTrueColor, isSizeChanged;
  FONSatlas atlas;
  unsigned int texDataLen;
  short ratio;

  inline FONScacheTex(bool trueColor)
      : isTrueColor(trueColor), isSizeChanged(false), _texData(nullptr) {
      reinit();
  }

  inline ~FONScacheTex() {
      freeTexData();
  }

  inline uint8_t *texData() {
      if (_texData == nullptr) {
          _texData = (uint8_t *) malloc(texDataLen);
          memset(_texData, 0, texDataLen);
      }
      return _texData;
  }

  inline void reinit() {
      freeTexData();
      ratio = FONS_MIN_TEX_RATIO;
      const unsigned short toShift = (isTrueColor ? 1 : 0);
      atlas.reset(FONS_TEX_WIDTH >> toShift, FONS_TEX_HEIGHT >> toShift);
      texDataLen = FONS_TEX_WIDTH * FONS_TEX_HEIGHT;
  }

  inline void resetBySize(int minWH) {
      int val = 0;
      if (minWH > 0) {
          const short
              newVal = 2 * (log2(ceil(float(minWH) / FONS_TEX_WIDTH)) + 1 + (isTrueColor ? 1 : 0));
          if (newVal > ratio) {
              val = newVal - ratio;
          }
      }
      reset(val);
  }

  inline void reset(short addToRatio = 0) {
      int newRatio = ratio + addToRatio;
      if (newRatio > FONS_MAX_TEX_RATIO) newRatio = FONS_MAX_TEX_RATIO;
      else if (newRatio < FONS_MIN_TEX_RATIO) newRatio = FONS_MIN_TEX_RATIO;

      const unsigned short toShift = (isTrueColor ? 1 : 0), mulW = (newRatio >> 1),
          mulH = newRatio - (newRatio >> 1);
      if (_texData == nullptr || newRatio != ratio) {
          const unsigned int newTexDataLen = mulW * mulH * FONS_TEX_WIDTH * FONS_TEX_HEIGHT;
          uint8_t *newData = (uint8_t *) malloc(newTexDataLen);
          if (newData != nullptr) {
              ratio = newRatio;
              freeTexData();
              _texData = newData;
              texDataLen = newTexDataLen;
              isSizeChanged = true;
          }
      }
      memset(_texData, 0, texDataLen);
      atlas.reset(mulW * (FONS_TEX_WIDTH >> toShift), mulH * (FONS_TEX_HEIGHT >> toShift));
  }
 private:
  uint8_t *_texData;

  inline void freeTexData() {
      if (_texData) free(_texData);
      _texData = nullptr;
  }
};

union FONSCountDown {
  unsigned int value;
  struct __attribute__((__packed__)) {
    unsigned short noneText;
    unsigned char normal, trueColor;
  } data;
};

static FonsSysLoadResult sFonsLoadResult;

struct FONScontext {
  Pool<FONSfont, FONS_INIT_FONTS> fonts;
  FONSerrCallbackFunc handleError;
  void *errorUptr;
  int defaultFallbackFontId, emojiFontId, languageSansId, languageSerifId;
  FONScacheTex texNormal, texTrueColor;
  FONSCountDown countDown;
  struct LangFont {
    FONSttFontImpl fontImpSerif = nullptr;
    FONSttFontImpl fontImp = nullptr;
    bool loadError = false;
  } langFonts[FONS_LANG_COUNT];

  inline FONScontext() : texNormal(false), texTrueColor(true) {
      countDown.value = 0;
      defaultFallbackFontId = emojiFontId = languageSansId = languageSerifId = FONS_INVALID;
      loadSystemFont();
  };

  bool loadSystemFont();
  int autoLoadSystemFontByName(const char *name);

  inline FONSfont *fontForLang(FONSLanguages lang, bool serif) {
      auto &cur = langFonts[lang];
      if (cur.fontImp == nullptr) {
          if (cur.loadError) return nullptr;
          auto loadRet = sFonsLoadResult.autoLoadForLanguage(lang);
          if (loadRet.sans == nullptr && loadRet.serif == nullptr) {
              cur.loadError = true;
              return nullptr;
          }
          cur.fontImpSerif = loadRet.serif;
          cur.fontImp = loadRet.sans ?: loadRet.serif;
      }
      if (serif && cur.fontImpSerif) {
          auto &curFont = fonts[languageSerifId];
          curFont.font = cur.fontImpSerif;
          return &curFont;
      }
      auto &curFont = fonts[languageSansId];
      curFont.font = cur.fontImp;
      return &curFont;
  }
};

// Copyright (c) 2008-2010 Bjoern Hoehrmann <bjoern@hoehrmann.de>
// See http://bjoern.hoehrmann.de/utf-8/decoder/dfa/ for details.

#define FONS_UTF8_ACCEPT 0
#define FONS_UTF8_REJECT 12

static unsigned int fons__decutf8(unsigned int *state, unsigned int *codep, unsigned int byte) {
    static const unsigned char utf8d[] = {
        // The first part of the table maps bytes to character classes that
        // to reduce the size of the transition table and create bitmasks.
        0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
        0,
        0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
        0,
        0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
        0,
        0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
        0,
        1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 9, 9, 9, 9, 9, 9, 9, 9, 9, 9, 9, 9, 9, 9, 9,
        9,
        7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7,
        7,
        8, 8, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2,
        2,
        10, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 4, 3, 3, 11, 6, 6, 6, 5, 8, 8, 8, 8, 8, 8, 8, 8, 8,
        8, 8,

        // The second part is a transition table that maps a combination
        // of a state of the automaton and a character class to a state.
        0, 12, 24, 36, 60, 96, 84, 12, 12, 12, 48, 72, 12, 12, 12, 12, 12, 12, 12, 12, 12, 12, 12,
        12,
        12, 0, 12, 12, 12, 12, 12, 0, 12, 0, 12, 12, 12, 24, 12, 12, 12, 12, 12, 24, 12, 24, 12, 12,
        12, 12, 12, 12, 12, 12, 12, 24, 12, 12, 12, 12, 12, 24, 12, 12, 12, 12, 12, 12, 12, 24, 12,
        12,
        12, 12, 12, 12, 12, 12, 12, 36, 12, 36, 12, 12, 12, 36, 12, 12, 12, 12, 12, 36, 12, 36, 12,
        12,
        12, 36, 12, 12, 12, 12, 12, 12, 12, 12, 12, 12,
    };

    unsigned int type = utf8d[byte];

    *codep = (*state != FONS_UTF8_ACCEPT) ?
             (byte & 0x3fu) | (*codep << 6) :
             (0xff >> type) & (byte);

    *state = utf8d[256 + *state + type];
    return *state;
}

static inline bool fonsNeedComplexLayout(unsigned int ch) {
    unsigned char high = (ch >> 8);
    switch (high) {
        case 0x05: return true; // Hebrew, Arabic
        case 0x06: return true; // arabic
        case 0x07: return (ch & 0x80);
        case 0x09: return true;  // Devanagari, Bengali
        case 0x0a: return true;  // Gujarat, ancient muki (Punjabi)
        case 0x0b: return true;  // Oriya, Tamil
        case 0x0c: return true;  // Telugu, Kanada
        case 0x0d: return true; // Dravidian (Malayalam)
        case 0x0e: return true; // Thai, Lao
        case 0x10: return (ch <= 0x109f); // myanmar
        case 0x17: return true; // Tagalog, Khmer
        case 0x19: return (ch & 0x80); // Kmer Symbols
        case 0xa9: return (ch >= 0xa9e0); // Myanmar extended B
        case 0xaa: return true; // Myanmar extended A
        case 0xfb: return (ch >= 0xfb50); // Arabic expression
        case 0xfc:
        case 0xfd: return true; // Arabic expression
        case 0xfe: return (ch >= 0xfe70); // Arabic expression B
        default: return false;
    }
}

static inline FONSLanguages fonsCharToLang(unsigned int ch) {
    unsigned char high = (ch >> 8);
    switch (high) {
        // Control characters, Latin extensions, phonetic symbols, etc
        case 0x00:
        case 0x01:
        case 0x02:
        case 0x03:
        case 0x04: return FONS_LANG_BASIC;
        // 0590-05FF: Hebrew
        case 0x05: return (ch & 0x80) ? FONS_LANG_HEBREW : FONS_LANG_ARABIC;
        // 0600-06FF: Arabic
        case 0x06: return FONS_LANG_ARABIC;
        // 0750-077F: Arabic Supplement
        case 0x07: return (ch & 0x80) ? FONS_LANG_ARABIC : FONS_LANG_ZERO;
        // 0900-097F: Devanagari   0980-09FF:Bengali
        case 0x09: return (ch & 0x80) ? FONS_LANG_BENGALI : FONS_LANG_DEVANAGARI;
        // 0A80-0AFF: Gujarati  0A00–0A7F: Gurmukhi
        case 0x0a: return (ch & 0x80) ? FONS_LANG_GUJARATI : FONS_LANG_GURMUKHI;
        // Oriya   0B80-0BFF: Tamil
        case 0x0b: return (ch & 0x80) ? FONS_LANG_TAMIL : FONS_LANG_ORIYA;
        // 0C00-0C7F: Telugu  0C80-0CFF: Kannada
        case 0x0c: return (ch & 0x80) ? FONS_LANG_KANNADA : FONS_LANG_TELUGU;
        // 0D00-0D7F: Malayalam
        case 0x0d: return FONS_LANG_MALAYALAM;
        // 0E00-0E7F: Thai 0E80-0EFF: Lao
        case 0x0e: return (ch & 0x80) ? FONS_LANG_LAOS : FONS_LANG_THAI;
        // 1000-109F: Myanmar
        case 0x10: return (ch < 0x10A0) ? FONS_LANG_MYANMAR : FONS_LANG_ZERO;
        // 1100-11FF: Hangul Jamo (Korea)
        case 0x11: return FONS_LANG_KOREAN;
        // 1700-171F: Tagalog 1780-17FF: Khmer
        case 0x17: return (ch & 0x80) ? FONS_LANG_KHMER : FONS_LANG_TAGALOG;
        // 19E0-19FF: Kmer Symbols
        case 0x19: return (ch & 0x80) ? FONS_LANG_KHMER : FONS_LANG_ZERO;
        // Speech, punctuation, superscript and subscript, mark, operator, etc
        case 0x1c:
        case 0x1d:
        case 0x1e:
        case 0x1f:
        case 0x20: return FONS_LANG_BASIC;
        // 2150-218F:Digital form, 2100-214F: Alphabetic symbol 2190-21FF: arrow
        case 0x21: return (ch >= 0x2150 && ch <= 0x218f) ? FONS_LANG_BASIC : FONS_LANG_SYMBOL;
        // various symbols
        case 0x22:
        case 0x23:
        case 0x24:
        case 0x25:
        case 0x26: return FONS_LANG_SYMBOL;
        case 0x27:
        case 0x28:
        case 0x29:
        case 0x2a:
        case 0x2b: return FONS_LANG_SYMBOL;
        // 2C60-2C7F: Latin Extended-C
        case 0x2c: return (ch & 0x80) ? FONS_LANG_BASIC : FONS_LANG_ZERO;
        // 2E00-2E7F: Supplemental Punctuation   2E80-2EFF: CJK Radicals Supplement, symbol
        case 0x2e: return (ch & 0x80) ? FONS_LANG_SYMBOL : FONS_LANG_BASIC;
        // 3040-30FF Japanese kana
        case 0x30: return (ch >= 0x3040) ? FONS_LANG_JAPANESE : FONS_LANG_ZERO;
        // 31F0-31FF Japanese kana
        case 0x31: if (ch >= 0x31f0) { return FONS_LANG_JAPANESE; }
            else if (ch >= 0x3130 && ch <= 0x318F) { return FONS_LANG_KOREAN; }
            else { return FONS_LANG_ZERO; }
        // 30XX-9FXX CJK related
        // A960-A97F: Hangul extension（Proverb expansion-A）  A9E0-A9FF: Myanmar Extended-B  A980-A9DF: Javanese
        case 0xa9: return (ch&0x80) ? FONS_LANG_MYANMAR : FONS_LANG_KOREAN;
        // AA60-AA7F: Myanmar Extended-A AA80-AADF: Tai Viet 
        case 0xaa: return FONS_LANG_MYANMAR;
        // FB50-FDFF Arabic Expression A
        case 0xfb: return (ch >= 0xfb50) ? FONS_LANG_ARABIC : FONS_LANG_BASIC;
        // FB50-FDFF Arabic Expression A
        case 0xfc:
        case 0xfd: return FONS_LANG_ARABIC;
        // FE70-FEFF Arabic Expression B, other symbols
        case 0xfe: return (ch >= 0xfe70) ? FONS_LANG_ARABIC : FONS_LANG_SYMBOL;
        // FF00-Half type, full type, special, etc
        case 0xff: return FONS_LANG_SYMBOL;
        default:
            // AC00-D7AF: Hangul Syllables
            if (high >= 0xac && high <= 0xd7) { return FONS_LANG_KOREAN; }
        break;
    }
    return FONS_LANG_ZERO;
}

static int fons__atlasInsertNode(FONSatlas &atlas, int idx, int x, int y, int w) {
    // Insert node
    atlas.nodes.alloc();
    if (atlas.nodes.ptr == NULL) return 0; // failed to alloc

    for (int i = atlas.nodes.length - 1; i > idx; i--)
        atlas.nodes[i] = atlas.nodes[i - 1];

    atlas.nodes[idx].x = (short) x;
    atlas.nodes[idx].y = (short) y;
    atlas.nodes[idx].width = (short) w;

    return 1;
}

static void fons__atlasRemoveNode(FONSatlas &atlas, int idx) {
    int i;
    if (atlas.nodes.length == 0) return;
    for (i = idx; i < atlas.nodes.length - 1; i++)
        atlas.nodes[i] = atlas.nodes[i + 1];
    atlas.nodes.length--;
}

static int fons__atlasAddSkylineLevel(FONSatlas &atlas, int idx, int x, int y, int w, int h) {
    int i;

    // Insert new node
    if (fons__atlasInsertNode(atlas, idx, x, y + h, w) == 0)
        return 0;

    // Delete skyline segments that fall under the shadow of the new segment.
    for (i = idx + 1; i < atlas.nodes.length; i++) {
        if (atlas.nodes[i].x < atlas.nodes[i - 1].x + atlas.nodes[i - 1].width) {
            int shrink = atlas.nodes[i - 1].x + atlas.nodes[i - 1].width - atlas.nodes[i].x;
            atlas.nodes[i].x += (short) shrink;
            atlas.nodes[i].width -= (short) shrink;
            if (atlas.nodes[i].width <= 0) {
                fons__atlasRemoveNode(atlas, i);
                i--;
            } else {
                break;
            }
        } else {
            break;
        }
    }

    // Merge same height skyline segments that are next to each other.
    for (i = 0; i < atlas.nodes.length - 1; i++) {
        if (atlas.nodes[i].y == atlas.nodes[i + 1].y) {
            atlas.nodes[i].width += atlas.nodes[i + 1].width;
            fons__atlasRemoveNode(atlas, i + 1);
            i--;
        }
    }

    return 1;
}

static int fons__atlasRectFits(FONSatlas &atlas, int i, int w, int h) {
    // Checks if there is enough space at the location of skyline span 'i',
    // and return the max height of all skyline spans under that at that location,
    // (think tetris block being dropped at that position). Or -1 if no space found.
    int x = atlas.nodes[i].x;
    int y = atlas.nodes[i].y;
    int spaceLeft;
    if (x + w > atlas.width)
        return -1;
    spaceLeft = w;
    while (spaceLeft > 0) {
        if (i == atlas.nodes.length) return -1;
        y = fons__maxi(y, atlas.nodes[i].y);
        if (y + h > atlas.height) return -1;
        spaceLeft -= atlas.nodes[i].width;
        ++i;
    }
    return y;
}

static int fons__atlasAddRect(FONSatlas &atlas, int rw, int rh, int *rx, int *ry) {
    int besth = atlas.height, bestw = atlas.width, besti = -1;
    int bestx = -1, besty = -1, i;

    // Bottom left fit heuristic.
    for (i = 0; i < atlas.nodes.length; i++) {
        int y = fons__atlasRectFits(atlas, i, rw, rh);
        if (y != -1) {
            if (y + rh < besth || (y + rh == besth && atlas.nodes[i].width < bestw)) {
                besti = i;
                bestw = atlas.nodes[i].width;
                besth = y + rh;
                bestx = atlas.nodes[i].x;
                besty = y;
            }
        }
    }

    if (besti == -1)
        return 0;

    // Perform the actual packing.
    if (fons__atlasAddSkylineLevel(atlas, besti, bestx, besty, rw, rh) == 0)
        return 0;

    *rx = bestx;
    *ry = besty;

    return 1;
}

int fonsAddFallbackFont(FONScontext &stash, int base, int fallback, bool deepCopy) {
    if (base == FONS_INVALID || fallback == FONS_INVALID) return 0;

    FONSfont &baseFont = stash.fonts[base];

    if (baseFont.nfallbacks >= FONS_MAX_FALLBACKS) return 0;

    baseFont.fallbacks[baseFont.nfallbacks++] = fallback;

    if (deepCopy) {
        FONSfont &fallbackFont = stash.fonts[fallback];
        int count = fallbackFont.nfallbacks;
        if (count + baseFont.nfallbacks >= FONS_MAX_FALLBACKS) {
            count = FONS_MAX_FALLBACKS - baseFont.nfallbacks - 1;
        }
        if (count > 0) {
            memcpy(baseFont.fallbacks + baseFont.nfallbacks,
                   fallbackFont.fallbacks,
                   count * sizeof(int));
            baseFont.nfallbacks += count;
        }
    }

    return 1;
}

int fonsAddFont(FONScontext &stash, const char *name, const char *path, int options) {
    FILE *fp = 0;
    int dataSize = 0;
    size_t readed;
    unsigned char *data = NULL;

    // Read in the font data.
    fp = fopen(path, "rb");
    if (fp == NULL) goto error;
    fseek(fp, 0, SEEK_END);
    dataSize = (int) ftell(fp);
    fseek(fp, 0, SEEK_SET);
    data = (unsigned char *) malloc(dataSize);
    if (data == NULL) goto error;
    readed = fread(data, 1, dataSize, fp);
    fclose(fp);
    fp = 0;
    if (readed != dataSize) goto error;

    return fonsAddFontMem(stash, name, data, dataSize, 1, options);

  error:
    if (data) free(data);
    if (fp) fclose(fp);
    return FONS_INVALID;
}

int fonsAddFontMem(FONScontext &stash,
                   const char *name,
                   unsigned char *data,
                   int dataSize,
                   int freeData,
                   int options) {
    int ascent, descent, fh, lineGap, unitPerEM;
    FONSfont *font;
    auto font_id = fonsGetFontByName(stash, name);
    int idx;
    if (font_id == FONS_INVALID) {
        font = &stash.fonts.alloc();
        
        idx = stash.fonts.length - 1;
        if (idx == FONS_INVALID)
            return FONS_INVALID;
    } else {
        idx = font_id;
        font = &stash.fonts[font_id];
        font->~FONSfont();
        // reset to zero to avoid last one affected
        memset(font, 0, sizeof(FONSfont));
    }

    new(font) FONSfont();

    strncpy(font->name, name, sizeof(font->name));
    font->name[sizeof(font->name) - 1] = '\0';

    // Read in the font data.
    font->dataSize = dataSize;
    font->data = data;
    font->freeData = (unsigned char) freeData;

    // Init font
    if (!fons__tt_loadFont(stash, font, data, dataSize)) goto error;

    // Store normalized line height. The real line height is got
    // by multiplying the lineh by font size.
    fons__tt_getFontVMetrics(font->font, &ascent, &descent, &lineGap, &unitPerEM);
    fh = ascent - descent;
    font->ascender = (float) ascent / (float) fh + 0.1;
    font->descender = (float) descent / (float) fh + 0.1;
    font->lineh = (float) (fh + lineGap) / (float) fh;
    font->rawAscender = ascent;
    font->rawDescender = descent;
    font->unitPerEM = unitPerEM;

    if ((options & FONS_ADDFONT_NO_COMPLEX_LAYOUT) == 0) {
        font->setFlag(FONT_SUPPORT_COMPLEX_LAYOUT);
    }
    if ((options & FONS_ADDFONT_IS_SERIF) != 0) {
        font->setFlag(FONT_SERIF);
    }
    return idx;

  error:
    font->~FONSfont();
    stash.fonts.length--;
    return FONS_INVALID;
}

int fonsAutoLoadSystemFontByName(FONScontext &s, const char *name) {
    return s.autoLoadSystemFontByName(name);
}

int fonsGetFontByName(FONScontext &s, const char *name) {
    int i;
    for (i = 0; i < s.fonts.length; i++) {
        if (strcmp(s.fonts[i].name, name) == 0) {
            return i;
        }
    }
    return FONS_INVALID;
}

int FONScontext::autoLoadSystemFontByName(const char *name) {
    if (name == nullptr || *name == 0) return FONS_INVALID;

    auto &ft = sFonsLoadResult;
    FONSttFontImpl ref = ft.autoLoadWithName(name);
    if (ref == nullptr) return FONS_INVALID;

    int retFont = fonsAddFontMem(*this, name, (unsigned char *) ref, DATA_SIZE_PRELOADED, 0, 0);
    fonsAddFallbackFont(*this, retFont, defaultFallbackFontId, true);

    return retFont;
}

bool FONScontext::loadSystemFont() {
    auto &ft = sFonsLoadResult;
    // load system font
    if (!ft.autoLoad()) {
        return false;
    }

    // The system fonts added by default do not support complex typesetting (only fonts added externally by users and multilingual fallback fonts are supported)
#define fonsAddFontMemPreloadWithOptions(fontName, fontImp, options)  (fontImp == nullptr ? FONS_INVALID : fonsAddFontMem(*this, fontName, (unsigned char *)fontImp, DATA_SIZE_PRELOADED, 0, options))
#define fonsAddFontMemPreload(fontName, fontImp) fonsAddFontMemPreloadWithOptions(fontName, fontImp, FONS_ADDFONT_NO_COMPLEX_LAYOUT)
#define fonsAddFontMemPreloadSerif(fontName, fontImp) fonsAddFontMemPreloadWithOptions(fontName, fontImp, FONS_ADDFONT_NO_COMPLEX_LAYOUT | FONS_ADDFONT_IS_SERIF)

    int sansFont = fonsAddFontMemPreload("sans-serif", ft.sans);
    if (ft.sansBak && ft.sansBak != ft.sans) {
        int sansFallback = fonsAddFontMemPreload("sans-fallback", ft.sansBak);
        fonsAddFallbackFont(*this, sansFont, sansFallback);
    }
    int serifFont = fonsAddFontMemPreloadSerif("serif", ft.serif);
    if (ft.serifBak && ft.serifBak != ft.serif && ft.serifBak != ft.sans) {
        int serifFallback = fonsAddFontMemPreloadSerif("serif-fallback", ft.serifBak);
        fonsAddFallbackFont(*this, serifFont, serifFallback);
    }
    int monoFont = fonsAddFontMemPreload("monospace", ft.monospace);
    defaultFallbackFontId = sansFont;
    emojiFontId = fonsAddFontMemPreload("\xf0\x9f\x98\x80", ft.emoji);
    // Multilingual fallback font combinations support complex typography by default
    languageSansId = fonsAddFontMemPreloadWithOptions("language-sans", ft.language, 0);
    languageSerifId =
        fonsAddFontMemPreloadWithOptions("language-serif", ft.language, FONS_ADDFONT_IS_SERIF);

    if (ft.serif != ft.sans) {
        fonsAddFallbackFont(*this, serifFont, sansFont, true);
    }
    if (ft.monospace != ft.sans) {
        fonsAddFallbackFont(*this, monoFont, sansFont, true);
    }

    if (ft.language) {
        memset(langFonts, 0, sizeof(langFonts));
        for (auto it = ft.mapLang.begin(); it != ft.mapLang.end(); ++it) {
            LangFont &cur = langFonts[it->first];
            cur.fontImp = it->second.sans;
            cur.fontImpSerif = it->second.serif;
        }
    }
    return true;
}

// Based on Exponential blur, Jani Huhtanen, 2006

#define APREC 16
#define ZPREC 7

static void fons__blurCols(unsigned char *dst, int w, int h, int dstStride, int alpha) {
    int x, y;
    for (y = 0; y < h; y++) {
        int z = 0; // force zero border
        for (x = 1; x < w; x++) {
            z += (alpha * (((int) (dst[x]) << ZPREC) - z)) >> APREC;
            dst[x] = (unsigned char) (z >> ZPREC);
        }
        dst[w - 1] = 0; // force zero border
        z = 0;
        for (x = w - 2; x >= 0; x--) {
            z += (alpha * (((int) (dst[x]) << ZPREC) - z)) >> APREC;
            dst[x] = (unsigned char) (z >> ZPREC);
        }
        dst[0] = 0; // force zero border
        dst += dstStride;
    }
}

static void fons__blurRows(unsigned char *dst, int w, int h, int dstStride, int alpha) {
    int x, y;
    for (x = 0; x < w; x++) {
        int z = 0; // force zero border
        for (y = dstStride; y < h * dstStride; y += dstStride) {
            z += (alpha * (((int) (dst[y]) << ZPREC) - z)) >> APREC;
            dst[y] = (unsigned char) (z >> ZPREC);
        }
        dst[(h - 1) * dstStride] = 0; // force zero border
        z = 0;
        for (y = (h - 2) * dstStride; y >= 0; y -= dstStride) {
            z += (alpha * (((int) (dst[y]) << ZPREC) - z)) >> APREC;
            dst[y] = (unsigned char) (z >> ZPREC);
        }
        dst[0] = 0; // force zero border
        dst++;
    }
}

static void fons__blur(FONScontext &stash,
                       unsigned char *dst,
                       int w,
                       int h,
                       int dstStride,
                       int blur) {
    int alpha;
    float sigma;
    (void) stash;

    if (blur < 1)
        return;
    // Calculate the alpha such that 90% of the kernel is within the radius. (Kernel extends to infinity)
    sigma = (float) blur * 0.57735f; // 1 / sqrt(3)
    alpha = (int) ((1 << APREC) * (1.0f - expf(-2.3f / (sigma + 1.0f))));
    fons__blurRows(dst, w, h, dstStride, alpha);
    fons__blurCols(dst, w, h, dstStride, alpha);
    fons__blurRows(dst, w, h, dstStride, alpha);
    fons__blurCols(dst, w, h, dstStride, alpha);
//	fons__blurrows(dst, w, h, dstStride, alpha);
//	fons__blurcols(dst, w, h, dstStride, alpha);
}

// Complex language typesetting processing
#if FONS_SUPPORT_COMPLEX_LAYOUT
extern int fons__tt_supportComplexLayout();

extern int fons__tt_getGlyphsForComplexLang(const FONSstate &state,
                                            FONSttFontImpl font,
                                            GlyphContext &ctx,
                                            std::vector<FonsGlyphItem> &glyphs,
                                            const char *str,
                                            int strLen);

static FONSglyph *fons__complexLayout(FONScontext &stash,
                                      const FONSstate &state,
                                      short iblur,
                                      GlyphContext &ctx,
                                      FONSfont *curFont,
                                      bool isSerif) {
    int g = 0;
    if (curFont && curFont->hasFlag(FONT_SUPPORT_COMPLEX_LAYOUT)) {
        g = fons__tt_getGlyphIndex(curFont, ctx.codepoint);
    }

    if (g == 0) {
        if (stash.languageSansId == FONS_INVALID) return nullptr;
        //Check if the incoming font cannot find the target glyph or does not support complex typography, directly find it from the multilingual fallback font
        if (ctx.lang == FONS_LANG_ZERO) ctx.lang = fonsCharToLang(ctx.codepoint);
        curFont = stash.fontForLang(ctx.lang, isSerif);
        if (curFont == nullptr) return nullptr;

        g = fons__tt_getGlyphIndex(curFont, ctx.codepoint);
    }

    if (g == 0) return nullptr;

    unsigned int codepoint = 0, utf8state = 0;
    const char *curStr = ctx.cur, *nextPos = ctx.cur;
    int total = 0;
    while (curStr < ctx.end) {
        if (fons__decutf8(&utf8state, &codepoint, *(const unsigned char *) (curStr))) {
            ++curStr;
            continue;
        }
        if (++total == 1) {
            // The first word should be the same as g above, no need to take
            nextPos = ++curStr;
            continue;
        }

        int g = fons__tt_getGlyphIndex(curFont, codepoint);
        if (g == 0) break;
        ++total;
        if (total > 30 && codepoint == 32) break;
        nextPos = ++curStr;
    }
    // did not find
    if (nextPos == ctx.cur) return nullptr;
    // Handle contiguous substrings supported by the current font

    std::vector<FonsGlyphItem> itemVec;
    int ret = fons__tt_getGlyphsForComplexLang(state,
                                               curFont->font,
                                               ctx,
                                               itemVec,
                                               ctx.cur,
                                               (int) (nextPos - ctx.cur));
    if (ret <= 0) return nullptr;

    // search for atlas
    int gx, gy;
    int pad = iblur + 2;
    int gw = ctx.w + pad * 2;
    int gh = ctx.h + pad * 2;

    FONSatlas &atlas = stash.texNormal.atlas;
    // Determines the spot to draw glyph in the atlas.
    if (ctx.bitmapOption != FONS_GLYPH_BITMAP_OPTIONAL) {
        // Find free spot for the rect in the atlas
        int added = fons__atlasAddRect(atlas, gw, gh, &gx, &gy);
        if (added == 0) {
            union FONSerrorParam ep;
            ep.atlas.isTrueColor = false;
            ep.atlas.minWidthHeight = (gw > gh ? gw : gh);
            stash.handleError(stash.errorUptr, FONS_ATLAS_FULL, ep);
            added = fons__atlasAddRect(atlas, gw, gh, &gx, &gy);
        }
        if (added == 0) {
            return NULL;
        }
    } else {
        // Negative coordinate indicates there is no bitmap data created.
        gx = -1;
        gy = -1;
    }

    unsigned int h = fons__hashint(ctx.codepoint) & (FONS_HASH_LUT_SIZE - 1);
    FONSglyph *glyph = curFont->glyphCache.insertNewGlyph(h);
    glyph->codepoint = -1;
    glyph->size = ctx.isize;
    glyph->blur = iblur;
    glyph->bitmapOption = ctx.bitmapOption;
    glyph->fixedStrokeWidth = state.strokeWidth * 64;
    glyph->lineCap = state.lineCap;
    glyph->lineJoin = state.lineJoin;
    glyph->fontWSV = state.fontWSV;
    glyph->index = 0xFFFF;
    glyph->x0 = (short) gx;
    glyph->y0 = (short) gy;
    glyph->x1 = (short) (glyph->x0 + gw);
    glyph->y1 = (short) (glyph->y0 + gh);
    glyph->xadv = (short) (ctx.advance * 10.0f);
    glyph->xoff = (short) (ctx.ratio * ctx.x - pad);
    glyph->yoff = (short) (ctx.ratio * ctx.y - pad);
    glyph->xend = (short) (ctx.ratio * (ctx.x + ctx.w) + pad);
    glyph->yend = (short) (ctx.ratio * (ctx.y + ctx.h) + pad);
    glyph->isTrueColor = false;

    ctx.cur = nextPos;
    ctx.isTrueColor = false;
    ctx.font = curFont;

    if (ctx.bitmapOption == FONS_GLYPH_BITMAP_OPTIONAL) {
        return glyph;
    }

    const int lineWidth = stash.texNormal.atlas.width;
    uint8_t *output = &stash.texNormal.texData()[(glyph->x0 + pad) + (glyph->y0 + pad) * lineWidth];
    fons__tt_buildBitmapForGlyphs(state,
                                  curFont->font,
                                  &itemVec[0],
                                  (int)itemVec.size(),
                                  output,
                                  lineWidth,
                                  ctx);

    // Blur
    if (iblur > 0) {
        unsigned char *bdst = &stash.texNormal.texData()[glyph->x0 + glyph->y0 * lineWidth];
        fons__blur(stash, bdst, gw, gh, lineWidth, iblur);
    }

    atlas.dirtyRect[0] = fons__mini(atlas.dirtyRect[0], glyph->x0);
    atlas.dirtyRect[1] = fons__mini(atlas.dirtyRect[1], glyph->y0);
    atlas.dirtyRect[2] = fons__maxi(atlas.dirtyRect[2], glyph->x1);
    atlas.dirtyRect[3] = fons__maxi(atlas.dirtyRect[3], glyph->y1);

    return glyph;
}
#endif

static inline int fons__findGlyphFromFallbacks(FONScontext &stash,
                                               GlyphContext &ctx,
                                               FONSfont *&renderFont,
                                               bool isSerif,
                                               int &fallbackIndex) {
    int g = 0;
    fallbackIndex = -1;
    FONSfont *font = ctx.font;
    for (int i = 0; i < font->nfallbacks; ++i) {
        FONSfont &fallbackFont = stash.fonts[font->fallbacks[i]];
        if (fallbackFont.font == NULL) continue;
        g = fons__tt_getGlyphIndex(&fallbackFont, ctx.codepoint);
        if (g == 0) continue;

        renderFont = &fallbackFont;
        fallbackIndex = i;
        return g;
    }
    // It is possible that we did not find a fallback glyph.
    // In that case the glyph index 'g' is 0, and we'll proceed below and cache empty glyph.
    if (stash.emojiFontId != FONS_INVALID &&
        ((ctx.codepoint > 0x2000 && ctx.codepoint < 0x3000) || ctx.codepoint > 0x1f000 || (ctx.codepoint >= 0xfe00 && ctx.codepoint <= 0xfe0f))) {
        // First try to find from emoji
        FONSfont *curFont = &stash.fonts[stash.emojiFontId];
        g = fons__tt_getGlyphIndex(curFont, ctx.codepoint);
        if (g != 0) {
            renderFont = curFont;
            fallbackIndex = stash.emojiFontId;
            return g;
        }
    }

    if (stash.languageSansId != FONS_INVALID) {
        if (ctx.lang == FONS_LANG_ZERO) ctx.lang = fonsCharToLang(ctx.codepoint);
        FONSfont *curFont = stash.fontForLang(ctx.lang, isSerif);
        if (curFont) {
            g = fons__tt_getGlyphIndex(curFont, ctx.codepoint);
            if (g != 0) {
                renderFont = curFont;
                fallbackIndex =
                    curFont->hasFlag(FONT_SERIF) ? stash.languageSerifId : stash.languageSansId;
                return g;
            }
        }
    }
    return 0;
}

// arg fixedStrokeWidth : strokeWidth * 64, default is 64
static FONSglyph *fons__getGlyph(FONScontext &stash,
                                 const FONSstate &state,
                                 short iblur,
                                 GlyphContext &ctx) {
    int i, g, gw, gh, gx, gy;
    FONSglyph *glyph = NULL;
    FONSfallbackglyph *fallbackglyph = NULL;
    unsigned int h;
    int pad;
    unsigned char *bdst;
    FONSfont *font = ctx.font;
    FONSfont *renderFont = ctx.font;
    const bool isSerif = (font && font->hasFlag(FONT_SERIF));

    if (ctx.isize < 2) return NULL;
    if (iblur > 20) iblur = 20;
    pad = iblur + 2;
    g = 0;

    // Reset allocator.

    // Find code point and size.
    h = fons__hashint(ctx.codepoint) & (FONS_HASH_LUT_SIZE - 1);

    // cache maybe in render fonts, so first to find the real fallback for codepoint
    i = font->fallbackCache.lut[h];
    while (i != -1) {
        FONSfallbackglyph &curfallback = font->fallbackCache.glyphs[i];
        if (curfallback.codepoint == ctx.codepoint && curfallback.fallbackIndex != FONS_INVALID) {
            const int fbIndex = curfallback.fallbackIndex;
            if (fbIndex < font->nfallbacks) {
                fallbackglyph = &curfallback;
                renderFont = &stash.fonts[font->fallbacks[fbIndex]];
                break;
            } else if (fbIndex == stash.emojiFontId) {
                fallbackglyph = &curfallback;
                renderFont = &stash.fonts[stash.emojiFontId];
                break;
            } else if (fbIndex == stash.languageSansId || fbIndex == stash.languageSerifId) {
                if (ctx.lang == FONS_LANG_ZERO) ctx.lang = fonsCharToLang(ctx.codepoint);
                FONSfont *curFont = stash.fontForLang(ctx.lang, isSerif);
                if (curFont) {
                    fallbackglyph = &curfallback;
                    renderFont = curFont;
                }
                break;
            }
        }
        i = curfallback.next;
    }

#if FONS_SUPPORT_COMPLEX_LAYOUT
    static bool platformSupportComplexLayout = fons__tt_supportComplexLayout();
    if (platformSupportComplexLayout && fonsNeedComplexLayout(ctx.codepoint)) {
        // Complex language typesetting
        FONSglyph *conplexRet = fons__complexLayout(stash, state, iblur, ctx, renderFont, isSerif);
        if (conplexRet) return conplexRet;
    }
#endif

    // find cache from render font
    i = renderFont->glyphCache.lut[h];
    int fixedStrokeWidth = state.strokeWidth * 64;
    while (i != -1) {
        FONSglyph &curr = renderFont->glyphCache.glyphs[i];
        if (curr.codepoint == ctx.codepoint && curr.size == ctx.isize && curr.blur == iblur
            && curr.bitmapOption == ctx.bitmapOption && curr.fontWSV == state.fontWSV &&
            (ctx.bitmapOption != FONS_GLYPH_BITMAP_STROKE || curr.isTrueColor
                || (curr.fixedStrokeWidth == fixedStrokeWidth && curr.lineCap == state.lineCap
                    && curr.lineJoin == state.lineJoin))
            ) {
            glyph = &curr;
            ctx.isTrueColor = glyph->isTrueColor;
            ctx.font = renderFont;

            if (ctx.bitmapOption == FONS_GLYPH_BITMAP_OPTIONAL
                || (glyph->x0 >= 0 && glyph->y0 >= 0)) {
                return glyph;
            }
            // At this point, glyph exists but the bitmap data is not yet created.
            g = glyph->index;
            break;
        }
        i = curr.next;
    }

    if (glyph == NULL) {
        // try to find the glyph first in renderFont (if renderFont is not font, font must not contain this codepoint)
        g = fons__tt_getGlyphIndex(renderFont, ctx.codepoint);

        // Try to find the glyph in fallback fonts.
        if (g == 0) {
            int fallbackIndex = -1;
            g = fons__findGlyphFromFallbacks(stash, ctx, renderFont, isSerif, fallbackIndex);
            // cache to fallback
            if (fallbackglyph == NULL) {
                fallbackglyph = font->fallbackCache.insertNewGlyph(h);
                fallbackglyph->codepoint = ctx.codepoint;
            }
            fallbackglyph->fallbackIndex = fallbackIndex;
        }
        ctx.isTrueColor = renderFont->hasFlag(FONT_TRUE_COLOR);
        if (ctx.isTrueColor && iblur > 0) {
            ctx.isTrueColor = false;
        }
        ctx.font = renderFont;
    }

    if (renderFont->font == NULL) return NULL;
    if (!fons__tt_getGlyphBounds(state, renderFont->font, g, ctx)) return NULL;

    gw = ctx.w + pad * 2;
    gh = ctx.h + pad * 2;

    FONSatlas &atlas = ctx.isTrueColor ? stash.texTrueColor.atlas : stash.texNormal.atlas;
    // Determines the spot to draw glyph in the atlas.
    if (ctx.bitmapOption != FONS_GLYPH_BITMAP_OPTIONAL) {
        // Find free spot for the rect in the atlas
        int added = fons__atlasAddRect(atlas, gw, gh, &gx, &gy);
        if (added == 0) {
            union FONSerrorParam ep;
            ep.atlas.isTrueColor = ctx.isTrueColor;
            ep.atlas.minWidthHeight = (gw > gh ? gw : gh);
            stash.handleError(stash.errorUptr, FONS_ATLAS_FULL, ep);
            added = fons__atlasAddRect(atlas, gw, gh, &gx, &gy);
        }
        if (added == 0) {
            return NULL;
        }
    } else {
        // Negative coordinate indicates there is no bitmap data created.
        gx = -1;
        gy = -1;
    }

    // Init glyph.
    if (glyph == NULL) {
        glyph = renderFont->glyphCache.insertNewGlyph(h);
        glyph->codepoint = ctx.codepoint;
        glyph->size = ctx.isize;
        glyph->blur = iblur;
        glyph->bitmapOption = ctx.bitmapOption;
        glyph->fixedStrokeWidth = fixedStrokeWidth;
        glyph->lineCap = state.lineCap;
        glyph->lineJoin = state.lineJoin;
        glyph->fontWSV = state.fontWSV;
    }

    glyph->index = g;
    glyph->x0 = (short) gx;
    glyph->y0 = (short) gy;
    glyph->x1 = (short) (glyph->x0 + gw);
    glyph->y1 = (short) (glyph->y0 + gh);
    glyph->xadv = (short) (ctx.advance * 10.0f);
    glyph->xoff = (short) (ctx.ratio * ctx.x - pad);
    glyph->yoff = (short) (ctx.ratio * ctx.y - pad);
    glyph->xend = (short) (ctx.ratio * (ctx.x + ctx.w) + pad);
    glyph->yend = (short) (ctx.ratio * (ctx.y + ctx.h) + pad);

    glyph->isTrueColor = ctx.isTrueColor;

    if (ctx.bitmapOption == FONS_GLYPH_BITMAP_OPTIONAL) {
        return glyph;
    }

    // Rasterize
    if (ctx.isTrueColor) {
        const int lineWidth = stash.texTrueColor.atlas.width * 4;
        fons__tt_buildGlyphBitmap(state, renderFont->font, g,
                                  &stash.texTrueColor.texData()[(glyph->x0 + pad) * 4
                                      + (glyph->y0 + pad) * lineWidth], lineWidth, ctx);
        iblur = 0;
    } else {
        const int lineWidth = stash.texNormal.atlas.width;
        fons__tt_buildGlyphBitmap(state, renderFont->font, g,
                                  &stash.texNormal.texData()[(glyph->x0 + pad)
                                      + (glyph->y0 + pad) * lineWidth], lineWidth, ctx);
    }

    // we do not need to add this, but we need to clear when the tex buffer alloced
    // Make sure there is one pixel empty border.
    // dst = &stash.texData[glyph->x0 + glyph->y0 * outStride];
    // for (y = 0; y < gh; y++) {
    // 	dst[y*FONS_TEX_WIDTH] = 0;
    // 	dst[gw-1 + y*FONS_TEX_WIDTH] = 0;
    // }
    // for (x = 0; x < gw; x++) {
    // 	dst[x] = 0;
    // 	dst[x + (gh-1)*FONS_TEX_WIDTH] = 0;
    // }

    // Debug code to color the glyph background
/*	unsigned char* fdst = &stash.texData()[glyph->x0 + glyph->y0 * FONS_TEX_WIDTH];
    for (y = 0; y < gh; y++) {
        for (x = 0; x < gw; x++) {
            int a = (int)fdst[x+y*FONS_TEX_WIDTH] + 20;
            if (a > 255) a = 255;
            fdst[x+y*FONS_TEX_WIDTH] = a;
        }
    }*/

    // Blur
    if (iblur > 0) {
        const int lineWidth = stash.texNormal.atlas.width;
        bdst = &stash.texNormal.texData()[glyph->x0 + glyph->y0 * lineWidth];
        fons__blur(stash, bdst, gw, gh, lineWidth, iblur);
    }

    atlas.dirtyRect[0] = fons__mini(atlas.dirtyRect[0], glyph->x0);
    atlas.dirtyRect[1] = fons__mini(atlas.dirtyRect[1], glyph->y0);
    atlas.dirtyRect[2] = fons__maxi(atlas.dirtyRect[2], glyph->x1);
    atlas.dirtyRect[3] = fons__maxi(atlas.dirtyRect[3], glyph->y1);

    return glyph;
}

static void fons__getQuad(FONScontext &stash, GlyphContext &ctx,
                          int prevGlyphIndex, FONSglyph *glyph,
                          short isize, float spacing, float *x, float *y, FONSquad *q) {
    float rx, ry, xoff, yoff, xend, yend, x0, y0, x1, y1;

    if (prevGlyphIndex != -1) {
        FONSttFontImpl fontRef = ctx.font->font;
        if (fontRef) {
            float adv =
                fons__tt_getGlyphKernAdvance(fontRef, prevGlyphIndex, glyph->index) * isize / 10.0f;
            *x += (int) (adv + spacing + 0.5f);
        }
    }

    // Each glyph has 2px border to allow good interpolation,
    // one pixel to prevent leaking, and one to allow good interpolation for rendering.
    // Inset the texture region by one pixel for correct interpolation.
    xoff = (short) (glyph->xoff + 1);
    yoff = (short) (glyph->yoff + 1);
    xend = (short) (glyph->xend - 1);
    yend = (short) (glyph->yend - 1);

    x0 = (float) (glyph->x0 + 1);
    y0 = (float) (glyph->y0 + 1);
    x1 = (float) (glyph->x1 - 1);
    y1 = (float) (glyph->y1 - 1);

    rx = (float) (int) (*x + xoff);
    ry = (float) (int) (*y + yoff);

    q->x0 = rx;
    q->y0 = ry;
    q->x1 = rx + xend - xoff;
    q->y1 = ry + yend - yoff;

    const FONSatlas &atlas = (ctx.isTrueColor ? stash.texTrueColor.atlas : stash.texNormal.atlas);
    q->s0 = x0 / atlas.width;
    q->t0 = y0 / atlas.height;
    q->s1 = x1 / atlas.width;
    q->t1 = y1 / atlas.height;

    *x += (int) (glyph->xadv / 10.0f + 0.5f);
}

static float fons__getVertAlign(FONScontext &stash, FONSfont *font, int align, float size) {
    if (!font->hasFlag(FONT_BITMAP_ONLY)) {
        if (align & FONS_ALIGN_TOP) {
            return font->ascender * size;
        } else if (align & FONS_ALIGN_MIDDLE) {
            return (font->ascender + font->descender) / 2.0f * size * 0.8; // fix middle position
        } else if (align & FONS_ALIGN_BASELINE) {
            return 0.0f;
        } else if (align & FONS_ALIGN_BOTTOM) {
            return font->descender * size;
        }
    } else {
        const float defaultAcent = 0.85f;
        if (align & FONS_ALIGN_TOP) {
            return defaultAcent * size;
        } else if (align & FONS_ALIGN_MIDDLE) {
            return (0.5f - defaultAcent) * size;
        } else if (align & FONS_ALIGN_BASELINE) {
            return 0.0f;
        } else if (align & FONS_ALIGN_BOTTOM) {
            return (defaultAcent - 1.0f) * size;
        }
    }
    return 0.0;
}

int fonsTextIterInit(FONScontext &stash,
                     const FONSstate &state,
                     FONStextIter &iter,
                     float x,
                     float y,
                     const char *str,
                     const char *end,
                     int bitmapOption) {
    float width;

    memset(&iter, 0, sizeof(iter));
    iter.state = state;

    if (state.font < 0 || state.font >= stash.fonts.length) return 0;
    iter.font = &stash.fonts[state.font];
    if (iter.font->data == NULL) return 0;

    iter.isize = (short) (state.size * 10.0f);
    iter.iblur = (short) state.blur;

    // Align horizontally
    if (state.align & FONS_ALIGN_LEFT) {
        // empty
    } else if (state.align & FONS_ALIGN_RIGHT) {
        width = fonsTextBounds(stash, state, x, y, str, end, NULL, NULL);
        x -= width;
    } else if (state.align & FONS_ALIGN_CENTER) {
        width = fonsTextBounds(stash, state, x, y, str, end, NULL, NULL);
        x -= width * 0.5f;
    }
    // Align vertically.
    y += fons__getVertAlign(stash, iter.font, state.align, iter.isize / 10.0f);

    if (end == NULL)
        end = str + strlen(str);

    iter.x = iter.nextx = x;
    iter.y = iter.nexty = y;
    iter.spacing = state.spacing;
    iter.str = iter.cur = str;
    iter.end = end;
    iter.codepoint = 0;
    iter.prevGlyphIndex = -1;
    iter.bitmapOption = (FONSglyphBitmap) bitmapOption;

    return 1;
}

int fonsTextIterNext(FONScontext &stash, FONStextIter &iter, FONSquad *quad) {
    FONSglyph *glyph = NULL;
    const char *curStr = iter.cur;
    while (curStr < iter.end) {
        if (fons__decutf8(&iter.utf8state, &iter.codepoint, *(const unsigned char *) (curStr))) {
            ++curStr;
            continue;
        }
        iter.x = iter.nextx;
        iter.y = iter.nexty;

        GlyphContext ctx;
        ctx.bitmapOption = iter.bitmapOption;
        ctx.font = iter.font;
        ctx.codepoint = iter.codepoint;
        ctx.isize = iter.isize;
        ctx.cur = iter.cur;  // The header position corresponding to the current utf8
        ctx.end = iter.end;
        ctx.lang = FONS_LANG_ZERO;

        glyph = fons__getGlyph(stash, iter.state, iter.iblur, ctx);
        if (glyph != NULL) {
            fons__getQuad(stash,
                          ctx,
                          iter.prevGlyphIndex,
                          glyph,
                          iter.isize,
                          iter.spacing,
                          &iter.nextx,
                          &iter.nexty,
                          quad);
        }
        iter.prevGlyphIndex = glyph != NULL ? glyph->index : -1;
        iter.isTrueColor = ctx.isTrueColor;
        if (ctx.cur > iter.cur) {
            curStr = iter.cur = ctx.cur;
        } else {
            iter.cur = ++curStr;  // After processing, modify cur
        }
        return 1;
    }

    iter.cur = curStr;  // After processing, modify cur
    iter.prevGlyphIndex = -1;
    return 0;
}

void fonsFontRawMatricsInfo(FONScontext &stash,
                            const FONSstate &state,
                            int *rawAscender,
                            int *rawDescender,
                            int *unitPerEM) {
    if (state.font >= 0 && state.font < stash.fonts.length) {
        const FONSfont &font = stash.fonts[state.font];
        *rawAscender = font.rawAscender;
        *rawDescender = font.rawDescender;
        *unitPerEM = font.unitPerEM;
    } else {
        *rawAscender = *rawDescender = *unitPerEM = 0;
    }
}

float fonsTextBounds(FONScontext &stash, const FONSstate &state,
                     float x, float y,
                     const char *str, const char *end,
                     float *bounds, int* pMissingGlyphCount) {
    unsigned int codepoint;
    unsigned int utf8state = 0;
    FONSquad q;
    FONSglyph *glyph = NULL;
    int prevGlyphIndex = -1;
    short isize = (short) (state.size * 10.0f);
    short iblur = (short) state.blur;
    FONSfont *font;
    float startx, advance;
    float minx, miny, maxx, maxy;
    int missingGlyphCount = 0;

    if (state.font < 0 || state.font >= stash.fonts.length) return 0;
    font = &stash.fonts[state.font];
    if (font->data == NULL) return 0;

    // Align vertically.
    y += fons__getVertAlign(stash, font, state.align, isize / 10.0f);

    minx = maxx = x;
    miny = maxy = y;
    startx = x;

    if (end == NULL) {
        end = str + strlen(str);
    }

    const char *cur = str;
    while (cur != end) {
        if (fons__decutf8(&utf8state, &codepoint, *(const unsigned char *) cur)) {
            ++cur;
            continue;
        }

        GlyphContext ctx;
        ctx.bitmapOption = FONS_GLYPH_BITMAP_OPTIONAL;
        ctx.font = font;
        ctx.codepoint = codepoint;
        ctx.isize = isize;
        ctx.cur = str; // The header position corresponding to the current utf8
        ctx.end = end;
        ctx.lang = FONS_LANG_ZERO;

        glyph = fons__getGlyph(stash, state, iblur, ctx);
        if (glyph != NULL) {
            fons__getQuad(stash, ctx, prevGlyphIndex, glyph, isize, state.spacing, &x, &y, &q);
            if (q.x0 < minx) minx = q.x0;
            if (q.x1 > maxx) maxx = q.x1;
            if (q.y0 < miny) miny = q.y0;
            if (q.y1 > maxy) maxy = q.y1;
            if (glyph->index == 0) {
                ++missingGlyphCount;
            }
        } else {
            ++missingGlyphCount;
        }
        prevGlyphIndex = glyph != NULL ? glyph->index : -1;
        if (ctx.cur > str) {
            str = cur = ctx.cur;
        } else {
            str = ++cur; // After processing, modify cur
        }
    }

    advance = x - startx;

    // Align horizontally
    if (state.align & FONS_ALIGN_LEFT) {
        // empty
    } else if (state.align & FONS_ALIGN_RIGHT) {
        minx -= advance;
        maxx -= advance;
    } else if (state.align & FONS_ALIGN_CENTER) {
        minx -= advance * 0.5f;
        maxx -= advance * 0.5f;
    }

    if (bounds) {
        bounds[0] = minx;
        bounds[1] = miny;
        bounds[2] = maxx;
        bounds[3] = maxy;
    }

    if (pMissingGlyphCount) {
        *pMissingGlyphCount = missingGlyphCount;
    }

    return advance;
}

void fonsLineBounds(FONScontext &stash, const FONSstate &state, float y, float *miny, float *maxy) {
    FONSfont *font;
    short isize;

    if (state.font < 0 || state.font >= stash.fonts.length) return;
    font = &stash.fonts[state.font];
    isize = (short) (state.size * 10.0f);
    if (font->data == NULL) return;

    y += fons__getVertAlign(stash, font, state.align, isize / 10.0f);

    *miny = y - font->ascender * (float) isize / 10.0f;
    *maxy = *miny + font->lineh * isize / 10.0f;
}

int fonsValidateTexture(FONScacheTex &tex, int *dirty) {
    FONSatlas &atlas = tex.atlas;
    if (atlas.dirtyRect[0] < atlas.dirtyRect[2] && atlas.dirtyRect[1] < atlas.dirtyRect[3]) {
        dirty[0] = atlas.dirtyRect[0];
        dirty[1] = atlas.dirtyRect[1];
        dirty[2] = atlas.dirtyRect[2];
        dirty[3] = atlas.dirtyRect[3];
        // Reset dirty rect
        atlas.dirtyRect[0] = atlas.width; // FIXME
        atlas.dirtyRect[1] = atlas.height; // FIXME
        atlas.dirtyRect[2] = 0;
        atlas.dirtyRect[3] = 0;
        return 1;
    }
    return 0;
}

void fonsSetErrorCallback(FONScontext &stash, FONSerrCallbackFunc callback, void *uptr) {
    stash.handleError = callback;
    stash.errorUptr = uptr;
}

int fonsResetAllAtlasToDefault(FONScontext &stash) {
    // Reset atlas
    stash.texTrueColor.reinit();
    stash.texNormal.reinit();

    // Reset cached glyphs
    for (int i = 0; i < stash.fonts.length; i++) {
        FONSfont &font = stash.fonts[i];
        font.glyphCache.clear();
    }

    return 1;
}

int fonsResetAtlas(FONScontext &stash, bool enlarge, int minWH) {
    // Reset atlas
    if (enlarge) {
        stash.texNormal.reset(1);
    } else {
        stash.texNormal.resetBySize(minWH);
    }
    // Reset cached glyphs
    for (int i = 0; i < stash.fonts.length; i++) {
        FONSfont &font = stash.fonts[i];
        // Color fonts may also contain caches of grayscale images (such as shadows), so there is no distinction here whether the color fonts are all cleaned up
        font.glyphCache.clear();
    }

    return 1;
}

int fonsResetAtlasTrueColor(FONScontext &stash, bool enlarge, int minWH) {
    // Reset atlas
    if (enlarge) {
        stash.texTrueColor.reset(1);
    } else {
        stash.texTrueColor.resetBySize(minWH);
    }

    // Reset cached glyphs
    for (int i = 0; i < stash.fonts.length; i++) {
        FONSfont &font = stash.fonts[i];
        if (!font.hasFlag(FONT_TRUE_COLOR)) continue;
        font.glyphCache.clear();
    }

    return 1;
}
} // namespace nanovg
} // namespace lynx

#endif  // CANVAS_2D_LITE_NANOVG_INCLUDE_FONTSTASH_INL_H_
