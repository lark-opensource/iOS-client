#ifndef CANVAS_GPU_GL_CONSTANTS_H_
#define CANVAS_GPU_GL_CONSTANTS_H_

/* User define */
#define KR_GL_FALSE 0
#define KR_GL_TRUE 1
#define KR_GL_INFO_LOG_LENGTH 0x8B84

/*
 * WEBGL 1.0
 */
/* ClearBufferMask */
#define KR_GL_DEPTH_BUFFER_BIT 0x00000100
#define KR_GL_STENCIL_BUFFER_BIT 0x00000400
#define KR_GL_COLOR_BUFFER_BIT 0x00004000

/* BeginMode */
#define KR_GL_POINTS 0x0000
#define KR_GL_LINES 0x0001
#define KR_GL_LINE_LOOP 0x0002
#define KR_GL_LINE_STRIP 0x0003
#define KR_GL_TRIANGLES 0x0004
#define KR_GL_TRIANGLE_STRIP 0x0005
#define KR_GL_TRIANGLE_FAN 0x0006

/* BlendingFactorDest */
#define KR_GL_ZERO 0
#define KR_GL_ONE 1
#define KR_GL_SRC_COLOR 0x0300
#define KR_GL_ONE_MINUS_SRC_COLOR 0x0301
#define KR_GL_SRC_ALPHA 0x0302
#define KR_GL_ONE_MINUS_SRC_ALPHA 0x0303
#define KR_GL_DST_ALPHA 0x0304
#define KR_GL_ONE_MINUS_DST_ALPHA 0x0305

/* BlendingFactorSrc */
/*      ZERO */
/*      ONE */
#define KR_GL_DST_COLOR 0x0306
#define KR_GL_ONE_MINUS_DST_COLOR 0x0307
#define KR_GL_SRC_ALPHA_SATURATE 0x0308
/*      SRC_ALPHA */
/*      ONE_MINUS_SRC_ALPHA */
/*      DST_ALPHA */
/*      ONE_MINUS_DST_ALPHA */

/* BlendEquationSeparate */
#define KR_GL_FUNC_ADD 0x8006
#define KR_GL_BLEND_EQUATION 0x8009
#define KR_GL_BLEND_EQUATION_RGB 0x8009 /* same as BLEND_EQUATION */
#define KR_GL_BLEND_EQUATION_ALPHA 0x883D

/* BlendSubtract */
#define KR_GL_FUNC_SUBTRACT 0x800A
#define KR_GL_FUNC_REVERSE_SUBTRACT 0x800B

/* Separate Blend Functions */
#define KR_GL_BLEND_DST_RGB 0x80C8
#define KR_GL_BLEND_SRC_RGB 0x80C9
#define KR_GL_BLEND_DST_ALPHA 0x80CA
#define KR_GL_BLEND_SRC_ALPHA 0x80CB
#define KR_GL_CONSTANT_COLOR 0x8001
#define KR_GL_ONE_MINUS_CONSTANT_COLOR 0x8002
#define KR_GL_CONSTANT_ALPHA 0x8003
#define KR_GL_ONE_MINUS_CONSTANT_ALPHA 0x8004
#define KR_GL_BLEND_COLOR 0x8005

/* Buffer Objects */
#define KR_GL_ARRAY_BUFFER 0x8892
#define KR_GL_ELEMENT_ARRAY_BUFFER 0x8893
#define KR_GL_ARRAY_BUFFER_BINDING 0x8894
#define KR_GL_ELEMENT_ARRAY_BUFFER_BINDING 0x8895

#define KR_GL_STREAM_DRAW 0x88E0
#define KR_GL_STATIC_DRAW 0x88E4
#define KR_GL_DYNAMIC_DRAW 0x88E8

#define KR_GL_BUFFER_SIZE 0x8764
#define KR_GL_BUFFER_USAGE 0x8765

#define KR_GL_CURRENT_VERTEX_ATTRIB 0x8626

/* CullFaceMode */
#define KR_GL_FRONT 0x0404
#define KR_GL_BACK 0x0405
#define KR_GL_FRONT_AND_BACK 0x0408

/* EnableCap */
/* TEXTURE_2D */
#define KR_GL_CULL_FACE 0x0B44
#define KR_GL_BLEND 0x0BE2
#define KR_GL_DITHER 0x0BD0
#define KR_GL_STENCIL_TEST 0x0B90
#define KR_GL_DEPTH_TEST 0x0B71
#define KR_GL_SCISSOR_TEST 0x0C11
#define KR_GL_POLYGON_OFFSET_FILL 0x8037
#define KR_GL_SAMPLE_ALPHA_TO_COVERAGE 0x809E
#define KR_GL_SAMPLE_COVERAGE 0x80A0

/* ErrorCode */
#define KR_GL_NO_ERROR 0
#define KR_GL_INVALID_ENUM 0x0500
#define KR_GL_INVALID_VALUE 0x0501
#define KR_GL_INVALID_OPERATION 0x0502
#define KR_GL_OUT_OF_MEMORY 0x0505

/* FrontFaceDirection */
#define KR_GL_CW 0x0900
#define KR_GL_CCW 0x0901

