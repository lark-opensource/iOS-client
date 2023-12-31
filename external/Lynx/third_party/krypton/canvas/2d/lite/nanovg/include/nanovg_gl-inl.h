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
#ifndef CANVAS_2D_LITE_NANOVG_INCLUDE_NANOVG_GL_INL_H_
#define CANVAS_2D_LITE_NANOVG_INCLUDE_NANOVG_GL_INL_H_

#include <stdlib.h>
#include <stdio.h>
#include <string.h>
#include <math.h>
#include "nanovg.h"
#include "nanovg_gl.h"

#include "canvas/gpu/gl/gl_api.h"

namespace lynx {
namespace nanovg {

enum GLNVGuniformLoc {
    GLNVG_LOC_VIEWSIZE,
    GLNVG_LOC_TEX,
    GLNVG_LOC_FRAG,
    GLNVG_LOC_TEX2,
    GLNVG_TEX_SIZE,
    GLNVG_ENABLE_BICUBIC_SAMPLER,
    GLNVG_MAX_LOCS,
};

enum GLNVGshaderType {
    NSVG_SHADER_FILLGRAD,
    NSVG_SHADER_FILLIMG,
    NSVG_SHADER_SIMPLE,
    NSVG_SHADER_IMG,
    NSVG_SHADER_IMG_GRAD,
    NSVG_SHADER_IMG_PATTERN,
    NSVG_SHADER_FILLGRADTEX,
};

#if NANOVG_GL_USE_UNIFORMBUFFER
enum GLNVGuniformBindings {
    GLNVG_FRAG_BINDING = 0,
};
#endif

struct GLNVGshader {
    GLuint prog = 0;
    GLuint frag = 0;
    GLuint vert = 0;
    GLint loc[GLNVG_MAX_LOCS] = {0};
};
typedef struct GLNVGshader GLNVGshader;

struct GLNVGtexture {
    int id;
    GLuint tex;
    int width, height;
    int type;
    int flags;
};
typedef struct GLNVGtexture GLNVGtexture;

struct GLNVGblend {
    GLenum srcRGB;
    GLenum dstRGB;
    GLenum srcAlpha;
    GLenum dstAlpha;
};
typedef struct GLNVGblend GLNVGblend;

enum GLNVGcallType {
    GLNVG_NONE = 0,
    GLNVG_FILL,
    GLNVG_CONVEXFILL,
    GLNVG_STROKE,
    GLNVG_TRIANGLES,
    GLNVG_EVENODDFILL,
    GLNVG_PATTERNTRIANGLES,
    GLNVG_CLIP,
    GLNVG_EVENODDCLIP,
    GLNVG_RESETCLIP,
};

struct GLNVGcall {
    int type;
    int image;
    int pathOffset;
    int pathCount;
    int triangleOffset;
    int triangleCount;
    int uniformOffset;
    GLNVGblend blendFunc;
    int image2;
};
typedef struct GLNVGcall GLNVGcall;

struct GLNVGpath {
    int fillOffset;
    int fillCount;
    int strokeOffset;
    int strokeCount;
};
typedef struct GLNVGpath GLNVGpath;

struct GLNVGfragUniforms {
#if NANOVG_GL_USE_UNIFORMBUFFER
    float scissorMat[12];  // matrices are actually 3 vec4s
    float paintMat[12];
    struct NVGcolor innerCol;
    struct NVGcolor outerCol;
    float scissorExt[2];
    float scissorScale[2];
    float extent[2];
    float radius;
    float feather;
    float strokeMult;
    float strokeThr;
    int texType;
    int type;
#else
// note: after modifying layout or size of uniform array,
// don't forget to also update the fragment shader source!
#define NANOVG_GL_UNIFORMARRAY_SIZE 11
    union {
        struct {
            float scissorMat[12];  // matrices are actually 3 vec4s
            float paintMat[12];
            struct NVGcolor innerCol;
            struct NVGcolor outerCol;
            float scissorExt[2];
            float scissorScale[2];
            float extent[2];
            float radius;
            float feather;
            float strokeMult;
            float strokeThr;
            float texType;
            float type;
        };
        float uniformArray[NANOVG_GL_UNIFORMARRAY_SIZE][4];
    };
#endif
};
typedef struct GLNVGfragUniforms GLNVGfragUniforms;

struct GLNVGcontext {
    GLNVGshader shader;
    GLNVGtexture* textures = nullptr;
    float view[2] = {0};
    int ntextures = 0;
    int ctextures = 0;
    int textureId = 0;
    GLuint vertBuf = 0;
#if NANOVG_GL_USE_UNIFORMBUFFER
    GLuint fragBuf = 0;
#endif
    int fragSize = 0;
    int flags = 0;

    // Per frame buffers
    GLNVGcall* calls = nullptr;
    int ccalls = 0;
    int ncalls = 0;
    GLNVGpath* paths = nullptr;
    int cpaths = 0;
    int npaths = 0;
    struct NVGvertex* verts = nullptr;
    int cverts = 0;
    int nverts = 0;
    unsigned char* uniforms = nullptr;
    int cuniforms = 0;
    int nuniforms = 0;

