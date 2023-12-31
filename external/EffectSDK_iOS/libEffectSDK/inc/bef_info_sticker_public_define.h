//----------------------------------------------------------------------------

#ifndef EFFECT_SDK_INFOSTICKER_PUBLIC_DEFINE_H
#define EFFECT_SDK_INFOSTICKER_PUBLIC_DEFINE_H

/// Information sticker handle type
typedef void* bef_info_sticker_director;

/// Unique identifier type for each information sticker
typedef void* bef_info_sticker_handle;

typedef void* bef_info_model_control_handle;

/// it will be triggered when call save_texture_to_png func
typedef void (*bef_brush2d_save_png_callback)(void*, const char*, bool);

typedef void (*bef_save_brushContext_callback)(void*, const char*, bool);

/// Informative sticker bbox, each attribute range [-1.0, 1.0], four attributes determine a rectangular area on the screen.
typedef struct bef_BoundingBox_2d_t {
    float left;
    float top;
    float right;
    float bottom;
} bef_BoundingBox_2d;

/// Maximum number of variable parameters of information stickers
#define INFO_STICKER_MAX_PARAMS 10

/// Variable parameter structure of information stickers(Remember to release)
typedef struct bef_InfoSticker_info_t {
    const char* params[INFO_STICKER_MAX_PARAMS];
    int count;
} bef_InfoSticker_info;

/// 0.0f ~ 1.0f
typedef struct bef_InfoSticker_color {
    float r;
    float g;
    float b;
    float a;
} bef_InfoSticker_color;

/// Input algorithm parameters per frame
typedef struct bef_InfoSticker_algorithm_param {
    unsigned long frameId;
    double timeStamp;
} bef_InfoSticker_algorithm_param;

typedef struct bef_InfoSticker_texture {
    unsigned int srcIndex;       // Texture index
    unsigned int width;          // Texture width
    unsigned int height;         // Texture height
} bef_InfoSticker_texture;

typedef void* device_texture_handle;
typedef struct bef_InfoSticker_device_texture {
    device_texture_handle srcDeviceTexture;     // DeviceTexture
    unsigned int width;                 // Texture width
    unsigned int height;                // Texture height
} bef_InfoSticker_device_texture;

typedef struct bef_InfoSticker_texture_buff {
    unsigned char* buff;      // Texture buffer
    unsigned int width;       // Texture width
    unsigned int height;      // Texture height
} bef_InfoSticker_texture_buff;

/// Pin algorithm parameters
typedef struct bef_InfoSticker_pin_param {
    bef_info_sticker_handle infoStickerName; // Information stickers to be tracked
    double startTime; // Start time
    double endTime;   // End time
    double pinTime;   // The moment of the frame where the pin is
    bef_InfoSticker_texture_buff initBuff; // Pin tracking initial texture buffer
} bef_InfoSticker_pin_param;

/// Pin algorithm selected area parameters
typedef struct bef_InfoSticker_pin_selected_area_param {
    bef_info_sticker_handle infoStickerName; // Information stickers to be tracked
    float centerX; // screen normalized coordinates[-1.0, 1.0]
    float centerY; // screen normalized coordinates[-1.0, 1.0]
    float angle;   // area rotate angle, Positive value is counterclockwise, negative value is clockwise.
    float rectWidth; //screen normalized [0.0, 2.0]
    float rectHeight;//screen normalized [0.0, 2.0]
    bool isUsingSelectedPinArea;
} bef_InfoSticker_pin_selected_area_param;

/// Query pin status
typedef enum bef_InfoSticker_pin_state {
    BEF_INFOSTICKER_NONE = 0,    // Not being pin
    BEF_INFOSTICKER_PINNING,     // Pin
    BEF_INFOSTICKER_PINNED,      // Pinned
} bef_InfoSticker_pin_state;

typedef struct bef_InfoSticker_crop_content_info {
    int contentWidth;
    int contentHeight;
} bef_InfoSticker_crop_content_info;

//get size of infoSticker via type
typedef enum bef_InfoSticker_resolution_type {
    BEF_INFOSTICKER_RESOLUTION_DESIGN = 0,
    BEF_INFOSTICKER_RESOLUTION_DESIGN_HEIGHT,
    BEF_INFOSTICKER_RESOLUTION_NORMALIZED,
    BEF_INFOSTICKER_RESOLUTION_ORIGINAL,
}bef_InfoSticker_resolution_type;

typedef struct bef_info_sticker_brush_sticker_info {
    const char* sticker_path;
    bef_InfoSticker_texture* background;
    int canvas_width;
    int canvas_height;
} bef_info_sticker_brush_sticker_info;

typedef struct bef_info_sticker_brush_sticker_state {
    int undo_count;
    int redo_count;
    float stroke_size;
    bef_BoundingBox_2d content_area;
} bef_info_sticker_brush_sticker_state;


typedef struct bef_InfoSticker_canvas_info {
    unsigned int width;
    unsigned int height;
} bef_InfoSticker_canvas_info;

typedef struct bef_info_sticker_edit_rich_text_param {
    int iOpCode;
    float iParam1;
    float iParam2;
    float iParam3;
    float iParam4;
    char* pParam5;
} bef_info_sticker_edit_rich_text_param;

#endif // EFFECT_SDK_INFOSTICKER_PUBLIC_DEFINE_H