/* GetPName */
#define KR_GL_LINE_WIDTH 0x0B21
#define KR_GL_ALIASED_POINT_SIZE_RANGE 0x846D
#define KR_GL_ALIASED_LINE_WIDTH_RANGE 0x846E
#define KR_GL_CULL_FACE_MODE 0x0B45
#define KR_GL_FRONT_FACE 0x0B46
#define KR_GL_DEPTH_RANGE 0x0B70
#define KR_GL_DEPTH_WRITEMASK 0x0B72
#define KR_GL_DEPTH_CLEAR_VALUE 0x0B73
#define KR_GL_DEPTH_FUNC 0x0B74
#define KR_GL_STENCIL_CLEAR_VALUE 0x0B91
#define KR_GL_STENCIL_FUNC 0x0B92
#define KR_GL_STENCIL_FAIL 0x0B94
#define KR_GL_STENCIL_PASS_DEPTH_FAIL 0x0B95
#define KR_GL_STENCIL_PASS_DEPTH_PASS 0x0B96
#define KR_GL_STENCIL_REF 0x0B97
#define KR_GL_STENCIL_VALUE_MASK 0x0B93
#define KR_GL_STENCIL_WRITEMASK 0x0B98
#define KR_GL_STENCIL_BACK_FUNC 0x8800
#define KR_GL_STENCIL_BACK_FAIL 0x8801
#define KR_GL_STENCIL_BACK_PASS_DEPTH_FAIL 0x8802
#define KR_GL_STENCIL_BACK_PASS_DEPTH_PASS 0x8803
#define KR_GL_STENCIL_BACK_REF 0x8CA3
#define KR_GL_STENCIL_BACK_VALUE_MASK 0x8CA4
#define KR_GL_STENCIL_BACK_WRITEMASK 0x8CA5
#define KR_GL_VIEWPORT 0x0BA2
#define KR_GL_SCISSOR_BOX 0x0C10
/*      SCISSOR_TEST */
#define KR_GL_COLOR_CLEAR_VALUE 0x0C22
#define KR_GL_COLOR_WRITEMASK 0x0C23
#define KR_GL_UNPACK_ALIGNMENT 0x0CF5
#define KR_GL_PACK_ALIGNMENT 0x0D05
#define KR_GL_MAX_TEXTURE_SIZE 0x0D33
#define KR_GL_MAX_VIEWPORT_DIMS 0x0D3A
#define KR_GL_SUBPIXEL_BITS 0x0D50
#define KR_GL_RED_BITS 0x0D52
#define KR_GL_GREEN_BITS 0x0D53
#define KR_GL_BLUE_BITS 0x0D54
#define KR_GL_ALPHA_BITS 0x0D55
#define KR_GL_DEPTH_BITS 0x0D56
#define KR_GL_STENCIL_BITS 0x0D57
#define KR_GL_POLYGON_OFFSET_UNITS 0x2A00

/*      POLYGON_OFFSET_FILL */
#define KR_GL_POLYGON_OFFSET_FACTOR 0x8038
#define KR_GL_TEXTURE_BINDING_2D 0x8069
#define KR_GL_SAMPLE_BUFFERS 0x80A8
#define KR_GL_SAMPLES 0x80A9
#define KR_GL_SAMPLE_COVERAGE_VALUE 0x80AA
#define KR_GL_SAMPLE_COVERAGE_INVERT 0x80AB

/* GetTextureParameter */
/*      TEXTURE_MAG_FILTER */
/*      TEXTURE_MIN_FILTER */
/*      TEXTURE_WRAP_S */
/*      TEXTURE_WRAP_T */

#define KR_GL_COMPRESSED_TEXTURE_FORMATS 0x86A3

/* HintMode */
#define KR_GL_DONT_CARE 0x1100
#define KR_GL_FASTEST 0x1101
#define KR_GL_NICEST 0x1102

/* HintTarget */
#define KR_GL_GENERATE_MIPMAP_HINT 0x8192

/* DataType */
#define KR_GL_BYTE 0x1400
#define KR_GL_UNSIGNED_BYTE 0x1401
#define KR_GL_SHORT 0x1402
#define KR_GL_UNSIGNED_SHORT 0x1403
#define KR_GL_INT 0x1404
#define KR_GL_UNSIGNED_INT 0x1405
#define KR_GL_FLOAT 0x1406
#define KR_GL_HALF_FLOAT_OES 0x8D61

/* PixelFormat */
#define KR_GL_DEPTH_COMPONENT 0x1902
#define KR_GL_ALPHA 0x1906
#define KR_GL_RGB 0x1907
#define KR_GL_RGBA 0x1908
#define KR_GL_LUMINANCE 0x1909
#define KR_GL_LUMINANCE_ALPHA 0x190A
#define KR_GL_RGBA32F_EXT 0x8814
#define KR_GL_RGB32F_EXT 0x8815

/* PixelType */
/*      UNSIGNED_BYTE */
#define KR_GL_UNSIGNED_SHORT_4_4_4_4 0x8033
#define KR_GL_UNSIGNED_SHORT_5_5_5_1 0x8034
#define KR_GL_UNSIGNED_SHORT_5_6_5 0x8363

/* Shaders */
#define KR_GL_FRAGMENT_SHADER 0x8B30
#define KR_GL_VERTEX_SHADER 0x8B31
#define KR_GL_MAX_VERTEX_ATTRIBS 0x8869
#define KR_GL_MAX_VERTEX_UNIFORM_VECTORS 0x8DFB
#define KR_GL_MAX_VARYING_VECTORS 0x8DFC
#define KR_GL_MAX_COMBINED_TEXTURE_IMAGE_UNITS 0x8B4D
#define KR_GL_MAX_VERTEX_TEXTURE_IMAGE_UNITS 0x8B4C
#define KR_GL_MAX_TEXTURE_IMAGE_UNITS 0x8872
#define KR_GL_MAX_FRAGMENT_UNIFORM_VECTORS 0x8DFD
#define KR_GL_SHADER_TYPE 0x8B4F
#define KR_GL_DELETE_STATUS 0x8B80
#define KR_GL_LINK_STATUS 0x8B82
#define KR_GL_VALIDATE_STATUS 0x8B83
#define KR_GL_ATTACHED_SHADERS 0x8B85
#define KR_GL_ACTIVE_UNIFORMS 0x8B86
#define KR_GL_ACTIVE_ATTRIBUTES 0x8B89
#define KR_GL_SHADING_LANGUAGE_VERSION 0x8B8C
#define KR_GL_CURRENT_PROGRAM 0x8B8D

/* StringName */
#define KR_GL_VENDOR 0x1F00
#define KR_GL_RENDERER 0x1F01
#define KR_GL_VERSION 0x1F02
#define KR_GL_EXTENSIONS 0x1F03

/* StringCounts */
#define KR_GL_NUM_EXTENSIONS 0x821D

/* StencilFunction */
#define KR_GL_NEVER 0x0200
#define KR_GL_LESS 0x0201
#define KR_GL_EQUAL 0x0202
#define KR_GL_LEQUAL 0x0203
#define KR_GL_GREATER 0x0204
#define KR_GL_NOTEQUAL 0x0205
#define KR_GL_GEQUAL 0x0206
#define KR_GL_ALWAYS 0x0207

/* StencilOp */
/*      ZERO */
#define KR_GL_KEEP 0x1E00
#define KR_GL_REPLACE 0x1E01
#define KR_GL_INCR 0x1E02
#define KR_GL_DECR 0x1E03
#define KR_GL_INVERT 0x150A
#define KR_GL_INCR_WRAP 0x8507
#define KR_GL_DECR_WRAP 0x8508

