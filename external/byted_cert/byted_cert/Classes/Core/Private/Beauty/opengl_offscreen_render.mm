#pragma Formatter Exempt
//
//  opengl_offscreen_render.cpp
//  smash_demo
//
//  Created by liqing on 2019/8/23.
//

#include <iostream>
#include <string.h>
#include <string>
#include <vector>
#define LOGI(...)

#include "opengl_offscreen_render.h"

#if __ANDROID__ || TARGET_OS_IOS
OpenglOffscreenRender::OpenglOffscreenRender()
    : m_shaderProgram(0)
    , m_fbo(0)
    , m_fboTexture(0) {
    memset(m_textures, 0, sizeof(m_textures));
    memset(m_textureNames, 0, sizeof(m_textureNames));
    memset(m_texNeedRelease, 0, sizeof(m_texNeedRelease));

    memset(m_attibuteNames, 0, sizeof(m_attibuteNames));
    memset(m_attributeLengthOfVec, 0, sizeof(m_attributeLengthOfVec));
    memset(m_attributeVertices, 0, sizeof(m_attributeVertices));

    memset(m_uniformNames, 0, sizeof(m_uniformNames));
    memset(m_uniformValues, 0, sizeof(m_uniformValues));
    memset(m_uniformTypes, 0, sizeof(m_uniformTypes));
    memset(m_uniformEletmentNum, 0, sizeof(m_uniformEletmentNum));
}

bool OpenglOffscreenRender::init(const char *vertexShaderSource,
                                 const char *fragmentShaderSource) {
    // vertex shader
    int vertexShader = glCreateShader(GL_VERTEX_SHADER);
    glShaderSource(vertexShader, 1, &vertexShaderSource, NULL);
    glCompileShader(vertexShader);
    // check for shader compile errors
    int success;
    glGetShaderiv(vertexShader, GL_COMPILE_STATUS, &success);
    if (success == GL_FALSE) {
        GLint length;
        glGetShaderiv(vertexShader, GL_INFO_LOG_LENGTH, &length);
        std::vector<char> error(length);
        glGetShaderInfoLog(vertexShader, length, &length, &error[0]);
        std::cout << "Failed to compile vertex shader: " << &error[0]
                  << std::endl;
        glDeleteShader(vertexShader);
        return false;
    }

    // fragment shader
    int fragmentShader = glCreateShader(GL_FRAGMENT_SHADER);
    glShaderSource(fragmentShader, 1, &fragmentShaderSource, NULL);
    glCompileShader(fragmentShader);
    // check for shader compile errors
    glGetShaderiv(fragmentShader, GL_COMPILE_STATUS, &success);
    if (success == GL_FALSE) {
        glDeleteShader(vertexShader);

        GLint length;
        glGetShaderiv(fragmentShader, GL_INFO_LOG_LENGTH, &length);
        std::vector<char> error(length);
        glGetShaderInfoLog(fragmentShader, length, &length, &error[0]);
        std::cout << "Failed to compile fragment shader: " << &error[0]
                  << std::endl;

        glDeleteShader(fragmentShader);
        return false;
    }

    // link shaders
    m_shaderProgram = glCreateProgram();
    glAttachShader(m_shaderProgram, vertexShader);
    glAttachShader(m_shaderProgram, fragmentShader);
    glLinkProgram(m_shaderProgram);
    // check for linking errors
    glGetProgramiv(m_shaderProgram, GL_LINK_STATUS, &success);
    if (success == GL_FALSE) {
        glDeleteShader(vertexShader);
        glDeleteShader(fragmentShader);

        GLint length;
        glGetShaderiv(m_shaderProgram, GL_INFO_LOG_LENGTH, &length);
        std::vector<char> error(length);
        glGetShaderInfoLog(m_shaderProgram, length, &length, &error[0]);
        std::cout << "Failed to link: " << &error[0] << std::endl;

        glDeleteProgram(m_shaderProgram);
        return false;
    }

    glDeleteShader(vertexShader);
    glDeleteShader(fragmentShader);

    return true;
}

void OpenglOffscreenRender::setTexture(int index, const char *textureName,
                                       int internalformat, int width,
                                       int height, void *pixels) {

    glPixelStorei(GL_UNPACK_ALIGNMENT, 1);
    if (m_textures[index] != 0) {
        if (m_texNeedRelease[index]) {
            glDeleteTextures(1, &m_textures[index]);
        }
        m_textures[index] = 0;
    }

    glGenTextures(1, &m_textures[index]);

    glBindTexture(GL_TEXTURE_2D, m_textures[index]);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);
    GLint format = GL_RGBA;
    switch (internalformat) {
    case 0:
        format = GL_RGBA;
        break;
    case 1:
        format = GL_LUMINANCE;
        break;
    case 2:
        format = GL_RGB;
        break;
    default:
        break;
    }
    glTexImage2D(GL_TEXTURE_2D, 0, format, width, height, 0, format,
                 GL_UNSIGNED_BYTE, pixels);

    m_textureNames[index] = textureName;
    m_texNeedRelease[index] = true;

    glBindTexture(GL_TEXTURE_2D, 0);
}