    canvas::GLCommandBuffer *gl_interface;
};
typedef struct GLNVGcontext GLNVGcontext;

static void glnvg__getShader(GLNVGcontext* gl, GLNVGshader &shader);

static int glnvg__maxi(int a, int b) {
    return a > b ? a : b;
}

#ifdef NANOVG_GLES2
static unsigned int glnvg__nearestPow2(unsigned int num) {
    unsigned n = num > 0 ? num - 1 : 0;
    n |= n >> 1;
    n |= n >> 2;
    n |= n >> 4;
    n |= n >> 8;
    n |= n >> 16;
    n++;
    return n;
}
#endif

static canvas::GLCommandBuffer* ContextGL(GLNVGcontext* gl) {
  DCHECK(gl);
  return gl->gl_interface;
}

static void glnvg__bindTexture(GLNVGcontext* gl, GLuint tex)
{
#if NANOVG_GL_USE_STATE_FILTER
  if (gl->boundTexture != tex) {
		gl->boundTexture = tex;
		ContextGL(gl)->BindTexture(GL_TEXTURE_2D, tex);
	}
#else
  ContextGL(gl)->BindTexture(GL_TEXTURE_2D, tex);
#endif
}

static GLNVGtexture* glnvg__allocTexture(GLNVGcontext* gl) {
    GLNVGtexture* tex = NULL;
    int i;

    for (i = 0; i < gl->ntextures; i++) {
        if (gl->textures[i].id == 0) {
            tex = &gl->textures[i];
            break;
        }
    }
    if (tex == NULL) {
        if (gl->ntextures + 1 > gl->ctextures) {
            GLNVGtexture* textures;
            int ctextures = glnvg__maxi(gl->ntextures + 1, 4) + gl->ctextures / 2;  // 1.5x Overallocate
            textures = (GLNVGtexture*) realloc(gl->textures, sizeof(GLNVGtexture) * ctextures);
            if (textures == NULL) return NULL;
            gl->textures = textures;
            gl->ctextures = ctextures;
        }
        tex = &gl->textures[gl->ntextures++];
    }

    memset(tex, 0, sizeof(*tex));
    tex->id = ++gl->textureId;

    return tex;
}

static GLNVGtexture* glnvg__findTexture(GLNVGcontext* gl, int id) {
    int i;
    for (i = 0; i < gl->ntextures; i++)
        if (gl->textures[i].id == id) return &gl->textures[i];
    return NULL;
}

static int glnvg__deleteTexture(GLNVGcontext* gl, int id)
{
    int i;
    for (i = 0; i < gl->ntextures; i++) {
        if (gl->textures[i].id == id) {
            if (gl->textures[i].tex != 0 && (gl->textures[i].flags & NVG_IMAGE_NODELETE) == 0)
                ContextGL(gl)->DeleteTextures(1, &gl->textures[i].tex);
            memset(&gl->textures[i], 0, sizeof(gl->textures[i]));
            return 1;
        }
    }
    return 0;
}

static void glnvg__dumpShaderError(GLNVGcontext* gl, GLuint shader, const char* name, const char* type)
{
  GLchar str[512+1];
  GLsizei len = 0;
  ContextGL(gl)->GetShaderInfoLog(shader, 512, &len, str);
  if (len > 512) len = 512;
  str[len] = '\0';
  KRYPTON_LOGE("Shader %s/%s error: ") << name << " type " << type << " str " << str;
}

static void glnvg__dumpProgramError(GLNVGcontext* gl, GLuint prog, const char* name) {
    GLchar str[512 + 1];
    GLsizei len = 0;
    ContextGL(gl)->GetProgramInfoLog(prog, 512, &len, str);
    if (len > 512) len = 512;
    str[len] = '\0';
    KRYPTON_LOGE("Program error ") << name << " str " << str;
}

static void glnvg__checkError(GLNVGcontext* gl, const char* str) {
//  GLenum err = ContextGL(gl)->GetError();
//  if (err != GL_NO_ERROR) {
//      printf("nanovg Error %08x after %s\n", err, str);
//      return;
//  }
}

static int glnvg__createShader(GLNVGcontext* gl, GLNVGshader* shader, const char* name, const char* header, const char* opts, const char* vshader,
                               const char* fshader) {
  GLint status;
  GLuint prog, vert, frag;
  const char* str[3];
  str[0] = header;
  str[1] = opts != NULL ? opts : "";

  memset(shader, 0, sizeof(*shader));

  prog = ContextGL(gl)->CreateProgram();
  vert = ContextGL(gl)->CreateShader(GL_VERTEX_SHADER);
  frag = ContextGL(gl)->CreateShader(GL_FRAGMENT_SHADER);
  str[2] = vshader;
  ContextGL(gl)->ShaderSource(vert, 3, str, 0);
  str[2] = fshader;
  ContextGL(gl)->ShaderSource(frag, 3, str, 0);

  ContextGL(gl)->CompileShader(vert);
  ContextGL(gl)->GetShaderiv(vert, GL_COMPILE_STATUS, &status);
  if (status != GL_TRUE) {
    glnvg__dumpShaderError(gl, vert, name, "vert");
    return 0;
  }

  ContextGL(gl)->CompileShader(frag);
  ContextGL(gl)->GetShaderiv(frag, GL_COMPILE_STATUS, &status);
  if (status != GL_TRUE) {
    glnvg__dumpShaderError(gl, frag, name, "frag");
    return 0;
  }

  ContextGL(gl)->AttachShader(prog, vert);
  ContextGL(gl)->AttachShader(prog, frag);

  ContextGL(gl)->BindAttribLocation(prog, 0, "vertex");
  ContextGL(gl)->BindAttribLocation(prog, 1, "tcoord");

  ContextGL(gl)->LinkProgram(prog);
  ContextGL(gl)->GetProgramiv(prog, GL_LINK_STATUS, &status);
  if (status != GL_TRUE) {
    glnvg__dumpProgramError(gl, prog, name);
    return 0;
  }

  shader->prog = prog;
  shader->vert = vert;
  shader->frag = frag;

  return 1;
}

static void glnvg__getUniforms(GLNVGcontext* gl, GLNVGshader* shader) {
  shader->loc[GLNVG_LOC_VIEWSIZE] = ContextGL(gl)->GetUniformLocation(shader->prog, "viewSize");
  shader->loc[GLNVG_LOC_TEX] = ContextGL(gl)->GetUniformLocation(shader->prog, "tex");

#if NANOVG_GL_USE_UNIFORMBUFFER
  shader->loc[GLNVG_LOC_FRAG] = ContextGL(gl)->GetUniformBlockIndex(shader->prog, "frag");
#else
  shader->loc[GLNVG_LOC_FRAG] = ContextGL(gl)->GetUniformLocation(shader->prog, "frag");
#endif
  shader->loc[GLNVG_LOC_TEX2] = ContextGL(gl)->GetUniformLocation(shader->prog, "tex2");
  shader->loc[GLNVG_TEX_SIZE] = ContextGL(gl)->GetUniformLocation(shader->prog, "texSize");
  shader->loc[GLNVG_ENABLE_BICUBIC_SAMPLER] = ContextGL(gl)->GetUniformLocation(shader->prog, "enableBiCubicSmapler");
}

//"float sdrRGradientCenterDiff(vec2 pt, float rad, vec3 radex) {\n"
//"   vec2 v = radex.xy / abs(radex.z);\n"
//"   float aa = 2.0*v.x*v.y*pt.x*pt.y + (1.0-v.y*v.y)*pt.x*pt.x + (1.0-v.x*v.x)*pt.y*pt.y;\n"
//"   if (aa < 0.0) discard;\n"
//"   float bb = 1.0-v.y*v.y-v.x*v.x ;\n"
//"   float sigBbz = (bb > 0.0 ? 1.0 : -1.0 * sign(radex.z)) ;\n"
//"   float dd = (-v.y*pt.x-v.x*pt.y+sqrt(aa)*sigBbz)/bb ;\n"
//"   if (dd < 0.0) discard;\n"
//"   return dd - rad;\n"
//"}\n"
//"\n"
//"float calGradientD(vec2 pt, vec2 ext, float rad, vec3 radex, float fth) {\n"
//"    if (radex.x == 0.0 && radex.y == 0.0) {\n"
//"        return clamp((sdroundrect(pt, ext, rad) + fth*0.5) / fth, 0.0, 1.0);\n"
//"    } else if (radex.z == 0.0) {\n"
//"        return clamp(sdrRGradientCenterEqual(pt, rad, radex), 0.0, 1.0);\n"
//"    } else {\n"
//"        return clamp((sdrRGradientCenterDiff(pt, rad, radex) + fth*0.5) / fth, 0.0, 1.0);\n"
//"    }\n"
//"}\n"
// Renderer       PowerVR SGX 554
// Version        OpenGL ES 2.0 IMGSGX554-129
// GLSL Version   OpenGL ES GLSL ES 1.00
// MD513ZP/A iPad4
// nanovg shader , use at runtime, shader GL_INVALID_OPERATION
// Use the macro to inline directly to solve the problem

// clang-format off
#define calGradientD(ret, pt, ext, rad, radex, fth) \
    "float "#ret";\n" \
    "if ("#radex".x == 0.0 && "#radex".y == 0.0) {\n" \
    "    "#ret" = clamp((sdroundrect("#pt", "#ext", "#rad") + "#fth"*0.5) / "#fth", 0.0, 1.0);\n" \
    "} else if ("#radex".z == 0.0) {\n" \
    "    "#ret" = clamp(sdrRGradientCenterEqual("#pt", "#rad", "#radex"), 0.0, 1.0);\n" \
    "} else {\n" \
    "    vec2 v = "#radex".xy / abs("#radex".z);\n" \
    "    float aa = 2.0*v.x*v.y*"#pt".x*"#pt".y + (1.0-v.y*v.y)*"#pt".x*"#pt".x + (1.0-v.x*v.x)*"#pt".y*"#pt".y;\n" \
    "    if (aa < 0.0) discard;\n" \
    "    float bb = 1.0-v.y*v.y-v.x*v.x ;\n" \
    "    float sigBbz = (bb > 0.0 ? 1.0 : -1.0 * sign("#radex".z)) ;\n" \
    "    float dd = (-v.y*pt.x-v.x*pt.y+sqrt(aa)*sigBbz)/bb ;\n" \
    "    if (dd < 0.0) discard;\n" \
    "    "#ret" = clamp((dd - "#rad" + "#fth"*0.5) / "#fth", 0.0, 1.0);\n" \
    "}\n"
// clang-format on

static void glnvg__getShader(GLNVGcontext* gl, GLNVGshader &shader) {
    // TODO: mediump float may not be enough for GLES2 in iOS.
    // see the following discussion: https://github.com/memononen/nanovg/issues/46
    const char* shaderHeader =
#if defined NANOVG_GLES2
        "#version 100\n"
        "#define NANOVG_GL2 1\n"
#elif defined NANOVG_GLES3
        "#version 300 es\n"
        "#define NANOVG_GL3 1\n"
#endif

#if NANOVG_GL_USE_UNIFORMBUFFER
        "#define USE_UNIFORMBUFFER 1\n"
#else
        "#define UNIFORMARRAY_SIZE 11\n"
#endif
        "\n";

#define NVGL_ANTIALIAS
    const char* fillVertShader =
        "#ifdef NANOVG_GL3\n"
        "	uniform vec2 viewSize;\n"
        "	in vec2 vertex;\n"
        "	in vec2 tcoord;\n"
        "	out vec2 ftcoord;\n"
        "	out vec2 fpos;\n"
        "#else\n"
        "	uniform vec2 viewSize;\n"
        "	attribute vec2 vertex;\n"
        "	attribute vec2 tcoord;\n"
        "	varying vec2 ftcoord;\n"
        "	varying vec2 fpos;\n"
        "#endif\n"
        "void main(void) {\n"
        "	ftcoord = tcoord;\n"
        "	fpos = vertex;\n"
        "	gl_Position = vec4(2.0*vertex.x/viewSize.x - 1.0, 1.0 - 2.0*vertex.y/viewSize.y, 0, 1);\n"
        "}\n";
#ifdef ANDROID
    const char* fillFragShader =
        "#ifdef GL_ES\n"
        "#if defined(GL_FRAGMENT_PRECISION_HIGH) || defined(NANOVG_GL3)\n"
        " precision highp float;\n"
        "#else\n"
        " precision mediump float;\n"
        "#endif\n"
        "#endif\n"
        "#ifdef NANOVG_GL3\n"
        "#ifdef USE_UNIFORMBUFFER\n"
        "	layout(std140) uniform frag {\n"
        "		mat3 scissorMat;\n"
        "		mat3 paintMat;\n"
        "		vec4 innerCol;\n"
        "		vec4 outerCol;\n"
        "		vec2 scissorExt;\n"
        "		vec2 scissorScale;\n"
        "		vec2 extent;\n"
        "		float radius;\n"
        "		float feather;\n"
        "		float strokeMult;\n"
        "		float strokeThr;\n"
        "		int texType;\n"
        "		int type;\n"
        "	};\n"
        "#else\n"  // NANOVG_GL3 && !USE_UNIFORMBUFFER
        "	uniform vec4 frag[UNIFORMARRAY_SIZE];\n"
        "#endif\n"
        "	uniform sampler2D tex;\n"
        "	uniform sampler2D tex2;\n"
        "   uniform vec2 texSize;\n"
        "   uniform int enableBiCubicSmapler;\n"
        "	in vec2 ftcoord;\n"
        "	in vec2 fpos;\n"
        "	out vec4 outColor;\n"
        "#else\n"  // !NANOVG_GL3
        "	uniform vec4 frag[UNIFORMARRAY_SIZE];\n"
        "	uniform sampler2D tex;\n"
        "	uniform sampler2D tex2;\n"
        "	varying vec2 ftcoord;\n"
        "	varying vec2 fpos;\n"
        "#endif\n"
        "#ifndef USE_UNIFORMBUFFER\n"
        "	#define scissorMat mat3(frag[0].xyz, frag[1].xyz, frag[2].xyz)\n"
        "	#define paintMat mat3(frag[3].xyz, frag[4].xyz, frag[5].xyz)\n"
        "	#define innerCol frag[6]\n"
        "	#define outerCol frag[7]\n"
        "	#define scissorExt frag[8].xy\n"
        "	#define scissorScale frag[8].zw\n"
        "	#define extent frag[9].xy\n"
        "	#define radius frag[9].z\n"
        "	#define feather frag[9].w\n"
        "	#define strokeMult frag[10].x\n"
        "	#define strokeThr frag[10].y\n"
        "	#define texType int(frag[10].z)\n"
        "	#define type int(frag[10].w)\n"
        "	#define repeatX int(frag[0].w)\n"
        "	#define repeatY int(frag[1].w)\n"
        "	#define radEx vec3(frag[0].w, frag[1].w, frag[2].w)\n"
        "#endif\n"
        "\n"
        "float sdroundrect(vec2 pt, vec2 ext, float rad) {\n"
        "	vec2 ext2 = ext - vec2(rad,rad);\n"
        "	vec2 d = abs(pt) - ext2;\n"
        "	return min(max(d.x,d.y),0.0) + length(max(d,0.0)) - rad;\n"
        "}\n"
        "float sdrRGradientCenterEqual(vec2 pt, float rad, vec3 radex) {\n"
        "    float pqlenp2 = radex.x*radex.x+radex.y*radex.y;\n"
        "    float pqlen = sqrt(pqlenp2);\n"
        "    float qxmpy = radex.y*pt.x-radex.x*pt.y;\n"
        "    float aa = pqlenp2*rad*rad - qxmpy*qxmpy;\n"
        "   if (aa < 0.0) discard;\n"
        "    float dd = ((pt.x*radex.x+pt.y*radex.y+rad*pqlen) + sqrt(aa)) / pqlenp2;\n"
        "    if (dd < 0.0) discard;\n"
        "    return dd - rad / pqlen;\n"
        "}\n"
        "float sdrRGradientCenterDiff(vec2 pt, float rad, vec3 radex) {\n"
        "   vec2 v = radex.xy / abs(radex.z);\n"
        "   float aa = 2.0*v.x*v.y*pt.x*pt.y + (1.0-v.y*v.y)*pt.x*pt.x + (1.0-v.x*v.x)*pt.y*pt.y;\n"
        "   if (aa < 0.0) discard;\n"
        "   float bb = 1.0-v.y*v.y-v.x*v.x ;\n"
        "   float sigBbz = (bb > 0.0 ? 1.0 : -1.0 * sign(radex.z)) ;\n"
        "   float dd = (-v.y*pt.x-v.x*pt.y+sqrt(aa)*sigBbz)/bb ;\n"
        "   if (dd < 0.0) discard;\n"
        "   return dd - rad;\n"
        "}\n"
        "\n"
        "float calGradientD(vec2 pt, vec2 ext, float rad, vec3 radex, float fth) {\n"
        "	if (radex.x == 0.0 && radex.y == 0.0) {\n"
        "		return clamp((sdroundrect(pt, ext, rad) + fth*0.5) / fth, 0.0, 1.0);\n"
        "	} else if (radex.z == 0.0) {\n"
        "		return clamp(sdrRGradientCenterEqual(pt, rad, radex), 0.0, 1.0);\n"
        "	} else {\n"
        "		return clamp((sdrRGradientCenterDiff(pt, rad, radex) + fth*0.5) / fth, 0.0, 1.0);\n"
        "	}\n"
        "}\n"
        "float BiCubicPoly1(float x, float a) {\n"
        " x = abs(x);\n"
        " float res = (a+float(2))*x*x*x - (a+float(3))*x*x + float(1);\n"
        " return res;\n"
        "}\n"
        "float BiCubicPoly2(float x, float a) {\n"
        " x = abs(x);\n"
        " float res = a*x*x*x - float(5)*a*x*x + float(8)*a*x - float(4)*a;\n"
        " return res;\n"
        "}\n"
        "vec4 BiCubicTexture(vec2 pt, vec2 texSize, sampler2D tex, float a) {\n"
        " vec2 basic = pt * texSize - vec2(0.5, 0.5);\n"
        " vec2 det = fract(basic);\n"
        " return vec4(0.0, 0.0, 0.0, 0.0)\n"
        "   + BiCubicPoly2(det.x - float(-1), a) * BiCubicPoly2(det.y - float(-1), a) * texture(tex, pt + (-det + vec2(float(-1), float(-1)))/texSize)\n"
        "   + BiCubicPoly2(det.x - float(-1), a) * BiCubicPoly1(det.y - float(0), a) * texture(tex, pt + (-det + vec2(float(-1), float(0)))/texSize)\n"
        "   + BiCubicPoly2(det.x - float(-1), a) * BiCubicPoly1(det.y - float(1), a) * texture(tex, pt + (-det + vec2(float(-1), float(1)))/texSize)\n"
        "   + BiCubicPoly2(det.x - float(-1), a) * BiCubicPoly2(det.y - float(2), a) * texture(tex, pt + (-det + vec2(float(-1), float(2)))/texSize)\n"
        "   + BiCubicPoly1(det.x - float(0), a) * BiCubicPoly2(det.y - float(-1), a) * texture(tex, pt + (-det + vec2(float(0), float(-1)))/texSize)\n"
        "   + BiCubicPoly1(det.x - float(0), a) * BiCubicPoly1(det.y - float(0), a) * texture(tex, pt + (-det + vec2(float(0), float(0)))/texSize)\n"
        "   + BiCubicPoly1(det.x - float(0), a) * BiCubicPoly1(det.y - float(1), a) * texture(tex, pt + (-det + vec2(float(0), float(1)))/texSize)\n"
        "   + BiCubicPoly1(det.x - float(0), a) * BiCubicPoly2(det.y - float(2), a) * texture(tex, pt + (-det + vec2(float(0), float(2)))/texSize)\n"
        "   + BiCubicPoly1(det.x - float(1), a) * BiCubicPoly2(det.y - float(-1), a) * texture(tex, pt + (-det + vec2(float(1), float(-1)))/texSize)\n"
        "   + BiCubicPoly1(det.x - float(1), a) * BiCubicPoly1(det.y - float(0), a) * texture(tex, pt + (-det + vec2(float(1), float(0)))/texSize)\n"
        "   + BiCubicPoly1(det.x - float(1), a) * BiCubicPoly1(det.y - float(1), a) * texture(tex, pt + (-det + vec2(float(1), float(1)))/texSize)\n"
        "   + BiCubicPoly1(det.x - float(1), a) * BiCubicPoly2(det.y - float(2), a) * texture(tex, pt + (-det + vec2(float(1), float(2)))/texSize)\n"
        "   + BiCubicPoly2(det.x - float(2), a) * BiCubicPoly2(det.y - float(-1), a) * texture(tex, pt + (-det + vec2(float(2), float(-1)))/texSize)\n"
        "   + BiCubicPoly2(det.x - float(2), a) * BiCubicPoly1(det.y - float(0), a) * texture(tex, pt + (-det + vec2(float(2), float(0)))/texSize)\n"
        "   + BiCubicPoly2(det.x - float(2), a) * BiCubicPoly1(det.y - float(1), a) * texture(tex, pt + (-det + vec2(float(2), float(1)))/texSize)\n"
        "   + BiCubicPoly2(det.x - float(2), a) * BiCubicPoly2(det.y - float(2), a) * texture(tex, pt + (-det + vec2(float(2), float(2)))/texSize);\n"
        "}\n"
        "\n"
#ifdef NVGL_ANTIALIAS
        "// Stroke - from [0..1] to clipped pyramid, where the slope is 1px.\n"
        "float strokeMask() {\n"
        "	return min(1.0, (1.0-abs(ftcoord.x*2.0-1.0))*strokeMult) * min(1.0, ftcoord.y);\n"
        "}\n"
#endif
        "\n"
        "void main(void) {\n"
        "   vec4 result;\n"
#ifdef NVGL_ANTIALIAS
        "	float strokeAlpha = strokeMask();\n"
        "	if (strokeAlpha < strokeThr) discard;\n"
#else
        "	float strokeAlpha = 1.0;\n"
#endif
        "	if (type == 0) {			// Gradient\n"
        "		// Calculate gradient color using box gradient\n"
        "		vec2 pt = (paintMat * vec3(fpos,1.0)).xy;\n"
        "		float d = calGradientD(pt, extent, radius, radEx, feather);\n"
        "        vec4 color = mix(innerCol,outerCol,d);\n"
        "        if (texType == 1) { \n"
        "#ifdef NANOVG_GL3\n"
        "           color = texture(tex, vec2(d,0.0));\n"
        "#else\n"
        "           color = texture2D(tex, vec2(d,0.0));\n"
        "#endif\n"
        "           color = vec4(color.xyz*color.w,color.w) * innerCol.a;\n"
        "        } \n"
        "		// Combine alpha\n"
        "		color *= strokeAlpha;\n"
        "		result = color;\n"
        "	} else if (type == 1) {		// Image\n"
        "		// Calculate color fron texture\n"
        "		vec2 pt = (paintMat * vec3(fpos,1.0)).xy / extent;\n"
        "		if (repeatX == 0) {\n"
        "			if (pt.x < 0.0 || pt.x > 1.0) discard;\n"
        "		} else {\n"
        "			pt.x = fract(pt.x);"
        "		}\n"
        "		if (repeatY == 0) { \n"
        "			if (pt.y < 0.0 || pt.y > 1.0) discard;\n"
        "		} else { \n"
        "			pt.y = fract(pt.y);"
        "		}\n"
        "#ifdef NANOVG_GL3\n"
        "   vec4 color;\n"
        "   if (enableBiCubicSmapler == 1) {\n"
        "     color = BiCubicTexture(pt, texSize, tex, float(-0.3));\n"
        "   } else {\n"
        "     color = texture(tex, pt);\n"
        "   }\n"
        "#else\n"
        "		vec4 color = texture2D(tex, pt);\n"
        "#endif\n"
        "		if (texType == 1) color = vec4(color.xyz*color.w,color.w);"
        "		if (texType == 2) color = vec4(color.x);"
        "		// Apply color tint and alpha.\n"
        "		color *= innerCol;\n"
        "		// Combine alpha\n"
        "		color *= strokeAlpha;\n"
        "		result = color;\n"
        "	} else if (type == 2) {		// Stencil fill\n"
        "		result = vec4(1,1,1,1);\n"
        "	} else if (type == 3) {		// Textured tris for txt\n"
        "#ifdef NANOVG_GL3\n"
        "		vec4 color = texture(tex, ftcoord);\n"
        "#else\n"
        "		vec4 color = texture2D(tex, ftcoord);\n"
        "#endif\n"
        "		if (texType == 1) color = vec4(color.xyz*color.w,color.w);"
        "		if (texType == 2) color = vec4(color.x);"
        "		result = color * innerCol;\n"
        "	} else if (type == 4) {		// Textured tris with gradient\n"
        "#ifdef NANOVG_GL3\n"
        "		vec4 color = texture(tex2, ftcoord);\n"
        "#else\n"
        "		vec4 color = texture2D(tex2, ftcoord);\n"
        "#endif\n"
        "		color = vec4(color.x);"
        "		vec2 pt = (paintMat * vec3(fpos,1.0)).xy;\n"
        "		float d = calGradientD(pt, extent, radius, radEx, feather);\n"
        "		vec4 colorMix = mix(innerCol,outerCol,d);\n"
        "        if (texType == 1) { \n"
        "#ifdef NANOVG_GL3\n"
        "           colorMix = texture(tex, vec2(d,0.0));\n"
        "#else\n"
        "           colorMix = texture2D(tex, vec2(d,0.0));\n"
        "#endif\n"
        "           colorMix = vec4(colorMix.xyz*colorMix.w,colorMix.w) * innerCol.a;\n"
        "        } \n"
        "		result = color * colorMix;\n"
        "	} else if (type == 5) {		// Textured tris with gradient\n"
        "#ifdef NANOVG_GL3\n"
        "		vec4 color = texture(tex2, ftcoord);\n"
        "#else\n"
        "		vec4 color = texture2D(tex2, ftcoord);\n"
        "#endif\n"
        "		color = vec4(color.x);"
        "		vec2 pt = (paintMat * vec3(fpos,1.0)).xy / extent;\n"
        "		if (repeatX == 0) {\n"
        "			if (pt.x < 0.0 || pt.x > 1.0) discard;\n"
        "		} else {\n"
        "			pt.x = fract(pt.x);"
        "		}\n"
        "		if (repeatY == 0) { \n"
        "			if (pt.y < 0.0 || pt.y > 1.0) discard;\n"
        "		} else { \n"
        "			pt.y = fract(pt.y);"
        "		}\n"
        "#ifdef NANOVG_GL3\n"
        "		vec4 colorPattern = texture(tex, pt);\n"
        "#else\n"
        "		vec4 colorPattern = texture2D(tex, pt);\n"
        "#endif\n"
        "		if (texType == 1) colorPattern = vec4(colorPattern.xyz*colorPattern.w,colorPattern.w);"
        "		if (texType == 2) colorPattern = vec4(colorPattern.x);"
        "		// Apply color tint and alpha.\n"
        "		result = color * colorPattern;\n"
        "	}\n"
        "#ifdef NANOVG_GL3\n"
        "	outColor = result;\n"
        "#else\n"
        "	gl_FragColor = result;\n"
        "#endif\n"
        "}\n";
#else
    const char* fillFragShader =
		"#ifdef GL_ES\n"
		"#if defined(GL_FRAGMENT_PRECISION_HIGH) || defined(NANOVG_GL3)\n"
		" precision highp float;\n"
		"#else\n"
		" precision mediump float;\n"
		"#endif\n"
		"#endif\n"
		"#ifdef NANOVG_GL3\n"
		"#ifdef USE_UNIFORMBUFFER\n"
		"	layout(std140) uniform frag {\n"
		"		mat3 scissorMat;\n"
		"		mat3 paintMat;\n"
		"		vec4 innerCol;\n"
		"		vec4 outerCol;\n"
		"		vec2 scissorExt;\n"
		"		vec2 scissorScale;\n"
		"		vec2 extent;\n"
		"		float radius;\n"
		"		float feather;\n"
		"		float strokeMult;\n"
		"		float strokeThr;\n"
		"		int texType;\n"
		"		int type;\n"
		"	};\n"
		"#else\n" // NANOVG_GL3 && !USE_UNIFORMBUFFER
		"	uniform vec4 frag[UNIFORMARRAY_SIZE];\n"
		"#endif\n"
		"	uniform sampler2D tex;\n"
		"	uniform sampler2D tex2;\n"
    " uniform vec2 texSize;\n"
    " uniform int enableBiCubicSmapler;\n"
		"	in vec2 ftcoord;\n"
		"	in vec2 fpos;\n"
		"	out vec4 outColor;\n"
		"#else\n" // !NANOVG_GL3
		"	uniform vec4 frag[UNIFORMARRAY_SIZE];\n"
		"	uniform sampler2D tex;\n"
		"	uniform sampler2D tex2;\n"
		"	varying vec2 ftcoord;\n"
		"	varying vec2 fpos;\n"
		"#endif\n"
		"#ifndef USE_UNIFORMBUFFER\n"
		"	#define scissorMat mat3(frag[0].xyz, frag[1].xyz, frag[2].xyz)\n"
		"	#define paintMat mat3(frag[3].xyz, frag[4].xyz, frag[5].xyz)\n"
		"	#define innerCol frag[6]\n"
		"	#define outerCol frag[7]\n"
		"	#define scissorExt frag[8].xy\n"
		"	#define scissorScale frag[8].zw\n"
		"	#define extent frag[9].xy\n"
		"	#define radius frag[9].z\n"
		"	#define feather frag[9].w\n"
		"	#define strokeMult frag[10].x\n"
		"	#define strokeThr frag[10].y\n"
		"	#define texType int(frag[10].z)\n"
		"	#define type int(frag[10].w)\n"
		"	#define repeatX int(frag[0].w)\n"
		"	#define repeatY int(frag[1].w)\n"
		"	#define radEx vec3(frag[0].w, frag[1].w, frag[2].w)\n"
		"#endif\n"
		"\n"
		"float sdroundrect(vec2 pt, vec2 ext, float rad) {\n"
		"	vec2 ext2 = ext - vec2(rad,rad);\n"
		"	vec2 d = abs(pt) - ext2;\n"
		"	return min(max(d.x,d.y),0.0) + length(max(d,0.0)) - rad;\n"
		"}\n"
    "float sdrRGradientCenterEqual(vec2 pt, float rad, vec3 radex) {\n"
		"    float pqlenp2 = radex.x*radex.x+radex.y*radex.y;\n"
		"    float pqlen = sqrt(pqlenp2);\n"
		"    float qxmpy = radex.y*pt.x-radex.x*pt.y;\n"
		"    float aa = pqlenp2*rad*rad - qxmpy*qxmpy;\n"
  	     "   if (aa < 0.0) discard;\n"
		"    float dd = ((pt.x*radex.x+pt.y*radex.y+rad*pqlen) + sqrt(aa)) / pqlenp2;\n"
       	"    if (dd < 0.0) discard;\n"
       	"    return dd - rad / pqlen;\n"
		"}\n"
        "float BiCubicPoly1(float x, float a) {\n"
        " x = abs(x);\n"
        " float res = (a+float(2))*x*x*x - (a+float(3))*x*x + float(1);\n"
        " return res;\n"
        "}\n"
        "float BiCubicPoly2(float x, float a) {\n"
        " x = abs(x);\n"
        " float res = a*x*x*x - float(5)*a*x*x + float(8)*a*x - float(4)*a;\n"
        " return res;\n"
        "}\n"
        "vec4 BiCubicTexture(vec2 pt, vec2 texSize, sampler2D tex, float a) {\n"
        " vec2 basic = pt * texSize - vec2(0.5, 0.5);\n"
        " vec2 det = fract(basic);\n"
        " return vec4(0.0, 0.0, 0.0, 0.0)\n"
        "   + BiCubicPoly2(det.x - float(-1), a) * BiCubicPoly2(det.y - float(-1), a) * texture(tex, pt + (-det + vec2(float(-1), float(-1)))/texSize)\n"
        "   + BiCubicPoly2(det.x - float(-1), a) * BiCubicPoly1(det.y - float(0), a) * texture(tex, pt + (-det + vec2(float(-1), float(0)))/texSize)\n"
        "   + BiCubicPoly2(det.x - float(-1), a) * BiCubicPoly1(det.y - float(1), a) * texture(tex, pt + (-det + vec2(float(-1), float(1)))/texSize)\n"
        "   + BiCubicPoly2(det.x - float(-1), a) * BiCubicPoly2(det.y - float(2), a) * texture(tex, pt + (-det + vec2(float(-1), float(2)))/texSize)\n"
        "   + BiCubicPoly1(det.x - float(0), a) * BiCubicPoly2(det.y - float(-1), a) * texture(tex, pt + (-det + vec2(float(0), float(-1)))/texSize)\n"
        "   + BiCubicPoly1(det.x - float(0), a) * BiCubicPoly1(det.y - float(0), a) * texture(tex, pt + (-det + vec2(float(0), float(0)))/texSize)\n"
        "   + BiCubicPoly1(det.x - float(0), a) * BiCubicPoly1(det.y - float(1), a) * texture(tex, pt + (-det + vec2(float(0), float(1)))/texSize)\n"
        "   + BiCubicPoly1(det.x - float(0), a) * BiCubicPoly2(det.y - float(2), a) * texture(tex, pt + (-det + vec2(float(0), float(2)))/texSize)\n"
        "   + BiCubicPoly1(det.x - float(1), a) * BiCubicPoly2(det.y - float(-1), a) * texture(tex, pt + (-det + vec2(float(1), float(-1)))/texSize)\n"
        "   + BiCubicPoly1(det.x - float(1), a) * BiCubicPoly1(det.y - float(0), a) * texture(tex, pt + (-det + vec2(float(1), float(0)))/texSize)\n"
        "   + BiCubicPoly1(det.x - float(1), a) * BiCubicPoly1(det.y - float(1), a) * texture(tex, pt + (-det + vec2(float(1), float(1)))/texSize)\n"
        "   + BiCubicPoly1(det.x - float(1), a) * BiCubicPoly2(det.y - float(2), a) * texture(tex, pt + (-det + vec2(float(1), float(2)))/texSize)\n"
        "   + BiCubicPoly2(det.x - float(2), a) * BiCubicPoly2(det.y - float(-1), a) * texture(tex, pt + (-det + vec2(float(2), float(-1)))/texSize)\n"
        "   + BiCubicPoly2(det.x - float(2), a) * BiCubicPoly1(det.y - float(0), a) * texture(tex, pt + (-det + vec2(float(2), float(0)))/texSize)\n"
        "   + BiCubicPoly2(det.x - float(2), a) * BiCubicPoly1(det.y - float(1), a) * texture(tex, pt + (-det + vec2(float(2), float(1)))/texSize)\n"
        "   + BiCubicPoly2(det.x - float(2), a) * BiCubicPoly2(det.y - float(2), a) * texture(tex, pt + (-det + vec2(float(2), float(2)))/texSize);\n"
        "}\n"
		"\n"
#ifdef NVGL_ANTIALIAS
		"// Stroke - from [0..1] to clipped pyramid, where the slope is 1px.\n"
		"float strokeMask() {\n"
		"	return min(1.0, (1.0-abs(ftcoord.x*2.0-1.0))*strokeMult) * min(1.0, ftcoord.y);\n"
		"}\n"
#endif
		"\n"
		"void main(void) {\n"
		"   vec4 result;\n"
#ifdef NVGL_ANTIALIAS
		"	float strokeAlpha = strokeMask();\n"
		"	if (strokeAlpha < strokeThr) discard;\n"
#else
		"	float strokeAlpha = 1.0;\n"
#endif
		"	if (type == 0) {			// Gradient\n"
		"		// Calculate gradient color using box gradient\n"
		"		vec2 pt = (paintMat * vec3(fpos,1.0)).xy;\n"
                calGradientD(d, pt, extent, radius, radEx, feather)
        "        vec4 color = mix(innerCol,outerCol,d);\n"
        "        if (texType == 1) { \n"
        "#ifdef NANOVG_GL3\n"
        "           color = texture(tex, vec2(d,0.0));\n"
        "#else\n"
        "           color = texture2D(tex, vec2(d,0.0));\n"
        "#endif\n"
        "           color = vec4(color.xyz*color.w,color.w) * innerCol.a;\n"
        "        } \n"
		"		// Combine alpha\n"
		"		color *= strokeAlpha;\n"
		"		result = color;\n"
		"	} else if (type == 1) {		// Image\n"
		"		// Calculate color fron texture\n"
		"		vec2 pt = (paintMat * vec3(fpos,1.0)).xy / extent;\n"
		"		if (repeatX == 0) {\n"
		"			if (pt.x < 0.0 || pt.x > 1.0) discard;\n"
		"		} else {\n"
		"			pt.x = fract(pt.x);"
		"		}\n"
		"		if (repeatY == 0) { \n"
		"			if (pt.y < 0.0 || pt.y > 1.0) discard;\n"
		"		} else { \n"
		"			pt.y = fract(pt.y);"
		"		}\n"
		"#ifdef NANOVG_GL3\n"
        "   vec4 color;\n"
        "   if (enableBiCubicSmapler == 1) {\n"
        "     color = BiCubicTexture(pt, texSize, tex, float(-0.3));\n"
        "   } else {\n"
        "     color = texture(tex, pt);\n"
        "   }\n"
		"#else\n"
		"		vec4 color = texture2D(tex, pt);\n"
		"#endif\n"
		"		if (texType == 1) color = vec4(color.xyz*color.w,color.w);"
		"		if (texType == 2) color = vec4(color.x);"
		"		// Apply color tint and alpha.\n"
		"		color *= innerCol;\n"
		"		// Combine alpha\n"
		"		color *= strokeAlpha;\n"
		"		result = color;\n"
		"	} else if (type == 2) {		// Stencil fill\n"
		"		result = vec4(1,1,1,1);\n"
		"	} else if (type == 3) {		// Textured tris for txt\n"
		"#ifdef NANOVG_GL3\n"
		"		vec4 color = texture(tex, ftcoord);\n"
		"#else\n"
		"		vec4 color = texture2D(tex, ftcoord);\n"
		"#endif\n"
		"		if (texType == 1) color = vec4(color.xyz*color.w,color.w);"
		"		if (texType == 2) color = vec4(color.x);"
		"		result = color * innerCol;\n"
		"	} else if (type == 4) {		// Textured tris with gradient\n"
		"#ifdef NANOVG_GL3\n"
		"		vec4 color = texture(tex2, ftcoord);\n"
		"#else\n"
		"		vec4 color = texture2D(tex2, ftcoord);\n"
		"#endif\n"
		"		color = vec4(color.x);"
		"		vec2 pt = (paintMat * vec3(fpos,1.0)).xy;\n"
                calGradientD(d, pt, extent, radius, radEx, feather)
		"		vec4 colorMix = mix(innerCol,outerCol,d);\n"
        "        if (texType == 1) { \n"
        "#ifdef NANOVG_GL3\n"
        "           colorMix = texture(tex, vec2(d,0.0));\n"
        "#else\n"
        "           colorMix = texture2D(tex, vec2(d,0.0));\n"
        "#endif\n"
        "           colorMix = vec4(colorMix.xyz*colorMix.w,colorMix.w) * innerCol.a;\n"
        "        } \n"
		"		result = color * colorMix;\n"
		"	} else if (type == 5) {		// Textured tris with gradient\n"
		"#ifdef NANOVG_GL3\n"
		"		vec4 color = texture(tex2, ftcoord);\n"
		"#else\n"
		"		vec4 color = texture2D(tex2, ftcoord);\n"
		"#endif\n"
		"		color = vec4(color.x);"
		"		vec2 pt = (paintMat * vec3(fpos,1.0)).xy / extent;\n"
		"		if (repeatX == 0) {\n"
		"			if (pt.x < 0.0 || pt.x > 1.0) discard;\n"
		"		} else {\n"
		"			pt.x = fract(pt.x);"
		"		}\n"
		"		if (repeatY == 0) { \n"
		"			if (pt.y < 0.0 || pt.y > 1.0) discard;\n"
		"		} else { \n"
		"			pt.y = fract(pt.y);"
		"		}\n"
				"#ifdef NANOVG_GL3\n"
		"		vec4 colorPattern = texture(tex, pt);\n"
		"#else\n"
		"		vec4 colorPattern = texture2D(tex, pt);\n"
		"#endif\n"
		"		if (texType == 1) colorPattern = vec4(colorPattern.xyz*colorPattern.w,colorPattern.w);"
		"		if (texType == 2) colorPattern = vec4(colorPattern.x);"
		"		// Apply color tint and alpha.\n"
		"		result = color * colorPattern;\n"
		"	}\n"
		"#ifdef NANOVG_GL3\n"
		"	outColor = result;\n"
		"#else\n"
		"	gl_FragColor = result;\n"
		"#endif\n"
		"}\n";
#endif
    glnvg__createShader(gl, &shader, "shader", shaderHeader, "", fillVertShader, fillFragShader);
}

static void glnvg__deleteShader(GLNVGcontext* gl, GLNVGshader* shader)
{
  if (shader->prog != 0)
    ContextGL(gl)->DeleteProgram(shader->prog);
  if (shader->vert != 0)
    ContextGL(gl)->DeleteShader(shader->vert);
  if (shader->frag != 0)
    ContextGL(gl)->DeleteShader(shader->frag);
}

static int glnvg__renderCreate(void* uptr) {
    GLNVGcontext* gl = (GLNVGcontext*) uptr;
    int align = 4;

    glnvg__checkError(gl, "init");

    glnvg__checkError(gl, "uniform locations");
    glnvg__getShader(gl, gl->shader);
    glnvg__getUniforms(gl, &gl->shader);

    ContextGL(gl)->GenBuffers(1, &gl->vertBuf);

#if NANOVG_GL_USE_UNIFORMBUFFER
    // Create UBOs
    glUniformBlockBinding(gl->shader.prog, gl->shader.loc[GLNVG_LOC_FRAG], GLNVG_FRAG_BINDING);
    glGenBuffers(1, &gl->fragBuf);
    glGetIntegerv(GL_UNIFORM_BUFFER_OFFSET_ALIGNMENT, &align);
#endif
    gl->fragSize = sizeof(GLNVGfragUniforms) + align - sizeof(GLNVGfragUniforms) % align;

    glnvg__checkError(gl, "create done");

    ContextGL(gl)->Finish();

    return 1;
}

static int glnvg__renderCreateTexture(void* uptr, int type, int w, int h, int imageFlags, const unsigned char* data) {
    GLNVGcontext* gl = (GLNVGcontext*) uptr;
    GLNVGtexture* tex = glnvg__allocTexture(gl);

    if (tex == NULL) return 0;

#ifdef NANOVG_GLES2
    // Check for non-power of 2.
    if (glnvg__nearestPow2(w) != (unsigned int) w || glnvg__nearestPow2(h) != (unsigned int) h) {
        // No repeat
        if ((imageFlags & NVG_IMAGE_REPEATX) != 0 || (imageFlags & NVG_IMAGE_REPEATY) != 0) {
            printf("Repeat X/Y is not supported for non power-of-two textures (%d x %d)\n", w, h);
            imageFlags &= ~(NVG_IMAGE_REPEATX | NVG_IMAGE_REPEATY);
        }
    }
#endif

    ContextGL(gl)->GenTextures(1, &tex->tex);
    tex->width = w;
    tex->height = h;
    tex->type = type;
    tex->flags = imageFlags;
    glnvg__bindTexture(gl, tex->tex);

    ContextGL(gl)->PixelStorei(GL_UNPACK_ALIGNMENT, 1);
#ifndef NANOVG_GLES2
    ContextGL(gl)->PixelStorei(GL_UNPACK_ROW_LENGTH, tex->width);
    ContextGL(gl)->PixelStorei(GL_UNPACK_SKIP_PIXELS, 0);
    ContextGL(gl)->PixelStorei(GL_UNPACK_SKIP_ROWS, 0);
#endif

    if (type == NVG_TEXTURE_RGBA)
        ContextGL(gl)->TexImage2D(GL_TEXTURE_2D, 0, GL_RGBA, w, h, 0, GL_RGBA, GL_UNSIGNED_BYTE, data);
    else
#if defined(NANOVG_GLES2)
        ContextGL(gl)->TexImage2D(GL_TEXTURE_2D, 0, GL_LUMINANCE, w, h, 0, GL_LUMINANCE, GL_UNSIGNED_BYTE, data);
#elif defined(NANOVG_GLES3)
        ContextGL(gl)->TexImage2D(GL_TEXTURE_2D, 0, GL_R8, w, h, 0, GL_RED, GL_UNSIGNED_BYTE, data);
#endif

    if (imageFlags & NVG_IMAGE_NEAREST) {
        ContextGL(gl)->TexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_NEAREST);
        ContextGL(gl)->TexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_NEAREST);
    } else {
        ContextGL(gl)->TexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
        ContextGL(gl)->TexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
    }