/* StringName */
#define KR_GL_VENDOR 0x1F00
#define KR_GL_RENDERER 0x1F01
#define KR_GL_VERSION 0x1F02

/* TextureMagFilter */
#define KR_GL_NEAREST 0x2600
#define KR_GL_LINEAR 0x2601

/* TextureMinFilter */
/*      NEAREST */
/*      LINEAR */
#define KR_GL_NEAREST_MIPMAP_NEAREST 0x2700
#define KR_GL_LINEAR_MIPMAP_NEAREST 0x2701
#define KR_GL_NEAREST_MIPMAP_LINEAR 0x2702
#define KR_GL_LINEAR_MIPMAP_LINEAR 0x2703

/* TextureParameterName */
#define KR_GL_TEXTURE_MAG_FILTER 0x2800
#define KR_GL_TEXTURE_MIN_FILTER 0x2801
#define KR_GL_TEXTURE_WRAP_S 0x2802
#define KR_GL_TEXTURE_WRAP_T 0x2803

/* TextureTarget */
#define KR_GL_TEXTURE_2D 0x0DE1
#define KR_GL_TEXTURE 0x1702

#define KR_GL_TEXTURE_CUBE_MAP 0x8513
#define KR_GL_TEXTURE_BINDING_CUBE_MAP 0x8514
#define KR_GL_TEXTURE_CUBE_MAP_POSITIVE_X 0x8515
#define KR_GL_TEXTURE_CUBE_MAP_NEGATIVE_X 0x8516
#define KR_GL_TEXTURE_CUBE_MAP_POSITIVE_Y 0x8517
#define KR_GL_TEXTURE_CUBE_MAP_NEGATIVE_Y 0x8518
#define KR_GL_TEXTURE_CUBE_MAP_POSITIVE_Z 0x8519
#define KR_GL_TEXTURE_CUBE_MAP_NEGATIVE_Z 0x851A
#define KR_GL_MAX_CUBE_MAP_TEXTURE_SIZE 0x851C

/* TextureUnit */
#define KR_GL_TEXTURE0 0x84C0
#define KR_GL_TEXTURE1 0x84C1
#define KR_GL_TEXTURE2 0x84C2
#define KR_GL_TEXTURE3 0x84C3
#define KR_GL_TEXTURE4 0x84C4
#define KR_GL_TEXTURE5 0x84C5
#define KR_GL_TEXTURE6 0x84C6
#define KR_GL_TEXTURE7 0x84C7
#define KR_GL_TEXTURE8 0x84C8
#define KR_GL_TEXTURE9 0x84C9
#define KR_GL_TEXTURE10 0x84CA
#define KR_GL_TEXTURE11 0x84CB
#define KR_GL_TEXTURE12 0x84CC
#define KR_GL_TEXTURE13 0x84CD
#define KR_GL_TEXTURE14 0x84CE
#define KR_GL_TEXTURE15 0x84CF
#define KR_GL_TEXTURE16 0x84D0
#define KR_GL_TEXTURE17 0x84D1
#define KR_GL_TEXTURE18 0x84D2
#define KR_GL_TEXTURE19 0x84D3
#define KR_GL_TEXTURE20 0x84D4
#define KR_GL_TEXTURE21 0x84D5
#define KR_GL_TEXTURE22 0x84D6
#define KR_GL_TEXTURE23 0x84D7
#define KR_GL_TEXTURE24 0x84D8
#define KR_GL_TEXTURE25 0x84D9
#define KR_GL_TEXTURE26 0x84DA
#define KR_GL_TEXTURE27 0x84DB
#define KR_GL_TEXTURE28 0x84DC
#define KR_GL_TEXTURE29 0x84DD
#define KR_GL_TEXTURE30 0x84DE
#define KR_GL_TEXTURE31 0x84DF
#define KR_GL_ACTIVE_TEXTURE 0x84E0

/* TextureWrapMode */
#define KR_GL_REPEAT 0x2901
#define KR_GL_CLAMP_TO_EDGE 0x812F
#define KR_GL_MIRRORED_REPEAT 0x8370

/* Uniform Types */
#define KR_GL_FLOAT_VEC2 0x8B50
#define KR_GL_FLOAT_VEC3 0x8B51
#define KR_GL_FLOAT_VEC4 0x8B52
#define KR_GL_INT_VEC2 0x8B53
#define KR_GL_INT_VEC3 0x8B54
#define KR_GL_INT_VEC4 0x8B55
#define KR_GL_BOOL 0x8B56
#define KR_GL_BOOL_VEC2 0x8B57
#define KR_GL_BOOL_VEC3 0x8B58
#define KR_GL_BOOL_VEC4 0x8B59
#define KR_GL_FLOAT_MAT2 0x8B5A
#define KR_GL_FLOAT_MAT3 0x8B5B
#define KR_GL_FLOAT_MAT4 0x8B5C
#define KR_GL_SAMPLER_2D 0x8B5E
#define KR_GL_SAMPLER_CUBE 0x8B60

/* Vertex Arrays */
#define KR_GL_VERTEX_ATTRIB_ARRAY_ENABLED 0x8622
#define KR_GL_VERTEX_ATTRIB_ARRAY_SIZE 0x8623
#define KR_GL_VERTEX_ATTRIB_ARRAY_STRIDE 0x8624
#define KR_GL_VERTEX_ATTRIB_ARRAY_TYPE 0x8625
#define KR_GL_VERTEX_ATTRIB_ARRAY_NORMALIZED 0x886A
#define KR_GL_VERTEX_ATTRIB_ARRAY_POINTER 0x8645
#define KR_GL_VERTEX_ATTRIB_ARRAY_BUFFER_BINDING 0x889F

/* Read Format */
#define KR_GL_IMPLEMENTATION_COLOR_READ_TYPE 0x8B9A
#define KR_GL_IMPLEMENTATION_COLOR_READ_FORMAT 0x8B9B

/* Shader Source */
#define KR_GL_COMPILE_STATUS 0x8B81

/* Shader Precision-Specified Types */
#define KR_GL_LOW_FLOAT 0x8DF0
#define KR_GL_MEDIUM_FLOAT 0x8DF1
#define KR_GL_HIGH_FLOAT 0x8DF2
#define KR_GL_LOW_INT 0x8DF3
#define KR_GL_MEDIUM_INT 0x8DF4
#define KR_GL_HIGH_INT 0x8DF5