void OpenglOffscreenRender::setTexture(int index, const char *textureName,
                                       const int texId) {
    if (m_textures[index] != 0) {
        if (m_texNeedRelease[index]) {
            glDeleteTextures(1, &m_textures[index]);
        }
        m_textures[index] = 0;
    }

    m_textures[index] = texId;
    m_texNeedRelease[index] = false;
    m_textureNames[index] = textureName;
}

void OpenglOffscreenRender::getTextureByName(const char *textureNamem,
                                             unsigned int &texId) {
    texId = -1;
    if (textureNamem == nullptr || strlen(textureNamem) == 0) {
        return;
    }
    for (int i = 0; i < MAX_TEXTURE_NUM; i++) {
        if (m_textureNames[i] && strcmp(textureNamem, m_textureNames[i]) == 0) {
            texId = m_textures[i];
            return;
        }
    }
}

void OpenglOffscreenRender::setAttitude(int index, const char *name,
                                        int lengthOfVec,
                                        const float *vertices) {
    m_attributeLengthOfVec[index] = lengthOfVec;
    m_attibuteNames[index] = name;
    m_attributeVertices[index] = vertices;
}

void OpenglOffscreenRender::setUniform(int index, const char *name,
                                       DataType type, const void *value,
                                       int elementNum) {
    m_uniformNames[index] = name;
    m_uniformTypes[index] = type;
    m_uniformValues[index] = value;
    m_uniformEletmentNum[index] = elementNum;
}

OpenglOffscreenRender::~OpenglOffscreenRender() {
    if (m_fbo > 0) {
        glDeleteFramebuffers(1, &m_fbo);
    }

    if (m_depthBuffer > 0) {
        glDeleteRenderbuffers(1, &m_depthBuffer);
    }

    if (m_shaderProgram > 0) {
        glDeleteProgram(m_shaderProgram);
    }

    if (m_fboTexture > 0) {
        glDeleteTextures(1, &m_fboTexture);
    }

    for (int i = 0; i < MAX_TEXTURE_NUM; i++) {
        if (m_textures[i] > 0 && m_texNeedRelease[i]) {
            glDeleteTextures(1, &m_textures[i]);
        }
    }
}
void OpenglOffscreenRender::render(int width, int height, int pointsNum,
                                   const unsigned short *indices) {
    this->render(0, 0, width, height, pointsNum, indices);
}