    if (imageFlags & NVG_IMAGE_REPEATX)
        ContextGL(gl)->TexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_REPEAT);
    else
        ContextGL(gl)->TexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);

    if (imageFlags & NVG_IMAGE_REPEATY)
        ContextGL(gl)->TexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_REPEAT);
    else
        ContextGL(gl)->TexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);

    ContextGL(gl)->PixelStorei(GL_UNPACK_ALIGNMENT, 4);
#ifndef NANOVG_GLES2
    ContextGL(gl)->PixelStorei(GL_UNPACK_ROW_LENGTH, 0);
    ContextGL(gl)->PixelStorei(GL_UNPACK_SKIP_PIXELS, 0);
    ContextGL(gl)->PixelStorei(GL_UNPACK_SKIP_ROWS, 0);
#endif

    glnvg__checkError(gl, "create tex");
    glnvg__bindTexture(gl, 0);

    return tex->id;
}

static int glnvg__renderDeleteTexture(void* uptr, int image) {
    GLNVGcontext* gl = (GLNVGcontext*) uptr;
    return glnvg__deleteTexture(gl, image);
}

static int glnvg__renderUpdateTexture(void* uptr, int image, int x, int y, int w, int h, const unsigned char* data) {
    GLNVGcontext* gl = (GLNVGcontext*) uptr;
    GLNVGtexture* tex = glnvg__findTexture(gl, image);

    if (tex == NULL) return 0;
    glnvg__bindTexture(gl, tex->tex);

    ContextGL(gl)->PixelStorei(GL_UNPACK_ALIGNMENT,1);
#ifdef NANOVG_GLES2
    // No support for all of unpack, need to update a whole row at a time.
    if (tex->type == NVG_TEXTURE_RGBA)
        data += y * tex->width * 4;
    else
        data += y * tex->width;
    x = 0;
    w = tex->width;
#else
    ContextGL(gl)->PixelStorei(GL_UNPACK_ROW_LENGTH, tex->width);
    ContextGL(gl)->PixelStorei(GL_UNPACK_SKIP_ROWS, y);
#ifdef OS_IOS
    // as in some situation (x > 0 & w is even && access last row of tex) ，
    // glSubTexImage2D in iOS may cause read overflow.
    // just always treat x offset is 0
    if (UNLIKELY(x > 0 && w % 2 == 0 && (y + h == tex->height))) {
      ContextGL(gl)->PixelStorei(GL_UNPACK_SKIP_PIXELS, 0);
      x = 0;
      w = tex->width;
    }
    else {
#endif
        ContextGL(gl)->PixelStorei(GL_UNPACK_SKIP_PIXELS, x);
#ifdef OS_IOS
    }
#endif
#endif

    if (tex->type == NVG_TEXTURE_RGBA)
        ContextGL(gl)->TexSubImage2D(GL_TEXTURE_2D, 0, x, y, w, h, GL_RGBA, GL_UNSIGNED_BYTE, data);
    else
#if defined(NANOVG_GLES2)
        ContextGL(gl)->TexSubImage2D(GL_TEXTURE_2D, 0, x, y, w, h, GL_LUMINANCE, GL_UNSIGNED_BYTE, data);
#else
        ContextGL(gl)->TexSubImage2D(GL_TEXTURE_2D, 0, x, y, w, h, GL_RED, GL_UNSIGNED_BYTE, data);
#endif

    ContextGL(gl)->PixelStorei(GL_UNPACK_ALIGNMENT, 4);
#ifndef NANOVG_GLES2
    ContextGL(gl)->PixelStorei(GL_UNPACK_ROW_LENGTH, 0);
    ContextGL(gl)->PixelStorei(GL_UNPACK_SKIP_PIXELS, 0);
    ContextGL(gl)->PixelStorei(GL_UNPACK_SKIP_ROWS, 0);
#endif
    glnvg__bindTexture(gl, 0);

    return 1;
}