/* Framebuffer Object. */
#define KR_GL_FRAMEBUFFER 0x8D40
#define KR_GL_RENDERBUFFER 0x8D41

#define KR_GL_RGBA4 0x8056
#define KR_GL_RGB5_A1 0x8057
#define KR_GL_RGB565 0x8D62
#define KR_GL_DEPTH_COMPONENT16 0x81A5
#define KR_GL_STENCIL_INDEX8 0x8D48
#define KR_GL_DEPTH_STENCIL 0x84F9

#define KR_GL_RENDERBUFFER_WIDTH 0x8D42
#define KR_GL_RENDERBUFFER_HEIGHT 0x8D43
#define KR_GL_RENDERBUFFER_INTERNAL_FORMAT 0x8D44
#define KR_GL_RENDERBUFFER_RED_SIZE 0x8D50
#define KR_GL_RENDERBUFFER_GREEN_SIZE 0x8D51
#define KR_GL_RENDERBUFFER_BLUE_SIZE 0x8D52
#define KR_GL_RENDERBUFFER_ALPHA_SIZE 0x8D53
#define KR_GL_RENDERBUFFER_DEPTH_SIZE 0x8D54
#define KR_GL_RENDERBUFFER_STENCIL_SIZE 0x8D55

#define KR_GL_FRAMEBUFFER_ATTACHMENT_OBJECT_TYPE 0x8CD0
#define KR_GL_FRAMEBUFFER_ATTACHMENT_OBJECT_NAME 0x8CD1
#define KR_GL_FRAMEBUFFER_ATTACHMENT_TEXTURE_LEVEL 0x8CD2
#define KR_GL_FRAMEBUFFER_ATTACHMENT_TEXTURE_CUBE_MAP_FACE 0x8CD3

#define KR_GL_COLOR_ATTACHMENT0 0x8CE0
#define KR_GL_DEPTH_ATTACHMENT 0x8D00
#define KR_GL_STENCIL_ATTACHMENT 0x8D20
#define KR_GL_DEPTH_STENCIL_ATTACHMENT 0x821A

#define KR_GL_NONE 0

#define KR_GL_FRAMEBUFFER_COMPLETE 0x8CD5
#define KR_GL_FRAMEBUFFER_INCOMPLETE_ATTACHMENT 0x8CD6
#define KR_GL_FRAMEBUFFER_INCOMPLETE_MISSING_ATTACHMENT 0x8CD7
#define KR_GL_FRAMEBUFFER_INCOMPLETE_DIMENSIONS 0x8CD9
#define KR_GL_FRAMEBUFFER_UNSUPPORTED 0x8CDD

#define KR_GL_FRAMEBUFFER_BINDING 0x8CA6
#define KR_GL_RENDERBUFFER_BINDING 0x8CA7
#define KR_GL_MAX_RENDERBUFFER_SIZE 0x84E8
#define KR_GL_INVALID_FRAMEBUFFER_OPERATION 0x0506

/* WebGL-specific enums */
#define KR_GL_UNPACK_FLIP_Y_WEBGL 0x9240
#define KR_GL_UNPACK_PREMULTIPLY_ALPHA_WEBGL 0x9241
#define KR_GL_CONTEXT_LOST_WEBGL 0x9242
#define KR_GL_UNPACK_COLORSPACE_CONVERSION_WEBGL 0x9243
#define KR_GL_BROWSER_DEFAULT_WEBGL 0x9244

/*
 * WEBGL 2.0
 */
