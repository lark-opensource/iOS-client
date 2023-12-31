//
// Copyright (c) 2013 Mikko Mononen memon@inside.org
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

#include <stdlib.h>
#include <stdio.h>
#include <math.h>
#include <memory.h>
#include <functional>

#include "canvas/base/log.h"
#include "canvas/2d/lite/nanovg/include/nanovg.h"
#include "canvas/2d/lite/nanovg/include/fontstash.h"
#include "canvas/2d/lite/nanovg/include/fontstash-inl.h"

#ifdef _MSC_VER
#pragma warning(disable: 4100)  // unreferenced formal parameter
#pragma warning(disable: 4127)  // conditional expression is constant
#pragma warning(disable: 4204)  // nonstandard extension used : non-constant aggregate initializer
#pragma warning(disable: 4706)  // assignment within conditional expression
#endif

#define NVG_INIT_FONTIMAGE_SIZE  512
#define NVG_MAX_FONTIMAGE_SIZE   2048
#define NVG_MAX_FONTIMAGES       1

#define NVG_INIT_COMMANDS_SIZE 256
#define NVG_INIT_POINTS_SIZE 128
#define NVG_INIT_PATHS_SIZE 16
#define NVG_INIT_TEXTS_SIZE 16
#define NVG_INIT_VERTS_SIZE 256
#define NVG_MAX_STATES 128
#define NVG_INIT_DASHES_SIZE 8

#define NVG_KAPPA90 0.5522847493f	// Length proportional to radius of a cubic bezier handle for 90deg arcs.

#define NVG_COUNTOF(arr) (sizeof(arr) / sizeof(0[arr]))

#define NVG_CMD_DEBUG(...)  // printf(__VA_ARGS__)
#define NVG_COLORF2I(val) (int(val * 0xFF) & 0xFF)