static int glnvg__renderGetTextureSize(void* uptr, int image, int* w, int* h) {
    GLNVGcontext* gl = (GLNVGcontext*) uptr;
    GLNVGtexture* tex = glnvg__findTexture(gl, image);
    if (tex == NULL) return 0;
    *w = tex->width;
    *h = tex->height;
    return 1;
}

static void glnvg__xformToMat3x4(float* m3, float* t) {
    m3[0] = t[0];
    m3[1] = t[1];
    m3[2] = 0.0f;
    m3[3] = 0.0f;
    m3[4] = t[2];
    m3[5] = t[3];
    m3[6] = 0.0f;
    m3[7] = 0.0f;
    m3[8] = t[4];
    m3[9] = t[5];
    m3[10] = 1.0f;
    m3[11] = 0.0f;
}

inline NVGcolor glnvg__premulColor(NVGcolor c) {
    c.r *= c.a;
    c.g *= c.a;
    c.b *= c.a;
    return c;
}

static int glnvg__convertPaint(GLNVGcontext* gl, GLNVGfragUniforms* frag, NVGpaint* paint, NVGscissor* scissor, float width,
                               float fringe, float strokeThr) {
    GLNVGtexture* tex = NULL;
    float invxform[6];

    memset(frag, 0, sizeof(*frag));

    frag->innerCol = glnvg__premulColor(paint->innerColor);
    frag->outerCol = glnvg__premulColor(paint->outerColor);

    if (scissor->extent[0] < -0.5f || scissor->extent[1] < -0.5f) {
        memset(frag->scissorMat, 0, sizeof(frag->scissorMat));
        frag->scissorExt[0] = 1.0f;
        frag->scissorExt[1] = 1.0f;
        frag->scissorScale[0] = 1.0f;
        frag->scissorScale[1] = 1.0f;
    } else {
        nvgTransformInverse(invxform, scissor->xform);
        glnvg__xformToMat3x4(frag->scissorMat, invxform);
        frag->scissorExt[0] = scissor->extent[0];
        frag->scissorExt[1] = scissor->extent[1];
        frag->scissorScale[0] = sqrtf(scissor->xform[0] * scissor->xform[0] + scissor->xform[2] * scissor->xform[2]) / fringe;
        frag->scissorScale[1] = sqrtf(scissor->xform[1] * scissor->xform[1] + scissor->xform[3] * scissor->xform[3]) / fringe;
    }

    memcpy(frag->extent, paint->extent, sizeof(frag->extent));
    frag->strokeMult = (width * 0.5f + fringe * 0.5f) / fringe;
    frag->strokeThr = strokeThr;

    if (paint->image != 0) {
        tex = glnvg__findTexture(gl, paint->image);
        if (tex == NULL) return 0;
        if ((tex->flags & NVG_IMAGE_FLIPY) != 0) {
            float m1[6], m2[6];
            nvgTransformTranslate(m1, 0.0f, frag->extent[1] * 0.5f);
            nvgTransformMultiply(m1, paint->xform);
            nvgTransformScale(m2, 1.0f, -1.0f);
            nvgTransformMultiply(m2, m1);
            nvgTransformTranslate(m1, 0.0f, -frag->extent[1] * 0.5f);
            nvgTransformMultiply(m1, m2);
            nvgTransformInverse(invxform, m1);
        } else {
            nvgTransformInverse(invxform, paint->xform);
        }
        frag->type = NSVG_SHADER_FILLIMG;
        if (paint->type == NVG_PAINT_IMAGE_PATTERNS) {
            // Reuse bits in scissorMat to store repeat information
            frag->scissorMat[3] = paint->imageFlags & NVG_IMAGE_REPEATX;
            frag->scissorMat[7] = paint->imageFlags & NVG_IMAGE_REPEATY;
        } else if (paint->type == NVG_PAINT_RADIAL_GRADIENT) {
            frag->scissorMat[3] = paint->rgEx[0];
            frag->scissorMat[7] = paint->rgEx[1];
            frag->scissorMat[11] = paint->rgEx[2];
        }
#if NANOVG_GL_USE_UNIFORMBUFFER
        if (tex->type == NVG_TEXTURE_RGBA)
            frag->texType = (tex->flags & NVG_IMAGE_PREMULTIPLIED) ? 0 : 1;
        else
            frag->texType = 2;
#else
        if (tex->type == NVG_TEXTURE_RGBA)
            frag->texType = (tex->flags & NVG_IMAGE_PREMULTIPLIED) ? 0.0f : 1.0f;
        else
            frag->texType = 2.0f;
#endif

        if (paint->type != NVG_PAINT_IMAGE_PATTERNS) {
            frag->type = NSVG_SHADER_FILLGRAD;
            frag->radius = paint->radius;
            frag->feather = paint->feather;
        }
    } else {
        frag->type = NSVG_SHADER_FILLGRAD;
        frag->radius = paint->radius;
        frag->feather = paint->feather;
        if (paint->type == NVG_PAINT_RADIAL_GRADIENT) {
            frag->scissorMat[3] = paint->rgEx[0];
            frag->scissorMat[7] = paint->rgEx[1];
            frag->scissorMat[11] = paint->rgEx[2];
        }
        nvgTransformInverse(invxform, paint->xform);
    }
    glnvg__xformToMat3x4(frag->paintMat, invxform);

    return 1;
}