#define KR_GL_READ_BUFFER 0x0C02
#define KR_GL_UNPACK_ROW_LENGTH 0x0CF2
#define KR_GL_UNPACK_SKIP_ROWS 0x0CF3
#define KR_GL_UNPACK_SKIP_PIXELS 0x0CF4
#define KR_GL_PACK_ROW_LENGTH 0x0D02
#define KR_GL_PACK_SKIP_ROWS 0x0D03
#define KR_GL_PACK_SKIP_PIXELS 0x0D04
#define KR_GL_COLOR 0x1800
#define KR_GL_DEPTH 0x1801
#define KR_GL_STENCIL 0x1802
#define KR_GL_RED 0x1903
#define KR_GL_GREEN 0x1904
#define KR_GL_RGB8 0x8051
#define KR_GL_RGBA8 0x8058
#define KR_GL_RGB10_A2 0x8059
#define KR_GL_TEXTURE_BINDING_3D 0x806A
#define KR_GL_UNPACK_SKIP_IMAGES 0x806D
#define KR_GL_UNPACK_IMAGE_HEIGHT 0x806E
#define KR_GL_TEXTURE_3D 0x806F
#define KR_GL_TEXTURE_WRAP_R 0x8072
#define KR_GL_MAX_3D_TEXTURE_SIZE 0x8073
#define KR_GL_UNSIGNED_INT_2_10_10_10_REV 0x8368
#define KR_GL_MAX_ELEMENTS_VERTICES 0x80E8
#define KR_GL_MAX_ELEMENTS_INDICES 0x80E9
#define KR_GL_TEXTURE_MIN_LOD 0x813A
#define KR_GL_TEXTURE_MAX_LOD 0x813B
#define KR_GL_TEXTURE_BASE_LEVEL 0x813C
#define KR_GL_TEXTURE_MAX_LEVEL 0x813D
#define KR_GL_MIN 0x8007
#define KR_GL_MAX 0x8008
#define KR_GL_DEPTH_COMPONENT24 0x81A6
#define KR_GL_MAX_TEXTURE_LOD_BIAS 0x84FD
#define KR_GL_TEXTURE_COMPARE_MODE 0x884C
#define KR_GL_TEXTURE_COMPARE_FUNC 0x884D
#define KR_GL_CURRENT_QUERY 0x8865
#define KR_GL_QUERY_RESULT 0x8866
#define KR_GL_QUERY_RESULT_AVAILABLE 0x8867
#define KR_GL_STREAM_READ 0x88E1
#define KR_GL_STREAM_COPY 0x88E2
#define KR_GL_STATIC_READ 0x88E5
#define KR_GL_STATIC_COPY 0x88E6
#define KR_GL_DYNAMIC_READ 0x88E9
#define KR_GL_DYNAMIC_COPY 0x88EA
#define KR_GL_MAX_DRAW_BUFFERS 0x8824
#define KR_GL_DRAW_BUFFER0 0x8825
#define KR_GL_DRAW_BUFFER1 0x8826
#define KR_GL_DRAW_BUFFER2 0x8827
#define KR_GL_DRAW_BUFFER3 0x8828
#define KR_GL_DRAW_BUFFER4 0x8829
#define KR_GL_DRAW_BUFFER5 0x882A
#define KR_GL_DRAW_BUFFER6 0x882B
#define KR_GL_DRAW_BUFFER7 0x882C
#define KR_GL_DRAW_BUFFER8 0x882D
#define KR_GL_DRAW_BUFFER9 0x882E
#define KR_GL_DRAW_BUFFER10 0x882F
#define KR_GL_DRAW_BUFFER11 0x8830
#define KR_GL_DRAW_BUFFER12 0x8831
#define KR_GL_DRAW_BUFFER13 0x8832
#define KR_GL_DRAW_BUFFER14 0x8833
#define KR_GL_DRAW_BUFFER15 0x8834
#define KR_GL_MAX_FRAGMENT_UNIFORM_COMPONENTS 0x8B49
#define KR_GL_MAX_VERTEX_UNIFORM_COMPONENTS 0x8B4A
#define KR_GL_SAMPLER_3D 0x8B5F
#define KR_GL_SAMPLER_2D_SHADOW 0x8B62
#define KR_GL_FRAGMENT_SHADER_DERIVATIVE_HINT 0x8B8B
#define KR_GL_PIXEL_PACK_BUFFER 0x88EB
#define KR_GL_PIXEL_UNPACK_BUFFER 0x88EC
#define KR_GL_PIXEL_PACK_BUFFER_BINDING 0x88ED
#define KR_GL_PIXEL_UNPACK_BUFFER_BINDING 0x88EF
#define KR_GL_FLOAT_MAT2x3 0x8B65
#define KR_GL_FLOAT_MAT2x4 0x8B66
#define KR_GL_FLOAT_MAT3x2 0x8B67
#define KR_GL_FLOAT_MAT3x4 0x8B68
#define KR_GL_FLOAT_MAT4x2 0x8B69
#define KR_GL_FLOAT_MAT4x3 0x8B6A
#define KR_GL_SRGB 0x8C40
#define KR_GL_SRGB8 0x8C41
#define KR_GL_SRGB8_ALPHA8 0x8C43
#define KR_GL_COMPARE_REF_TO_TEXTURE 0x884E
#define KR_GL_RGBA32F 0x8814
#define KR_GL_RGB32F 0x8815
#define KR_GL_RGBA16F 0x881A
#define KR_GL_RGB16F 0x881B
#define KR_GL_VERTEX_ATTRIB_ARRAY_INTEGER 0x88FD
#define KR_GL_MAX_ARRAY_TEXTURE_LAYERS 0x88FF
#define KR_GL_MIN_PROGRAM_TEXEL_OFFSET 0x8904
#define KR_GL_MAX_PROGRAM_TEXEL_OFFSET 0x8905
#define KR_GL_MAX_VARYING_COMPONENTS 0x8B4B
#define KR_GL_TEXTURE_2D_ARRAY 0x8C1A
#define KR_GL_TEXTURE_BINDING_2D_ARRAY 0x8C1D
#define KR_GL_R11F_G11F_B10F 0x8C3A
#define KR_GL_UNSIGNED_INT_10F_11F_11F_REV 0x8C3B
#define KR_GL_RGB9_E5 0x8C3D
#define KR_GL_UNSIGNED_INT_5_9_9_9_REV 0x8C3E
#define KR_GL_TRANSFORM_FEEDBACK_BUFFER_MODE 0x8C7F
#define KR_GL_MAX_TRANSFORM_FEEDBACK_SEPARATE_COMPONENTS 0x8C80
#define KR_GL_TRANSFORM_FEEDBACK_VARYINGS 0x8C83
#define KR_GL_TRANSFORM_FEEDBACK_BUFFER_START 0x8C84
#define KR_GL_TRANSFORM_FEEDBACK_BUFFER_SIZE 0x8C85
#define KR_GL_TRANSFORM_FEEDBACK_PRIMITIVES_WRITTEN 0x8C88
#define KR_GL_RASTERIZER_DISCARD 0x8C89
#define KR_GL_MAX_TRANSFORM_FEEDBACK_INTERLEAVED_COMPONENTS 0x8C8A
#define KR_GL_MAX_TRANSFORM_FEEDBACK_SEPARATE_ATTRIBS 0x8C8B
#define KR_GL_INTERLEAVED_ATTRIBS 0x8C8C
#define KR_GL_SEPARATE_ATTRIBS 0x8C8D
#define KR_GL_TRANSFORM_FEEDBACK_BUFFER 0x8C8E
#define KR_GL_TRANSFORM_FEEDBACK_BUFFER_BINDING 0x8C8F
#define KR_GL_RGBA32UI 0x8D70
#define KR_GL_RGB32UI 0x8D71
#define KR_GL_RGBA16UI 0x8D76
#define KR_GL_RGB16UI 0x8D77
#define KR_GL_RGBA8UI 0x8D7C
#define KR_GL_RGB8UI 0x8D7D
#define KR_GL_RGBA32I 0x8D82
#define KR_GL_RGB32I 0x8D83
#define KR_GL_RGBA16I 0x8D88
#define KR_GL_RGB16I 0x8D89
#define KR_GL_RGBA8I 0x8D8E
#define KR_GL_RGB8I 0x8D8F
#define KR_GL_RED_INTEGER 0x8D94
#define KR_GL_RGB_INTEGER 0x8D98
#define KR_GL_RGBA_INTEGER 0x8D99
#define KR_GL_SAMPLER_2D_ARRAY 0x8DC1
#define KR_GL_SAMPLER_2D_ARRAY_SHADOW 0x8DC4
#define KR_GL_SAMPLER_CUBE_SHADOW 0x8DC5
#define KR_GL_UNSIGNED_INT_VEC2 0x8DC6
#define KR_GL_UNSIGNED_INT_VEC3 0x8DC7
#define KR_GL_UNSIGNED_INT_VEC4 0x8DC8
#define KR_GL_INT_SAMPLER_2D 0x8DCA
#define KR_GL_INT_SAMPLER_3D 0x8DCB
#define KR_GL_INT_SAMPLER_CUBE 0x8DCC
#define KR_GL_INT_SAMPLER_2D_ARRAY 0x8DCF
#define KR_GL_UNSIGNED_INT_SAMPLER_2D 0x8DD2
#define KR_GL_UNSIGNED_INT_SAMPLER_3D 0x8DD3
#define KR_GL_UNSIGNED_INT_SAMPLER_CUBE 0x8DD4
#define KR_GL_UNSIGNED_INT_SAMPLER_2D_ARRAY 0x8DD7
#define KR_GL_DEPTH_COMPONENT32F 0x8CAC
#define KR_GL_DEPTH32F_STENCIL8 0x8CAD
#define KR_GL_FLOAT_32_UNSIGNED_INT_24_8_REV 0x8DAD
#define KR_GL_FRAMEBUFFER_ATTACHMENT_COLOR_ENCODING 0x8210
#define KR_GL_FRAMEBUFFER_ATTACHMENT_COMPONENT_TYPE 0x8211
#define KR_GL_FRAMEBUFFER_ATTACHMENT_RED_SIZE 0x8212
#define KR_GL_FRAMEBUFFER_ATTACHMENT_GREEN_SIZE 0x8213
#define KR_GL_FRAMEBUFFER_ATTACHMENT_BLUE_SIZE 0x8214
#define KR_GL_FRAMEBUFFER_ATTACHMENT_ALPHA_SIZE 0x8215
#define KR_GL_FRAMEBUFFER_ATTACHMENT_DEPTH_SIZE 0x8216
#define KR_GL_FRAMEBUFFER_ATTACHMENT_STENCIL_SIZE 0x8217
#define KR_GL_FRAMEBUFFER_DEFAULT 0x8218
#define KR_GL_UNSIGNED_INT_24_8 0x84FA
#define KR_GL_DEPTH24_STENCIL8 0x88F0
#define KR_GL_UNSIGNED_NORMALIZED 0x8C17
#define KR_GL_DRAW_FRAMEBUFFER_BINDING  \
  0x8CA6 /* Same as FRAMEBUFFER_BINDING \
          */
