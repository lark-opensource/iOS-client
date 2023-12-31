//
//  opengl_offscreen_render.hpp
//  smash_demo
//
//  Created by liqing on 2019/8/23.
//
#if __ANDROID__ || TARGET_OS_IOS
#ifndef opengl_offscreen_render_hpp
#define opengl_offscreen_render_hpp
//#include "base.h"
#ifdef __ANDROID__
#include <GLES2/gl2.h>
#include <GLES2/gl2ext.h>
#define glBindVertexArray glBindVertexArrayOES
#define glDeleteVertexArrays glDeleteVertexArraysOES
#define glGenVertexArrays glGenVertexArraysOES
#define glIsVertexArray glIsVertexArrayOES
#define GL_DEPTH24_STENCIL8 GL_DEPTH24_STENCIL8_OES
#define glClearDepth glClearDepthf
#include <malloc.h>

#include <android/log.h>
#include <jni.h>
#define LOG_TAG "offscreen"
#define LOGI(...) __android_log_print(ANDROID_LOG_INFO, LOG_TAG, __VA_ARGS__)

#elif WIN32
#define WIN32_LEAN_AND_MEAN
#define GLEW_STATIC
#include <GL/glew.h>
#define GP_USE_VAO
#elif __linux__
#define GLEW_STATIC
#include <GL/glew.h>
#define GP_USE_VAO
#elif __APPLE__
#include "TargetConditionals.h"
#if TARGET_OS_IPHONE || TARGET_IPHONE_SIMULATOR
#include <OpenGLES/ES2/gl.h>
#include <OpenGLES/ES2/glext.h>
#define glBindVertexArray glBindVertexArrayOES
#define glDeleteVertexArrays glDeleteVertexArraysOES
#define glGenVertexArrays glGenVertexArraysOES
#define glIsVertexArray glIsVertexArrayOES
#define GL_DEPTH24_STENCIL8 GL_DEPTH24_STENCIL8_OES
#define glClearDepth glClearDepthf
#define OPENGL_ES
#define GP_USE_VAO
#elif TARGET_OS_MAC
#include <OpenGL/gl.h>
#include <OpenGL/glext.h>
#define glBindVertexArray glBindVertexArrayAPPLE
#define glDeleteVertexArrays glDeleteVertexArraysAPPLE
#define glGenVertexArrays glGenVertexArraysAPPLE
#define glIsVertexArray glIsVertexArrayAPPLE
#define GP_USE_VAO
#else
#error "Unsupported Apple Device"
#endif
#endif

#if __ANDROID__ || TARGET_OS_IOS
//#include "opengl_meshcreator.h"
//#include <glm/glm.hpp>
//#include <glm/gtc/matrix_transform.hpp>
//#include <glm/gtc/quaternion.hpp>
// using namespace glm;

enum DataType { DT_UINT = 0, DT_INT, DT_FLOAT };

enum BeginMode { BM_TRIANGLE_STRIP = 0, BM_TRIANGLE, BM_POINTS };

class OpenglOffscreenRender {
public:
    OpenglOffscreenRender();
    ~OpenglOffscreenRender();

    bool init(const char *vertexShaderSource, const char *fragmentShaderSource);
    void setTexture(int index, const char *textureName, int internalformat,
                    int width, int height, void *pixels);
    void setAttitude(int index, const char *name, int lengthOfVec,
                     const float *vertices);
    void setUniform(int index, const char *name, DataType type,
                    const void *value, int elementNum = 1);
    void getRenderResult(int width, int height, void *pixels);
    void render(int width, int height, int pointsNum,
                const unsigned short *indices = nullptr);
    void render(int x, int y, int width, int height, int pointsNum,
                const unsigned short *indices = nullptr);
    int getOutputTexture() { return m_fboTexture; }
    void setTexture(int index, const char *textureName, const int texId);
    void setBeginMode(BeginMode bm) { m_bm = bm; }
    void setEnableDepthTest(bool flag) { m_enableDepthTest = flag; };
    void setEnableCullFace(bool flag) { m_enableCullFace = flag; };
    void setEnableBlend(bool flag) { m_enableBlend = flag; };
    void setEnableClearFrameBuf(bool flag) { m_enableClearFrameBuf = flag; };
    void setIsOffScreenRender(bool flag) { isOffScreenRender = flag; };
    void getTextureByName(const char *textureNamem, unsigned int &texId);
    void clearBuffer();

private:
    static constexpr int MAX_TEXTURE_NUM = 16;
    static constexpr int MAX_ATTRIBUTE_NUM = 8;
    static constexpr int MAX_UNIFORM_NUM = 128;

    unsigned int m_shaderProgram;
    unsigned int m_fbo;
    unsigned int m_depthBuffer = 0;
    unsigned int m_fboTexture;
    int m_frameBufWidth = 0;
    int m_frameBufHeight = 0;
    BeginMode m_bm = BM_TRIANGLE_STRIP;
    unsigned int m_textures[MAX_TEXTURE_NUM];
    bool m_texNeedRelease[MAX_TEXTURE_NUM];
    int m_attributeLengthOfVec[MAX_ATTRIBUTE_NUM];
    DataType m_uniformTypes[MAX_UNIFORM_NUM];
    int m_uniformEletmentNum[MAX_UNIFORM_NUM];
    bool isOffScreenRender = true;
    // 3D相关
    bool m_enableDepthTest = false;
    bool m_enableBlend = false;
    bool m_enableCullFace = false;
    bool m_enableClearFrameBuf = true;

    //以下数组元素只存指针，不拥有数据
    const char *m_textureNames[MAX_TEXTURE_NUM];
    const char *m_attibuteNames[MAX_ATTRIBUTE_NUM];
    const char *m_uniformNames[MAX_UNIFORM_NUM];
    const float *m_attributeVertices[MAX_ATTRIBUTE_NUM];
    const void *m_uniformValues[MAX_UNIFORM_NUM];
};

#endif /* opengl_offscreen_render_hpp */
#endif
#endif