static GLNVGfragUniforms* nvg__fragUniformPtr(GLNVGcontext* gl, int i);

static void glnvg__setUniforms(GLNVGcontext* gl, int uniformOffset, int image) {
    GLNVGtexture* tex = NULL;
#if NANOVG_GL_USE_UNIFORMBUFFER
    glBindBufferRange(GL_UNIFORM_BUFFER, GLNVG_FRAG_BINDING, gl->fragBuf, uniformOffset, sizeof(GLNVGfragUniforms));
#else
    GLNVGfragUniforms* frag = nvg__fragUniformPtr(gl, uniformOffset);
    ContextGL(gl)->Uniform4fv(gl->shader.loc[GLNVG_LOC_FRAG], NANOVG_GL_UNIFORMARRAY_SIZE, &(frag->uniformArray[0][0]));
#endif

    if (image != 0) {
        tex = glnvg__findTexture(gl, image);
        // TODO maybe need dummy tex
    }
    
    if (tex != NULL) {
      glnvg__bindTexture(gl, tex->tex);
      ContextGL(gl)->Uniform2f(gl->shader.loc[GLNVG_TEX_SIZE], tex->width, tex->height);
      ContextGL(gl)->Uniform1i(gl->shader.loc[GLNVG_ENABLE_BICUBIC_SAMPLER], (tex->flags & nanovg::NVG_IMAGE_SMOOTHINGIN) > 0);
    } else {
      glnvg__bindTexture(gl, 0);
      ContextGL(gl)->Uniform1i(gl->shader.loc[GLNVG_ENABLE_BICUBIC_SAMPLER], 0);
    }

    
    glnvg__checkError(gl, "tex paint tex");
}