#define KR_GL_READ_FRAMEBUFFER 0x8CA8
#define KR_GL_DRAW_FRAMEBUFFER 0x8CA9
#define KR_GL_READ_FRAMEBUFFER_BINDING 0x8CAA
#define KR_GL_RENDERBUFFER_SAMPLES 0x8CAB
#define KR_GL_FRAMEBUFFER_ATTACHMENT_TEXTURE_LAYER 0x8CD4
#define KR_GL_MAX_COLOR_ATTACHMENTS 0x8CDF
#define KR_GL_COLOR_ATTACHMENT1 0x8CE1
#define KR_GL_COLOR_ATTACHMENT2 0x8CE2
#define KR_GL_COLOR_ATTACHMENT3 0x8CE3
#define KR_GL_COLOR_ATTACHMENT4 0x8CE4
#define KR_GL_COLOR_ATTACHMENT5 0x8CE5
#define KR_GL_COLOR_ATTACHMENT6 0x8CE6
#define KR_GL_COLOR_ATTACHMENT7 0x8CE7
#define KR_GL_COLOR_ATTACHMENT8 0x8CE8
#define KR_GL_COLOR_ATTACHMENT9 0x8CE9
#define KR_GL_COLOR_ATTACHMENT10 0x8CEA
#define KR_GL_COLOR_ATTACHMENT11 0x8CEB
#define KR_GL_COLOR_ATTACHMENT12 0x8CEC
#define KR_GL_COLOR_ATTACHMENT13 0x8CED
#define KR_GL_COLOR_ATTACHMENT14 0x8CEE
#define KR_GL_COLOR_ATTACHMENT15 0x8CEF
#define KR_GL_FRAMEBUFFER_INCOMPLETE_MULTISAMPLE 0x8D56
#define KR_GL_MAX_SAMPLES 0x8D57
#define KR_GL_HALF_FLOAT 0x140B
#define KR_GL_RG 0x8227
#define KR_GL_RG_INTEGER 0x8228
#define KR_GL_R8 0x8229
#define KR_GL_RG8 0x822B
#define KR_GL_R16F 0x822D
#define KR_GL_R32F 0x822E
#define KR_GL_RG16F 0x822F
#define KR_GL_RG32F 0x8230
#define KR_GL_R8I 0x8231
#define KR_GL_R8UI 0x8232
#define KR_GL_R16I 0x8233
#define KR_GL_R16UI 0x8234
#define KR_GL_R32I 0x8235
#define KR_GL_R32UI 0x8236
#define KR_GL_RG8I 0x8237
#define KR_GL_RG8UI 0x8238
#define KR_GL_RG16I 0x8239
#define KR_GL_RG16UI 0x823A
#define KR_GL_RG32I 0x823B
#define KR_GL_RG32UI 0x823C
#define KR_GL_VERTEX_ARRAY_BINDING 0x85B5
#define KR_GL_R8_SNORM 0x8F94
#define KR_GL_RG8_SNORM 0x8F95
#define KR_GL_RGB8_SNORM 0x8F96
#define KR_GL_RGBA8_SNORM 0x8F97
#define KR_GL_SIGNED_NORMALIZED 0x8F9C
#define KR_GL_COPY_READ_BUFFER 0x8F36
#define KR_GL_COPY_WRITE_BUFFER 0x8F37
#define KR_GL_COPY_READ_BUFFER_BINDING 0x8F36  /* Same as COPY_READ_BUFFER */
#define KR_GL_COPY_WRITE_BUFFER_BINDING 0x8F37 /* Same as COPY_WRITE_BUFFER */
#define KR_GL_UNIFORM_BUFFER 0x8A11
#define KR_GL_UNIFORM_BUFFER_BINDING 0x8A28
#define KR_GL_UNIFORM_BUFFER_START 0x8A29
#define KR_GL_UNIFORM_BUFFER_SIZE 0x8A2A
#define KR_GL_MAX_VERTEX_UNIFORM_BLOCKS 0x8A2B
#define KR_GL_MAX_FRAGMENT_UNIFORM_BLOCKS 0x8A2D
#define KR_GL_MAX_COMBINED_UNIFORM_BLOCKS 0x8A2E
#define KR_GL_MAX_UNIFORM_BUFFER_BINDINGS 0x8A2F
#define KR_GL_MAX_UNIFORM_BLOCK_SIZE 0x8A30
#define KR_GL_MAX_COMBINED_VERTEX_UNIFORM_COMPONENTS 0x8A31
#define KR_GL_MAX_COMBINED_FRAGMENT_UNIFORM_COMPONENTS 0x8A33
#define KR_GL_UNIFORM_BUFFER_OFFSET_ALIGNMENT 0x8A34
#define KR_GL_ACTIVE_UNIFORM_BLOCKS 0x8A36
#define KR_GL_UNIFORM_TYPE 0x8A37
#define KR_GL_UNIFORM_SIZE 0x8A38
#define KR_GL_UNIFORM_BLOCK_INDEX 0x8A3A
#define KR_GL_UNIFORM_OFFSET 0x8A3B
#define KR_GL_UNIFORM_ARRAY_STRIDE 0x8A3C
#define KR_GL_UNIFORM_MATRIX_STRIDE 0x8A3D
#define KR_GL_UNIFORM_IS_ROW_MAJOR 0x8A3E
#define KR_GL_UNIFORM_BLOCK_BINDING 0x8A3F
#define KR_GL_UNIFORM_BLOCK_DATA_SIZE 0x8A40
#define KR_GL_UNIFORM_BLOCK_ACTIVE_UNIFORMS 0x8A42
#define KR_GL_UNIFORM_BLOCK_ACTIVE_UNIFORM_INDICES 0x8A43
#define KR_GL_UNIFORM_BLOCK_REFERENCED_BY_VERTEX_SHADER 0x8A44
#define KR_GL_UNIFORM_BLOCK_REFERENCED_BY_FRAGMENT_SHADER 0x8A46
#define KR_GL_INVALID_INDEX 0xFFFFFFFF
#define KR_GL_MAX_VERTEX_OUTPUT_COMPONENTS 0x9122
#define KR_GL_MAX_FRAGMENT_INPUT_COMPONENTS 0x9125
#define KR_GL_MAX_SERVER_WAIT_TIMEOUT 0x9111
#define KR_GL_OBJECT_TYPE 0x9112
#define KR_GL_SYNC_CONDITION 0x9113
#define KR_GL_SYNC_STATUS 0x9114
#define KR_GL_SYNC_FLAGS 0x9115
#define KR_GL_SYNC_FENCE 0x9116
#define KR_GL_SYNC_GPU_COMMANDS_COMPLETE 0x9117
#define KR_GL_UNSIGNALED 0x9118
#define KR_GL_SIGNALED 0x9119
#define KR_GL_ALREADY_SIGNALED 0x911A
#define KR_GL_TIMEOUT_EXPIRED 0x911B
#define KR_GL_CONDITION_SATISFIED 0x911C
#define KR_GL_WAIT_FAILED 0x911D
#define KR_GL_SYNC_FLUSH_COMMANDS_BIT 0x00000001
#define KR_GL_VERTEX_ATTRIB_ARRAY_DIVISOR 0x88FE
#define KR_GL_ANY_SAMPLES_PASSED 0x8C2F
#define KR_GL_ANY_SAMPLES_PASSED_CONSERVATIVE 0x8D6A
#define KR_GL_SAMPLER_BINDING 0x8919
#define KR_GL_RGB10_A2UI 0x906F
#define KR_GL_TEXTURE_SWIZZLE_R 0x8E42
#define KR_GL_TEXTURE_SWIZZLE_G 0x8E43
#define KR_GL_TEXTURE_SWIZZLE_B 0x8E44
#define KR_GL_TEXTURE_SWIZZLE_A 0x8E45
#define KR_GL_INT_2_10_10_10_REV 0x8D9F
#define KR_GL_TRANSFORM_FEEDBACK 0x8E22
#define KR_GL_TRANSFORM_FEEDBACK_PAUSED 0x8E23
#define KR_GL_TRANSFORM_FEEDBACK_ACTIVE 0x8E24
#define KR_GL_TRANSFORM_FEEDBACK_BINDING 0x8E25
#define KR_GL_TEXTURE_IMMUTABLE_FORMAT 0x912F
#define KR_GL_MAX_ELEMENT_INDEX 0x8D6B
#define KR_GL_TEXTURE_IMMUTABLE_LEVELS 0x82DF
#define KR_GL_TIMEOUT_IGNORED -1  // GLint64