void OpenglOffscreenRender::render(int x, int y, int width, int height,
                                   int pointsNum,
                                   const unsigned short *indices) {
    // create fbo
    if ((m_fbo == 0 || m_frameBufWidth != width ||
         m_frameBufHeight != height) &&
        isOffScreenRender) {
        m_frameBufWidth = width;
        m_frameBufHeight = height;
        // 创建并初始化 FBO 纹理
        glGenTextures(1, &m_fboTexture);
        glBindTexture(GL_TEXTURE_2D, m_fboTexture);
        glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);
        glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);
        glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
        glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
        glBindTexture(GL_TEXTURE_2D, GL_NONE);

        // 创建并初始化 FBO
        glGenFramebuffers(1, &m_fbo);
        glBindFramebuffer(GL_FRAMEBUFFER, m_fbo);
        glBindTexture(GL_TEXTURE_2D, m_fboTexture);
        glFramebufferTexture2D(GL_FRAMEBUFFER, GL_COLOR_ATTACHMENT0,
                               GL_TEXTURE_2D, m_fboTexture, 0);
        glTexImage2D(GL_TEXTURE_2D, 0, GL_RGBA, width, height, 0, GL_RGBA,
                     GL_UNSIGNED_BYTE, nullptr);
        if (glCheckFramebufferStatus(GL_FRAMEBUFFER) !=
            GL_FRAMEBUFFER_COMPLETE) {
            return;
        }

        glGenRenderbuffers(1, &m_depthBuffer);
        glBindRenderbuffer(GL_RENDERBUFFER, m_depthBuffer);
        glRenderbufferStorage(GL_RENDERBUFFER, GL_DEPTH24_STENCIL8, width,
                              height);

        glFramebufferRenderbuffer(GL_FRAMEBUFFER, GL_DEPTH_ATTACHMENT,
                                  GL_RENDERBUFFER, m_depthBuffer);
        glFramebufferRenderbuffer(GL_FRAMEBUFFER, GL_STENCIL_ATTACHMENT,
                                  GL_RENDERBUFFER, m_depthBuffer);

        glBindTexture(GL_TEXTURE_2D, GL_NONE);
        glBindFramebuffer(GL_FRAMEBUFFER, GL_NONE);
    }

    if (isOffScreenRender) {
        glBindFramebuffer(GL_FRAMEBUFFER, m_fbo);
    }

    if (m_enableDepthTest) {
        glEnable(GL_DEPTH_TEST);
        glDepthFunc(GL_LESS);
    }
    if (m_enableCullFace) {
        glEnable(GL_CULL_FACE);
    }
    if (m_enableBlend) {
        glEnable(GL_BLEND);
        glBlendFunc(GL_ONE, GL_ONE_MINUS_SRC_ALPHA);
    }

    glViewport(x, y, width, height);
    glClearColor(0.0f, 0.f, 0.f, 0.0f);
    if (m_enableClearFrameBuf) {
        glClear(GL_DEPTH_BUFFER_BIT | GL_COLOR_BUFFER_BIT);
    }

    glUseProgram(m_shaderProgram);

    // set attributes
    for (int i = 0; i < MAX_ATTRIBUTE_NUM; i++) {
        const char *name = m_attibuteNames[i];
        if (name == nullptr) {
            break;
        }

        int len = m_attributeLengthOfVec[i];
        const float *vertice = m_attributeVertices[i];

        GLuint gvPositionHandle = glGetAttribLocation(m_shaderProgram, name);
        glVertexAttribPointer(gvPositionHandle, len, GL_FLOAT, GL_FALSE, 0,
                              (void *)vertice);
        glEnableVertexAttribArray(gvPositionHandle);
    }

    LOGI("glGetError : %d", glGetError());

    // set uniforms
    for (int i = 0; i < MAX_UNIFORM_NUM; i++) {
        const char *name = m_uniformNames[i];
        if (name == nullptr) {
            break;
        }
        GLuint loc = glGetUniformLocation(m_shaderProgram, name);
        const void *v = m_uniformValues[i];
        DataType type = m_uniformTypes[i];
        int elementNum = m_uniformEletmentNum[i];
        switch (type) {
        case DT_INT: {
            int *value = (int *)v;
            switch (elementNum) {
            case 1:
                glUniform1i(loc, value[0]);
                break;
            case 2:
                glUniform2i(loc, value[0], value[1]);
                break;
            case 3:
                glUniform3i(loc, value[0], value[1], value[2]);
                break;
            case 4:
                glUniform4i(loc, value[0], value[1], value[2], value[3]);
                break;
            default:
                glUniform1iv(loc, elementNum, value);
                break;
            }
        } break;
        case DT_FLOAT: {
            float *value = (float *)v;
            switch (elementNum) {
            case 1:
                glUniform1f(loc, value[0]);
                break;
            case 2:
                glUniform2f(loc, value[0], value[1]);
                break;
            case 3:
                glUniform3f(loc, value[0], value[1], value[2]);
                break;
            case 4:
                glUniform4f(loc, value[0], value[1], value[2], value[3]);
                break;
            case 9:
                glUniformMatrix3fv(loc, 1, GL_FALSE, value);
                break;
            case 16:
                glUniformMatrix4fv(loc, 1, GL_FALSE, value);
                break;
            default:
                glUniform1fv(loc, elementNum, value);
                break;
            }
        } break;
        }
    }

    // set textures
    for (int i = 0; i < MAX_TEXTURE_NUM; i++) {
        int texId = m_textures[i];
        if (texId == 0) {
            break;
        }
        const char *texName = m_textureNames[i];

        glActiveTexture(GL_TEXTURE0 + i);
        glBindTexture(GL_TEXTURE_2D, texId);
        GLuint loc = glGetUniformLocation(m_shaderProgram, texName);
        glUniform1i(loc, i);
    }

    // draw
    GLenum mode;
    switch (m_bm) {
    case BM_TRIANGLE_STRIP:
        mode = GL_TRIANGLE_STRIP;
        break;
    case BM_TRIANGLE:
        mode = GL_TRIANGLES;
        break;
    case BM_POINTS:
        mode = GL_POINTS;
        break;
    default:
        mode = GL_TRIANGLE_STRIP;
        break;
    }
    if (indices == nullptr) {
        glDrawArrays(mode, 0, pointsNum);
    } else {
        glDrawElements(mode, pointsNum, GL_UNSIGNED_SHORT, indices);
    }

    glDisable(GL_DEPTH_TEST);
    glDisable(GL_BLEND);
    glDisable(GL_CULL_FACE);
}

void OpenglOffscreenRender::getRenderResult(int width, int height,
                                            void *pixels) {
    if (isOffScreenRender) {
        glBindFramebuffer(GL_FRAMEBUFFER, m_fbo);
    }
    // read pixels from fbo
    glPixelStorei(GL_PACK_ALIGNMENT, 1);
    glReadPixels(0, 0, width, height, GL_RGBA, GL_UNSIGNED_BYTE, pixels);

    if (isOffScreenRender) {
        glBindFramebuffer(GL_FRAMEBUFFER, 0);
    }
}

void OpenglOffscreenRender::clearBuffer() {
    if (isOffScreenRender) {
        glBindFramebuffer(GL_FRAMEBUFFER, m_fbo);
        glClearColor(0.0f, 0.f, 0.f, 0.0f);
        glClear(GL_DEPTH_BUFFER_BIT | GL_COLOR_BUFFER_BIT);
        glBindFramebuffer(GL_FRAMEBUFFER, 0);
    }
}

#endif