static void glnvg__renderViewport(void* uptr, float width, float height, float devicePixelRatio) {
    NVG_NOTUSED(devicePixelRatio);
    GLNVGcontext* gl = (GLNVGcontext*) uptr;
    gl->view[0] = width;
    gl->view[1] = height;
}

#define AUTO_USE_CLIP_START(useClip)                                    \
    if (useClip) {                                                      \
        ContextGL(gl)->Enable(GL_STENCIL_TEST);                         \
        ContextGL(gl)->StencilMask(0xff);                               \
        ContextGL(gl)->StencilFunc(GL_EQUAL, 0x80, 0x80);               \
        ContextGL(gl)->StencilOp(GL_KEEP, GL_KEEP, GL_KEEP);            \
        ContextGL(gl)->ColorMask(GL_TRUE, GL_TRUE, GL_TRUE, GL_TRUE);   \
    }
#define AUTO_USE_CLIP_END(useClip)                                      \
    if (useClip) {                                                      \
        ContextGL(gl)->Disable(GL_STENCIL_TEST);                        \
    }

static void glnvg__clip(GLNVGcontext* gl, GLNVGcall* call, bool evenOdd) {
    GLNVGpath* paths = &gl->paths[call->pathOffset];
    int i, npaths = call->pathCount;

    // Draw shapes
    ContextGL(gl)->Enable(GL_STENCIL_TEST);
    ContextGL(gl)->StencilMask(0xff);

    ContextGL(gl)->StencilFunc(GL_NOTEQUAL, 0x00, 0xff);
    ContextGL(gl)->ColorMask(GL_FALSE, GL_FALSE, GL_FALSE, GL_FALSE);

    glnvg__setUniforms(gl, call->uniformOffset, 0);
    glnvg__checkError(gl, "clip simple");

    ContextGL(gl)->StencilOpSeparate(GL_FRONT, GL_KEEP, GL_KEEP, GL_INCR_WRAP);
    ContextGL(gl)->StencilOpSeparate(GL_BACK, GL_KEEP, GL_KEEP, GL_DECR_WRAP);
    ContextGL(gl)->Disable(GL_CULL_FACE);
    for (i = 0; i < npaths; i++) {
      ContextGL(gl)->DrawArrays(GL_TRIANGLE_FAN, paths[i].fillOffset, paths[i].fillCount);
    }
    ContextGL(gl)->Enable(GL_CULL_FACE);

    const int funcMask = (evenOdd ? 0x01 : 0x7f);
    ContextGL(gl)->StencilFunc(GL_NOTEQUAL, 0x80, funcMask);
    ContextGL(gl)->StencilOp(GL_ZERO, GL_ZERO, GL_REPLACE);
    ContextGL(gl)->DrawArrays(GL_TRIANGLE_STRIP, call->triangleOffset, call->triangleCount);

    ContextGL(gl)->Disable(GL_STENCIL_TEST);
}

static void glnvg__fill(GLNVGcontext* gl, GLNVGcall* call, bool evenOdd, bool useClip) {
    GLNVGpath* paths = &gl->paths[call->pathOffset];
    int i, npaths = call->pathCount;

    // Draw shapes
    ContextGL(gl)->Enable(GL_STENCIL_TEST);
    ContextGL(gl)->StencilMask(0xff);

    ContextGL(gl)->StencilFunc(GL_NOTEQUAL, 0x00, 0xff);
    ContextGL(gl)->ColorMask(GL_FALSE, GL_FALSE, GL_FALSE, GL_FALSE);

    // set bindpoint for solid loc
    glnvg__setUniforms(gl, call->uniformOffset, 0);
    glnvg__checkError(gl, "fill simple");

    ContextGL(gl)->StencilOpSeparate(GL_FRONT, GL_KEEP, GL_KEEP, GL_INCR_WRAP);
    ContextGL(gl)->StencilOpSeparate(GL_BACK, GL_KEEP, GL_KEEP, GL_DECR_WRAP);
    ContextGL(gl)->Disable(GL_CULL_FACE);
    for (i = 0; i < npaths; i++) {
      ContextGL(gl)->DrawArrays(GL_TRIANGLE_FAN, paths[i].fillOffset, paths[i].fillCount);
    }
    ContextGL(gl)->Enable(GL_CULL_FACE);

    // Draw anti-aliased pixels
    ContextGL(gl)->ColorMask(GL_TRUE, GL_TRUE, GL_TRUE, GL_TRUE);

    glnvg__setUniforms(gl, call->uniformOffset + gl->fragSize, call->image);
    glnvg__checkError(gl, "fill fill");

    if (gl->flags & NVG_ANTIALIAS) {
        const int funcMaskAA = (evenOdd ? 0x81 : 0xff);
        ContextGL(gl)->StencilFunc(GL_EQUAL, 0x80, funcMaskAA);
        ContextGL(gl)->StencilOp(GL_KEEP, GL_KEEP, GL_KEEP);
        // Draw fringes
        for (i = 0; i < npaths; i++) {
          ContextGL(gl)->DrawArrays(GL_TRIANGLE_STRIP, paths[i].strokeOffset, paths[i].strokeCount);
        }
    }

    // Draw fill
    if (evenOdd) {
        ContextGL(gl)->StencilFunc(GL_NOTEQUAL, 0x80, 0x01);
        ContextGL(gl)->StencilOp(GL_KEEP, GL_KEEP, GL_KEEP);
        ContextGL(gl)->DrawArrays(GL_TRIANGLE_STRIP, call->triangleOffset, call->triangleCount);
        ContextGL(gl)->ColorMask(GL_FALSE, GL_FALSE, GL_FALSE, GL_FALSE);
    }

    ContextGL(gl)->StencilFunc(GL_NOTEQUAL, 0x80, 0x7f);
    ContextGL(gl)->StencilOp(GL_KEEP, GL_KEEP, GL_REPLACE);
    ContextGL(gl)->DrawArrays(GL_TRIANGLE_STRIP, call->triangleOffset, call->triangleCount);
    ContextGL(gl)->ColorMask(GL_TRUE, GL_TRUE, GL_TRUE, GL_TRUE);

    ContextGL(gl)->Disable(GL_STENCIL_TEST);
}

static void glnvg__convexFill(GLNVGcontext* gl, GLNVGcall* call, bool useClip) {
    AUTO_USE_CLIP_START(useClip);

    GLNVGpath* paths = &gl->paths[call->pathOffset];
    int i, npaths = call->pathCount;

    glnvg__setUniforms(gl, call->uniformOffset, call->image);
    glnvg__checkError(gl, "convex fill");

    for (i = 0; i < npaths; i++) {
      ContextGL(gl)->DrawArrays(GL_TRIANGLE_FAN, paths[i].fillOffset, paths[i].fillCount);
    }

    if (gl->flags & NVG_ANTIALIAS) {
        // Draw fringes
        for (i = 0; i < npaths; i++) {
          ContextGL(gl)->DrawArrays(GL_TRIANGLE_STRIP, paths[i].strokeOffset, paths[i].strokeCount);
        }
    }

    AUTO_USE_CLIP_END(useClip);
}

static void glnvg__stroke(GLNVGcontext* gl, GLNVGcall* call, bool useClip) {
    GLNVGpath* paths = &gl->paths[call->pathOffset];
    int npaths = call->pathCount, i;

    {
        AUTO_USE_CLIP_START(useClip);

        glnvg__setUniforms(gl, call->uniformOffset, call->image);
        glnvg__checkError(gl, "stroke fill");
        // Draw Strokes
        for (i = 0; i < npaths; i++) {
          ContextGL(gl)->DrawArrays(GL_TRIANGLE_STRIP, paths[i].strokeOffset, paths[i].strokeCount);
        }

        AUTO_USE_CLIP_END(useClip);
    }
}

inline void glnvg__triangles(GLNVGcontext* gl, GLNVGcall* call, bool useClip) {
    AUTO_USE_CLIP_START(useClip);

    glnvg__setUniforms(gl, call->uniformOffset, call->image);
    glnvg__checkError(gl, "triangles fill");

    ContextGL(gl)->DrawArrays(GL_TRIANGLES, call->triangleOffset, call->triangleCount);

    AUTO_USE_CLIP_END(useClip);
}

inline void glnvg__pattern_triangles(GLNVGcontext* gl, GLNVGcall* call, bool useClip) {
    ContextGL(gl)->ActiveTexture(GL_TEXTURE1);
    GLNVGtexture* tex = glnvg__findTexture(gl, call->image2);
    glnvg__bindTexture(gl, tex != NULL ? tex->tex : 0);
    ContextGL(gl)->Uniform1i(gl->shader.loc[GLNVG_LOC_TEX2], 1);
    ContextGL(gl)->ActiveTexture(GL_TEXTURE0);

    glnvg__triangles(gl, call, useClip);

    ContextGL(gl)->ActiveTexture(GL_TEXTURE1);
    glnvg__bindTexture(gl, 0);
    ContextGL(gl)->ActiveTexture(GL_TEXTURE0);
}

static void glnvg__renderCancel(void* uptr) {
    GLNVGcontext* gl = (GLNVGcontext*) uptr;
    gl->nverts = 0;
    gl->npaths = 0;
    gl->ncalls = 0;
    gl->nuniforms = 0;
}

inline GLenum glnvg_convertBlendFuncFactor(int factor) {
    const GLenum factors[] = {
        GL_ZERO,
        GL_ONE,
        GL_SRC_COLOR,
        GL_ONE_MINUS_SRC_COLOR,
        GL_DST_COLOR,
        GL_ONE_MINUS_DST_COLOR,
        GL_SRC_ALPHA,
        GL_ONE_MINUS_SRC_ALPHA,
        GL_DST_ALPHA,
        GL_ONE_MINUS_DST_ALPHA,
        GL_SRC_ALPHA_SATURATE,
    };
    return factors[factor];
}

static GLNVGblend glnvg__blendCompositeOperation(NVGcompositeOperationState op) {
    GLNVGblend blend;
    blend.srcRGB = glnvg_convertBlendFuncFactor(op.srcRGB);
    blend.dstRGB = glnvg_convertBlendFuncFactor(op.dstRGB);
    blend.srcAlpha = glnvg_convertBlendFuncFactor(op.srcAlpha);
    blend.dstAlpha = glnvg_convertBlendFuncFactor(op.dstAlpha);
    if (blend.srcRGB == GL_INVALID_ENUM || blend.dstRGB == GL_INVALID_ENUM || blend.srcAlpha == GL_INVALID_ENUM ||
        blend.dstAlpha == GL_INVALID_ENUM) {
        blend.srcRGB = GL_ONE;
        blend.dstRGB = GL_ONE_MINUS_SRC_ALPHA;
        blend.srcAlpha = GL_ONE;
        blend.dstAlpha = GL_ONE_MINUS_SRC_ALPHA;
    }
    return blend;
}