/* WebGL-specific enums */
#define KR_GL_MAX_CLIENT_WAIT_TIMEOUT_WEBGL 0x9247

/* Compressed texture format Extension */
/* - WEBGL_compressed_texture_s3tc extension */
#define KR_GL_COMPRESSED_RGB_S3TC_DXT1_EXT 0x83F0
#define KR_GL_COMPRESSED_RGBA_S3TC_DXT1_EXT 0x83F1
#define KR_GL_COMPRESSED_RGBA_S3TC_DXT3_EXT 0x83F2
#define KR_GL_COMPRESSED_RGBA_S3TC_DXT5_EXT 0x83F3

/* - WEBGL_compressed_texture_s3tc_srgb extension */
#define KR_GL_COMPRESSED_SRGB_S3TC_DXT1_EXT 0x8C4C
#define KR_GL_COMPRESSED_SRGB_ALPHA_S3TC_DXT1_EXT 0x8C4D
#define KR_GL_COMPRESSED_SRGB_ALPHA_S3TC_DXT3_EXT 0x8C4E
#define KR_GL_COMPRESSED_SRGB_ALPHA_S3TC_DXT5_EXT 0x8C4F

/* - WEBGL_compressed_texture_etc extension */
#define KR_GL_COMPRESSED_R11_EAC 0x9270
#define KR_GL_COMPRESSED_SIGNED_R11_EAC 0x9271
#define KR_GL_COMPRESSED_RG11_EAC 0x9272
#define KR_GL_COMPRESSED_SIGNED_RG11_EAC 0x9273
#define KR_GL_COMPRESSED_RGB8_ETC2 0x9274
#define KR_GL_COMPRESSED_RGBA8_ETC2_EAC 0x9278
#define KR_GL_COMPRESSED_SRGB8_ETC2 0x9275
#define KR_GL_COMPRESSED_SRGB8_ALPHA8_ETC2_EAC 0x9279
#define KR_GL_COMPRESSED_RGB8_PUNCHTHROUGH_ALPHA1_ETC2 0x9276
#define KR_GL_COMPRESSED_SRGB8_PUNCHTHROUGH_ALPHA1_ETC2 0x9277

