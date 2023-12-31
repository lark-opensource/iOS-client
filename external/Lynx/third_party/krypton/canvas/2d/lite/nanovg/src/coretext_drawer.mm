#ifndef HELIUM_NO_TEXT_RENDER
#include <math.h>
#include "canvas/2d/lite/nanovg/include/nanovg.h"
#include "canvas/2d/lite/nanovg/include/fontstash.h"
#include "canvas/base/log.h"
#include "canvas/text/font_registry.h"
#include <map>
#include <vector>
#include <string>

#if !defined(FONS_USE_FREETYPE)

#import "TargetConditionals.h"
#if TARGET_OS_IPHONE || TARGET_IPHONE_SIMULATOR
#import <UIKit/UIKit.h>
#import <CoreText/CTFont.h>
#else
#import <AppKit/AppKit.h>
#endif

// Complex typography related support
#if FONS_SUPPORT_COMPLEX_LAYOUT

#if TARGET_OS_IPHONE || TARGET_IPHONE_SIMULATOR
#import <CoreText/CTLine.h>
#import <CoreText/CTRun.h>
#import <CoreText/CTStringAttributes.h>
#endif

#endif

namespace lynx {
namespace nanovg {

static CGColorSpaceRef const colorSpaceGray = CGColorSpaceCreateDeviceGray();
static CGColorSpaceRef const colorSpaceRGBA = CGColorSpaceCreateDeviceRGB();

static inline bool isContextStroke(const GlyphContext &ctx) {
    return (ctx.bitmapOption == FONS_GLYPH_BITMAP_STROKE) && !ctx.font->hasFlag(FONT_BITMAP_ONLY | FONT_TRUE_COLOR);
}

static CGFontRef fonsCreateWithUrl(const char* url) {
    NSString* path = nil;
    if (strncasecmp(url, "file:///", 8) == 0) {
        path = [NSString stringWithUTF8String:url + 7];
    } else if (*url == '/') {
        path = [NSString stringWithUTF8String:url];
    } else if (strncasecmp(url, "assets://", 9) == 0) {
        path = [NSString stringWithUTF8String:url + 9];
        NSString* ext = @"";
        NSRange range = [path rangeOfString:@"." options:NSBackwardsSearch];
        if (range.location != NSNotFound) {
            ext = [path substringFromIndex:range.location + 1];
            path = [path substringToIndex:range.location];
        }
        path = [[NSBundle mainBundle] pathForResource:[@"Resource/" stringByAppendingString:path] ofType:ext];
    }
    if ([path length] == 0) {
        KRYPTON_LOGI("use external url ") << url << " error";
        return nullptr;
    }

    NSData *dynamicFontData = [NSData dataWithContentsOfFile:path];
    if (dynamicFontData == nil) {
        KRYPTON_LOGI("use external url ") << url << " error read data";
        return nullptr;
    }

    CGDataProviderRef providerRef = CGDataProviderCreateWithCFData((__bridge CFDataRef)dynamicFontData);
    CGFontRef ref = CGFontCreateWithDataProvider(providerRef);
    CFRelease(providerRef);

    KRYPTON_LOGI("use external url ") << url << " success";
    return ref;
}

static CGFontRef fonsCreateWithFontName(const char *fontName, bool useFontRegistry = false) {
    struct FontLoadItem {
        FONSttFontImpl font = nullptr;
        bool loadError = false;
    };
    static std::map<std::string, FontLoadItem> fonsAddFontMapByName;

    auto &mapItem = fonsAddFontMapByName[fontName];
    if (mapItem.font != nullptr) {
        return mapItem.font;
    } else if (mapItem.loadError) {
        return nullptr;
    }
    
    CGFontRef ref = nullptr;
    if (useFontRegistry) {
        auto url = lynx::canvas::FontRegistry::Instance().GetFontUrl(fontName);
        if (!url.empty()) {
            ref = fonsCreateWithUrl(url.c_str());
        }
    }

    if (ref == nullptr) {
        // load font with font name
        ref = CGFontCreateWithFontName(__CFStringMakeConstantString(fontName));
    }
    
    if (ref == nullptr) {
        mapItem.loadError = true;
        return nullptr;
    }

    mapItem.font = ref;
    mapItem.loadError = false;

    const int bufLen = 512;
    char buf[bufLen];
    size_t fontNameLen = strlen(fontName);
    if (fontNameLen > bufLen - 1) fontNameLen = bufLen - 1;
    // Add aliases and full names to the name list, which is convenient for quick search and reuse next time, reducing repetition
    CFStringRef names[] = {CGFontCopyFullName(ref), CGFontCopyPostScriptName(ref)};
    for (int i = 0; i < 2; ++i) {
        CFStringRef curName = names[i];
        if (curName == nullptr) continue;
        if (CFStringGetCString(curName, buf, bufLen, kCFStringEncodingUTF8)) {
            if (*buf && memcmp(buf, fontName, fontNameLen) != 0) {
                auto &newItem = fonsAddFontMapByName[buf];
                if (newItem.font != nullptr) {
                    // do not overwrite the original
                    newItem.font = ref;
                    newItem.loadError = false;
                }
            }
        }
        CFRelease(curName);
    }
    return ref;
}

CGFontRef FonsSysLoadResult::autoLoadWithName(const char *fontName) {
    if (fontName == 0 || *fontName == 0) return 0;
    return fonsCreateWithFontName(fontName, true);
}

FonsSysLoadResult::LangImps FonsSysLoadResult::autoLoadForLanguage(FONSLanguages lang) {
    auto it = mapLang.find(lang);
    if (it != mapLang.end()) {
        return it->second;
    }

    CGFontRef fontRef = nullptr, fontRefSerif = nullptr;
    switch (lang) {
        case FONS_LANG_HEBREW:
            fontRef = fonsCreateWithFontName("LucidaGrande.ttc");
            fontRefSerif = fonsCreateWithFontName("Times New Roman");
            break;
        case FONS_LANG_ARABIC:
            fontRef = fonsCreateWithFontName("Courier New.ttf");
            fontRefSerif = fonsCreateWithFontName("Times New Roman");
            break;
        case FONS_LANG_KOREAN:
            fontRef = fonsCreateWithFontName("Apple SD Gothic Neo Regular");
            fontRefSerif = fonsCreateWithFontName("AppleMyungjo");
            break;
        case FONS_LANG_BENGALI:
            fontRef = fonsCreateWithFontName("Bangla Sangam MN");
            if (fontRef == nil) {
                fontRef = fonsCreateWithFontName("KohinoorBangla-Regular");
            }
            fontRefSerif = fonsCreateWithFontName("Bangla MN");
            break;
        case FONS_LANG_LAOS:
            fontRef = fonsCreateWithFontName("Lao Sangam MN");
            fontRefSerif = fonsCreateWithFontName("Lao MN");
            break;
        case FONS_LANG_KHMER:
            fontRef = fonsCreateWithFontName("Khmer Sangam MN");
            fontRefSerif = fonsCreateWithFontName("Khmer MN");
            break;
        case FONS_LANG_THAI:
            fontRef = fonsCreateWithFontName("Thonburi");
            fontRefSerif = fonsCreateWithFontName("Ayuthaya");
            break;
        case FONS_LANG_DEVANAGARI:
            fontRef = fonsCreateWithFontName("Devanagari Sangam MN");
            if (fontRef == nil) {
                fontRef = fonsCreateWithFontName("KohinoorDevanagari-Regular");
            }
            fontRefSerif = fonsCreateWithFontName("Devanagari MN");
            break;
        case FONS_LANG_TAMIL:
            fontRef = fonsCreateWithFontName("Tamil Sangam MN");
            fontRefSerif = fonsCreateWithFontName("Tamil MN");
            break;
        case FONS_LANG_TELUGU:
            fontRef = fonsCreateWithFontName("Telugu Sangam MN");
            if (fontRef == nil) {
                fontRef = fonsCreateWithFontName("KohinoorTelugu-Regular");
            }
            fontRefSerif = fonsCreateWithFontName("Telugu MN");
            break;
        case FONS_LANG_MALAYALAM:
            fontRef = fonsCreateWithFontName("Malayalam Sangam MN");
            fontRefSerif = fonsCreateWithFontName("Malayalam MN");
            break;
        case FONS_LANG_GUJARATI:
            fontRef = fonsCreateWithFontName("Gujarati Sangam MN");
            if (fontRef == nil) {
                fontRef = fonsCreateWithFontName("KohinoorGujarati-Regular");
            }
            fontRefSerif = fonsCreateWithFontName("Gujarati MN");
            break;
        case FONS_LANG_KANNADA:
            fontRef = fonsCreateWithFontName("Kannada Sangam MN");
            if (fontRef == nil) {
                fontRef = fonsCreateWithFontName("NotoSansKannada-Regular");
            }
            fontRefSerif = fonsCreateWithFontName("Kannada MN");
            break;
        case FONS_LANG_ORIYA:
            fontRef = fonsCreateWithFontName("Oriya Sangam MN");
            if (fontRef == nil) {
                fontRef = fonsCreateWithFontName("NotoSansOriya");
            }
            fontRefSerif = fonsCreateWithFontName("Oriya MN");
            break;
        case FONS_LANG_GURMUKHI:
            fontRef = fonsCreateWithFontName("Gurmukhi Sangam MN");
            if (fontRef == nil) {
                fontRef = fonsCreateWithFontName("MuktaMahee-Regular");
            }
            fontRefSerif = fonsCreateWithFontName("Gurmukhi MN");
            break;
        case FONS_LANG_MYANMAR:
            fontRef = fonsCreateWithFontName("Myanmar Sangam MN");
            if (fontRef == nil) {
                fontRef = fonsCreateWithFontName("NotoSansMyanmar-Regular");
            }
            break;
        default:
            break;
    }

    LangImps &langImps = mapLang[lang];
    langImps.sans = fontRef;
    langImps.serif = fontRefSerif;
    return langImps;
}

bool FonsSysLoadResult::autoLoad() {
    if (sans != nullptr) return true;

    CGFontRef sansCJK = NULL, serifCJK = NULL;
    CGFontRef sansLatin = fonsCreateWithFontName("Helvetica");  //
    CGFontRef serifLatin = fonsCreateWithFontName("Times New Roman");
    monospace = fonsCreateWithFontName("Courier");
    emoji = fonsCreateWithFontName("Apple Color Emoji");
    symbol = fonsCreateWithFontName("Apple Symbols");

    bool latinPrefer = false;
    switch (FONS_LANGUAGE_PREFER) {
        case FONS_LANGPREFER_JP:
            sansCJK = fonsCreateWithFontName("Hiragino Mincho ProN W3");
            serifCJK = fonsCreateWithFontName("Hiragino Sans W3");
            break;
        case FONS_LANGPREFER_TC:
            sansCJK = fonsCreateWithFontName("PingFang TC Regular");
            serifCJK = fonsCreateWithFontName("Songti TC");
            break;
        case FONS_LANGPREFER_LATIN:
            latinPrefer = true;
            // no break
        default:
            sansCJK = fonsCreateWithFontName("PingFang SC Regular");
            serifCJK = fonsCreateWithFontName("Songti SC");
            break;
    }
    if (latinPrefer) {
        // Latin class as the preferred language, CJK lower priority support (Western fonts are used as the main font, Chinese fonts are used as fallback)
        sans = sansLatin ?: sansCJK;
        sansBak = sansLatin ? sansCJK : NULL;
        serif = serifLatin ?: serifCJK;
        serifBak = serifLatin ? serifCJK : NULL;
    } else {
        sans = sansCJK ?: sansLatin;
        sansBak = NULL;  // There is no need to set Western fallback, it is processed in multiple languages
        // If you can't find Chinese serif fonts, then Western fonts don't need serif fonts, and sans serif fonts are used uniformly.
        serif = serifCJK ?: NULL;
        serifBak = serifCJK ? serifLatin : NULL;
    }
    if (sans == NULL) {
//        FERROR("Load System Font Error!!");
        return false;
    }

    language = sansLatin ?: sans;
    mapLang[FONS_LANG_BASIC].sans = language;
    mapLang[FONS_LANG_BASIC].serif = serifLatin;
    mapLang[FONS_LANG_SYMBOL].sans = symbol ?: language;

    if (serif == NULL) serif = sans;
    if (monospace == NULL) monospace = sans;
    return true;
}

bool fons__tt_loadFont(FONScontext &context, FONSfont *font, unsigned char *data, int dataSize) {
    if (dataSize == DATA_SIZE_PRELOADED) {
        font->font = (CGFontRef) data;
    } else {
        CGDataProviderRef dataProvider = CGDataProviderCreateWithData(NULL, data, dataSize, NULL);
        font->font = CGFontCreateWithDataProvider(dataProvider);
        font->setFlag(FONT_TO_RELEASE_IMP);
        CGDataProviderRelease(dataProvider);
    }
    CTFontRef ft = CTFontCreateWithGraphicsFont(font->font, 0.0, NULL, NULL);
    auto st = CTFontGetSymbolicTraits(ft);
    if ((st & kCTFontTraitColorGlyphs) != 0) {
        font->setFlag(FONT_TRUE_COLOR);
    }
    CFRelease(ft);

    return font->font != NULL;
}

void fons__tt_getFontVMetrics(CGFontRef font, int *ascent, int *descent, int *lineGap, int *unitPerEM) {
    *ascent = CGFontGetAscent(font);
    *descent = CGFontGetDescent(font);
    *lineGap = 0;
    *unitPerEM = CGFontGetUnitsPerEm(font);
}

int fons__tt_getGlyphIndex(FONSfont *font, int codepoint) {
    if (font->font == NULL) return 0;
    CTFontRef ft = CTFontCreateWithGraphicsFont(font->font, 0.0, NULL, NULL);
    CGGlyph glyph;
    if (codepoint > 65535) {
        UniChar ch[2];
        ch[0] = 0xd7c0 + (codepoint >> 10);
        ch[1] = 0xdc00 | (codepoint & 0x3ff);
        CGGlyph glyphs[2];
        if (!CTFontGetGlyphsForCharacters(ft, ch, glyphs, 2)) {
            glyph = 0;
        } else {
            glyph = glyphs[0];
        }
    } else {
        UniChar ch = codepoint;
        if (!CTFontGetGlyphsForCharacters(ft, &ch, &glyph, 1)) {
            glyph = 0;
        }
    }
    CFRelease(ft);
    return glyph;
}

void fons__innerInitFontRefAndSizeRatio(const FONSstate &state, CGFontRef font, GlyphContext &ctx) {
    float size = ctx.isize / 10.0f;
    float sizeRatio = 1.0f, useFontSize = size;
    const short maxSize = FONS_MAX_RENDER_GLYPH_SIZE;
    if (useFontSize > maxSize) {
        sizeRatio = size / maxSize;
        useFontSize = maxSize;
    }
    ctx.ratio = sizeRatio;

    CTFontRef ft = CTFontCreateWithGraphicsFont(font, useFontSize, NULL, NULL);
    if ((state.fontWSV & (FONS_STYLE_ITALIC | FONS_STYLE_OBLIQUE)) != 0 &&
        (CTFontGetSymbolicTraits(ft) & kCTFontTraitItalic) == 0) {
        CGAffineTransform matrix = CGAffineTransformIdentity;
        matrix.c = 0.25;
        CFRelease(ft);
        ft = CTFontCreateWithGraphicsFont(font, useFontSize, &matrix, NULL);
    }
    if (ctx.fontRef) CFRelease(ctx.fontRef);
    ctx.fontRef = ft;
}

static CGRect fons__innerGetBindingForGlyph(const FONSstate &state, CGFontRef font, GlyphContext &ctx, int glyph) {
    CGGlyph glyphs[] = {(CGGlyph) glyph};
    int adv = 0;
    CGFontGetGlyphAdvances(font, glyphs, 1, &adv);
    ctx.advance = adv * ctx.isize / 10.0f / CGFontGetUnitsPerEm(font);
    return CTFontGetBoundingRectsForGlyphs(ctx.fontRef, kCTFontOrientationDefault, glyphs, NULL, 1);
}

bool fons__innerPostGetBinding(const FONSstate &state, GlyphContext &ctx, CGRect &boundingBox) {
    float x = boundingBox.origin.x, y = boundingBox.origin.y;
    float w = boundingBox.size.width, h = boundingBox.size.height;
    int X = x - 1, Y = y - 1;
    int width = ceilf(w + (x - X)), height = ceilf(h + (y - Y));
    if (!width || !height) {
        ctx.ratio = 1.0f;
        ctx.x = ctx.y = ctx.w = ctx.h = ctx.pad = 0;
        return false;
    }

    int pad = 0;
    if (isContextStroke(ctx)) {
        // Stroke, the pixels in all directions need to expand
        pad = state.strokeWidth + 1.999f;
    }
    if (state.fontWSV != 0) {
        const int newFontWeight = fons__weightFromWsv(state.fontWSV);
        if (newFontWeight > 4) {
            const float lwFoWeight = 0.001 * ctx.isize * (newFontWeight - 4);
            int lwForWeightInt = (int) (lwFoWeight + 0.8f);
            if (lwForWeightInt > 0) {
                pad += lwForWeightInt;
            }
        }
    }

    ctx.pad = pad;
    ctx.x = X - pad;
    ctx.y = -Y - height - pad;
    ctx.w = width + (pad << 1);
    ctx.h = height + (pad << 1);

    return true;
}

static void fons__innerBuildBitmapForGlyphs(const FONSstate &state, CGGlyph *glyphs, CGPoint *positions, int count,
                                            uint8_t *output, size_t stride, const GlyphContext &ctx) {
    CGContextRef context =
        CGBitmapContextCreate(output, ctx.w, ctx.h, 8, stride, ctx.isTrueColor ? colorSpaceRGBA : colorSpaceGray,
                              ctx.isTrueColor ? kCGImageAlphaPremultipliedLast : 0);

    CGFloat color[] = {1.0, 1.0, 1.0, 1.0};
    const bool stroke = isContextStroke(ctx);
    if (stroke) {
        const CGLineCap lineCaps[] = {
            [NVG_BUTT] = kCGLineCapButt,
            [NVG_ROUND] = kCGLineCapRound,
            [NVG_SQUARE] = kCGLineCapSquare,

        };
        const CGLineJoin lineJoins[] = {
            [NVG_ROUND] = kCGLineJoinRound,
            [NVG_BEVEL] = kCGLineJoinBevel,
            [NVG_MITER] = kCGLineJoinMiter,
        };

        CGContextSetLineCap(context, lineCaps[state.lineCap]);
        CGContextSetLineJoin(context, lineJoins[state.lineJoin]);
    }

    const int newFontWeight = fons__weightFromWsv(state.fontWSV);
    if (newFontWeight == 0) {
        // default font weight
        if (stroke) {
            CGContextSetTextDrawingMode(context, kCGTextStroke);
            CGContextSetLineWidth(context, state.strokeWidth);
            CGContextSetStrokeColor(context, color);
        } else {
            CGContextSetFillColor(context, color);
        }
        CTFontDrawGlyphs(ctx.fontRef, glyphs, positions, count, context);
    } else {
        float lwFoWeight = 0;
        int cmpWeight = 4;
        if (!stroke && ctx.fontRef && (CTFontGetSymbolicTraits(ctx.fontRef) & kCTFontTraitBold) != 0) {
            cmpWeight = 7;
        }
        if (newFontWeight > cmpWeight) {
            // extend the stroke area for change thr weight (bold)
            lwFoWeight = 0.01 * state.size * (newFontWeight - cmpWeight);
        } else if (newFontWeight >= 1 && newFontWeight < cmpWeight) {
            lwFoWeight = 0.015 * state.size * (newFontWeight - cmpWeight);
        }

        // other font weight
        CGContextSetStrokeColor(context, color);
        CGContextSetFillColor(context, color);
        if (stroke) {
            bool toCutInner = (lwFoWeight > 2.0f);
            CGContextSetTextDrawingMode(context, kCGTextStroke);
            CGContextSetLineWidth(context, (toCutInner ? lwFoWeight * 1.5 : 0) + state.strokeWidth);
            CTFontDrawGlyphs(ctx.fontRef, glyphs, positions, count, context);
            if (toCutInner) {
                CGContextSetTextDrawingMode(context, kCGTextFillStroke);
                CGContextSetBlendMode(context, kCGBlendModeSourceOut);
                CGContextSetLineWidth(context, lwFoWeight - 2.0f);
                CTFontDrawGlyphs(ctx.fontRef, glyphs, positions, count, context);
            }
        } else {
            if (lwFoWeight > 0.1f) {
                CGContextSetTextDrawingMode(context, kCGTextFillStroke);
                CGContextSetLineWidth(context, lwFoWeight);
                CTFontDrawGlyphs(ctx.fontRef, glyphs, positions, count, context);
            } else {
                CGContextSetTextDrawingMode(context, kCGTextFill);
                CTFontDrawGlyphs(ctx.fontRef, glyphs, positions, count, context);
                if (lwFoWeight < -1.0f) {
                    CGContextSetTextDrawingMode(context, kCGTextStroke);
                    CGContextSetBlendMode(context, kCGBlendModeSourceOut);
                    CGContextSetLineWidth(context, -lwFoWeight);
                    CTFontDrawGlyphs(ctx.fontRef, glyphs, positions, count, context);
                }
            }
        }
    }

    CGContextFlush(context);
    CGContextRelease(context);
}

bool fons__tt_getGlyphBounds(const FONSstate &state, CGFontRef font, int glyph, GlyphContext &ctx) {
    fons__innerInitFontRefAndSizeRatio(state, font, ctx);
    CGRect boundingBox = fons__innerGetBindingForGlyph(state, font, ctx, glyph);
    return fons__innerPostGetBinding(state, ctx, boundingBox);
}

bool fons__tt_buildBitmapForGlyphs(const FONSstate &state, CGFontRef font, const FonsGlyphItem *glyphItems, int count,
                                   uint8_t *output, size_t stride, const GlyphContext &ctx) {
    if (glyphItems == nullptr || count <= 0) return false;

    std::vector<CGGlyph> glyphs;
    std::vector<CGPoint> postions;
    CGPoint basePostion = CGPointMake(-ctx.x, ctx.y + ctx.h);

    glyphs.resize(count);
    postions.resize(count);

    const FonsGlyphItem *item = glyphItems;
    for (int i = 0; i < count; ++i, ++item) {
        glyphs[i] = (CGGlyph) item->glyph;
        CGPoint &curPos = postions[i];
        curPos = basePostion;
        curPos.x += item->x;
        // curPos.y; // y does not need to be adjusted
    }

    fons__innerBuildBitmapForGlyphs(state, &glyphs[0], &postions[0], count, output, stride, ctx);

    return true;
}

bool fons__tt_buildGlyphBitmap(const FONSstate &state, CGFontRef font, int glyph, uint8_t *output, size_t stride,
                               const GlyphContext &ctx) {
    CGGlyph glyphs[] = {(CGGlyph) glyph};
    CGPoint position = CGPointMake(-ctx.x, ctx.y + ctx.h);

    fons__innerBuildBitmapForGlyphs(state, glyphs, &position, 1, output, stride, ctx);

    // debug
#ifdef DEBUG
    CGDataProviderRef data = CGDataProviderCreateWithData(nullptr, output, stride * ctx.h, nullptr);
    CGImageRef image =
        CGImageCreate(ctx.w, ctx.h, 8, ctx.isTrueColor ? 32 : 8, stride, ctx.isTrueColor ? colorSpaceRGBA : colorSpaceGray,
                      kCGBitmapByteOrder32Big, data, nullptr, false, kCGRenderingIntentDefault);

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wunused-variable"
#if TARGET_OS_IPHONE || TARGET_IPHONE_SIMULATOR
    UIImage *img = [[UIImage alloc] initWithCGImage:image];
#else
    NSImage *img = [[NSImage alloc] initWithCGImage:image size:NSMakeSize(ctx.w, ctx.h)];
#endif
#pragma clang diagnostic pop
    CGDataProviderRelease(data);
    CGImageRelease(image);
#endif
    return true;
}

int fons__tt_getGlyphKernAdvance(CGFontRef font, int glyph1, int glyph2) {
    // No processing is required here, the returned bindingBox has been processed
    return 0;
}

// Complex typography related support
#if FONS_SUPPORT_COMPLEX_LAYOUT

int fons__tt_supportComplexLayout() {
    return true;
}

static CGRect fons__innerGetBindingForGlyphs(const FONSstate &state, CGFontRef font, GlyphContext &ctx,
                                             std::vector<FonsGlyphItem> &glyphs) {
    int adv = 0;
    const int count = (int) glyphs.size();
    const size_t bufLen = count * (sizeof(CGGlyph) + sizeof(int) + sizeof(CGRect));
    std::vector<char> buffer;
    buffer.resize(bufLen);
    CGGlyph *bufGlyphs = (CGGlyph *) (&buffer[0]);
    int *advs = (int *) ((&buffer[0]) + count * sizeof(CGGlyph));
    CGRect *rects = (CGRect *) ((&buffer[0]) + count * sizeof(CGGlyph) + count * sizeof(int));
    for (int i = 0; i < count; ++i) {
        bufGlyphs[i] = (CGGlyph) glyphs[i].glyph;
    }
    CGFontGetGlyphAdvances(font, bufGlyphs, count, advs);
    CTFontGetBoundingRectsForGlyphs(ctx.fontRef, kCTFontOrientationHorizontal, bufGlyphs, rects, count);
    CGRect boundingBox = CGRectZero;

    const float advRatio = ctx.isize / 10.0f / CGFontGetUnitsPerEm(font);
    for (int i = 0; i < count; ++i) {
        auto &item = glyphs[i];
        auto &curRect = rects[i];
        item.x = adv * advRatio;  // There is no need to take the position of curRect here, it is not needed when drawing
        item.y = 0;
        curRect.origin.x += item.x;
        item.adv = advs[i] * advRatio;
        adv += advs[i];
        boundingBox = CGRectUnion(boundingBox, curRect);
    }
    ctx.advance = adv * advRatio;
    if (boundingBox.size.width < ctx.advance) {
        boundingBox.size.width = ctx.advance;
    }
    // Calculated as relative size
    for (int i = 0; i < count; ++i) {
        auto &item = glyphs[i];
        item.x -= boundingBox.origin.x;
        item.y -= boundingBox.origin.y;
    }

    return boundingBox;
}

int fons__tt_getGlyphsForComplexLang(const FONSstate &state, CGFontRef font, GlyphContext &ctx,
                                     std::vector<FonsGlyphItem> &glyphs, const char *str, int strLen) {
    glyphs.clear();

    if (font == nullptr || strLen <= 0) return 0;

    CFStringRef cstr = CFStringCreateWithBytes(kCFAllocatorDefault, (const UInt8 *) str, strLen, kCFStringEncodingUTF8, false);
    if (!cstr) {
        return 0;
    }

    fons__innerInitFontRefAndSizeRatio(state, font, ctx);
    CFTypeRef keys[] = {(CFTypeRef) kCTFontAttributeName};
    CFTypeRef values[] = {ctx.fontRef};

    CFDictionaryRef attributes = CFDictionaryCreate(kCFAllocatorDefault, (const void **) keys, (const void **) values, 1,
                                                    &kCFCopyStringDictionaryKeyCallBacks, &kCFTypeDictionaryValueCallBacks);
    CFAttributedStringRef attstr = CFAttributedStringCreate(kCFAllocatorDefault, cstr, attributes);
    CTLineRef line = CTLineCreateWithAttributedString(attstr);
    CFArrayRef runs = CTLineGetGlyphRuns(line);

    std::vector<CGGlyph> glyphBuf;
    const CFIndex runCount = CFArrayGetCount(runs);
    for (int i = 0; i < runCount; ++i) {
        CTRunRef curRun = (CTRunRef) CFArrayGetValueAtIndex(runs, i);
        const CFIndex glyphCount = CTRunGetGlyphCount(curRun);
        if (glyphCount <= 0) continue;
        glyphBuf.resize(glyphCount);
        CTRunGetGlyphs(curRun, CFRangeMake(0, glyphCount), &glyphBuf[0]);
        for (int j = 0; j < glyphCount; j++) {
            glyphs.push_back(FonsGlyphItem(glyphBuf[j]));
        }
    }

    CFRelease(line);
    CFRelease(attributes);
    CFRelease(attstr);
    CFRelease(cstr);

    if (glyphs.empty()) return 0;

    // Layout
    CGRect boundingBox = fons__innerGetBindingForGlyphs(state, font, ctx, glyphs);
    if (!fons__innerPostGetBinding(state, ctx, boundingBox)) {
        glyphs.clear();
    }
    return (int) glyphs.size();
}
#endif

} /* namespace nanovg */
} /* namespace lynx */


#endif  // #if !defined(FONS_USE_FREETYPE)

#endif  // #ifndef HELIUM_NO_TEXT_RENDER