static void glnvg__renderFlush(void* uptr) {
    GLNVGcontext* gl = (GLNVGcontext*) uptr;
    int i;
    bool useClip = false;

    if (gl->ncalls > 0) {
        // Setup require GL state.
        ContextGL(gl)->UseProgram(gl->shader.prog);

        ContextGL(gl)->Enable(GL_CULL_FACE);
        ContextGL(gl)->CullFace(GL_BACK);
        ContextGL(gl)->FrontFace(GL_CCW);
        ContextGL(gl)->Enable(GL_BLEND);
        ContextGL(gl)->Disable(GL_DEPTH_TEST);
        ContextGL(gl)->Disable(GL_SCISSOR_TEST);
        ContextGL(gl)->ColorMask(GL_TRUE, GL_TRUE, GL_TRUE, GL_TRUE);
        ContextGL(gl)->StencilMask(0xffffffff);
        ContextGL(gl)->StencilOp(GL_KEEP, GL_KEEP, GL_KEEP);
        ContextGL(gl)->StencilFunc(GL_ALWAYS, 0, 0xffffffff);
        ContextGL(gl)->ActiveTexture(GL_TEXTURE0);
        ContextGL(gl)->BindTexture(GL_TEXTURE_2D, 0);

#if NANOVG_GL_USE_UNIFORMBUFFER
        // Upload ubo for frag shaders
        ContextGL(gl)->BindBuffer(GL_UNIFORM_BUFFER, gl->fragBuf);
        ContextGL(gl)->BufferData(GL_UNIFORM_BUFFER, gl->nuniforms * gl->fragSize, gl->uniforms, GL_STREAM_DRAW);
#endif

        // Upload vertex data
        ContextGL(gl)->BindBuffer(GL_ARRAY_BUFFER, gl->vertBuf);
        ContextGL(gl)->BufferData(GL_ARRAY_BUFFER, gl->nverts * sizeof(NVGvertex), gl->verts, GL_STREAM_DRAW);
        ContextGL(gl)->EnableVertexAttribArray(0);
        ContextGL(gl)->EnableVertexAttribArray(1);
//        glDisableAttrib(2); ?
        ContextGL(gl)->VertexAttribPointer(0, 2, GL_FLOAT, GL_FALSE, sizeof(NVGvertex), (const GLvoid*)(size_t)0);
        ContextGL(gl)->VertexAttribPointer(1, 2, GL_FLOAT, GL_FALSE, sizeof(NVGvertex), (const GLvoid*)(0 + 2 * sizeof(float)));
//        glVertexAttribDivisor(0, 0);
//        glVertexAttribDivisor(1, 0);
//        glVertexAttribDivisor(2, 0); ?

        // Set view and texture just once per frame.
        ContextGL(gl)->Uniform1i(gl->shader.loc[GLNVG_LOC_TEX], 0);
        ContextGL(gl)->Uniform2fv(gl->shader.loc[GLNVG_LOC_VIEWSIZE], 1, gl->view);

#if NANOVG_GL_USE_UNIFORMBUFFER
        ContextGL(gl)->BindBuffer(GL_UNIFORM_BUFFER, gl->fragBuf);
#endif
        ContextGL(gl)->ClearStencil(0x80);
        ContextGL(gl)->Clear(GL_STENCIL_BUFFER_BIT);

        for (i = 0; i < gl->ncalls; i++) {
            GLNVGcall* call = &gl->calls[i];
            ContextGL(gl)->BlendFuncSeparate(call->blendFunc.srcRGB, call->blendFunc.dstRGB, call->blendFunc.srcAlpha,
                                  call->blendFunc.dstAlpha);
            if (call->type == GLNVG_FILL)
                glnvg__fill(gl, call, false, useClip);
            else if (call->type == GLNVG_EVENODDFILL)
                glnvg__fill(gl, call, true, useClip);
            else if (call->type == GLNVG_CONVEXFILL)
                glnvg__convexFill(gl, call, useClip);
            else if (call->type == GLNVG_STROKE)
                glnvg__stroke(gl, call, useClip);
            else if (call->type == GLNVG_TRIANGLES)
                glnvg__triangles(gl, call, useClip);
            else if (call->type == GLNVG_PATTERNTRIANGLES)
                glnvg__pattern_triangles(gl, call, useClip);
            else if (call->type == GLNVG_CLIP) {
                useClip = true;
                glnvg__clip(gl, call, false);
            } else if (call->type == GLNVG_EVENODDCLIP) {
                useClip = true;
                glnvg__clip(gl, call, true);
            } else if (call->type == GLNVG_RESETCLIP) {
                ContextGL(gl)->ClearStencil(0x80);
                ContextGL(gl)->Clear(GL_STENCIL_BUFFER_BIT);
            }
        }

        ContextGL(gl)->DisableVertexAttribArray(0);
        ContextGL(gl)->DisableVertexAttribArray(1);
        ContextGL(gl)->Disable(GL_CULL_FACE);
        ContextGL(gl)->BindBuffer(GL_ARRAY_BUFFER, 0);
        ContextGL(gl)->UseProgram(0);
        glnvg__bindTexture(gl, 0);
    }

    // Reset calls
    gl->nverts = 0;
    gl->npaths = 0;
    gl->ncalls = 0;
    gl->nuniforms = 0;
}

static int glnvg__maxVertCount(const NVGpath* paths, int npaths) {
    int i, count = 0;
    for (i = 0; i < npaths; i++) {
        count += paths[i].nfill;
        count += paths[i].nstroke;
    }
    return count;
}

static GLNVGcall* glnvg__allocCall(GLNVGcontext* gl) {
    GLNVGcall* ret = NULL;
    if (gl->ncalls + 1 > gl->ccalls) {
        GLNVGcall* calls;
        int ccalls = glnvg__maxi(gl->ncalls + 1, 128) + gl->ccalls / 2;  // 1.5x Overallocate
        calls = (GLNVGcall*) realloc(gl->calls, sizeof(GLNVGcall) * ccalls);
        if (calls == NULL) return NULL;
        gl->calls = calls;
        gl->ccalls = ccalls;
    }
    ret = &gl->calls[gl->ncalls++];
    memset(ret, 0, sizeof(GLNVGcall));
    return ret;
}

static int glnvg__allocPaths(GLNVGcontext* gl, int n) {
    int ret = 0;
    if (gl->npaths + n > gl->cpaths) {
        GLNVGpath* paths;
        int cpaths = glnvg__maxi(gl->npaths + n, 128) + gl->cpaths / 2;  // 1.5x Overallocate
        paths = (GLNVGpath*) realloc(gl->paths, sizeof(GLNVGpath) * cpaths);
        if (paths == NULL) return -1;
        gl->paths = paths;
        gl->cpaths = cpaths;
    }
    ret = gl->npaths;
    gl->npaths += n;
    return ret;
}

static int glnvg__allocVerts(GLNVGcontext* gl, int n) {
    int ret = 0;
    if (gl->nverts + n > gl->cverts) {
        NVGvertex* verts;
        int cverts = glnvg__maxi(gl->nverts + n, 4096) + gl->cverts / 2;  // 1.5x Overallocate
        verts = (NVGvertex*) realloc(gl->verts, sizeof(NVGvertex) * cverts);
        if (verts == NULL) return -1;
        gl->verts = verts;
        gl->cverts = cverts;
    }
    ret = gl->nverts;
    gl->nverts += n;
    return ret;
}

static int glnvg__allocFragUniforms(GLNVGcontext* gl, int n) {
    int ret = 0, structSize = gl->fragSize;
    if (gl->nuniforms + n > gl->cuniforms) {
        unsigned char* uniforms;
        int cuniforms = glnvg__maxi(gl->nuniforms + n, 128) + gl->cuniforms / 2;  // 1.5x Overallocate
        uniforms = (unsigned char*) realloc(gl->uniforms, structSize * cuniforms);
        if (uniforms == NULL) return -1;
        gl->uniforms = uniforms;
        gl->cuniforms = cuniforms;
    }
    ret = gl->nuniforms * structSize;
    gl->nuniforms += n;
    return ret;
}

inline GLNVGfragUniforms* nvg__fragUniformPtr(GLNVGcontext* gl, int i) {
    return (GLNVGfragUniforms*) &gl->uniforms[i];
}

inline void glnvg__vset(NVGvertex* vtx, float x, float y, float u, float v) {
    vtx->x = x;
    vtx->y = y;
    vtx->u = u;
    vtx->v = v;
}

static void glnvg__resetClip(void* uptr) {
    GLNVGcontext* gl = (GLNVGcontext*) uptr;
    GLNVGcall* call = glnvg__allocCall(gl);
    if (call == NULL) return;
    call->type = GLNVG_RESETCLIP;
    return;
}

static void glnvg__renderClip(void* uptr, NVGcompositeOperationState compositeOperation, NVGscissor* scissor, float fringe,
                              const NVGpath* paths, int npaths, bool evenOdd) {
    GLNVGcontext* gl = (GLNVGcontext*) uptr;
    GLNVGcall* call = glnvg__allocCall(gl);
    NVGvertex* quad;
    GLNVGfragUniforms* frag;
    int i, maxverts, offset;

    if (call == NULL) return;

    call->type = evenOdd ? GLNVG_EVENODDCLIP : GLNVG_CLIP;
    call->triangleCount = 4;
    call->pathOffset = glnvg__allocPaths(gl, npaths);
    if (call->pathOffset == -1) goto error;
    call->pathCount = npaths;
    call->image = 0;
    call->blendFunc = glnvg__blendCompositeOperation(compositeOperation);

    // Allocate vertices for all the paths.
    maxverts = glnvg__maxVertCount(paths, npaths) + call->triangleCount;
    offset = glnvg__allocVerts(gl, maxverts);
    if (offset == -1) goto error;

    for (i = 0; i < npaths; i++) {
        GLNVGpath* copy = &gl->paths[call->pathOffset + i];
        const NVGpath* path = &paths[i];
        memset(copy, 0, sizeof(GLNVGpath));
        if (path->nfill > 0) {
            copy->fillOffset = offset;
            copy->fillCount = path->nfill;
            memcpy(&gl->verts[offset], path->fill, sizeof(NVGvertex) * path->nfill);
            offset += path->nfill;
        }
        if (path->nstroke > 0) {
            copy->strokeOffset = offset;
            copy->strokeCount = path->nstroke;
            memcpy(&gl->verts[offset], path->stroke, sizeof(NVGvertex) * path->nstroke);
            offset += path->nstroke;
        }
    }

    // Setup uniforms for draw calls
    // Quad
    call->triangleOffset = offset;
    quad = &gl->verts[call->triangleOffset];

    glnvg__vset(&quad[0], gl->view[0], gl->view[1], 0.5f, 1.0f);
    glnvg__vset(&quad[1], gl->view[0], 0, 0.5f, 1.0f);
    glnvg__vset(&quad[2], 0, gl->view[1], 0.5f, 1.0f);
    glnvg__vset(&quad[3], 0, 0, 0.5f, 1.0f);

    call->uniformOffset = glnvg__allocFragUniforms(gl, 2);
    if (call->uniformOffset == -1) goto error;
    // Simple shader for stencil
    frag = nvg__fragUniformPtr(gl, call->uniformOffset);
    memset(frag, 0, sizeof(*frag));
    frag->strokeThr = -1.0f;
    frag->type = NSVG_SHADER_SIMPLE;
    return;

error:
    // We get here if call alloc was ok, but something else is not.
    // Roll back the last call to prevent drawing it.
    if (gl->ncalls > 0) gl->ncalls--;
}