/* - WEBGL_compressed_texture_pvrtc extension */
#define KR_GL_COMPRESSED_RGB_PVRTC_4BPPV1_IMG 0x8C00
#define KR_GL_COMPRESSED_RGBA_PVRTC_4BPPV1_IMG 0x8C02
#define KR_GL_COMPRESSED_RGB_PVRTC_2BPPV1_IMG 0x8C01
#define KR_GL_COMPRESSED_RGBA_PVRTC_2BPPV1_IMG 0x8C03

/* - WEBGL_compressed_texture_atc extension */
#define KR_GL_COMPRESSED_RGB_ATC_WEBGL 0x8C92
#define KR_GL_COMPRESSED_RGBA_ATC_EXPLICIT_ALPHA_WEBGL 0x8C93
#define KR_GL_COMPRESSED_RGBA_ATC_INTERPOLATED_ALPHA_WEBGL 0x87EE

/* -  WEBGL_compressed_texture_astc extension */
#define KR_GL_COMPRESSED_RGBA_ASTC_4x4_KHR 0x93B0
#define KR_GL_COMPRESSED_SRGB8_ALPHA8_ASTC_4x4_KHR 0x93D0
#define KR_GL_COMPRESSED_RGBA_ASTC_5x4_KHR 0x93B1
#define KR_GL_COMPRESSED_SRGB8_ALPHA8_ASTC_5x4_KHR 0x93D1
#define KR_GL_COMPRESSED_RGBA_ASTC_5x5_KHR 0x93B2
#define KR_GL_COMPRESSED_SRGB8_ALPHA8_ASTC_5x5_KHR 0x93D2
#define KR_GL_COMPRESSED_RGBA_ASTC_6x5_KHR 0x93B3
#define KR_GL_COMPRESSED_SRGB8_ALPHA8_ASTC_6x5_KHR 0x93D3
#define KR_GL_COMPRESSED_RGBA_ASTC_6x6_KHR 0x93B4
#define KR_GL_COMPRESSED_SRGB8_ALPHA8_ASTC_6x6_KHR 0x93D4
#define KR_GL_COMPRESSED_RGBA_ASTC_8x5_KHR 0x93B5
#define KR_GL_COMPRESSED_SRGB8_ALPHA8_ASTC_8x5_KHR 0x93D5
#define KR_GL_COMPRESSED_RGBA_ASTC_8x6_KHR 0x93B6
#define KR_GL_COMPRESSED_SRGB8_ALPHA8_ASTC_8x6_KHR 0x93D6
#define KR_GL_COMPRESSED_RGBA_ASTC_8x8_KHR 0x93B7
#define KR_GL_COMPRESSED_SRGB8_ALPHA8_ASTC_8x8_KHR 0x93D7
#define KR_GL_COMPRESSED_RGBA_ASTC_10x5_KHR 0x93B8
#define KR_GL_COMPRESSED_SRGB8_ALPHA8_ASTC_10x5_KHR 0x93D8
#define KR_GL_COMPRESSED_RGBA_ASTC_10x6_KHR 0x93B9
#define KR_GL_COMPRESSED_SRGB8_ALPHA8_ASTC_10x6_KHR 0x93D9
#define KR_GL_COMPRESSED_RGBA_ASTC_10x8_KHR 0x93BA
#define KR_GL_COMPRESSED_SRGB8_ALPHA8_ASTC_10x8_KHR 0x93DA
#define KR_GL_COMPRESSED_RGBA_ASTC_10x10_KHR 0x93BB
#define KR_GL_COMPRESSED_SRGB8_ALPHA8_ASTC_10x10_KHR 0x93DB
#define KR_GL_COMPRESSED_RGBA_ASTC_12x10_KHR 0x93BC
#define KR_GL_COMPRESSED_SRGB8_ALPHA8_ASTC_12x10_KHR 0x93DC
#define KR_GL_COMPRESSED_RGBA_ASTC_12x12_KHR 0x93BD
#define KR_GL_COMPRESSED_SRGB8_ALPHA8_ASTC_12x12_KHR 0x93DD

/* - EXT_texture_compression_bptc extension */
#define KR_GL_COMPRESSED_RGBA_BPTC_UNORM_EXT 0x8E8C
#define KR_GL_COMPRESSED_SRGB_ALPHA_BPTC_UNORM_EXT 0x8E8D
#define KR_GL_COMPRESSED_RGB_BPTC_SIGNED_FLOAT_EXT 0x8E8E
#define KR_GL_COMPRESSED_RGB_BPTC_UNSIGNED_FLOAT_EXT 0x8E8F

/* - EXT_texture_compression_rgtc extension */
#define KR_GL_COMPRESSED_RED_RGTC1_EXT 0x8DBB
#define KR_GL_COMPRESSED_SIGNED_RED_RGTC1_EXT 0x8DBC
#define KR_GL_COMPRESSED_RED_GREEN_RGTC2_EXT 0x8DBD
#define KR_GL_COMPRESSED_SIGNED_RED_GREEN_RGTC2_EXT 0x8DBE

#define KR_GL_TEXTURE_EXTERNAL_OES 0x8D65
#define KR_GL_SAMPLER_EXTERNAL_OES 0x8D66

/* GL_APPLE_texture_format_BGRA8888 */
#define KR_GL_BGRA_EXT 0x80E1
#define KR_GL_BGRA8_EXT 0x93A1

/* GL_EXT_sRGB */
#define KR_GL_SRGB_EXT 0x8C40
#define KR_GL_SRGB_ALPHA_EXT 0x8C42
#define KR_GL_SRGB8_ALPHA8_EXT 0x8C43

/* GL_EXT_color_buffer_half_float */
#define KR_GL_RGBA16F_EXT 0x881A
#define KR_GL_RGB16F_EXT 0x881B
#define KR_GL_RG16F_EXT 0x822F
#define KR_GL_R16F_EXT 0x822D
#define KR_GL_FRAMEBUFFER_ATTACHMENT_COMPONENT_TYPE_EXT 0x8211
#define KR_GL_UNSIGNED_NORMALIZED_EXT 0x8C17

#endif  // CANVAS_GPU_GL_CONSTANTS_H_