namespace lynx {
namespace nanovg {

enum NVGcommands {
	NVG_MOVETO = 0,
	NVG_LINETO = 1,
	NVG_BEZIERTO = 2,
	NVG_CLOSE = 3,
	NVG_WINDING = 4,
};

enum NVGpointFlags
{
	NVG_PT_CORNER = 0x01,
	NVG_PT_LEFT = 0x02,
	NVG_PT_BEVEL = 0x04,
	NVG_PR_INNERBEVEL = 0x08,
};

struct NVGclip {
    int start, end, ver;
    bool evenodd;
};

struct NVGstate {
	NVGcompositeOperationState compositeOperation;
	int shapeAntiAlias;
	NVGpaint fill;
	NVGpaint stroke;
	float strokeWidth;
	float miterLimit;
	int lineJoin;
	int lineCap;
	float alpha;
	float xform[6];
	NVGscissor scissor;
	float fontSize;
	float letterSpacing;
	float lineHeight;
	float fontBlur;
	int textAlign;
	int fontId;
	int dashStart, dashLen;
	NVGShadow shadow;
	// text weight, italic, transform etc.
	unsigned short fontWSV;
    int clipCount;
    float lineDashOffset;
};
typedef struct NVGstate NVGstate;

struct NVGpoint {
	float x,y;
	float dx, dy;
	float len;
	float dmx, dmy;
	unsigned char flags;
};
typedef struct NVGpoint NVGpoint;

struct NVGpathCache {
	NVGpoint* points;
	int npoints;
	int cpoints;
	NVGpath* paths;
	int npaths;
	int cpaths;
	NVGvertex* verts;
	int nverts;
	int cverts;
	float bounds[4];
    float* dashs;
    int ndashs;
    int cdashs;
    NVGvertex* txtverts;
    int ntxtverts;
    int ctxtverts;
    int txtopts;
};
typedef struct NVGpathCache NVGpathCache;

struct NVGBackups {
    template<typename S>
    struct Item {
        S* items;
        int citems, nitems, ver;
    };
    Item<float> paths;
    Item<float> clipPaths;
    Item<NVGclip> clips;
};

#define MAX_GRIMG_COUNT 25
struct GradientImages {
    int imgArray[MAX_GRIMG_COUNT];
    unsigned short curCount, curIndex;
};

struct NVGcontext {
	NVGparams params;
	float* commands = nullptr;
	int ccommands = 0;
	int ncommands = 0;
	int commandver = 0;
	float commandx = 0, commandy = 0;
	NVGstate states[NVG_MAX_STATES];
	int nstates = 0;
	NVGpathCache* cache = 0;
	float tessTol = 0;
	float distTol = 0;
	float fringeWidth = 0;
	float devicePxRatio = 0;
	struct FONScontext fs;
	int fontImage = 0;
	int emojiImage = 0;
	int drawCallCount = 0;
	int fillTriCount = 0;
	int strokeTriCount = 0;
	int textTriCount = 0;
    NVGBackups backups;
	bool addClipsBeforeNext = 0;
    GradientImages gradientImages;
};

static float nvg__sqrtf(float a) { return sqrtf(a); }
static float nvg__modf(float a, float b) { return fmodf(a, b); }
static float nvg__sinf(float a) { return sinf(a); }
static float nvg__cosf(float a) { return cosf(a); }
static float nvg__tanf(float a) { return tanf(a); }
static float nvg__atan2f(float a,float b) { return atan2f(a, b); }
static float nvg__acosf(float a) { return acosf(a); }

static int nvg__mini(int a, int b) { return a < b ? a : b; }
static int nvg__maxi(int a, int b) { return a > b ? a : b; }
static int nvg__clampi(int a, int mn, int mx) { return a < mn ? mn : (a > mx ? mx : a); }
static float nvg__minf(float a, float b) { return a < b ? a : b; }
static float nvg__maxf(float a, float b) { return a > b ? a : b; }
static float nvg__absf(float a) { return a >= 0.0f ? a : -a; }
static float nvg__signf(float a) { return a >= 0.0f ? 1.0f : -1.0f; }
static float nvg__clampf(float a, float mn, float mx) { return a < mn ? mn : (a > mx ? mx : a); }
static float nvg__cross(float dx0, float dy0, float dx1, float dy1) { return dx1*dy0 - dx0*dy1; }

static float nvg__normalize(float *x, float* y)
{
	float d = nvg__sqrtf((*x)*(*x) + (*y)*(*y));
	if (d > 1e-6f) {
		float id = 1.0f / d;
		*x *= id;
		*y *= id;
	}
	return d;
}


static void nvg__deletePathCache(NVGpathCache* c)
{
	if (c == NULL) return;
	if (c->points != NULL) free(c->points);
	if (c->paths != NULL) free(c->paths);
	if (c->verts != NULL) free(c->verts);
    if (c->dashs != NULL) free(c->dashs);
    if (c->txtverts != NULL) free(c->txtverts);
	free(c);
}

static NVGpathCache* nvg__allocPathCache(void)
{
	NVGpathCache* c = (NVGpathCache*)malloc(sizeof(NVGpathCache));
	if (c == NULL) goto error;
	memset(c, 0, sizeof(NVGpathCache));

	c->points = (NVGpoint*)malloc(sizeof(NVGpoint)*NVG_INIT_POINTS_SIZE);
	if (!c->points) goto error;
	c->npoints = 0;
	c->cpoints = NVG_INIT_POINTS_SIZE;

	c->paths = (NVGpath*)malloc(sizeof(NVGpath)*NVG_INIT_PATHS_SIZE);
	if (!c->paths) goto error;
	c->npaths = 0;
	c->cpaths = NVG_INIT_PATHS_SIZE;

	c->verts = (NVGvertex*)malloc(sizeof(NVGvertex)*NVG_INIT_VERTS_SIZE);
	if (!c->verts) goto error;
	c->nverts = 0;
	c->cverts = NVG_INIT_VERTS_SIZE;

    c->dashs = (float*)malloc(sizeof(float)*NVG_INIT_DASHES_SIZE);
    if (!c->dashs) goto error;
    c->ndashs = 0;
    c->cdashs = NVG_INIT_DASHES_SIZE;

    c->txtverts = (NVGvertex*)malloc(sizeof(NVGvertex)*NVG_INIT_VERTS_SIZE);
    if (!c->txtverts) goto error;
    c->ntxtverts = 0;
    c->ctxtverts = NVG_INIT_VERTS_SIZE;

	return c;
error:
	nvg__deletePathCache(c);
	return NULL;
}

static void nvg__setDevicePixelRatio(NVGcontext* ctx, float ratio)
{
	ctx->tessTol = 0.25f / ratio;
	ctx->distTol = 0.01f / ratio;
	ctx->fringeWidth = 1.0f / ratio;
	ctx->devicePxRatio = ratio;
}

static NVGcompositeOperationState nvg__compositeOperationState(int op)
{
	int sfactor, dfactor;

	if (op == NVG_SOURCE_OVER)
	{
		sfactor = NVG_ONE;
		dfactor = NVG_ONE_MINUS_SRC_ALPHA;
	}
	else if (op == NVG_SOURCE_IN)
	{
		sfactor = NVG_DST_ALPHA;
		dfactor = NVG_ZERO;
	}
	else if (op == NVG_SOURCE_OUT)
	{
		sfactor = NVG_ONE_MINUS_DST_ALPHA;
		dfactor = NVG_ZERO;
	}
	else if (op == NVG_ATOP)
	{
		sfactor = NVG_DST_ALPHA;
		dfactor = NVG_ONE_MINUS_SRC_ALPHA;
	}
	else if (op == NVG_DESTINATION_OVER)
	{
		sfactor = NVG_ONE_MINUS_DST_ALPHA;
		dfactor = NVG_ONE;
	}
	else if (op == NVG_DESTINATION_IN)
	{
		sfactor = NVG_ZERO;
		dfactor = NVG_SRC_ALPHA;
	}
	else if (op == NVG_DESTINATION_OUT)
	{
		sfactor = NVG_ZERO;
		dfactor = NVG_ONE_MINUS_SRC_ALPHA;
	}
	else if (op == NVG_DESTINATION_ATOP)
	{
		sfactor = NVG_ONE_MINUS_DST_ALPHA;
		dfactor = NVG_SRC_ALPHA;
	}
	else if (op == NVG_LIGHTER)
	{
		sfactor = NVG_ONE;
		dfactor = NVG_ONE;
	}
	else if (op == NVG_COPY)
	{
		sfactor = NVG_ONE;
		dfactor = NVG_ZERO;
	}
	else if (op == NVG_XOR)
	{
		sfactor = NVG_ONE_MINUS_DST_ALPHA;
		dfactor = NVG_ONE_MINUS_SRC_ALPHA;
	}
	else
	{
		sfactor = NVG_ONE;
		dfactor = NVG_ZERO;
	}

	NVGcompositeOperationState state;
	state.srcRGB = sfactor;
	state.dstRGB = dfactor;
	state.srcAlpha = sfactor;
	state.dstAlpha = dfactor;
	return state;
}

static NVGstate* nvg__getState(NVGcontext* ctx)
{
	return &ctx->states[ctx->nstates-1];
}

inline void nvg__autoClearPathCache(NVGcontext* ctx)
{
    if (ctx->cache->npoints > 0) {
        ctx->cache->npoints = 0;
        ctx->cache->npaths = 0;
    }
}

template<typename S> inline void nvg__doBackupItemInit(NVGBackups::Item<S>& bk)
{
    bk.items = nullptr;
    bk.citems = bk.nitems = 0;
    bk.ver = 0;
}

template<typename S> inline void nvg__doBackupItemFree(NVGBackups::Item<S>& bk)
{
    if (bk.items != nullptr) {
        free(bk.items);
    }
    nvg__doBackupItemInit(bk);
}

template<typename S> inline bool nvg__doBackupItem(NVGBackups::Item<S>& bk, const NVGBackups::Item<S>& src, int curVenSkipLen = -1)
{
    if (src.nitems <= 0) {
        bk.ver = src.ver;
        return true;
    }

    int countToCopy = 0;
    if (bk.ver == src.ver && curVenSkipLen >= 0 && curVenSkipLen <= src.nitems) {
        countToCopy = src.nitems - curVenSkipLen;
    } else {
        countToCopy = src.nitems;
    }
    if (countToCopy <= 0) {
        bk.ver = src.ver;
        return true;
    }

    const int newCount = bk.nitems + countToCopy;
    if (bk.citems < newCount) {
        int countToAlloc = src.citems;
        if (countToAlloc < newCount) {
            countToAlloc = newCount;
        }

        S* newItems = (S*)realloc(bk.items, sizeof(S) * countToAlloc);
        if (newItems != nullptr) {
            bk.items = newItems;
            bk.citems = countToAlloc;
        }
        if (bk.citems < newCount) {
            return false;
        }
    }

    memcpy(bk.items + bk.nitems, src.items + src.nitems - countToCopy, sizeof(S) * countToCopy);
    bk.nitems += countToCopy;
    bk.ver = src.ver;
    return true;
}

void nvg__InitBackups(NVGcontext* ctx)
{
    nvg__doBackupItemInit(ctx->backups.paths);
    nvg__doBackupItemInit(ctx->backups.clipPaths);
    nvg__doBackupItemInit(ctx->backups.clips);
}

void nvg__FreeBackups(NVGcontext* ctx)
{
    nvg__doBackupItemFree(ctx->backups.paths);
    nvg__doBackupItemFree(ctx->backups.clipPaths);
    nvg__doBackupItemFree(ctx->backups.clips);
}

NVGcontext* nvgCreateInternal(NVGparams* params)
{
	NVGcontext* ctx = new NVGcontext();
	memset(&ctx->gradientImages, 0, sizeof(ctx->gradientImages));

	ctx->params = *params;

	ctx->commands = (float*)malloc(sizeof(float)*NVG_INIT_COMMANDS_SIZE);
	if (!ctx->commands) goto error;
	ctx->ncommands = 0;
	ctx->ccommands = NVG_INIT_COMMANDS_SIZE;
	ctx->commandver = 0;

	ctx->cache = nvg__allocPathCache();
	if (ctx->cache == NULL) goto error;

	nvgSave(ctx);
	nvgReset(ctx);

	nvg__setDevicePixelRatio(ctx, 1.0f);

	if (ctx->params.renderCreate(ctx->params.userPtr) == 0) goto error;

	// Init font rendering

	return ctx;

error:
	delete ctx;
	return 0;
}

NVGparams* nvgInternalParams(NVGcontext* ctx)
{
    return &ctx->params;
}

static inline int nvg__autoNewOrUpdateFontImage(NVGcontext* ctx, bool isTrueColor, bool checkSizeChange)
{
    int& fontImg = (isTrueColor ? ctx->emojiImage : ctx->fontImage);
    if (checkSizeChange) {
        struct FONScacheTex& cacheTex = (isTrueColor ? ctx->fs.texTrueColor : ctx->fs.texNormal);
        if (cacheTex.isSizeChanged) {
            cacheTex.isSizeChanged = false;
            if (fontImg) {
                nvgDeleteImage(ctx, fontImg);
                fontImg = 0;
            }
        }
    }
    if (fontImg == 0) {
        const NVGtexture type = (isTrueColor ? NVG_TEXTURE_RGBA : NVG_TEXTURE_ALPHA);
        struct FONScacheTex& cacheTex = (isTrueColor ? ctx->fs.texTrueColor : ctx->fs.texNormal);
        fontImg = ctx->params.renderCreateTexture(ctx->params.userPtr, type, cacheTex.atlas.width, cacheTex.atlas.height, 0, NULL);
    }
    return fontImg;
}

inline void nvg__deleteFontImages(NVGcontext* ctx)
{
    if (ctx->fontImage != 0) {
        nvgDeleteImage(ctx, ctx->fontImage);
        ctx->fontImage = 0;
    }

    if (ctx->emojiImage != 0) {
        nvgDeleteImage(ctx, ctx->emojiImage);
        ctx->emojiImage = 0;
    }
}

void nvgDeleteInternal(NVGcontext* ctx)
{
	if (ctx == NULL) return;
	if (ctx->commands != NULL) free(ctx->commands);
	if (ctx->cache != NULL) nvg__deletePathCache(ctx->cache);

    nvg__FreeBackups(ctx);

    nvg__deleteFontImages(ctx);

    if (ctx->gradientImages.curCount > 0) {
        for (int i = 0; i < ctx->gradientImages.curCount; ++i) {
            nvgDeleteImage(ctx, ctx->gradientImages.imgArray[i]);
        }
        memset(&ctx->gradientImages, 0, sizeof(ctx->gradientImages));
    }

	if (ctx->params.renderDelete != NULL)
		ctx->params.renderDelete(ctx->params.userPtr);
}

void nvgBeginFrame(NVGcontext* ctx, float windowWidth, float windowHeight, float devicePixelRatio)
{
/*	printf("Tris: draws:%d  fill:%d  stroke:%d  text:%d  TOT:%d\n",
		ctx->drawCallCount, ctx->fillTriCount, ctx->strokeTriCount, ctx->textTriCount,
		ctx->fillTriCount+ctx->strokeTriCount+ctx->textTriCount);*/

	ctx->nstates = 0;
    nvg__InitBackups(ctx);

	nvgSave(ctx);
	nvgReset(ctx);

	nvg__setDevicePixelRatio(ctx, devicePixelRatio);

	ctx->params.renderViewport(ctx->params.userPtr, windowWidth, windowHeight, devicePixelRatio);

	ctx->drawCallCount = 0;
	ctx->fillTriCount = 0;
	ctx->strokeTriCount = 0;
	ctx->textTriCount = 0;
}

void nvgCancelFrame(NVGcontext* ctx)
{
	ctx->params.renderCancel(ctx->params.userPtr);
}

void nvgEndFrame(NVGcontext* ctx)
{
	ctx->params.renderFlush(ctx->params.userPtr);
}

NVGcolor nvgRGB(unsigned char r, unsigned char g, unsigned char b)
{
	return nvgRGBA(r,g,b,255);
}

NVGcolor nvgRGBf(float r, float g, float b)
{
	return nvgRGBAf(r,g,b,1.0f);
}

NVGcolor nvgRGBA(unsigned char r, unsigned char g, unsigned char b, unsigned char a)
{
	NVGcolor color;
	// Use longer initialization to suppress warning.
	color.r = r / 255.0f;
	color.g = g / 255.0f;
	color.b = b / 255.0f;
	color.a = a / 255.0f;
	return color;
}

NVGcolor nvgRGBAf(float r, float g, float b, float a)
{
	NVGcolor color;
	// Use longer initialization to suppress warning.
	color.r = r;
	color.g = g;
	color.b = b;
	color.a = a;
	return color;
}

NVGcolor nvgTransRGBA(NVGcolor c, unsigned char a)
{
	c.a = a / 255.0f;
	return c;
}

NVGcolor nvgTransRGBAf(NVGcolor c, float a)
{
	c.a = a;
	return c;
}

NVGcolor nvgLerpRGBA(NVGcolor c0, NVGcolor c1, float u)
{
	int i;
	float oneminu;
	NVGcolor cint = {{{0}}};

	u = nvg__clampf(u, 0.0f, 1.0f);
	oneminu = 1.0f - u;
	for( i = 0; i <4; i++ )
	{
		cint.rgba[i] = c0.rgba[i] * oneminu + c1.rgba[i] * u;
	}

	return cint;
}

NVGcolor nvgHSL(float h, float s, float l)
{
	return nvgHSLA(h,s,l,255);
}

static float nvg__hue(float h, float m1, float m2)
{
	if (h < 0) h += 1;
	if (h > 1) h -= 1;
	if (h < 1.0f/6.0f)
		return m1 + (m2 - m1) * h * 6.0f;
	else if (h < 3.0f/6.0f)
		return m2;
	else if (h < 4.0f/6.0f)
		return m1 + (m2 - m1) * (2.0f/3.0f - h) * 6.0f;
	return m1;
}

NVGcolor nvgHSLA(float h, float s, float l, unsigned char a)
{
	float m1, m2;
	NVGcolor col;
	h = nvg__modf(h, 1.0f);
	if (h < 0.0f) h += 1.0f;
	s = nvg__clampf(s, 0.0f, 1.0f);
	l = nvg__clampf(l, 0.0f, 1.0f);
	m2 = l <= 0.5f ? (l * (1 + s)) : (l + s - l * s);
	m1 = 2 * l - m2;
	col.r = nvg__clampf(nvg__hue(h + 1.0f/3.0f, m1, m2), 0.0f, 1.0f);
	col.g = nvg__clampf(nvg__hue(h, m1, m2), 0.0f, 1.0f);
	col.b = nvg__clampf(nvg__hue(h - 1.0f/3.0f, m1, m2), 0.0f, 1.0f);
	col.a = a/255.0f;
	return col;
}

void nvgTransformIdentity(float* t)
{
	t[0] = 1.0f; t[1] = 0.0f;
	t[2] = 0.0f; t[3] = 1.0f;
	t[4] = 0.0f; t[5] = 0.0f;
}

void nvgTransformTranslate(float* t, float tx, float ty)
{
	t[0] = 1.0f; t[1] = 0.0f;
	t[2] = 0.0f; t[3] = 1.0f;
	t[4] = tx; t[5] = ty;
}

void nvgTransformScale(float* t, float sx, float sy)
{
	t[0] = sx; t[1] = 0.0f;
	t[2] = 0.0f; t[3] = sy;
	t[4] = 0.0f; t[5] = 0.0f;
}

void nvgTransformRotate(float* t, float a)
{
	float cs = nvg__cosf(a), sn = nvg__sinf(a);
	t[0] = cs; t[1] = sn;
	t[2] = -sn; t[3] = cs;
	t[4] = 0.0f; t[5] = 0.0f;
}

void nvgTransformSkewX(float* t, float a)
{
	t[0] = 1.0f; t[1] = 0.0f;
	t[2] = nvg__tanf(a); t[3] = 1.0f;
	t[4] = 0.0f; t[5] = 0.0f;
}

void nvgTransformSkewY(float* t, float a)
{
	t[0] = 1.0f; t[1] = nvg__tanf(a);
	t[2] = 0.0f; t[3] = 1.0f;
	t[4] = 0.0f; t[5] = 0.0f;
}

void nvgTransformMultiply(float* t, const float* s)
{
	float t0 = t[0] * s[0] + t[1] * s[2];
	float t2 = t[2] * s[0] + t[3] * s[2];
	float t4 = t[4] * s[0] + t[5] * s[2] + s[4];
	t[1] = t[0] * s[1] + t[1] * s[3];
	t[3] = t[2] * s[1] + t[3] * s[3];
	t[5] = t[4] * s[1] + t[5] * s[3] + s[5];
	t[0] = t0;
	t[2] = t2;
	t[4] = t4;
}

void nvgTransformPremultiply(float* t, const float* s)
{
	float s2[6];
	memcpy(s2, s, sizeof(float)*6);
	nvgTransformMultiply(s2, t);
	memcpy(t, s2, sizeof(float)*6);
}

int nvgTransformInverse(float* inv, const float* t)
{
	double invdet, det = (double)t[0] * t[3] - (double)t[2] * t[1];
	if (det > -1e-6 && det < 1e-6) {
		nvgTransformIdentity(inv);
		return 0;
	}
	invdet = 1.0 / det;
	inv[0] = (float)(t[3] * invdet);
	inv[2] = (float)(-t[2] * invdet);
	inv[4] = (float)(((double)t[2] * t[5] - (double)t[3] * t[4]) * invdet);
	inv[1] = (float)(-t[1] * invdet);
	inv[3] = (float)(t[0] * invdet);
	inv[5] = (float)(((double)t[1] * t[4] - (double)t[0] * t[5]) * invdet);
	return 1;
}

void nvgTransformPoint(float* dx, float* dy, const float* t, float sx, float sy)
{
	*dx = sx*t[0] + sy*t[2] + t[4];
	*dy = sx*t[1] + sy*t[3] + t[5];
}

float nvgDegToRad(float deg)
{
	return deg / 180.0f * NVG_PI;
}

float nvgRadToDeg(float rad)
{
	return rad / NVG_PI * 180.0f;
}

static void nvg__setPaintColor(NVGpaint* p, NVGcolor color)
{
	memset(p, 0, sizeof(*p));
	nvgTransformIdentity(p->xform);
	p->radius = 0.0f;
	p->feather = 1.0f;
	p->innerColor = color;
	p->outerColor = color;
	p->type = NVG_PAINT_DEFAULT;
}

// Backup the current path. Keep only the latest backup.
void nvgBackupPath(NVGcontext* ctx)
{
    // clear old backups
    ctx->backups.paths.nitems = 0;

    // backup path from ctx
    const NVGBackups::Item<float> src = {
        .items = ctx->commands, .citems = ctx->ccommands, .nitems = ctx->ncommands, .ver = ctx->commandver,
    };
    nvg__doBackupItem(ctx->backups.paths, src);
}

bool nvg__backupClipPath(NVGcontext* ctx, bool evenOdd)
{
    auto& clips = ctx->backups.clips;
    auto& clipPaths = ctx->backups.clipPaths;

    int skipLen = -1, newStart = 0;
    const NVGclip* lastClip = nullptr;
    if (clips.nitems) {
        lastClip = &clips.items[clips.nitems - 1];
        if (lastClip->ver == ctx->commandver) {
            skipLen = lastClip->end - lastClip->start;
            newStart = lastClip->start;
        } else {
            newStart = lastClip->end;
        }
    }

    const NVGBackups::Item<float> src = {
        .items = ctx->commands, .citems = ctx->ccommands, .nitems = ctx->ncommands, .ver = ctx->commandver,
    };

    if (!nvg__doBackupItem(clipPaths, src, skipLen)) {
        return false;
    }
    NVGclip newClip = {
        .start = newStart, .end = clipPaths.nitems, .ver = ctx->commandver, .evenodd = evenOdd,
    };

    if (lastClip != nullptr && memcmp(lastClip, &newClip, sizeof(newClip)) == 0) {
        // all equal, do not need to add
        return false;
    }

    const NVGBackups::Item<NVGclip> clipSrc = {
        .items = &newClip, .citems = clips.citems + 20, .nitems = 1, .ver = newClip.ver,
    };
    if (!nvg__doBackupItem(clips, clipSrc)) {
        clipPaths.nitems = newClip.start;
        return false;
    }
    return true;
}

// Restore from the latest backup of path if exists
void nvgRestorePath(NVGcontext* ctx)
{
    nvg__autoClearPathCache(ctx);

    auto& bk = ctx->backups.paths;
    if (bk.nitems > ctx->ccommands) {
        // error
        return;
    }

    ctx->ncommands = bk.nitems;
    ctx->commandver = bk.ver;
    if (bk.nitems > 0) {
        memcpy(ctx->commands, bk.items, sizeof(float) * bk.nitems);
    }
    bk.nitems = 0;
    bk.ver = 0;
}

// State handling
void nvgSave(NVGcontext* ctx)
{
  NVG_CMD_DEBUG("ctx.save();\r\n");

  if (ctx->nstates >= NVG_MAX_STATES) {
    KRYPTON_LOGE("nstates out of NVG_MAX_STATES: ") << NVG_MAX_STATES;
		return;
  }
	if (ctx->nstates > 0)
		memcpy(&ctx->states[ctx->nstates], &ctx->states[ctx->nstates-1], sizeof(NVGstate));
	ctx->nstates++;
}

void nvgReset(NVGcontext* ctx)
{
	NVGstate* state = nvg__getState(ctx);
	memset(state, 0, sizeof(*state));

	nvg__setPaintColor(&state->fill, nvgRGBA(0,0,0,255));
	nvg__setPaintColor(&state->stroke, nvgRGBA(0,0,0,255));
	state->compositeOperation = nvg__compositeOperationState(NVG_SOURCE_OVER);
	state->shapeAntiAlias = 1;
	state->strokeWidth = 1.0f;
	state->miterLimit = 10.0f;
	state->lineCap = NVG_BUTT;
	state->lineJoin = NVG_MITER;
	state->alpha = 1.0f;
	nvgTransformIdentity(state->xform);

	state->scissor.extent[0] = -1.0f;
	state->scissor.extent[1] = -1.0f;

	state->fontSize = 16.0f;
	state->letterSpacing = 0.0f;
	state->lineHeight = 1.0f;
	state->fontBlur = 0.0f;
	state->textAlign = NVG_ALIGN_LEFT | NVG_ALIGN_BASELINE;
	state->fontId = 0;
	state->dashStart = state->dashLen = 0;
	state->fontWSV = 0;
    state->clipCount = 0;
    state->lineDashOffset = 0;
}

// State setting
void nvgShapeAntiAlias(NVGcontext* ctx, int enabled)
{
	NVGstate* state = nvg__getState(ctx);
	state->shapeAntiAlias = enabled;
}

void nvgStrokeWidth(NVGcontext* ctx, float width)
{
    NVG_CMD_DEBUG("ctx.lineWidth = %.2f;\r\n", width);

	NVGstate* state = nvg__getState(ctx);
	state->strokeWidth = width;
}

float nvgGetStrokeWidth(NVGcontext* ctx) {
  NVGstate* state = nvg__getState(ctx);
  return state->strokeWidth;
}

void nvgMiterLimit(NVGcontext* ctx, float limit)
{
    NVG_CMD_DEBUG("ctx.miterLimit = %.2f;\r\n", limit);

    NVGstate* state = nvg__getState(ctx);
	state->miterLimit = limit;
}

float nvgGetMiterLimit(NVGcontext* ctx) {
	NVGstate* state = nvg__getState(ctx);
	return state->miterLimit;
}

void nvgLineDashOffset(NVGcontext* ctx, float offset) {
	NVGstate* state = nvg__getState(ctx);
	state->lineDashOffset = offset;
}

float nvgGetLineDashOffset(NVGcontext* ctx) {
	NVGstate* state = nvg__getState(ctx);
	return state->lineDashOffset;
}


void nvgLineCap(NVGcontext* ctx, int cap)
{
    NVG_CMD_DEBUG("ctx.lineCap = '%s';\r\n",(cap==2?"square":(cap?"round":"butt")));

	NVGstate* state = nvg__getState(ctx);
	state->lineCap = cap;
}

int nvgGetLineCap(NVGcontext* ctx) {
  NVGstate* state = nvg__getState(ctx);
  return state->lineCap;
}

void nvgLineJoin(NVGcontext* ctx, int join)
{
    NVG_CMD_DEBUG("ctx.lineJoin = '%s';\r\n",(join==2?"bevel":(join?"round":"miter")));

	NVGstate* state = nvg__getState(ctx);
	state->lineJoin = join;
}

int nvgGetLineJoin(NVGcontext* ctx) {
	NVGstate* state = nvg__getState(ctx);
	return state->lineJoin;
}

inline void nvg__autoClearLineDashData(NVGcontext* ctx) {
	if (ctx->cache->ndashs <= 0) {
		return;
	}

	int dashCount = 0;
	for (int i = 0; i < ctx->nstates; ++i) {
		NVGstate& curState = ctx->states[i];
		if (curState.dashLen > 0) {
			if (dashCount < curState.dashStart + curState.dashLen) {
				dashCount = curState.dashStart + curState.dashLen;
			}
		}
	}
    ctx->cache->ndashs = dashCount;
}

void nvgLineDash(NVGcontext* ctx, const float *floats, uint32_t count)
{
	NVGstate* state = nvg__getState(ctx);
	state->dashStart = state->dashLen = 0;
	nvg__autoClearLineDashData(ctx);
	if (floats == nullptr || count == 0) {
		return;
	}

	NVGpathCache& cache = *ctx->cache;
	if (cache.ndashs + count > cache.cdashs) {
		const int cdashes = cache.ndashs + count + cache.cdashs / 2;
		float* newDashes = (float*)realloc(cache.dashs, sizeof(float)*cdashes);
		if (newDashes == NULL) return;
		cache.dashs = newDashes;
		cache.cdashs = cdashes;
	}
	memcpy(cache.dashs + cache.ndashs, floats, count * sizeof(float));

	state->dashStart = cache.ndashs;
	state->dashLen = count;
	cache.ndashs += count;
}

void nvgGlobalAlpha(NVGcontext* ctx, float alpha)
{
    NVG_CMD_DEBUG("ctx.globalAlpha = %.2f;\r\n",alpha);

	NVGstate* state = nvg__getState(ctx);
	state->alpha = alpha;
}

float nvgGetGlobalAlpha(NVGcontext *ctx)
{
	NVGstate* state = nvg__getState(ctx);
	return state->alpha;
}

void nvgTransform(NVGcontext* ctx, float a, float b, float c, float d, float e, float f)
{
    NVG_CMD_DEBUG("ctx.transform(%.2f,%.2f,%.2f,%.2f,%.2f,%.2f);\r\n",a, b, c, d, e, f);

    NVGstate* state = nvg__getState(ctx);
	float t[6] = { a, b, c, d, e, f };
	nvgTransformPremultiply(state->xform, t);
}

void nvgResetTransform(NVGcontext* ctx)
{
	NVGstate* state = nvg__getState(ctx);
	nvgTransformIdentity(state->xform);
}

void nvgTranslate(NVGcontext* ctx, float x, float y)
{
    NVG_CMD_DEBUG("ctx.translate(%.2f,%.2f);\r\n",x, y);

	NVGstate* state = nvg__getState(ctx);
	float t[6];
	nvgTransformTranslate(t, x,y);
	nvgTransformPremultiply(state->xform, t);
}

void nvgRotate(NVGcontext* ctx, float angle)
{
    NVG_CMD_DEBUG("ctx.rotate(%.2f);\r\n",angle);

    NVGstate* state = nvg__getState(ctx);
	float t[6];
	nvgTransformRotate(t, angle);
	nvgTransformPremultiply(state->xform, t);
}

void nvgSkewX(NVGcontext* ctx, float angle)
{
	NVGstate* state = nvg__getState(ctx);
	float t[6];
	nvgTransformSkewX(t, angle);
	nvgTransformPremultiply(state->xform, t);
}

void nvgSkewY(NVGcontext* ctx, float angle)
{
	NVGstate* state = nvg__getState(ctx);
	float t[6];
	nvgTransformSkewY(t, angle);
	nvgTransformPremultiply(state->xform, t);
}

void nvgScale(NVGcontext* ctx, float x, float y)
{
    NVG_CMD_DEBUG("ctx.scale(%.2f, %.2f);\r\n",x, y);

    NVGstate* state = nvg__getState(ctx);
	float t[6];
	nvgTransformScale(t, x,y);
	nvgTransformPremultiply(state->xform, t);
}

void nvgCurrentTransform(NVGcontext* ctx, float* xform)
{
	NVGstate* state = nvg__getState(ctx);
	if (xform == NULL) return;
	memcpy(xform, state->xform, sizeof(float)*6);
}

void nvgStrokeColor(NVGcontext* ctx, NVGcolor color)
{
    NVG_CMD_DEBUG("ctx.strokeStyle='rgb(%d, %d, %d)'\r\n", NVG_COLORF2I(color.r), NVG_COLORF2I(color.g), NVG_COLORF2I(color.b));

    NVGstate* state = nvg__getState(ctx);
	nvg__setPaintColor(&state->stroke, color);
}

void nvgStrokePaint(NVGcontext* ctx, NVGpaint paint)
{
	NVGstate* state = nvg__getState(ctx);
	state->stroke = paint;
	nvgTransformMultiply(state->stroke.xform, state->xform);
}

void nvgFillColor(NVGcontext* ctx, NVGcolor color)
{
    NVG_CMD_DEBUG("ctx.fillStyle='rgb(%d, %d, %d)'\r\n", NVG_COLORF2I(color.r), NVG_COLORF2I(color.g), NVG_COLORF2I(color.b));

    NVGstate* state = nvg__getState(ctx);
	nvg__setPaintColor(&state->fill, color);
}

void nvgFillPaint(NVGcontext* ctx, NVGpaint paint)
{
	NVGstate* state = nvg__getState(ctx);
	state->fill = paint;
	nvgTransformMultiply(state->fill.xform, state->xform);
}

int nvgCreateImageRGBA(NVGcontext* ctx, int w, int h, int imageFlags, const unsigned char* data)
{
	return ctx->params.renderCreateTexture(ctx->params.userPtr, NVG_TEXTURE_RGBA, w, h, imageFlags, data);
}

void nvgUpdateImage(NVGcontext* ctx, int image, const unsigned char* data)
{
	int w, h;
	ctx->params.renderGetTextureSize(ctx->params.userPtr, image, &w, &h);
	ctx->params.renderUpdateTexture(ctx->params.userPtr, image, 0,0, w,h, data);
}

void nvgImageSize(NVGcontext* ctx, int image, int* w, int* h)
{
	ctx->params.renderGetTextureSize(ctx->params.userPtr, image, w, h);
}

void nvgDeleteImage(NVGcontext* ctx, int image)
{
	ctx->params.renderDeleteTexture(ctx->params.userPtr, image);
}

inline uint32_t nvg__MixColor(uint32_t color0, uint32_t mul0, uint32_t color1, uint32_t mul1, uint32_t div) {
    uint32_t result = 0;
    u_char* dst = (u_char*)&result;
    const u_char *src0 = (const u_char*)&color0, *src1 = (const u_char*)&color1;
    for (u_char i = 0; i < 4; ++i) {
        *dst++ = (u_char)(((*src0++) * mul0 + (*src1++) * mul1) / div);
    }
    return result;
}

static bool nvg__autoFlushGradientTexture(NVGcontext* ctx, const GradientItems* otherItems, NVGpaint* p, bool reverse)
{
    const uint32_t gw = 100, mpos = 99;
    auto& imgs = ctx->gradientImages;

    int gradientImage = imgs.imgArray[imgs.curIndex];
    if (imgs.curCount <= imgs.curIndex) {
        gradientImage = imgs.imgArray[imgs.curIndex]
        = ctx->params.renderCreateTexture(ctx->params.userPtr, NVG_TEXTURE_RGBA, gw, 1, 0, NULL);
        if (gradientImage != 0) {
            imgs.curCount = imgs.curIndex + 1;
        }
    }
    if (gradientImage == 0) {
        return false;
    }

    const uint32_t first = reverse ? otherItems->count-1 : 0;
    const uint32_t last = reverse ? 0 : otherItems->count-1;
    uint32_t buffer[gw];
    uint32_t nextColor, curColor = otherItems->items[first].color;
    uint32_t curPos = 0, nextPos = 0;
    int i = 0, j = 0;
    for (; i < otherItems->count; ++i) {
        if (reverse) {
            const int index = otherItems->count - i - 1;
            nextPos = (1.0 - otherItems->items[index].pos) * mpos;
            nextColor = otherItems->items[index].color;
        } else {
            nextPos = otherItems->items[i].pos * mpos;
            nextColor = otherItems->items[i].color;
        }

        if (nextPos >= mpos) {
            nextPos = mpos;
        }
        if (nextPos > curPos) {
            for (; j < nextPos; ++j) {
                buffer[j] = nvg__MixColor(curColor, nextPos - j, nextColor, j - curPos, nextPos - curPos);
            }
        }
        curPos = nextPos;
        curColor = nextColor;
    }
    nextColor = otherItems->items[last].color;
    nextPos = gw;
    if (nextPos > curPos) {
        for (; j < nextPos; ++j) {
            buffer[j] = nvg__MixColor(curColor, nextPos - j, nextColor, j - curPos, nextPos - curPos);
        }
    }
    // final set
    buffer[0] = otherItems->items[first].color;
    buffer[mpos] = otherItems->items[last].color;

    ctx->params.renderUpdateTexture(ctx->params.userPtr, gradientImage, 0,0, gw,1, (const unsigned char*)buffer);
    p->image = gradientImage;
    imgs.curIndex = (imgs.curIndex + 1) % MAX_GRIMG_COUNT;

    return true;
}

inline NVGcolor nvg__colorFromABGR(uint32_t ABGR) {
    return nvgRGBA(ABGR & 0xff, (ABGR >> 8) & 0xff, (ABGR >> 16) & 0xff, (ABGR >> 24) & 0xff);
}

static void nvg__parseGradientItems(NVGcontext* ctx, const GradientItems* items, NVGpaint& p, bool reverse) {
	if (items == nullptr || items->count == 0) {
		return;
	}

	uint32_t innerColorVal = items->items[reverse ? items->count - 1 : 0].color;
	uint32_t outerColorVal = items->items[reverse ? 0 : items->count - 1].color;

	p.innerColor = nvg__colorFromABGR(innerColorVal);
	p.outerColor = nvg__colorFromABGR(outerColorVal);

	int cmpCount = 0;
	if (items->items[0].pos <= 1e-3) {
		++cmpCount;
	}
	if (items->count > 1 && items->items[items->count - 1].pos >= 1 - 1e-3) {
		++cmpCount;
	}

	if (items->count > cmpCount) {
		nvg__autoFlushGradientTexture(ctx, items, &p, reverse);
	}
}

NVGpaint nvgLinearGradient(NVGcontext* ctx,
								  float sx, float sy, float ex, float ey,
								  const GradientItems* items)
{
    NVG_CMD_DEBUG("ctx.createLinearGradient(%.2f,%.2f,%.2f,%.2f);\r\n",sx, sy, ex, ey);

    NVGpaint p;
	float dx, dy, d;
	const float large = 1e5;
	NVG_NOTUSED(ctx);
	memset(&p, 0, sizeof(p));

	// Calculate transform aligned to the line
	dx = ex - sx;
	dy = ey - sy;
	d = sqrtf(dx*dx + dy*dy);
	if (d > 0.0001f) {
		dx /= d;
		dy /= d;
	} else {
		dx = 0;
		dy = 1;
	}

    p.type = NVG_PAINT_LINEAR_GRADIENT;

	p.xform[0] = dy; p.xform[1] = -dx;
	p.xform[2] = dx; p.xform[3] = dy;
	p.xform[4] = sx - dx*large; p.xform[5] = sy - dy*large;

	p.extent[0] = large;
	p.extent[1] = large + d*0.5f;

	p.radius = 0.0f;

	p.feather = nvg__maxf(1.0f, d);

	nvg__parseGradientItems(ctx, items, p, false);

	return p;
}

NVGpaint nvgRadialGradient(NVGcontext* ctx,
								  float cx, float cy, float cx2, float cy2,
								  float inr, float outr,
								  const GradientItems* items)
{
    NVG_CMD_DEBUG("ctx.createRadialGradient(%.2f,%.2f,%.2f,%.2f,%.2f,%.2f);\r\n",cx, cy, inr, cx2, cy2, outr);

    NVGpaint p;
    NVG_NOTUSED(ctx);
    memset(&p, 0, sizeof(p));

    float r = (inr+outr)*0.5f;
	float f = (outr-inr);
    float absF = abs(f);

    const bool reverse = (f < 0.0);
    if (reverse) {
        // reverse all points
        float tmp = inr; inr = outr; outr = tmp;
        tmp = cx; cx = cx2; cx2 = tmp;
        tmp = cy; cy = cy2; cy2 = tmp;
    }

    p.type = NVG_PAINT_RADIAL_GRADIENT;

	nvgTransformIdentity(p.xform);
	p.xform[4] = cx;
	p.xform[5] = cy;

	p.extent[0] = r;
	p.extent[1] = r;

	p.radius = r;

    if ((abs(cx2 - cx) > 1e-3 || abs(cy2 - cy) > 1e-3)) {
        p.rgEx[0] = cx2 - cx;
        p.rgEx[1] = cy2 - cy;
        if (absF > 1e-3) {
	        p.rgEx[2] = f;
            p.xform[4] = (cx * outr - cx2 * inr) / absF;
            p.xform[5] = (cy * outr - cy2 * inr) / absF;
        } else {
	        p.rgEx[2] = 0.0;
		}
    }

	p.feather = nvg__maxf(1.0f, absF);

	nvg__parseGradientItems(ctx, items, p, reverse);

	return p;
}

NVGpaint nvgBoxGradient(NVGcontext* ctx,
							   float x, float y, float w, float h, float r, float f,
							   NVGcolor icol, NVGcolor ocol)
{
	NVGpaint p;
	NVG_NOTUSED(ctx);
	memset(&p, 0, sizeof(p));

    p.type = NVG_PAINT_BOX_GRADIENT;

	nvgTransformIdentity(p.xform);
	p.xform[4] = x+w*0.5f;
	p.xform[5] = y+h*0.5f;

	p.extent[0] = w*0.5f;
	p.extent[1] = h*0.5f;

	p.radius = r;

	p.feather = nvg__maxf(1.0f, f);

	p.innerColor = icol;
	p.outerColor = ocol;

	return p;
}


NVGpaint nvgImagePattern(NVGcontext* ctx,
								float cx, float cy, float w, float h, float angle,
								int image, int flags)
{
	NVGpaint p;
	NVG_NOTUSED(ctx);
	memset(&p, 0, sizeof(p));

    p.type = NVG_PAINT_IMAGE_PATTERNS;

	nvgTransformRotate(p.xform, angle);
	p.xform[4] = cx;
	p.xform[5] = cy;

	p.extent[0] = w;
	p.extent[1] = h;

	p.image = image;

	p.innerColor = p.outerColor = nvgRGBAf(1,1,1,1);
	p.imageFlags = flags;

	return p;
}

// Scissoring
void nvgScissor(NVGcontext* ctx, float x, float y, float w, float h)
{
	NVGstate* state = nvg__getState(ctx);

	w = nvg__maxf(0.0f, w);
	h = nvg__maxf(0.0f, h);

	nvgTransformIdentity(state->scissor.xform);
	state->scissor.xform[4] = x+w*0.5f;
	state->scissor.xform[5] = y+h*0.5f;
	nvgTransformMultiply(state->scissor.xform, state->xform);

	state->scissor.extent[0] = w*0.5f;
	state->scissor.extent[1] = h*0.5f;
}

static void nvg__isectRects(float* dst,
							float ax, float ay, float aw, float ah,
							float bx, float by, float bw, float bh)
{
	float minx = nvg__maxf(ax, bx);
	float miny = nvg__maxf(ay, by);
	float maxx = nvg__minf(ax+aw, bx+bw);
	float maxy = nvg__minf(ay+ah, by+bh);
	dst[0] = minx;
	dst[1] = miny;
	dst[2] = nvg__maxf(0.0f, maxx - minx);
	dst[3] = nvg__maxf(0.0f, maxy - miny);
}

void nvgIntersectScissor(NVGcontext* ctx, float x, float y, float w, float h)
{
	NVGstate* state = nvg__getState(ctx);
	float pxform[6], invxorm[6];
	float rect[4];
	float ex, ey, tex, tey;

	// If no previous scissor has been set, set the scissor as current scissor.
	if (state->scissor.extent[0] < 0) {
		nvgScissor(ctx, x, y, w, h);
		return;
	}

	// Transform the current scissor rect into current transform space.
	// If there is difference in rotation, this will be approximation.
	memcpy(pxform, state->scissor.xform, sizeof(float)*6);
	ex = state->scissor.extent[0];
	ey = state->scissor.extent[1];
	nvgTransformInverse(invxorm, state->xform);
	nvgTransformMultiply(pxform, invxorm);
	tex = ex*nvg__absf(pxform[0]) + ey*nvg__absf(pxform[2]);
	tey = ex*nvg__absf(pxform[1]) + ey*nvg__absf(pxform[3]);

	// Intersect rects.
	nvg__isectRects(rect, pxform[4]-tex,pxform[5]-tey,tex*2,tey*2, x,y,w,h);

	nvgScissor(ctx, rect[0], rect[1], rect[2], rect[3]);
}

void nvgResetScissor(NVGcontext* ctx)
{
	NVGstate* state = nvg__getState(ctx);
	memset(state->scissor.xform, 0, sizeof(state->scissor.xform));
	state->scissor.extent[0] = -1.0f;
	state->scissor.extent[1] = -1.0f;
}

// Global composite operation.
void nvgGlobalCompositeOperation(NVGcontext* ctx, int op)
{
	NVGstate* state = nvg__getState(ctx);
	state->compositeOperation = nvg__compositeOperationState(op);
}

static int nvg__ptEquals(float x1, float y1, float x2, float y2, float tol)
{
	float dx = x2 - x1;
	float dy = y2 - y1;
	return dx*dx + dy*dy < tol*tol;
}

static float nvg__distPtSeg(float x, float y, float px, float py, float qx, float qy)
{
	float pqx, pqy, dx, dy, d, t;
	pqx = qx-px;
	pqy = qy-py;
	dx = x-px;
	dy = y-py;
	d = pqx*pqx + pqy*pqy;
	t = pqx*dx + pqy*dy;
	if (d > 0) t /= d;
	if (t < 0) t = 0;
	else if (t > 1) t = 1;
	dx = px + t*pqx - x;
	dy = py + t*pqy - y;
	return dx*dx + dy*dy;
}

static void nvg__appendCommands(NVGcontext* ctx, float* vals, int nvals)
{
	NVGstate* state = nvg__getState(ctx);
	int i;

	if (ctx->ncommands+nvals > ctx->ccommands) {
		float* commands;
		int ccommands = ctx->ncommands+nvals + ctx->ccommands/2;
		commands = (float*)realloc(ctx->commands, sizeof(float)*ccommands);
		if (commands == NULL) return;
		ctx->commands = commands;
		ctx->ccommands = ccommands;
	}

	if ((int)vals[0] != NVG_CLOSE && (int)vals[0] != NVG_WINDING) {
		ctx->commandx = vals[nvals-2];
		ctx->commandy = vals[nvals-1];
	}
    // Subsequent prevention nvg__flattenPaths direct return
    // Fix the incorrect drawing of rect -> fill -> rect -> fil
    nvg__autoClearPathCache(ctx);

	// transform commands
	i = 0;
	while (i < nvals) {
		int cmd = (int)vals[i];
		switch (cmd) {
		case NVG_MOVETO:
			nvgTransformPoint(&vals[i+1],&vals[i+2], state->xform, vals[i+1],vals[i+2]);
			i += 3;
			break;
		case NVG_LINETO:
			nvgTransformPoint(&vals[i+1],&vals[i+2], state->xform, vals[i+1],vals[i+2]);
			i += 3;
			break;
		case NVG_BEZIERTO:
			nvgTransformPoint(&vals[i+1],&vals[i+2], state->xform, vals[i+1],vals[i+2]);
			nvgTransformPoint(&vals[i+3],&vals[i+4], state->xform, vals[i+3],vals[i+4]);
			nvgTransformPoint(&vals[i+5],&vals[i+6], state->xform, vals[i+5],vals[i+6]);
			i += 7;
			break;
		case NVG_CLOSE:
			i++;
			break;
		case NVG_WINDING:
			i += 2;
			break;
		default:
			i++;
		}
	}

	memcpy(&ctx->commands[ctx->ncommands], vals, nvals*sizeof(float));

	ctx->ncommands += nvals;
}


static void nvg__clearPathCache(NVGcontext* ctx)
{
	ctx->cache->npoints = 0;
	ctx->cache->npaths = 0;
}

static NVGpath* nvg__lastPath(NVGcontext* ctx)
{
	if (ctx->cache->npaths > 0)
		return &ctx->cache->paths[ctx->cache->npaths-1];
	return NULL;
}

static NVGpath* nvg__addPath(NVGcontext* ctx)
{
	NVGpath* path = nullptr;
	if (ctx->cache->npaths+1 > ctx->cache->cpaths) {
		NVGpath* paths;
		int cpaths = ctx->cache->npaths+1 + ctx->cache->cpaths/2;
		paths = (NVGpath*)realloc(ctx->cache->paths, sizeof(NVGpath)*cpaths);
		if (paths == NULL) return path;
		ctx->cache->paths = paths;
		ctx->cache->cpaths = cpaths;
	}
	path = &ctx->cache->paths[ctx->cache->npaths];
	memset(path, 0, sizeof(*path));
	path->first = ctx->cache->npoints;
	path->winding = path->realWinding = NVG_NONE_WINDING;
	ctx->cache->npaths++;
    return path;
}

static NVGpoint* nvg__lastPoint(NVGcontext* ctx)
{
	if (ctx->cache->npoints > 0)
		return &ctx->cache->points[ctx->cache->npoints-1];
	return NULL;
}

static void nvg__addPoint(NVGcontext* ctx, float x, float y, int flags)
{
	NVGpath* path = nvg__lastPath(ctx);
	NVGpoint* pt;
	if (path == NULL) return;

	if (path->count > 0 && ctx->cache->npoints > 0) {
		pt = nvg__lastPoint(ctx);
		if (nvg__ptEquals(pt->x,pt->y, x,y, ctx->distTol)) {
			pt->flags |= flags;
			return;
		}
	}

	if (ctx->cache->npoints+1 > ctx->cache->cpoints) {
		NVGpoint* points;
		int cpoints = ctx->cache->npoints+1 + ctx->cache->cpoints/2;
		points = (NVGpoint*)realloc(ctx->cache->points, sizeof(NVGpoint)*cpoints);
		if (points == NULL) return;
		ctx->cache->points = points;
		ctx->cache->cpoints = cpoints;
	}

	pt = &ctx->cache->points[ctx->cache->npoints];
	memset(pt, 0, sizeof(*pt));
	pt->x = x;
	pt->y = y;
	pt->flags = (unsigned char)flags;

	ctx->cache->npoints++;
	path->count++;
}

static void nvg__closePath(NVGcontext* ctx)
{
	NVGpath* path = nvg__lastPath(ctx);
	if (path == NULL) return;
	path->closed = 1;
}

static void nvg__pathWinding(NVGcontext* ctx, int winding)
{
	NVGpath* path = nvg__lastPath(ctx);
	if (path == NULL) return;
	path->winding = winding;
}

static float nvg__getAverageScale(float *t)
{
	float sx = sqrtf(t[0]*t[0] + t[2]*t[2]);
	float sy = sqrtf(t[1]*t[1] + t[3]*t[3]);
	return (sx + sy) * 0.5f;
}

static NVGvertex* nvg__allocTempVerts(NVGcontext* ctx, int nverts)
{
    if (nverts > ctx->cache->cverts) {
        NVGvertex* verts;
        int cverts = (nverts + 0xff) & ~0xff; // Round up to prevent allocations when things change just slightly.
        verts = (NVGvertex*)realloc(ctx->cache->verts, sizeof(NVGvertex)*cverts);
        if (verts == NULL) return NULL;
        ctx->cache->verts = verts;
        ctx->cache->cverts = cverts;
    }

    return ctx->cache->verts;
}

static NVGvertex* nvg__allocTempTextVerts(NVGcontext* ctx, int nverts)
{
    if (nverts > ctx->cache->ctxtverts) {
        NVGvertex* verts;
        int cverts = (nverts + 0xff) & ~0xff; // Round up to prevent allocations when things change just slightly.
        verts = (NVGvertex*)realloc(ctx->cache->txtverts, sizeof(NVGvertex)*cverts);
        if (verts == NULL) return NULL;
        ctx->cache->txtverts = verts;
        ctx->cache->ctxtverts = cverts;
    }

    return ctx->cache->txtverts;
}

static float nvg__triarea2(float ax, float ay, float bx, float by, float cx, float cy)
{
	float abx = bx - ax;
	float aby = by - ay;
	float acx = cx - ax;
	float acy = cy - ay;
	return acx*aby - abx*acy;
}

static float nvg__polyArea(NVGpoint* pts, int npts)
{
	int i;
	float area = 0;
	for (i = 2; i < npts; i++) {
		NVGpoint* a = &pts[0];
		NVGpoint* b = &pts[i-1];
		NVGpoint* c = &pts[i];
		area += nvg__triarea2(a->x,a->y, b->x,b->y, c->x,c->y);
	}
	return area * 0.5f;
}

static void nvg__polyReverse(NVGpoint* pts, int npts)
{
	NVGpoint tmp;
	int i = 0, j = npts-1;
	while (i < j) {
		tmp = pts[i];
		pts[i] = pts[j];
		pts[j] = tmp;
		i++;
		j--;
	}
}


static void nvg__vset(NVGvertex* vtx, float x, float y, float u, float v)
{
	vtx->x = x;
	vtx->y = y;
	vtx->u = u;
	vtx->v = v;
}

static void nvg__tesselateBezier(NVGcontext* ctx,
								 float x1, float y1, float x2, float y2,
								 float x3, float y3, float x4, float y4,
								 int level, int type)
{
	float x12,y12,x23,y23,x34,y34,x123,y123,x234,y234,x1234,y1234;
	float dx,dy,d2,d3;

	if (level > 10) return;

	x12 = (x1+x2)*0.5f;
	y12 = (y1+y2)*0.5f;
	x23 = (x2+x3)*0.5f;
	y23 = (y2+y3)*0.5f;
	x34 = (x3+x4)*0.5f;
	y34 = (y3+y4)*0.5f;
	x123 = (x12+x23)*0.5f;
	y123 = (y12+y23)*0.5f;

	dx = x4 - x1;
	dy = y4 - y1;
	d2 = nvg__absf(((x2 - x4) * dy - (y2 - y4) * dx));
	d3 = nvg__absf(((x3 - x4) * dy - (y3 - y4) * dx));

	if ((d2 + d3)*(d2 + d3) < ctx->tessTol * (dx*dx + dy*dy)) {
		nvg__addPoint(ctx, x4, y4, type);
		return;
	}

/*	if (nvg__absf(x1+x3-x2-x2) + nvg__absf(y1+y3-y2-y2) + nvg__absf(x2+x4-x3-x3) + nvg__absf(y2+y4-y3-y3) < ctx->tessTol) {
		nvg__addPoint(ctx, x4, y4, type);
		return;
	}*/

	x234 = (x23+x34)*0.5f;
	y234 = (y23+y34)*0.5f;
	x1234 = (x123+x234)*0.5f;
	y1234 = (y123+y234)*0.5f;

	nvg__tesselateBezier(ctx, x1,y1, x12,y12, x123,y123, x1234,y1234, level+1, 0);
	nvg__tesselateBezier(ctx, x1234,y1234, x234,y234, x34,y34, x4,y4, level+1, type);
}

static void nvg__flattenPathsForDash(NVGcontext* ctx, NVGstate* state);

inline bool nvg__checkLineForAntiAlias(NVGcontext* ctx, float p0, float p1) {
    static const float cmpVal = 1e-4;
    NVGpoint* last = nvg__lastPoint(ctx);
    if (last && (fabs(last->x - p0) > cmpVal && fabs(last->y - p1) > cmpVal)) {
        return true;
    }
    return false;
}

static void nvg__flattenPaths(NVGcontext* ctx, bool forStroke, bool forClip)
{
	NVGpathCache* cache = ctx->cache;
	NVGstate* state = nvg__getState(ctx);
	NVGpoint* last;
	NVGpoint* p0;
	NVGpoint* p1;
	NVGpoint* pts;
	NVGpath* path = nullptr;
	int i, j;
	const float* cp1;
	const float* cp2;
	const float* p;
	float area;
	const float* commands = ctx->commands;
	int ncommands = ctx->ncommands;
	const bool toCheckDash = (forStroke && state->dashLen > 0);

	if (toCheckDash || forClip) {
		nvg__autoClearPathCache(ctx);
	}

	if (cache->npaths > 0)
		return;

	// Flatten
	i = 0;
	while (i < ncommands) {
		int cmd = (int)commands[i];
		switch (cmd) {
		case NVG_MOVETO:
			path = nvg__addPath(ctx);
			p = &commands[i+1];
			nvg__addPoint(ctx, p[0], p[1], NVG_PT_CORNER);
           // printf("ctx.moveTo(%.2f,%.2f);\r\n", p[0], p[1]);
			i += 3;
			break;
		case NVG_LINETO:
            if (path && path->closed) {
                NVGpoint& ptToAdd = ctx->cache->points[path->first];
                path = nvg__addPath(ctx);
                nvg__addPoint(ctx, ptToAdd.x, ptToAdd.y, NVG_PT_CORNER);
            } else if (path == nullptr) {
                path = nvg__addPath(ctx);
             }
			p = &commands[i+1];
            if (!path->antiAlias && nvg__checkLineForAntiAlias(ctx, p[0], p[1])) {
                path->antiAlias = true;
            }
			nvg__addPoint(ctx, p[0], p[1], NVG_PT_CORNER);
           // printf("ctx.lineTo(%.2f,%.2f);\r\n", p[0], p[1]);
			i += 3;
			break;
		case NVG_BEZIERTO:
            if (path && path->closed) {
                NVGpoint& ptToAdd = ctx->cache->points[path->first];
                path = nvg__addPath(ctx);
                nvg__addPoint(ctx, ptToAdd.x, ptToAdd.y, NVG_PT_CORNER);
            } else if (path == nullptr) {
                path = nvg__addPath(ctx);
            }
            cp1 = &commands[i+1];
            cp2 = &commands[i+3];
            p = &commands[i+5];
            last = nvg__lastPoint(ctx);
            if (last == NULL) {
                nvg__addPoint(ctx, cp1[0],cp1[1], NVG_PT_CORNER);
                last = nvg__lastPoint(ctx);
            }
            nvg__tesselateBezier(ctx, last->x,last->y, cp1[0],cp1[1], cp2[0],cp2[1], p[0],p[1], 0, NVG_PT_CORNER);
          //  printf("ctx.bezierCurveTo(%.2f,%.2f,%.2f,%.2f,%.2f,%.2f);\r\n", cp1[0],cp1[1], cp2[0],cp2[1], p[0],p[1]);
            path->antiAlias = true;
			i += 7;
			break;
		case NVG_CLOSE:
            if (path && path->count > 1) {
                NVGpoint* pt0 = &ctx->cache->points[path->first];
                if (!path->antiAlias && nvg__checkLineForAntiAlias(ctx, pt0->x, pt0->y)) {
                    path->antiAlias = true;
                }
            }
          //  printf("ctx.closePath();\r\n");
			nvg__closePath(ctx);
			i++;
			break;
		case NVG_WINDING:
			nvg__pathWinding(ctx, (int)commands[i+1]);
			i += 2;
			break;
		default:
			i++;
		}
	}

    if (toCheckDash && cache->npaths > 0) {
		nvg__flattenPathsForDash(ctx, state);
    }

	cache->bounds[0] = cache->bounds[1] = 1e6f;
	cache->bounds[2] = cache->bounds[3] = -1e6f;

	// Calculate the direction and length of line segments.
	for (j = 0; j < cache->npaths; j++) {
		path = &cache->paths[j];
		pts = &cache->points[path->first];

		// If the first and last points are the same, remove the last, mark as closed path.
		p0 = &pts[path->count-1];
		p1 = &pts[0];
		if (nvg__ptEquals(p0->x,p0->y, p1->x,p1->y, ctx->distTol)) {
             path->count--;
             p0 = &pts[path->count-1];
			path->closed = 1;
		}

		// Enforce winding.
		if (path->count > 2) {
			area = nvg__polyArea(pts, path->count);
            if (area < 0.0f) {
                if (path->winding == NVG_CCW) {
                    nvg__polyReverse(pts, path->count);
                    path->realWinding = NVG_CCW;
                } else {
                    path->realWinding = NVG_CW;
                }
            } else if (area > 0.0f) {
                if (path->winding == NVG_CW) {
                    nvg__polyReverse(pts, path->count);
                    path->realWinding = NVG_CW;
                } else {
                    path->realWinding = NVG_CCW;
                }
            } else {
                path->realWinding = NVG_NONE_WINDING;
            }
		}

		for(i = 0; i < path->count; i++) {
			// Calculate segment direction and length
			p0->dx = p1->x - p0->x;
			p0->dy = p1->y - p0->y;
			p0->len = nvg__normalize(&p0->dx, &p0->dy);
			// Update bounds
			cache->bounds[0] = nvg__minf(cache->bounds[0], p0->x);
			cache->bounds[1] = nvg__minf(cache->bounds[1], p0->y);
			cache->bounds[2] = nvg__maxf(cache->bounds[2], p0->x);
			cache->bounds[3] = nvg__maxf(cache->bounds[3], p0->y);
			// Advance
			p0 = p1++;
		}
	}
}

inline void nvg__findPointForDashSeg(float* tmpx, float* tmpy, NVGpoint* lastPt, NVGpoint* curPt, float pos) {
    *tmpx = lastPt->x + pos * (curPt->x - lastPt->x);
    *tmpy = lastPt->y + pos * (curPt->y - lastPt->y);
}

static void nvg__flattenPathsForDash(NVGcontext* ctx, NVGstate* state) {
    NVGpathCache* cache = ctx->cache;
	int nStartNpath = cache->npaths;
	const float* dashArr = cache->dashs + state->dashStart;
	for (int j = 0; j < nStartNpath; j++) {
		float segVal = dashArr[0];
		bool segToUse = true, toAddPath = true;
		int segIndex = 0;

		NVGpoint *pts = nullptr, *lastPt = nullptr;
		NVGpath curPath, *path;

		path = &curPath;
		memcpy(path, &cache->paths[j], sizeof(NVGpath));
		lastPt = pts = new NVGpoint[path->count];
		memcpy(pts, &cache->points[path->first], path->count * sizeof(NVGpoint));

        const int nCurStartNpath = cache->npaths;
        float offset = state->lineDashOffset;

		if (path->count <= 0) continue;
		if (offset != 0) {
			float SegSum = 0;
			for (int i = 0; i < state->dashLen; i++) {
				SegSum += dashArr[i];
			}
			if (SegSum < 1e-2) { offset = 0; }
			while (offset < 0) {
				offset += SegSum;
			}
			while (offset > 0) {
				offset -=SegSum;
			}
		}
		if (segToUse) {
            if (toAddPath) { nvg__addPath(ctx); toAddPath = false; }
			nvg__addPoint(ctx, lastPt->x, lastPt->y, NVG_PT_CORNER);
		}

        const int maxLoop = path->count + (path->closed ? 1 : 0);
		for (int i = 1; i < maxLoop; i++) {
            const bool isClosePt = (i == path->count);
			float tmpx, tmpy;
			float curdis = offset;
            NVGpoint* curPt = pts + (isClosePt ? 0 : i);
			const float totaldis = sqrtf((curPt->x - lastPt->x) * (curPt->x - lastPt->x)
				+ (curPt->y - lastPt->y) * (curPt->y - lastPt->y));
			while (totaldis > curdis) {
                float len = totaldis - curdis;
                if (len  > segVal) {
                    len = segVal;
                    segVal = 0;
                } else {
                    segVal -= len;
                }
                curdis += len;
                if (segToUse) {
                    if (toAddPath) {
						if (curdis - len >= 0) {
                        nvg__addPath(ctx);
                        toAddPath = false;
                        nvg__findPointForDashSeg(&tmpx, &tmpy, lastPt, curPt, (curdis - len) / totaldis);
							nvg__addPoint(ctx, tmpx, tmpy, NVG_PT_CORNER);
                        }
                    }
                    if (len > 1e-2) {
						if (curdis >= 0) {
                        nvg__findPointForDashSeg(&tmpx, &tmpy, lastPt, curPt, curdis / totaldis);
							nvg__addPoint(ctx, tmpx, tmpy, NVG_PT_CORNER);
                        }
                    } else {
                        // seg is 0
                        const NVGpoint& ptBefore = cache->points[cache->npoints - 1];
                        nvg__addPoint(ctx, ptBefore.x + 0.5, ptBefore.y, NVG_PT_CORNER);
                    }
                }
                if (segVal <= 0) {
                    toAddPath = true;
					segIndex = (++segIndex) % state->dashLen;
					segVal = dashArr[segIndex];
					segToUse = !segToUse;
                }
            }
			lastPt = curPt;
		}

        // if path is closed, check whether the first and last subpath can be combined
        if (cache->paths[j].closed && cache->npaths > nCurStartNpath) {
            NVGpath* firstPath = &cache->paths[nCurStartNpath];
            NVGpoint* firstPt = &cache->points[firstPath->first];
            NVGpath* lastPath = &cache->paths[cache->npaths - 1];
            NVGpoint* lastPt = &cache->points[lastPath->first + lastPath->count - 1];
            if (fabs(firstPt->x - lastPt->x) <= 1e-3 && fabs(firstPt->y - lastPt->y) <= 1e-3) {
                // add first into last
                for (int i = 0; i < firstPath->count; i++) {
                    nvg__addPoint(ctx, firstPt->x, firstPt->y, NVG_PT_CORNER);
                    ++firstPt;
                }
                ++nStartNpath;
            }
        }
		delete[] pts;
	} // for paths

    // remove paths unused
	for (int j = nStartNpath; j < cache->npaths; j++) {
		memcpy(cache->paths + j - nStartNpath, cache->paths + j, sizeof(NVGpath));
	}
	cache->npaths -= nStartNpath;
}

static int nvg__curveDivs(float r, float arc, float tol)
{
	float da = acosf(r / (r + tol)) * 2.0f;
	return nvg__maxi(2, (int)ceilf(arc / da));
}

static void nvg__chooseBevel(int bevel, NVGpoint* p0, NVGpoint* p1, float w,
							float* x0, float* y0, float* x1, float* y1)
{
	if (bevel) {
		*x0 = p1->x + p0->dy * w;
		*y0 = p1->y - p0->dx * w;
		*x1 = p1->x + p1->dy * w;
		*y1 = p1->y - p1->dx * w;
	} else {
		*x0 = p1->x + p1->dmx * w;
		*y0 = p1->y + p1->dmy * w;
		*x1 = p1->x + p1->dmx * w;
		*y1 = p1->y + p1->dmy * w;
	}
}

static NVGvertex* nvg__roundJoin(NVGvertex* dst, NVGpoint* p0, NVGpoint* p1,
								 float lw, float rw, float lu, float ru, int ncap,
								 float fringe)
{
	int i, n;
	float dlx0 = p0->dy;
	float dly0 = -p0->dx;
	float dlx1 = p1->dy;
	float dly1 = -p1->dx;
	NVG_NOTUSED(fringe);

	if (p1->flags & NVG_PT_LEFT) {
		float lx0,ly0,lx1,ly1,a0,a1;
		nvg__chooseBevel(p1->flags & NVG_PR_INNERBEVEL, p0, p1, lw, &lx0,&ly0, &lx1,&ly1);
		a0 = atan2f(-dly0, -dlx0);
		a1 = atan2f(-dly1, -dlx1);
		if (a1 > a0) a1 -= NVG_PI*2;

		nvg__vset(dst, lx0, ly0, lu,1); dst++;
		nvg__vset(dst, p1->x - dlx0*rw, p1->y - dly0*rw, ru,1); dst++;

		n = nvg__clampi((int)ceilf(((a0 - a1) / NVG_PI) * ncap), 2, ncap);
		for (i = 0; i < n; i++) {
			float u = i/(float)(n-1);
			float a = a0 + u*(a1-a0);
			float rx = p1->x + cosf(a) * rw;
			float ry = p1->y + sinf(a) * rw;
			nvg__vset(dst, p1->x, p1->y, 0.5f,1); dst++;
			nvg__vset(dst, rx, ry, ru,1); dst++;
		}

		nvg__vset(dst, lx1, ly1, lu,1); dst++;
		nvg__vset(dst, p1->x - dlx1*rw, p1->y - dly1*rw, ru,1); dst++;

	} else {
		float rx0,ry0,rx1,ry1,a0,a1;
		nvg__chooseBevel(p1->flags & NVG_PR_INNERBEVEL, p0, p1, -rw, &rx0,&ry0, &rx1,&ry1);
		a0 = atan2f(dly0, dlx0);
		a1 = atan2f(dly1, dlx1);
		if (a1 < a0) a1 += NVG_PI*2;

		nvg__vset(dst, p1->x + dlx0*rw, p1->y + dly0*rw, lu,1); dst++;
		nvg__vset(dst, rx0, ry0, ru,1); dst++;

		n = nvg__clampi((int)ceilf(((a1 - a0) / NVG_PI) * ncap), 2, ncap);
		for (i = 0; i < n; i++) {
			float u = i/(float)(n-1);
			float a = a0 + u*(a1-a0);
			float lx = p1->x + cosf(a) * lw;
			float ly = p1->y + sinf(a) * lw;
			nvg__vset(dst, lx, ly, lu,1); dst++;
			nvg__vset(dst, p1->x, p1->y, 0.5f,1); dst++;
		}

		nvg__vset(dst, p1->x + dlx1*rw, p1->y + dly1*rw, lu,1); dst++;
		nvg__vset(dst, rx1, ry1, ru,1); dst++;

	}
	return dst;
}

static NVGvertex* nvg__bevelJoin(NVGvertex* dst, NVGpoint* p0, NVGpoint* p1,
										float lw, float rw, float lu, float ru, float fringe)
{
	float rx0,ry0,rx1,ry1;
	float lx0,ly0,lx1,ly1;
	float dlx0 = p0->dy;
	float dly0 = -p0->dx;
	float dlx1 = p1->dy;
	float dly1 = -p1->dx;
	NVG_NOTUSED(fringe);

	if (p1->flags & NVG_PT_LEFT) {
		nvg__chooseBevel(p1->flags & NVG_PR_INNERBEVEL, p0, p1, lw, &lx0,&ly0, &lx1,&ly1);

		nvg__vset(dst, lx0, ly0, lu,1); dst++;
		nvg__vset(dst, p1->x - dlx0*rw, p1->y - dly0*rw, ru,1); dst++;

		if (p1->flags & NVG_PT_BEVEL) {
			nvg__vset(dst, lx0, ly0, lu,1); dst++;
			nvg__vset(dst, p1->x - dlx0*rw, p1->y - dly0*rw, ru,1); dst++;

			nvg__vset(dst, lx1, ly1, lu,1); dst++;
			nvg__vset(dst, p1->x - dlx1*rw, p1->y - dly1*rw, ru,1); dst++;
		} else {
			rx0 = p1->x - p1->dmx * rw;
			ry0 = p1->y - p1->dmy * rw;

			nvg__vset(dst, p1->x, p1->y, 0.5f,1); dst++;
			nvg__vset(dst, p1->x - dlx0*rw, p1->y - dly0*rw, ru,1); dst++;

			nvg__vset(dst, rx0, ry0, ru,1); dst++;
			nvg__vset(dst, rx0, ry0, ru,1); dst++;

			nvg__vset(dst, p1->x, p1->y, 0.5f,1); dst++;
			nvg__vset(dst, p1->x - dlx1*rw, p1->y - dly1*rw, ru,1); dst++;
		}

		nvg__vset(dst, lx1, ly1, lu,1); dst++;
		nvg__vset(dst, p1->x - dlx1*rw, p1->y - dly1*rw, ru,1); dst++;

	} else {
		nvg__chooseBevel(p1->flags & NVG_PR_INNERBEVEL, p0, p1, -rw, &rx0,&ry0, &rx1,&ry1);

		nvg__vset(dst, p1->x + dlx0*lw, p1->y + dly0*lw, lu,1); dst++;
		nvg__vset(dst, rx0, ry0, ru,1); dst++;

		if (p1->flags & NVG_PT_BEVEL) {
			nvg__vset(dst, p1->x + dlx0*lw, p1->y + dly0*lw, lu,1); dst++;
			nvg__vset(dst, rx0, ry0, ru,1); dst++;

			nvg__vset(dst, p1->x + dlx1*lw, p1->y + dly1*lw, lu,1); dst++;
			nvg__vset(dst, rx1, ry1, ru,1); dst++;
		} else {
			lx0 = p1->x + p1->dmx * lw;
			ly0 = p1->y + p1->dmy * lw;

			nvg__vset(dst, p1->x + dlx0*lw, p1->y + dly0*lw, lu,1); dst++;
			nvg__vset(dst, p1->x, p1->y, 0.5f,1); dst++;

			nvg__vset(dst, lx0, ly0, lu,1); dst++;
			nvg__vset(dst, lx0, ly0, lu,1); dst++;

			nvg__vset(dst, p1->x + dlx1*lw, p1->y + dly1*lw, lu,1); dst++;
			nvg__vset(dst, p1->x, p1->y, 0.5f,1); dst++;
		}

		nvg__vset(dst, p1->x + dlx1*lw, p1->y + dly1*lw, lu,1); dst++;
		nvg__vset(dst, rx1, ry1, ru,1); dst++;
	}

	return dst;
}

static NVGvertex* nvg__buttCapStart(NVGvertex* dst, NVGpoint* p,
									float dx, float dy, float w, float d,
									float aa, float u0, float u1)
{
	float px = p->x - dx*d;
	float py = p->y - dy*d;
	float dlx = dy;
	float dly = -dx;
	nvg__vset(dst, px + dlx*w - dx*aa, py + dly*w - dy*aa, u0,0); dst++;
	nvg__vset(dst, px - dlx*w - dx*aa, py - dly*w - dy*aa, u1,0); dst++;
	nvg__vset(dst, px + dlx*w, py + dly*w, u0,1); dst++;
	nvg__vset(dst, px - dlx*w, py - dly*w, u1,1); dst++;
	return dst;
}

static NVGvertex* nvg__buttCapEnd(NVGvertex* dst, NVGpoint* p,
								  float dx, float dy, float w, float d,
								  float aa, float u0, float u1)
{
	float px = p->x + dx*d;
	float py = p->y + dy*d;
	float dlx = dy;
	float dly = -dx;
	nvg__vset(dst, px + dlx*w, py + dly*w, u0,1); dst++;
	nvg__vset(dst, px - dlx*w, py - dly*w, u1,1); dst++;
	nvg__vset(dst, px + dlx*w + dx*aa, py + dly*w + dy*aa, u0,0); dst++;
	nvg__vset(dst, px - dlx*w + dx*aa, py - dly*w + dy*aa, u1,0); dst++;
	return dst;
}


static NVGvertex* nvg__roundCapStart(NVGvertex* dst, NVGpoint* p,
									 float dx, float dy, float w, int ncap,
									 float aa, float u0, float u1)
{
	int i;
	float px = p->x;
	float py = p->y;
	float dlx = dy;
	float dly = -dx;
	NVG_NOTUSED(aa);
	for (i = 0; i < ncap; i++) {
		float a = i/(float)(ncap-1)*NVG_PI;
		float ax = cosf(a) * w, ay = sinf(a) * w;
		nvg__vset(dst, px - dlx*ax - dx*ay, py - dly*ax - dy*ay, u0,1); dst++;
		nvg__vset(dst, px, py, 0.5f,1); dst++;
	}
	nvg__vset(dst, px + dlx*w, py + dly*w, u0,1); dst++;
	nvg__vset(dst, px - dlx*w, py - dly*w, u1,1); dst++;
	return dst;
}

static NVGvertex* nvg__roundCapEnd(NVGvertex* dst, NVGpoint* p,
								   float dx, float dy, float w, int ncap,
								   float aa, float u0, float u1)
{
	int i;
	float px = p->x;
	float py = p->y;
	float dlx = dy;
	float dly = -dx;
	NVG_NOTUSED(aa);
	nvg__vset(dst, px + dlx*w, py + dly*w, u0,1); dst++;
	nvg__vset(dst, px - dlx*w, py - dly*w, u1,1); dst++;
	for (i = 0; i < ncap; i++) {
		float a = i/(float)(ncap-1)*NVG_PI;
		float ax = cosf(a) * w, ay = sinf(a) * w;
		nvg__vset(dst, px, py, 0.5f,1); dst++;
		nvg__vset(dst, px - dlx*ax + dx*ay, py - dly*ax + dy*ay, u0,1); dst++;
	}
	return dst;
}


static void nvg__calculateJoins(NVGcontext* ctx, float w, int lineJoin, float miterLimit)
{
	NVGpathCache* cache = ctx->cache;
	int i, j;
	float iw = 0.0f;

	if (w > 0.0f) iw = 1.0f / w;

	// Calculate which joins needs extra vertices to append, and gather vertex count.
	for (i = 0; i < cache->npaths; i++) {
		NVGpath* path = &cache->paths[i];
		NVGpoint* pts = &cache->points[path->first];
		NVGpoint* p0 = &pts[path->count-1];
		NVGpoint* p1 = &pts[0];
		int nleft = 0;

		path->nbevel = 0;

		for (j = 0; j < path->count; j++) {
			float dlx0, dly0, dlx1, dly1, dmr2, cross, limit;
			dlx0 = p0->dy;
			dly0 = -p0->dx;
			dlx1 = p1->dy;
			dly1 = -p1->dx;
			// Calculate extrusions
			p1->dmx = (dlx0 + dlx1) * 0.5f;
			p1->dmy = (dly0 + dly1) * 0.5f;
			dmr2 = p1->dmx*p1->dmx + p1->dmy*p1->dmy;
			if (dmr2 > 0.000001f) {
				float scale = 1.0f / dmr2;
				if (scale > 600.0f) {
					scale = 600.0f;
				}
				p1->dmx *= scale;
				p1->dmy *= scale;
			}

			// Clear flags, but keep the corner.
			p1->flags = (p1->flags & NVG_PT_CORNER) ? NVG_PT_CORNER : 0;

			// Keep track of left turns.
			cross = p1->dx * p0->dy - p0->dx * p1->dy;
			if (cross > 0.0f) {
				nleft++;
				p1->flags |= NVG_PT_LEFT;
			}

			// Calculate if we should use bevel or miter for inner join.
			limit = nvg__maxf(1.01f, nvg__minf(p0->len, p1->len) * iw);
			if ((dmr2 * limit*limit) < 1.0f)
				p1->flags |= NVG_PR_INNERBEVEL;

			// Check to see if the corner needs to be beveled.
			if (p1->flags & NVG_PT_CORNER) {
				if ((dmr2 * miterLimit*miterLimit) < 1.0f || lineJoin == NVG_BEVEL || lineJoin == NVG_ROUND) {
					p1->flags |= NVG_PT_BEVEL;
				}
			}

			if ((p1->flags & (NVG_PT_BEVEL | NVG_PR_INNERBEVEL)) != 0)
				path->nbevel++;

			p0 = p1++;
		}

		// At present, the simple drawing of convex polygons only considers the counterclockwise direction. 
		// Here, it is also judged that nleft is the number of left turns. There is no additional change here
		path->convex = (nleft == path->count) ? 1 : 0;
        // Irregular concave polygons (such as five pointed stars) have problems with fill, 
		// so only those with less than five edges should be considered to go through convex for simple processing, 
		// and others should not use simple processing.
        if (path->convex && (path->count > 4 || (path->closed && path->count == 4))) {
            path->convex = false;
        }
	}
}


static int nvg__expandStroke(NVGcontext* ctx, float w, float fringe, int lineCap, int lineJoin, float miterLimit)
{
	NVGpathCache* cache = ctx->cache;
	NVGvertex* verts;
	NVGvertex* dst;
	int cverts, i, j;
	float aa = fringe;//ctx->fringeWidth;
	float u0 = 0.0f, u1 = 1.0f;
	int ncap = nvg__curveDivs(w, NVG_PI, ctx->tessTol);	// Calculate divisions per half circle.

	w += aa * 0.5f;

	// Disable the gradient used for antialiasing when antialiasing is not used.
	if (aa == 0.0f) {
		u0 = 0.5f;
		u1 = 0.5f;
	}

	nvg__calculateJoins(ctx, w, lineJoin, miterLimit);

	// Calculate max vertex usage.
	cverts = 0;
	for (i = 0; i < cache->npaths; i++) {
		NVGpath* path = &cache->paths[i];
		int loop = (path->closed == 0) ? 0 : 1;
		if (lineJoin == NVG_ROUND)
			cverts += (path->count + path->nbevel*(ncap+2) + 1) * 2; // plus one for loop
		else
			cverts += (path->count + path->nbevel*5 + 1) * 2; // plus one for loop
		if (loop == 0) {
			// space for caps
			if (lineCap == NVG_ROUND) {
				cverts += (ncap*2 + 2)*2;
			} else {
				cverts += (3+3)*2;
			}
		}
	}

	verts = nvg__allocTempVerts(ctx, cverts);
	if (verts == NULL) return 0;

	for (i = 0; i < cache->npaths; i++) {
		NVGpath* path = &cache->paths[i];
		NVGpoint* pts = &cache->points[path->first];
		NVGpoint* p0;
		NVGpoint* p1;
		int s, e, loop;
		float dx, dy;

		path->fill = 0;
		path->nfill = 0;

		// Calculate fringe or stroke
		loop = (path->closed == 0) ? 0 : 1;
		dst = verts;
		path->stroke = dst;

		if (loop) {
			// Looping
			p0 = &pts[path->count-1];
			p1 = &pts[0];
			s = 0;
			e = path->count;
		} else {
			// Add cap
			p0 = &pts[0];
			p1 = &pts[1];
			s = 1;
			e = path->count-1;
		}

		if (loop == 0) {
			// Add cap
			dx = p1->x - p0->x;
			dy = p1->y - p0->y;
			nvg__normalize(&dx, &dy);
			if (lineCap == NVG_BUTT)
				dst = nvg__buttCapStart(dst, p0, dx, dy, w, -aa*0.5f, aa, u0, u1);
			else if (lineCap == NVG_BUTT || lineCap == NVG_SQUARE)
				dst = nvg__buttCapStart(dst, p0, dx, dy, w, w-aa, aa, u0, u1);
			else if (lineCap == NVG_ROUND)
				dst = nvg__roundCapStart(dst, p0, dx, dy, w, ncap, aa, u0, u1);
		}

		for (j = s; j < e; ++j) {
			if ((p1->flags & (NVG_PT_BEVEL | NVG_PR_INNERBEVEL)) != 0) {
				if (lineJoin == NVG_ROUND) {
					dst = nvg__roundJoin(dst, p0, p1, w, w, u0, u1, ncap, aa);
				} else {
					dst = nvg__bevelJoin(dst, p0, p1, w, w, u0, u1, aa);
				}
			} else {
				nvg__vset(dst, p1->x + (p1->dmx * w), p1->y + (p1->dmy * w), u0,1); dst++;
				nvg__vset(dst, p1->x - (p1->dmx * w), p1->y - (p1->dmy * w), u1,1); dst++;
			}
			p0 = p1++;
		}

		if (loop) {
			// Loop it
			nvg__vset(dst, verts[0].x, verts[0].y, u0,1); dst++;
			nvg__vset(dst, verts[1].x, verts[1].y, u1,1); dst++;
		} else {
			// Add cap
			dx = p1->x - p0->x;
			dy = p1->y - p0->y;
			nvg__normalize(&dx, &dy);
			if (lineCap == NVG_BUTT)
				dst = nvg__buttCapEnd(dst, p1, dx, dy, w, -aa*0.5f, aa, u0, u1);
			else if (lineCap == NVG_BUTT || lineCap == NVG_SQUARE)
				dst = nvg__buttCapEnd(dst, p1, dx, dy, w, w-aa, aa, u0, u1);
			else if (lineCap == NVG_ROUND)
				dst = nvg__roundCapEnd(dst, p1, dx, dy, w, ncap, aa, u0, u1);
		}

		path->nstroke = (int)(dst - verts);

		verts = dst;
	}

	return 1;
}

static int nvg__expandFill(NVGcontext* ctx, float w, int lineJoin, float miterLimit)
{
	NVGpathCache* cache = ctx->cache;
	NVGvertex* verts;
	NVGvertex* dst;
	int cverts, convex, i, j;
	float aa = ctx->fringeWidth;
	int fringe = w > 0.0f;

	nvg__calculateJoins(ctx, w, lineJoin, miterLimit);

	// Calculate max vertex usage.
	cverts = 0;
	for (i = 0; i < cache->npaths; i++) {
		NVGpath* path = &cache->paths[i];
		cverts += path->count + path->nbevel + 1;
		if (fringe)
			cverts += (path->count + path->nbevel*5 + 1) * 2; // plus one for loop
	}

	verts = nvg__allocTempVerts(ctx, cverts);
	if (verts == NULL) return 0;

	convex = cache->npaths == 1 && cache->paths[0].convex;

	for (i = 0; i < cache->npaths; i++) {
		NVGpath* path = &cache->paths[i];
		NVGpoint* pts = &cache->points[path->first];
		NVGpoint* p0;
		NVGpoint* p1;
		float rw, lw, woff;
		float ru, lu;

		// Calculate shape vertices.
		woff = 0.5f*aa;
        if (path->realWinding == NVG_CW) {
            // Clockwise, the vector is outward, antialias should shrink inward, and then stroke
            woff = -woff;
        }

		dst = verts;
		path->fill = dst;

		if (fringe && path->antiAlias) {
			// Looping
			p0 = &pts[path->count-1];
			p1 = &pts[0];
			for (j = 0; j < path->count; ++j) {
				if (p1->flags & NVG_PT_BEVEL) {
					float dlx0 = p0->dy;
					float dly0 = -p0->dx;
					float dlx1 = p1->dy;
					float dly1 = -p1->dx;
					if (p1->flags & NVG_PT_LEFT) {
						float lx = p1->x + p1->dmx * woff;
						float ly = p1->y + p1->dmy * woff;
						nvg__vset(dst, lx, ly, 0.5f,1); dst++;
					} else {
						float lx0 = p1->x + dlx0 * woff;
						float ly0 = p1->y + dly0 * woff;
						float lx1 = p1->x + dlx1 * woff;
						float ly1 = p1->y + dly1 * woff;
						nvg__vset(dst, lx0, ly0, 0.5f,1); dst++;
						nvg__vset(dst, lx1, ly1, 0.5f,1); dst++;
					}
				} else {
					nvg__vset(dst, p1->x + (p1->dmx * woff), p1->y + (p1->dmy * woff), 0.5f,1); dst++;
				}
				p0 = p1++;
			}
		} else {
			for (j = 0; j < path->count; ++j) {
				nvg__vset(dst, pts[j].x, pts[j].y, 0.5f,1);
				dst++;
			}
		}

		path->nfill = (int)(dst - verts);
		verts = dst;

		// Calculate fringe
		if (fringe && path->antiAlias) {
			lw = w + woff;
			rw = w - woff;
			lu = 0;
			ru = 1;
			dst = verts;
			path->stroke = dst;

			// Create only half a fringe for convex shapes so that
			// the shape can be rendered without stenciling.
			if (convex) {
				lw = woff;	// This should generate the same vertex as fill inset above.
				lu = 0.5f;	// Set outline fade at middle.
			}

			// Looping
			p0 = &pts[path->count-1];
			p1 = &pts[0];

			for (j = 0; j < path->count; ++j) {
				if ((p1->flags & (NVG_PT_BEVEL | NVG_PR_INNERBEVEL)) != 0) {
					dst = nvg__bevelJoin(dst, p0, p1, lw, rw, lu, ru, ctx->fringeWidth);
				} else {
					nvg__vset(dst, p1->x + (p1->dmx * lw), p1->y + (p1->dmy * lw), lu,1); dst++;
					nvg__vset(dst, p1->x - (p1->dmx * rw), p1->y - (p1->dmy * rw), ru,1); dst++;
				}
				p0 = p1++;
			}

			// Loop it
			nvg__vset(dst, verts[0].x, verts[0].y, lu,1); dst++;
			nvg__vset(dst, verts[1].x, verts[1].y, ru,1); dst++;

			path->nstroke = (int)(dst - verts);
			verts = dst;
		} else {
			path->stroke = NULL;
			path->nstroke = 0;
		}
	}

	return 1;
}


// Draw
void nvgBeginPath(NVGcontext* ctx)
{
    NVG_CMD_DEBUG("ctx.beginPath();\r\n");

    ctx->ncommands = 0;
	++ctx->commandver;
	nvg__clearPathCache(ctx);
}

void nvgMoveTo(NVGcontext* ctx, float x, float y)
{
    NVG_CMD_DEBUG("ctx.moveTo(%.2f,%.2f);\r\n", x, y);

    float vals[] = { NVG_MOVETO, x, y };
	nvg__appendCommands(ctx, vals, NVG_COUNTOF(vals));
}

void nvgLineTo(NVGcontext* ctx, float x, float y)
{
    NVG_CMD_DEBUG("ctx.lineTo(%.2f,%.2f);\r\n", x, y);

    float vals[] = { NVG_LINETO, x, y };
	nvg__appendCommands(ctx, vals, NVG_COUNTOF(vals));
}

void nvgBezierTo(NVGcontext* ctx, float c1x, float c1y, float c2x, float c2y, float x, float y)
{
    NVG_CMD_DEBUG("ctx.bezierCurveTo(%.2f,%.2f,%.2f,%.2f,%.2f,%.2f);\r\n", c1x, c1y, c2x, c2y, x, y);

    float vals[] = { NVG_BEZIERTO, c1x, c1y, c2x, c2y, x, y };
	nvg__appendCommands(ctx, vals, NVG_COUNTOF(vals));
}

void nvgQuadTo(NVGcontext* ctx, float cx, float cy, float x, float y)
{
    NVG_CMD_DEBUG("ctx.quadraticCurveTo(%.2f,%.2f,%.2f,%.2f);\r\n", cx, cy, x, y);

    float x0 = ctx->commandx;
    float y0 = ctx->commandy;
    float vals[] = { NVG_BEZIERTO,
        x0 + 2.0f/3.0f*(cx - x0), y0 + 2.0f/3.0f*(cy - y0),
        x + 2.0f/3.0f*(cx - x), y + 2.0f/3.0f*(cy - y),
        x, y };
    nvg__appendCommands(ctx, vals, NVG_COUNTOF(vals));
}

void nvgArcTo(NVGcontext* ctx, float x1, float y1, float x2, float y2, float radius)
{
    NVG_CMD_DEBUG("ctx.arcTo(%.2f,%.2f,%.2f,%.2f,%.2f);\r\n", x1, y1, x2, y2, radius);

    if (ctx->ncommands == 0) {
        nvgMoveTo(ctx, x1, y1);
    }

	float x0 = ctx->commandx;
	float y0 = ctx->commandy;
	float dx0,dy0, dx1,dy1, a, d, cx,cy, a0,a1;
	int dir;

	// Handle degenerate cases.
	if (nvg__ptEquals(x0,y0, x1,y1, ctx->distTol) ||
		nvg__ptEquals(x1,y1, x2,y2, ctx->distTol) ||
		nvg__distPtSeg(x1,y1, x0,y0, x2,y2) < ctx->distTol*ctx->distTol ||
		radius < ctx->distTol) {
		nvgLineTo(ctx, x1,y1);
		return;
	}

	// Calculate tangential circle to lines (x0,y0)-(x1,y1) and (x1,y1)-(x2,y2).
	dx0 = x0-x1;
	dy0 = y0-y1;
	dx1 = x2-x1;
	dy1 = y2-y1;
	nvg__normalize(&dx0,&dy0);
	nvg__normalize(&dx1,&dy1);
	a = nvg__acosf(dx0*dx1 + dy0*dy1);
	d = radius / nvg__tanf(a/2.0f);

//	printf("a=%f° d=%f\n", a/NVG_PI*180.0f, d);

	if (d > 10000.0f) {
		nvgLineTo(ctx, x1,y1);
		return;
	}

	if (nvg__cross(dx0,dy0, dx1,dy1) > 0.0f) {
		cx = x1 + dx0*d + dy0*radius;
		cy = y1 + dy0*d + -dx0*radius;
		a0 = nvg__atan2f(dx0, -dy0);
		a1 = nvg__atan2f(-dx1, dy1);
		dir = NVG_CW;
//		printf("CW c=(%f, %f) a0=%f° a1=%f°\n", cx, cy, a0/NVG_PI*180.0f, a1/NVG_PI*180.0f);
	} else {
		cx = x1 + dx0*d + -dy0*radius;
		cy = y1 + dy0*d + dx0*radius;
		a0 = nvg__atan2f(-dx0, dy0);
		a1 = nvg__atan2f(dx1, -dy1);
		dir = NVG_CCW;
//		printf("CCW c=(%f, %f) a0=%f° a1=%f°\n", cx, cy, a0/NVG_PI*180.0f, a1/NVG_PI*180.0f);
	}

	nvgArc(ctx, cx, cy, radius, a0, a1, dir);
}

void nvgClosePath(NVGcontext* ctx)
{
    NVG_CMD_DEBUG("ctx.closePath();\r\n");

    float vals[] = { NVG_CLOSE };
	nvg__appendCommands(ctx, vals, NVG_COUNTOF(vals));
}

void nvgPathWinding(NVGcontext* ctx, int dir)
{
	float vals[] = { NVG_WINDING, (float)dir };
	nvg__appendCommands(ctx, vals, NVG_COUNTOF(vals));
}

void nvgArc(NVGcontext* ctx, float cx, float cy, float r, float a0, float a1, int dir)
{
    NVG_CMD_DEBUG("ctx.arc(%.2f,%.2f,%.2f,Math.PI*%.2f,Math.PI*%.2f,%s);\r\n", cx, cy, r, a0/NVG_PI, a1/NVG_PI, (dir==NVG_CCW)?"true":"false");

	float a = 0, da = 0, hda = 0, kappa = 0;
	float dx = 0, dy = 0, x = 0, y = 0, tanx = 0, tany = 0;
	float px = 0, py = 0, ptanx = 0, ptany = 0;
	float vals[3 + 5*7 + 100];
	int i, ndivs, nvals;
	int move = ctx->ncommands > 0 ? NVG_LINETO : NVG_MOVETO;

	// Clamp angles
	da = a1 - a0;
	if (dir == NVG_CW) {
		if (nvg__absf(da) >= NVG_PI*2) {
			da = NVG_PI*2;
		} else {
			while (da < 0.0f) da += NVG_PI*2;
		}
	} else {
		if (nvg__absf(da) >= NVG_PI*2) {
			da = -NVG_PI*2;
		} else {
			while (da > 0.0f) da -= NVG_PI*2;
		}
	}

	// Split arc into max 90 degree segments.
	ndivs = nvg__maxi(1, nvg__mini((int)(nvg__absf(da) / (NVG_PI*0.5f) + 0.5f), 5));
	hda = (da / (float)ndivs) / 2.0f;
	kappa = nvg__absf(4.0f / 3.0f * (1.0f - nvg__cosf(hda)) / nvg__sinf(hda));

	if (dir == NVG_CCW)
		kappa = -kappa;

	nvals = 0;
	for (i = 0; i <= ndivs; i++) {
		a = a0 + da * (i/(float)ndivs);
		dx = nvg__cosf(a);
		dy = nvg__sinf(a);
		x = cx + dx*r;
		y = cy + dy*r;
		tanx = -dy*r*kappa;
		tany = dx*r*kappa;

		if (i == 0) {
			vals[nvals++] = (float)move;
			vals[nvals++] = x;
			vals[nvals++] = y;
		} else {
			vals[nvals++] = NVG_BEZIERTO;
			vals[nvals++] = px+ptanx;
			vals[nvals++] = py+ptany;
			vals[nvals++] = x-tanx;
			vals[nvals++] = y-tany;
			vals[nvals++] = x;
			vals[nvals++] = y;
		}
		px = x;
		py = y;
		ptanx = tanx;
		ptany = tany;
	}

	nvg__appendCommands(ctx, vals, nvals);
}

void nvgRect(NVGcontext* ctx, float x, float y, float w, float h)
{
    NVG_CMD_DEBUG("ctx.rect(%.2f,%.2f,%.2f,%.2f);\r\n", x, y, w, h);

    float vals[] = {
		NVG_MOVETO, x,y,
		NVG_LINETO, x+w,y,
		NVG_LINETO, x+w,y+h,
		NVG_LINETO, x,y+h,
		NVG_CLOSE
	};
	nvg__appendCommands(ctx, vals, NVG_COUNTOF(vals));
}

void nvgRoundedRect(NVGcontext* ctx, float x, float y, float w, float h, float r)
{
	nvgRoundedRectVarying(ctx, x, y, w, h, r, r, r, r);
}

void nvgRoundedRectVarying(NVGcontext* ctx, float x, float y, float w, float h, float radTopLeft, float radTopRight, float radBottomRight, float radBottomLeft)
{
	if(radTopLeft < 0.1f && radTopRight < 0.1f && radBottomRight < 0.1f && radBottomLeft < 0.1f) {
		nvgRect(ctx, x, y, w, h);
		return;
	} else {
		float halfw = nvg__absf(w)*0.5f;
		float halfh = nvg__absf(h)*0.5f;
		float rxBL = nvg__minf(radBottomLeft, halfw) * nvg__signf(w), ryBL = nvg__minf(radBottomLeft, halfh) * nvg__signf(h);
		float rxBR = nvg__minf(radBottomRight, halfw) * nvg__signf(w), ryBR = nvg__minf(radBottomRight, halfh) * nvg__signf(h);
		float rxTR = nvg__minf(radTopRight, halfw) * nvg__signf(w), ryTR = nvg__minf(radTopRight, halfh) * nvg__signf(h);
		float rxTL = nvg__minf(radTopLeft, halfw) * nvg__signf(w), ryTL = nvg__minf(radTopLeft, halfh) * nvg__signf(h);
		float vals[] = {
			NVG_MOVETO, x, y + ryTL,
			NVG_LINETO, x, y + h - ryBL,
			NVG_BEZIERTO, x, y + h - ryBL*(1 - NVG_KAPPA90), x + rxBL*(1 - NVG_KAPPA90), y + h, x + rxBL, y + h,
			NVG_LINETO, x + w - rxBR, y + h,
			NVG_BEZIERTO, x + w - rxBR*(1 - NVG_KAPPA90), y + h, x + w, y + h - ryBR*(1 - NVG_KAPPA90), x + w, y + h - ryBR,
			NVG_LINETO, x + w, y + ryTR,
			NVG_BEZIERTO, x + w, y + ryTR*(1 - NVG_KAPPA90), x + w - rxTR*(1 - NVG_KAPPA90), y, x + w - rxTR, y,
			NVG_LINETO, x + rxTL, y,
			NVG_BEZIERTO, x + rxTL*(1 - NVG_KAPPA90), y, x, y + ryTL*(1 - NVG_KAPPA90), x, y + ryTL,
			NVG_CLOSE
		};
		nvg__appendCommands(ctx, vals, NVG_COUNTOF(vals));
	}
}

void nvgEllipse(NVGcontext* ctx, float cx, float cy, float rx, float ry)
{
	float vals[] = {
		NVG_MOVETO, cx-rx, cy,
		NVG_BEZIERTO, cx-rx, cy+ry*NVG_KAPPA90, cx-rx*NVG_KAPPA90, cy+ry, cx, cy+ry,
		NVG_BEZIERTO, cx+rx*NVG_KAPPA90, cy+ry, cx+rx, cy+ry*NVG_KAPPA90, cx+rx, cy,
		NVG_BEZIERTO, cx+rx, cy-ry*NVG_KAPPA90, cx+rx*NVG_KAPPA90, cy-ry, cx, cy-ry,
		NVG_BEZIERTO, cx-rx*NVG_KAPPA90, cy-ry, cx-rx, cy-ry*NVG_KAPPA90, cx-rx, cy,
		NVG_CLOSE
	};
	nvg__appendCommands(ctx, vals, NVG_COUNTOF(vals));
}

void nvgCircle(NVGcontext* ctx, float cx, float cy, float r)
{
	nvgEllipse(ctx, cx,cy, r,r);
}

void nvgDebugDumpPathCache(NVGcontext* ctx)
{
	const NVGpath* path;
	int i, j;

	printf("Dumping %d cached paths\n", ctx->cache->npaths);
	for (i = 0; i < ctx->cache->npaths; i++) {
		path = &ctx->cache->paths[i];
		printf(" - Path %d\n", i);
		if (path->nfill) {
			printf("   - fill: %d\n", path->nfill);
			for (j = 0; j < path->nfill; j++)
				printf("%f\t%f\n", path->fill[j].x, path->fill[j].y);
		}
		if (path->nstroke) {
			printf("   - stroke: %d\n", path->nstroke);
			for (j = 0; j < path->nstroke; j++)
				printf("%f\t%f\n", path->stroke[j].x, path->stroke[j].y);
		}
	}
}

static void nvg__renderClip(NVGcontext* ctx, bool evenOdd)
{
    NVGstate* state = nvg__getState(ctx);
    const NVGpath* path;
    int i;

    nvg__flattenPaths(ctx, false, true);
    // Translucent anti aliasing cannot be used in the reduction area, so anti aliasing related logic is not followed
    nvg__expandFill(ctx, 0.0f, NVG_MITER, 2.4f);

    ctx->params.renderClip(ctx->params.userPtr, state->compositeOperation, &state->scissor, ctx->fringeWidth,
                           ctx->cache->paths, ctx->cache->npaths, evenOdd);

    // Count triangles
    for (i = 0; i < ctx->cache->npaths; i++) {
        path = &ctx->cache->paths[i];
        ctx->fillTriCount += path->nfill-2;
        ctx->fillTriCount += path->nstroke-2;
        ctx->drawCallCount += 2;
    }

    nvg__autoClearPathCache(ctx);
}

static void nvg__checkToRenderClips(NVGcontext* ctx)
{
    auto& clipPaths = ctx->backups.clipPaths;
    auto& bk = ctx->backups.clips;
    if (bk.nitems <= 0) {
        return;
    }
    nvgBackupPath(ctx);
    for (int i = 0; i < bk.nitems; ++i) {
        const auto& cur = bk.items[i];
        const int len = cur.end - cur.start;
        if (len <= 0 || len > ctx->ccommands) {
            continue;
        }

        ctx->ncommands = len;
        ctx->commandver = cur.ver;
        memcpy(ctx->commands, clipPaths.items + cur.start, sizeof(float) * len);

        nvg__renderClip(ctx, cur.evenodd);
    }
    nvgRestorePath(ctx);
}

inline void nvg__autoRestoreClips(NVGcontext* ctx) {
    auto& bk = ctx->backups.clips;
    NVGstate& curState = ctx->states[ctx->nstates-1];
    if (bk.nitems <= curState.clipCount) {
		// not changed
        return;
    }

	if (bk.nitems > 0) {
	    ctx->addClipsBeforeNext = true;
	}
    bk.nitems = curState.clipCount;
    auto& clipPaths = ctx->backups.clipPaths;
    clipPaths.nitems = (bk.nitems > 0) ? bk.items[bk.nitems-1].end : 0;
}

bool nvgHasClip(NVGcontext* ctx) {
    NVGstate& curState = ctx->states[ctx->nstates-1];
    return curState.clipCount > 0;
}

void nvgClip(NVGcontext* ctx, bool evenOdd)
{
    NVG_CMD_DEBUG("ctx.clip('%s');\r\n",(evenOdd?"evenodd":"nonzero"));

    if (!nvg__backupClipPath(ctx, evenOdd)) {
        return;
    }

    NVGstate* state = nvg__getState(ctx);
    state->clipCount = ctx->backups.clips.nitems;

    nvg__renderClip(ctx, evenOdd);
}

inline void nvg__forceRenderFlush(NVGcontext* ctx)
{
    ctx->params.renderFlush(ctx->params.userPtr);

    if (ctx->backups.clips.nitems > 0) {
        ctx->addClipsBeforeNext = true;
    }
}

inline void nvg__autoCheckAndRenderClips(NVGcontext* ctx)
{
    if (ctx->addClipsBeforeNext) {
        ctx->addClipsBeforeNext = false;

	    ctx->params.resetClip(ctx->params.userPtr);

        nvg__checkToRenderClips(ctx);
    }
}

inline void nvg__applyGlobalAlphaToPainColor(NVGstate* state, NVGpaint& paint) {
    if (paint.image != 0) {
        if (paint.type == NVG_PAINT_LINEAR_GRADIENT || paint.type == NVG_PAINT_RADIAL_GRADIENT) {
            paint.innerColor.a = state->alpha;
            paint.outerColor.a = state->alpha;
            return;
        }
    }
    paint.innerColor.a *= state->alpha;
    paint.outerColor.a *= state->alpha;
}

static inline void nvg__pointSub(NVGpoint& dst, const NVGpoint& p1, const NVGpoint& p2) {
    dst.x = p1.x - p2.x;
    dst.y = p1.y - p2.y;
}

static inline float nvg__crossProduct(const NVGpoint& p1, const NVGpoint& p2) {
    return p1.x * p2.y -  p2.x * p1.y;
}

static inline float nvg__pointToSegDistSquare(const NVGpoint& p, const NVGpoint& p1, const NVGpoint& p2) {
    const float cross = (p2.x - p1.x) * (p.x - p1.x) + (p2.y - p1.y) * (p.y - p1.y);
    if (cross <= 0) return (p.x - p1.x) * (p.x - p1.x) + (p.y - p1.y) * (p.y - p1.y);

    const float d2 = (p2.x - p1.x) * (p2.x - p1.x) + (p2.y - p1.y) * (p2.y - p1.y);
    if (cross >= d2) return (p.x - p2.x) * (p.x - p2.x) + (p.y - p2.y) * (p.y - p2.y);

    const float r = cross / d2;
    const float px = p1.x + (p2.x - p1.x) * r;
    const float py = p1.y + (p2.y - p1.y) * r;
    return (p.x - px) * (p.x - px) + (py - p.y) * (py - p.y);
}

bool nvgIsPointInConvexPolygon(NVGcontext* ctx, float x, float y, short opts) {
    if (isnan(x) || isinf(x) || isnan(y) || isinf(y)) {
        return false;
    }

    nvg__flattenPaths(ctx, false, false);

    NVGpathCache* cache = ctx->cache;
    if (cache->npaths <= 0) {
        return false;
    }

    NVGstate* state = nvg__getState(ctx);
    NVGpoint vTarget = {.x = x, .y = y};
    const bool isStrokeMode = ((opts & NVG_POINTCK_STROKE)!= 0);
    const float distTol = isStrokeMode ? state->strokeWidth * 0.5f : ctx->distTol;
    if (vTarget.x < cache->bounds[0] - distTol || vTarget.x > cache->bounds[2] + distTol) {
        return false;
    }
    if (vTarget.y < cache->bounds[1] - distTol || vTarget.y > cache->bounds[3] + distTol) {
        return false;
    }

    // Calculate the direction and length of line segments.
    int resultCount = 0;
    for (int j = 0; j < cache->npaths; j++) {
        float nCurCrossProduct = 0, nLastValue = 0;
        NVGpath* path = &cache->paths[j];
        if (path->count <= 0) {
            continue;
        }
        NVGpoint* pts = &cache->points[path->first];
        NVGpoint* p0 = &pts[path->count-1];
        NVGpoint* p1 = &pts[0];
        if (isStrokeMode) {
            const float distSquare = distTol * distTol;
            for (int i = 0; i < path->count; i++) {
                float curSQ = nvg__pointToSegDistSquare(vTarget, *p1, *p0);
                if (curSQ <= distSquare) {
                    return true;
                }
                p0 = p1++;
            }
        } else {
            bool isInBound = false;
            for (int i = 0; i < path->count; i++) {
                NVGpoint vU, vV;
                nvg__pointSub(vU, vTarget, *p0);
                nvg__pointSub(vV, *p1, *p0);
                nCurCrossProduct = nvg__crossProduct(vU, vV);
                if (i > 0 && nCurCrossProduct * nLastValue <= 0) {
                    isInBound = false;
                    break;
                }
                isInBound = true;
                nLastValue = nCurCrossProduct;
                p0 = p1++;
            }
            if (isInBound) {
                ++resultCount;
            } else {
                p0 = &pts[path->count-1];
                p1 = &pts[0];
                for (int i = 0; i < path->count; i++) {
                    float curSQ = nvg__pointToSegDistSquare(vTarget, *p1, *p0);
                    if (curSQ <= 1e-5) {
                        // point is on the line
                        resultCount = 1;
                        break;
                    }
                    p0 = p1++;
                }
            }
        }
    }

    if (isStrokeMode) {
        return false;
    } else if ((opts & NVG_POINTCK_EVENODD)!= 0) {
        return resultCount % 2;
    } else {
        return resultCount > 0;
    }
}

void nvgFillEx(NVGcontext* ctx, bool evenOdd)
{
    NVG_CMD_DEBUG("ctx.fill('%s');\r\n",(evenOdd?"evenodd":"nonzero"));

	NVGstate* state = nvg__getState(ctx);
	const NVGpath* path;
	NVGpaint fillPaint = state->fill;

    if (fillPaint.imageFlags & NVG_IMAGE_TRANSFORM) {
        float current_transfrom[6];
        nvgCurrentTransform(ctx, current_transfrom);
        nvgTransformPremultiply(fillPaint.xform, current_transfrom);
    }

	int i;

    nvg__autoCheckAndRenderClips(ctx);

	nvg__flattenPaths(ctx, false, false);
	if (ctx->params.edgeAntiAlias && state->shapeAntiAlias)
		nvg__expandFill(ctx, ctx->fringeWidth, NVG_MITER, 2.4f);
	else
		nvg__expandFill(ctx, 0.0f, NVG_MITER, 2.4f);

    nvg__applyGlobalAlphaToPainColor(state, fillPaint);

	ctx->params.renderFill(ctx->params.userPtr, &fillPaint, state->compositeOperation, &state->scissor, ctx->fringeWidth,
						   ctx->cache->bounds, ctx->cache->paths, ctx->cache->npaths, evenOdd);

	// Count triangles
	for (i = 0; i < ctx->cache->npaths; i++) {
		path = &ctx->cache->paths[i];
		ctx->fillTriCount += path->nfill-2;
		ctx->fillTriCount += path->nstroke-2;
		ctx->drawCallCount += 2;
	}

}

void nvgFill(NVGcontext* ctx)
{
	nvgFillEx(ctx, false);
}

void nvgRestore(NVGcontext* ctx)
{
    NVG_CMD_DEBUG("ctx.restore();\r\n");

    if (ctx->nstates <= 1)
        return;

    ctx->nstates--;

    nvg__autoRestoreClips(ctx);
}

void nvgStroke(NVGcontext* ctx)
{
    NVG_CMD_DEBUG("ctx.stroke();\r\n");

	NVGstate* state = nvg__getState(ctx);
	float scale = nvg__getAverageScale(state->xform);
	float strokeWidth = nvg__clampf(state->strokeWidth * scale, 0.0f, 200.0f);
	NVGpaint strokePaint = state->stroke;
	const NVGpath* path;
	int i;

    nvg__autoCheckAndRenderClips(ctx);

	if (strokeWidth < ctx->fringeWidth) {
		// If the stroke width is less than pixel size, use alpha to emulate coverage.
		// Since coverage is area, scale by alpha*alpha.
		float alpha = nvg__clampf(strokeWidth / ctx->fringeWidth, 0.0f, 1.0f);
		strokePaint.innerColor.a *= alpha*alpha;
		strokePaint.outerColor.a *= alpha*alpha;
		strokeWidth = ctx->fringeWidth;
	}

    nvg__applyGlobalAlphaToPainColor(state, strokePaint);

	nvg__flattenPaths(ctx, true, false);

	if (ctx->params.edgeAntiAlias && state->shapeAntiAlias)
		nvg__expandStroke(ctx, strokeWidth*0.5f, ctx->fringeWidth, state->lineCap, state->lineJoin, state->miterLimit);
	else
		nvg__expandStroke(ctx, strokeWidth*0.5f, 0.0f, state->lineCap, state->lineJoin, state->miterLimit);

	ctx->params.renderStroke(ctx->params.userPtr, &strokePaint, state->compositeOperation, &state->scissor, ctx->fringeWidth,
							 strokeWidth, ctx->cache->paths, ctx->cache->npaths);

	// Count triangles
	for (i = 0; i < ctx->cache->npaths; i++) {
		path = &ctx->cache->paths[i];
		ctx->strokeTriCount += path->nstroke-2;
		ctx->drawCallCount++;
	}

    if (state->dashLen > 0) {
        nvg__autoClearPathCache(ctx);
    }
}

// Add fonts
int nvgCreateFont(NVGcontext* ctx, const char* name, const char* path)
{
	return fonsAddFont(ctx->fs, name, path);
}

int nvgCreateFontMem(NVGcontext* ctx, const char* name, unsigned char* data, int ndata, int freeData)
{
	return fonsAddFontMem(ctx->fs, name, data, ndata, freeData);
}

int nvgFindFont(NVGcontext* ctx, const char* name)
{
	if (name == NULL) return -1;
	return fonsGetFontByName(ctx->fs, name);
}

int nvgAutoLoadSystemFont(NVGcontext* ctx, const char* name)
{
    if (name == NULL) return -1;
    return fonsAutoLoadSystemFontByName(ctx->fs, name);
}

int nvgAddFallbackFontId(NVGcontext* ctx, int baseFont, int fallbackFont)
{
	if (baseFont == -1 || fallbackFont == -1) return 0;

    // deep copy the fallbacks
	return fonsAddFallbackFont(ctx->fs, baseFont, fallbackFont, true);
}

int nvgAddFallbackFont(NVGcontext* ctx, const char* baseFont, const char* fallbackFont)
{
	return nvgAddFallbackFontId(ctx, nvgFindFont(ctx, baseFont), nvgFindFont(ctx, fallbackFont));
}

// State setting
void nvgFontSize(NVGcontext* ctx, float size)
{
	NVGstate* state = nvg__getState(ctx);
	state->fontSize = size;
}

void nvgFontBlur(NVGcontext* ctx, float blur)
{
	NVGstate* state = nvg__getState(ctx);
	state->fontBlur = blur;
}

void nvgTextLetterSpacing(NVGcontext* ctx, float spacing)
{
	NVGstate* state = nvg__getState(ctx);
	state->letterSpacing = spacing;
}

void nvgTextLineHeight(NVGcontext* ctx, float lineHeight)
{
	NVGstate* state = nvg__getState(ctx);
	state->lineHeight = lineHeight;
}

void nvgTextAlign(NVGcontext* ctx, int align)
{
	NVGstate* state = nvg__getState(ctx);
	state->textAlign = align;
}

void nvgFontFaceId(NVGcontext* ctx, int font)
{
	NVGstate* state = nvg__getState(ctx);
	state->fontId = font;
}

void nvgFontFace(NVGcontext* ctx, const char* font)
{
	NVGstate* state = nvg__getState(ctx);
	state->fontId = fonsGetFontByName(ctx->fs, font);
}

void nvgFontWSV(NVGcontext* ctx, unsigned short packagedWSV)
{
    NVGstate* state = nvg__getState(ctx);
    state->fontWSV = packagedWSV;
}

static float nvg__quantize(float a, float d)
{
	return ((int)(a / d + 0.5f)) * d;
}

static float nvg__getFontScale(NVGstate* state)
{
	return nvg__minf(nvg__quantize(nvg__getAverageScale(state->xform), 0.01f), 4.0f);
}

static void nvg__renderText(NVGcontext* ctx, NVGvertex* verts, int nverts, int bitmapOption, bool isTrueColor)
{
	NVGstate* state = nvg__getState(ctx);
	NVGpaint paint = bitmapOption & NVG_STROKE ? state->stroke : state->fill;

    nvg__autoCheckAndRenderClips(ctx);

    nvg__applyGlobalAlphaToPainColor(state, paint);

	if (isTrueColor) {
		paint.innerColor.r = paint.innerColor.g = paint.innerColor.b = 1.0f;
		paint.outerColor = paint.innerColor;
        ctx->cache->txtopts |= 2;
    } else {
        ctx->cache->txtopts |= 1;
    }

    const int fontImage = nvg__autoNewOrUpdateFontImage(ctx, isTrueColor, false);
	ctx->params.renderTriangles(ctx->params.userPtr, &paint, fontImage, state->compositeOperation, &state->scissor, verts, nverts);

	ctx->drawCallCount++;
	ctx->textTriCount += nverts/3;
}

static void fonsErrorCallback(void* uptr, FONSerrorCode error, const FONSerrorParam& val) {
	if (error == FONS_ATLAS_FULL) {
		auto& onTextAtlasFull = *static_cast<std::function<void(const FONSerrorParam& val)> *>(uptr);
		onTextAtlasFull(val);
	}
}

static inline void nvg__renderFlushTextTexture(NVGcontext* ctx) {
    int& opts = ctx->cache->txtopts;
    const bool hasNormalTxt = (opts & 1);
    const bool hasColorTxt = (opts & 2);
    opts = 0;

    int dirty[4];
    if (hasNormalTxt) {
        FONScacheTex& tex = ctx->fs.texNormal;
        if (fonsValidateTexture(tex, dirty)) {
            ctx->params.renderUpdateTexture(ctx->params.userPtr, ctx->fontImage, dirty[0], dirty[1], dirty[2] - dirty[0], dirty[3] - dirty[1], tex.texData());
        }
    }
    if (hasColorTxt) {
        FONScacheTex& tex = ctx->fs.texTrueColor;
        if (fonsValidateTexture(tex, dirty)) {
            ctx->params.renderUpdateTexture(ctx->params.userPtr, ctx->emojiImage, dirty[0], dirty[1], dirty[2] - dirty[0], dirty[3] - dirty[1], tex.texData());
        }
    }
}

float nvgText(NVGcontext* ctx, float x, float y, const char* string, const char* end, int bitmapOption)
{
	NVGstate* state = nvg__getState(ctx);
	FONSquad q;

	float scale = nvg__getFontScale(state) * ctx->devicePxRatio;
	float invscale = 1.0f / scale;

	if (end == NULL) {
		end = string + strlen(string);
	}
	if (end == string || *string == 0) {
		return x;
	}

	if (state->fontId == FONS_INVALID) return x;

    const int VERTS_PER_CHAR = 6;
    const int buffLen = nvg__maxi(2, (int)(end - string)) * VERTS_PER_CHAR;
    NVGvertex* tex = nullptr;
    int texOffset = 0, texCount = 0;
    bool lastColorType = false;

    std::function<void(const FONSerrorParam&)> onTextAtlasFull = [&](const FONSerrorParam& errParam) {
        if (tex && texCount > 0) {
            nvg__renderText(ctx, tex+texOffset, texCount, bitmapOption, lastColorType);
        }
        union FONSCountDown& cd = ctx->fs.countDown;
        cd.data.noneText = FONS_NOTEXT_COUNTDOWN;
        if (ctx->cache->txtopts) {
            nvg__renderFlushTextTexture(ctx);
        }
        nvg__forceRenderFlush(ctx);
        const bool isTrueColor = errParam.atlas.isTrueColor;
		if (isTrueColor) {
            // if cd.data.trueColor > 0 then we enlarge the atlas and tex
			fonsResetAtlasTrueColor(ctx->fs, cd.data.trueColor > 0, errParam.atlas.minWidthHeight);
            cd.data.trueColor = FONS_FORCEFLUSH_COUNTDOWN;
		} else {
            // if cd.data.normal > 0 then we enlarge the atlas and tex
			fonsResetAtlas(ctx->fs, cd.data.normal > 0, errParam.atlas.minWidthHeight);
            cd.data.normal = FONS_FORCEFLUSH_COUNTDOWN;
		}
        nvg__autoNewOrUpdateFontImage(ctx, isTrueColor, true);
        tex = nullptr; // clear and continue
	};
	fonsSetErrorCallback(ctx->fs, fonsErrorCallback, &onTextAtlasFull);

	FONSstate fstate = {
        .font = state->fontId,
        .align = state->textAlign,
        .size = state->fontSize * scale,
		.blur = state->fontBlur * scale,
		.spacing = state->letterSpacing * scale,
		.strokeWidth = state->strokeWidth * scale,
		.lineJoin = state->lineJoin,
		.lineCap = state->lineCap,
		.fontWSV = state->fontWSV,
	};

	FONStextIter iter;
	fonsTextIterInit(ctx->fs, fstate, iter, x*scale, y*scale, string, end, bitmapOption);
	while (fonsTextIterNext(ctx->fs, iter, &q)) {
		if (iter.prevGlyphIndex == -1) { // can not retrieve glyph?
			continue;
		}
		float c[4*2];
		// Transform corners.
		nvgTransformPoint(&c[0],&c[1], state->xform, q.x0*invscale, q.y0*invscale);
		nvgTransformPoint(&c[2],&c[3], state->xform, q.x1*invscale, q.y0*invscale);
		nvgTransformPoint(&c[4],&c[5], state->xform, q.x1*invscale, q.y1*invscale);
		nvgTransformPoint(&c[6],&c[7], state->xform, q.x0*invscale, q.y1*invscale);

        if (tex == nullptr) {
            tex = nvg__allocTempTextVerts(ctx, buffLen);
            if (tex == nullptr) return x;
            texOffset = texCount = 0;
            lastColorType = iter.isTrueColor;
        } else if (lastColorType != iter.isTrueColor) {
            if (texCount > 0) {
                nvg__renderText(ctx, tex+texOffset, texCount, bitmapOption, lastColorType);
                texOffset += texCount; texCount = 0;
            }
            lastColorType = iter.isTrueColor;
        }

        NVGvertex* verts = tex + texOffset + texCount;
        nvg__vset(verts, c[0], c[1], q.s0, q.t0);
        nvg__vset(verts + 1, c[4], c[5], q.s1, q.t1);
        nvg__vset(verts + 2, c[2], c[3], q.s1, q.t0);
        nvg__vset(verts + 3, c[0], c[1], q.s0, q.t0);
        nvg__vset(verts + 4, c[6], c[7], q.s0, q.t1);
        nvg__vset(verts + 5, c[4], c[5], q.s1, q.t1);

        texCount += VERTS_PER_CHAR;
        ctx->cache->ntxtverts += VERTS_PER_CHAR;
	}
    if (tex && texCount > 0) {
        nvg__renderText(ctx, tex+texOffset, texCount, bitmapOption, lastColorType);
    }
	fonsSetErrorCallback(ctx->fs, nullptr, nullptr);
	return iter.nextx / scale;
}

float nvgTextBounds(NVGcontext* ctx, float x, float y, const char* string, const char* end, float* bounds)
{
	NVGstate* state = nvg__getState(ctx);
	float scale = nvg__getFontScale(state) * ctx->devicePxRatio;
	float invscale = 1.0f / scale;
	float width;

	if (state->fontId == FONS_INVALID) return 0;

	FONSstate fstate = {
        .font = state->fontId,
        .align = state->textAlign,
		.size = state->fontSize * scale,
        .blur = state->fontBlur * scale,
        .spacing = state->letterSpacing * scale,
	};

	width = fonsTextBounds(ctx->fs, fstate, x*scale, y*scale, string, end, bounds, nullptr);
	if (bounds != NULL) {
		// Use line bounds for height.
		fonsLineBounds(ctx->fs, fstate, y*scale, &bounds[1], &bounds[3]);
		bounds[0] *= invscale;
		bounds[1] *= invscale;
		bounds[2] *= invscale;
		bounds[3] *= invscale;
	}
	return width * invscale;
}

float nvgTextMetricsInfo(NVGcontext* ctx, float x, float y, const char* string, const char* end, NVGtextMetricsInfo* info)
{
	if (info == nullptr) {
		return 0;
	}

	NVGstate* state = nvg__getState(ctx);
	float scale = nvg__getFontScale(state) * ctx->devicePxRatio;
	float invscale = 1.0f / scale;
	float width;

	if (state->fontId == FONS_INVALID) {
		memset(info, 0, sizeof(NVGtextMetricsInfo));
		return 0;
	}

	FONSstate fstate = {
        .font = state->fontId,
        .align = state->textAlign,
        .size = state->fontSize * scale,
        .blur = state->fontBlur * scale,
        .spacing = state->letterSpacing * scale,
	};

	int rawAscender = 0, rawDescender = 0, unitPerEM = 0;
    fonsFontRawMatricsInfo(ctx->fs, fstate, &rawAscender, &rawDescender, &unitPerEM);
	if (unitPerEM > 0) {
		float ratio = 1.0f * fstate.size / unitPerEM;
		info->fontAscent = rawAscender * ratio;
		info->fontDescent = -rawDescender * ratio;
	} else {
		info->fontAscent = fstate.size;
		info->fontDescent = 0;
	}

	info->missingGlyphCount = 0;

	width = fonsTextBounds(ctx->fs, fstate, x*scale, y*scale, string, end, info->textBounds, &info->missingGlyphCount);
	for (int i = 0; i < 4; ++i) {
		info->textBounds[i] *= invscale;
	}

	return width * invscale;
}


void nvgSetTransform(NVGcontext* ctx, const float *matrix)
{
    NVG_CMD_DEBUG("ctx.setTransform(%.2f,%.2f,%.2f,%.2f,%.2f,%.2f);\r\n"
                  ,matrix[0],matrix[1],matrix[2],matrix[3],matrix[4],matrix[5]);

    NVGstate* state = nvg__getState(ctx);
	memcpy(state->xform, matrix, sizeof(state->xform));
}

int nvgIsDirty(NVGcontext* ctx) {
	return ctx->drawCallCount != 0;
}

static void nvg__checkTextCountDown(NVGcontext* ctx) {
    union FONSCountDown& cd = ctx->fs.countDown;
    if (cd.data.normal) {
        --cd.data.normal;
    }
    if (cd.data.trueColor) {
        --cd.data.trueColor;
    }
    if (cd.data.noneText) {
        if (ctx->textTriCount > 0) {
            cd.data.noneText = FONS_NOTEXT_COUNTDOWN;
        } else if ((--cd.data.noneText) == 0) {
            // we do not use text for some time, shrink the text cache
            fonsResetAllAtlasToDefault(ctx->fs);
            nvg__deleteFontImages(ctx);
        }
    }
}

int nvgFlush(NVGcontext* ctx) {

    NVG_CMD_DEBUG("======nvg Flush========\r\n");

	if(!ctx->drawCallCount) return 0;

    if (ctx->cache->txtopts) {
        nvg__renderFlushTextTexture(ctx);
    }

    nvg__forceRenderFlush(ctx);

    if (ctx->fs.countDown.value) {
        nvg__checkTextCountDown(ctx);
    }

		ctx->drawCallCount = 0;
    ctx->fillTriCount = ctx->strokeTriCount = ctx->textTriCount = 0;
    ctx->cache->txtopts = 0;
    ctx->cache->ntxtverts = 0;

	return 1;
}

void nvgClear(NVGcontext* ctx) {
    if(!ctx->drawCallCount) return;

    ctx->params.renderCancel(ctx->params.userPtr);

    ctx->drawCallCount = 0;
    ctx->fillTriCount = ctx->strokeTriCount = ctx->textTriCount = 0;
}

NVGShadow *nvgGetShadow(NVGcontext *ctx) {
	NVGstate* state = nvg__getState(ctx);
	return &state->shadow;
}

int nvgGetTextAlign(NVGcontext *ctx) {
	NVGstate* state = nvg__getState(ctx);
	return state->textAlign;
}

void nvgSetPaintTransform(NVGpaint *paint, const float *matrix) {
	memcpy(paint->xform, matrix, sizeof(paint->xform));
}

void nvgSetImagePatternTransform(NVGcontext *ctx, NVGpaint *paint, const float *matrix) {
    memcpy(paint->xform, matrix, sizeof(paint->xform));
    NVGstate* state = nvg__getState(ctx);
    float invMatrix[6];
    nvgTransformInverse(invMatrix, state->xform);
    nvgTransformMultiply(paint->xform, invMatrix);
}

// vim: ft=c nu noet ts=4

} // namespace nanovg
} // namespace lynx