static void glnvg__renderFill(void* uptr, NVGpaint* paint, NVGcompositeOperationState compositeOperation, NVGscissor* scissor,
                              float fringe, const float* bounds, const NVGpath* paths, int npaths, bool evenOdd) {
    GLNVGcontext* gl = (GLNVGcontext*) uptr;
    GLNVGcall* call = glnvg__allocCall(gl);
    NVGvertex* quad;
    GLNVGfragUniforms* frag;
    int i, maxverts, offset;

    if (call == NULL) return;

    call->type = evenOdd ? GLNVG_EVENODDFILL : GLNVG_FILL;
    call->triangleCount = 4;
    call->pathOffset = glnvg__allocPaths(gl, npaths);
    if (call->pathOffset == -1) goto error;
    call->pathCount = npaths;
    call->image = paint->image;
    call->blendFunc = glnvg__blendCompositeOperation(compositeOperation);

    if (npaths == 1 && paths[0].convex) {
        call->type = GLNVG_CONVEXFILL;
        call->triangleCount = 0;  // Bounding box fill quad not needed for convex fill
    }

    // Allocate vertices for all the paths.
    maxverts = glnvg__maxVertCount(paths, npaths) + call->triangleCount;
    offset = glnvg__allocVerts(gl, maxverts);
    if (offset == -1) goto error;

    for (i = 0; i < npaths; i++) {
        GLNVGpath* copy = &gl->paths[call->pathOffset + i];
        const NVGpath* path = &paths[i];
        memset(copy, 0, sizeof(GLNVGpath));
        if (path->nfill > 0) {
            copy->fillOffset = offset;
            copy->fillCount = path->nfill;
            memcpy(&gl->verts[offset], path->fill, sizeof(NVGvertex) * path->nfill);
            offset += path->nfill;
        }
        if (path->nstroke > 0) {
            copy->strokeOffset = offset;
            copy->strokeCount = path->nstroke;
            memcpy(&gl->verts[offset], path->stroke, sizeof(NVGvertex) * path->nstroke);
            offset += path->nstroke;
        }
    }

    // Setup uniforms for draw calls
    if (call->type == GLNVG_FILL || call->type == GLNVG_EVENODDFILL) {
        // Quad
        call->triangleOffset = offset;
        quad = &gl->verts[call->triangleOffset];
        glnvg__vset(&quad[0], bounds[2], bounds[3], 0.5f, 1.0f);
        glnvg__vset(&quad[1], bounds[2], bounds[1], 0.5f, 1.0f);
        glnvg__vset(&quad[2], bounds[0], bounds[3], 0.5f, 1.0f);
        glnvg__vset(&quad[3], bounds[0], bounds[1], 0.5f, 1.0f);

        call->uniformOffset = glnvg__allocFragUniforms(gl, 2);
        if (call->uniformOffset == -1) goto error;
        // Simple shader for stencil
        frag = nvg__fragUniformPtr(gl, call->uniformOffset);
        memset(frag, 0, sizeof(*frag));
        frag->strokeThr = -1.0f;
        frag->type = NSVG_SHADER_SIMPLE;
        // Fill shader
        glnvg__convertPaint(gl, nvg__fragUniformPtr(gl, call->uniformOffset + gl->fragSize), paint, scissor, fringe, fringe,
                            -1.0f);
    } else {
        call->uniformOffset = glnvg__allocFragUniforms(gl, 1);
        if (call->uniformOffset == -1) goto error;
        // Fill shader
        glnvg__convertPaint(gl, nvg__fragUniformPtr(gl, call->uniformOffset), paint, scissor, fringe, fringe, -1.0f);
    }

    return;

error:
    // We get here if call alloc was ok, but something else is not.
    // Roll back the last call to prevent drawing it.
    if (gl->ncalls > 0) gl->ncalls--;
}

static void glnvg__renderStroke(void* uptr, NVGpaint* paint, NVGcompositeOperationState compositeOperation, NVGscissor* scissor,
                                float fringe, float strokeWidth, const NVGpath* paths, int npaths) {
    GLNVGcontext* gl = (GLNVGcontext*) uptr;
    GLNVGcall* call = glnvg__allocCall(gl);
    int i, maxverts, offset;

    if (call == NULL) return;

    call->type = GLNVG_STROKE;
    call->pathOffset = glnvg__allocPaths(gl, npaths);
    if (call->pathOffset == -1) goto error;
    call->pathCount = npaths;
    call->image = paint->image;
    call->blendFunc = glnvg__blendCompositeOperation(compositeOperation);

    // Allocate vertices for all the paths.
    maxverts = glnvg__maxVertCount(paths, npaths);
    offset = glnvg__allocVerts(gl, maxverts);
    if (offset == -1) goto error;

    for (i = 0; i < npaths; i++) {
        GLNVGpath* copy = &gl->paths[call->pathOffset + i];
        const NVGpath* path = &paths[i];
        memset(copy, 0, sizeof(GLNVGpath));
        if (path->nstroke) {
            copy->strokeOffset = offset;
            copy->strokeCount = path->nstroke;
            memcpy(&gl->verts[offset], path->stroke, sizeof(NVGvertex) * path->nstroke);
            offset += path->nstroke;
        }
    }

    {
        // Fill shader
        call->uniformOffset = glnvg__allocFragUniforms(gl, 1);
        if (call->uniformOffset == -1) goto error;
        glnvg__convertPaint(gl, nvg__fragUniformPtr(gl, call->uniformOffset), paint, scissor, strokeWidth, fringe, -1.0f);
    }

    return;

error:
    // We get here if call alloc was ok, but something else is not.
    // Roll back the last call to prevent drawing it.
    if (gl->ncalls > 0) gl->ncalls--;
}

static void glnvg__renderTriangles(void* uptr, NVGpaint* paint, int fontImg, NVGcompositeOperationState compositeOperation,
                                   NVGscissor* scissor, const NVGvertex* verts, int nverts) {
    GLNVGcontext* gl = (GLNVGcontext*) uptr;
    GLNVGcall* call = glnvg__allocCall(gl);
    GLNVGfragUniforms* frag = nullptr;
    bool useGradMode = false;

    if (call == NULL) return;

    if (paint->type != NVG_PAINT_DEFAULT) {
        GLNVGtexture* tex = glnvg__findTexture(gl, fontImg);
        if (tex != NULL && tex->type != NVG_TEXTURE_RGBA) {
            useGradMode = true;
        }
    }

    if (!useGradMode) {
        call->image = paint->image = fontImg;
    } else {
        GLNVGtexture* tex = glnvg__findTexture(gl, fontImg);
        if (tex != NULL && tex->type == NVG_TEXTURE_RGBA) {
            // color fonts
            call->image = paint->image = fontImg;
        } else {
            call->image = paint->image;
            call->image2 = fontImg;
        }
    }

    call->type = GLNVG_TRIANGLES;
    call->blendFunc = glnvg__blendCompositeOperation(compositeOperation);

    // Allocate vertices for all the paths.
    call->triangleOffset = glnvg__allocVerts(gl, nverts);
    if (call->triangleOffset == -1) goto error;
    call->triangleCount = nverts;

    memcpy(&gl->verts[call->triangleOffset], verts, sizeof(NVGvertex) * nverts);
    // Fill shader
    call->uniformOffset = glnvg__allocFragUniforms(gl, 1);
    if (call->uniformOffset == -1) goto error;
    frag = nvg__fragUniformPtr(gl, call->uniformOffset);
    glnvg__convertPaint(gl, frag, paint, scissor, 1.0f, 1.0f, -1.0f);

    if (!useGradMode) {
        frag->type = NSVG_SHADER_IMG;
    } else {
        call->type = GLNVG_PATTERNTRIANGLES;
        if (paint->type == NVG_PAINT_IMAGE_PATTERNS) {
            frag->type = NSVG_SHADER_IMG_PATTERN;
        } else {
            frag->type = NSVG_SHADER_IMG_GRAD;
        }
        frag->radius = paint->radius;
        frag->feather = paint->feather;
    }

    return;
error:
    // We get here if call alloc was ok, but something else is not.
    // Roll back the last call to prevent drawing it.
    if (gl->ncalls > 0) gl->ncalls--;
}

static void glnvg__renderDelete(void* uptr) {
    GLNVGcontext* gl = (GLNVGcontext*) uptr;
    int i;
    if (gl == NULL) return;

    // TODO can be shared across 2d context so do not need to delete
    glnvg__deleteShader(gl, &gl->shader);

    if (gl->vertBuf != 0) {
        ContextGL(gl)->DeleteBuffers(1, &gl->vertBuf);
    }

    for (i = 0; i < gl->ntextures; i++) {
        if (gl->textures[i].tex != 0 && (gl->textures[i].flags & NVG_IMAGE_NODELETE) == 0) {
            ContextGL(gl)->DeleteTextures(1, &gl->textures[i].tex);
        }
    }
    free(gl->textures);

    free(gl->paths);
    free(gl->verts);
    free(gl->uniforms);
    free(gl->calls);

    delete gl;
}

#if defined NANOVG_GLES2
NVGcontext* nvgCreateGLES2(int flags)
#elif defined NANOVG_GLES3
NVGcontext* nvgCreateGLES3(int flags, canvas::GLCommandBuffer *gl_interface)
#endif
{
    NVGparams params;
    NVGcontext* ctx = NULL;
    GLNVGcontext* gl = new GLNVGcontext();
    if (gl == NULL) goto error;

    memset(&params, 0, sizeof(params));
    params.renderCreate = glnvg__renderCreate;
    params.renderCreateTexture = glnvg__renderCreateTexture;
    params.renderDeleteTexture = glnvg__renderDeleteTexture;
    params.renderUpdateTexture = glnvg__renderUpdateTexture;
    params.renderGetTextureSize = glnvg__renderGetTextureSize;
    params.renderViewport = glnvg__renderViewport;
    params.renderCancel = glnvg__renderCancel;
    params.renderFlush = glnvg__renderFlush;
    params.renderFill = glnvg__renderFill;
    params.renderClip = glnvg__renderClip;
    params.resetClip = glnvg__resetClip;
    params.renderStroke = glnvg__renderStroke;
    params.renderTriangles = glnvg__renderTriangles;
    params.renderDelete = glnvg__renderDelete;
    params.userPtr = gl;
    // Determine whether to open according to the parameter settings passed in from outside
    params.edgeAntiAlias = flags & NVG_ANTIALIAS ? 1 : 0;

    gl->flags = flags;
    gl->gl_interface = gl_interface;

    ctx = nvgCreateInternal(&params);
    if (ctx == NULL) goto error;

    return ctx;

error:
    // 'gl' is freed by nvgDeleteInternal.
    if (ctx != NULL) nvgDeleteInternal(ctx);
    return NULL;
}

#if defined NANOVG_GLES2
void nvgDeleteGLES2(NVGcontext* ctx)
#elif defined NANOVG_GLES3
void nvgDeleteGLES3(NVGcontext* ctx)
#endif
{
    nvgDeleteInternal(ctx);
}

#if defined NANOVG_GLES2
int nvglCreateImageFromHandleGLES2(NVGcontext* ctx, GLuint textureId, int w, int h, int imageFlags)
#elif defined NANOVG_GLES3
int nvglCreateImageFromHandleGLES3(NVGcontext* ctx, GLuint textureId, int w, int h, int imageFlags)
#endif
{
    GLNVGcontext* gl = (GLNVGcontext*) nvgInternalParams(ctx)->userPtr;

    GLNVGtexture* tex = NULL;
    for (int i = 0; i < gl->ntextures; i++)
        if (gl->textures[i].tex == textureId) {
            tex = &gl->textures[i];
        }
    if (tex == NULL) tex = glnvg__allocTexture(gl);
    if (tex == NULL) return 0;

    tex->type = NVG_TEXTURE_RGBA;
    tex->tex = textureId;
    tex->flags = imageFlags | NVG_IMAGE_NODELETE;
    tex->width = w;
    tex->height = h;

    return tex->id;
}

#if defined NANOVG_GLES2
GLuint nvglImageHandleGLES2(NVGcontext* ctx, int image)
#elif defined NANOVG_GLES3
GLuint nvglImageHandleGLES3(NVGcontext* ctx, int image)
#endif
{
    GLNVGcontext* gl = (GLNVGcontext*) nvgInternalParams(ctx)->userPtr;
    GLNVGtexture* tex = glnvg__findTexture(gl, image);
    return tex->tex;
}

} // namespace nanovg
} // namespace lynx

#endif  // CANVAS_2D_LITE_NANOVG_INCLUDE_NANOVG_GL_INL_H_
