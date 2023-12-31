//
//  bef_effect_brush2d_define.h
//  Pods
//
//  Created by cl h on 2019/10/22.
//

#ifndef bef_effect_brush2d_define_h
#define bef_effect_brush2d_define_h

#include <stdbool.h>

// Brush parameter type
#define BEF_BRUSH2D_PARAM_NONE                      0x00000000
#define BEF_BRUSH2D_PARAM_STROKE_SIZE               0x00000001
#define BEF_BRUSH2D_PARAM_STROKE_STEP               0x00000002
#define BEF_BRUSH2D_PARAM_FEATHER_SIZE              0x00000004
#define BEF_BRUSH2D_PARAM_NORMALIZED                0x00000008
#define BEF_BRUSH2D_PARAM_SPEED_INFLUNENCE          0x00000010
#define BEF_BRUSH2D_PARAM_NOISE_INFLUNENCE          0x00000020
#define BEF_BRUSH2D_PARAM_USE_ORIENTATION           0x00000040
#define BEF_BRUSH2D_PARAM_ORIENT                    0x00000080
#define BEF_BRUSH2D_PARAM_BRUSH_TYPE                0x00000100
#define BEF_BRUSH2D_PARAM_CURVE_TYPE                0x00000200
#define BEF_BRUSH2D_PARAM_COLOR                     0x00000400
#define BEF_BRUSH2D_PARAM_ALL_VALUE                 0x000007FF
#define BEF_BRUSH2D_PARAM_SAMPLER_RESOURCE_PATH     0x00000800
#define BEF_BRUSH2D_PARAM_MASK_RESOURCE_PATH        0x00001000
#define BEF_BRUSH2D_PARAM_STICKER_RESOURCE_PATH     0x00002000
#define BEF_BRUSH2D_PARAM_FILTER_NAME_LIST          0x00004000
#define BEF_BRUSH2D_PARAM_ALL                       0x00007FFF

// brush2d filter name string length
#define BRUSH2D_FILTER_NAME_LENGTH_MAX  256
// Maximum number of brush2d filters contained in a single feature or filter
#define BRUSH2D_FILTER_NUM_MAX          5
// Brush type
typedef enum bef_brush2d_type_e{
    BRUSH2D_TYPE_COLOR = 0, // Color filling
    BRUSH2D_TYPE_SAMPLER = 1, // Texture filling
    BRUSH2D_TYPE_MASK = 2, // Mask texture filling, e.g. mosaic
    BRUSH2D_TYPE_STICKER = 4, // Sticker filling, such as emoji
    BRUSH2D_TYPE_ERASER = 8 // Eraser
} bef_brush2d_type;

// Curve type
typedef enum bef_brush2d_curve_e{
    BRUSH2D_CURVE_DEFAULT = 0, // Default Hermite sampling
    BRUSH2D_CURVE_QUAD = 1,
    BRUSH2D_CURVE_BEZIER = 2 // Not yet realized
} bef_brush2d_curve;

// Brush parameters
typedef struct bef_brush2d_param_st {
    float strokeSize;  // Brush diameter
    float strokeStep;  // Brush drawing spacing(enable when use BRUSH2D_TYPE_STICKER)
    float featherSize; // Feather radius
    bool  bNormalized; // Whether the above parameters are in the normalized coordinate system (used for information stickers)
    float speedInfluence; // Speed ​​affects the magnitude of brush size
    float noiseInfluence; // Noise ​​affects the magnitude of brush size
    float orient;      // Basic rotation angle, set according to bef_rotate_type
    bool  bUseOrient;  // Whether to use the rotation information of the gesture point
    bef_brush2d_type  brushType; // Brush type
    bef_brush2d_curve curveType; // Curve type
    float color[4];  // Brush color
    char* samplerResourcePath; // Sampler resource path, currently only supports setting, not support getting
    char* maskResourcePath; // Mask resource path, currently only supports setting, not support getting
    char* stickerResourcePath; // Sticker resource path, currently only supports setting, not support getting
    char filterNameList[BRUSH2D_FILTER_NUM_MAX][BRUSH2D_FILTER_NAME_LENGTH_MAX]; // list of brush2d filter names included under feature, currently only supports setting, not support getting
    int filterNum; // The number of brush2d filters included under feature, currently only supports setting, not support getting
    int validParams;  // The effective parameters in this structure are set bit by bit. Only when the corresponding bit is 1, the parameter corresponding to the bit will be effectively set or get, validParams = BEF_BRUSH2D_PARAM_ALL means all parameters are valid
    float alpha; // Brush transparency value
    
} bef_brush2d_param;

// Single brush
typedef struct brush2d_stroke_st {
    bef_brush2d_param           parameters;      // Current brush parameters
    int                         nVertices;       // Number of vertices
    /*
     * Stroke vertex information string, contains two substrings
     * The first substring contains the starting coordinates of the vertex in each drawing in incremental mode.
     * The second substring contains information for each vertex,(1) The x coordinate of the vertex of the stroke, (2) The y coordinate of the vertex of the stroke, (3) Point size, (4) The value in the x direction from the current point to the previous point, (5) The value in the y direction from the current point to the previous point
     */
    char*                       vertices_info_string;
    float                       custom_data[3];
} brush2d_stroke;

// redo/undo data
typedef struct bef_brush2d_redo_undo_st {
    char*                       name;             // The default is an empty string
    
    // When it is valid in the get method, it can be set to a null pointer in the set method
    brush2d_stroke              active_stroke;    // Currently active strokes
    
    // Only valid under the set method, including incremental and non-incremental modes, the null pointer returned in the get method
    brush2d_stroke*             history_strokes;  // List of strokes
    int                         nHistoryStrokes;  // Number of strokes
} bef_brush2d_redo_undo;


void init_bef_brush2d_redo_undo(bef_brush2d_redo_undo* info);

// Used to store intermediate results of Custom Algo type filters
typedef struct bef_custom_algo_data_st {
    int action_flag;// 0: no action, 1: undo, 2: redo
} bef_custom_algo_data;

#endif /* bef_effect_brush2d_define_h */
