//
// Created by Steven on 2021/2/7.
//

#ifndef CUTSAMECONSUMERCONST_HPP
#define CUTSAMECONSUMERCONST_HPP

static const int32_t CONVERT_RESULT_SUCCESS = 0;
static const int32_t CONVERT_RESULT_FAIL = -1;
static const int32_t CONVERT_RESULT_FAIL_UNKNOWN_TRACK_TYPE = -2;

static const std::string TM_TRACK_TYPE_VIDEO = "video";
static const std::string TM_TRACK_TYPE_AUDIO = "audio";
static const std::string TM_TRACK_TYPE_STICKER = "sticker";
static const std::string TM_TRACK_TYPE_EFFECT = "effect";
static const std::string TM_TRACK_TYPE_FILTER = "filter";

static const std::string TM_CANVAS_TYPE_COLOR = "canvas_color";
static const std::string TM_CANVAS_TYPE_IMAGE = "canvas_image";
static const std::string TM_CANVAS_TYPE_BLUR = "canvas_blur";

static const std::string TM_COLOR_RGBA_BLACK = "#000000FF";
static const std::string TM_COLOR_RGBA_WHITE = "#FFFFFFFF";

static const std::string TM_CANVAS_RATIO_ORIGINAL = "original";
static const std::string TM_CANVAS_RATIO_3_4 = "3:4";
static const std::string TM_CANVAS_RATIO_1_1 = "1:1";
static const std::string TM_CANVAS_RATIO_9_16 = "9:16";
static const std::string TM_CANVAS_RATIO_4_3 = "4:3";
static const std::string TM_CANVAS_RATIO_16_9 = "16:9";
static const std::string TM_CANVAS_RATIO_2_1 = "2:1";
static const std::string TM_CANVAS_RATIO_235_100 = "2.35:1";
static const std::string TM_CANVAS_RATIO_185_100 = "1.85:1";
static const std::string TM_CANVAS_RATIO_IPHONE_X = "1.125:2.436";

static const std::string TM_MATERIAL_TYPE_VIDEO = "video";
static const std::string TM_MATERIAL_TYPE_IMAGE = "photo";
static const std::string TM_MATERIAL_TYPE_GIF = "gif";

static const std::string TM_MATERIAL_TYPE_VIDEO_ANIM = "video_animation";
static const std::string TM_MATERIAL_TYPE_MIX_MODE = "mix_mode";
static const std::string TM_MATERIAL_TYPE_VIDEO_EFFECT = "video_effect";
static const std::string TM_MATERIAL_TYPE_FACE_EFFECT = "face_effect";
static const std::string TM_MATERIAL_TYPE_FILTER = "filter";
static const std::string TM_MATERIAL_TYPE_BEAUTY = "beauty";
static const std::string TM_MATERIAL_TYPE_RESHAPE = "reshape";
static const std::string TM_MATERIAL_TYPE_BRIGHTNESS = "brightness"; // 亮度
static const std::string TM_MATERIAL_TYPE_CONTRAST = "contrast"; // 对比度
static const std::string TM_MATERIAL_TYPE_SATURATION = "saturation"; // 饱和度
static const std::string TM_MATERIAL_TYPE_SHARPENING = "sharpen"; // 锐化
static const std::string TM_MATERIAL_TYPE_HIGHLIGHT = "highlight"; // 高光
static const std::string TM_MATERIAL_TYPE_SHADOW = "shadow"; // 阴影
static const std::string TM_MATERIAL_TYPE_COLOR_TEMPERATURE = "temperature"; //  色温
static const std::string TM_MATERIAL_TYPE_HUE = "tone"; // 色调
static const std::string TM_MATERIAL_TYPE_FADE = "fade"; // 褪色
static const std::string TM_MATERIAL_TYPE_VIGNETTING = "vignetting"; // 暗角
static const std::string TM_MATERIAL_TYPE_PARTICLE = "particle"; // 颗粒
static const std::string TM_MATERIAL_TYPE_LIGHT_SENSATION = "light_sensation"; // 光感

static const std::string TM_ANIM_LOOP = "loop"; // 循环动画
static const std::string TM_ANIM_IN = "in"; // 入场动画
static const std::string TM_ANIM_OUT = "out"; // 出场动画

static const std::string TM_AUDIO_CHANGER_NONE = "none";
static const std::string TM_AUDIO_CHANGER_BOY = "boy";
static const std::string TM_AUDIO_CHANGER_GIRL = "girl";
static const std::string TM_AUDIO_CHANGER_LOLI = "loli";
static const std::string TM_AUDIO_CHANGER_UNCLE = "uncle";
static const std::string TM_AUDIO_CHANGER_MONSTER = "monster";

static const std::string TM_EFFECT_TYPE_TEXT_EFFECT = "text_effect";
static const std::string TM_EFFECT_TYPE_TEXT_SHAPE = "text_shape";

static const int TM_TRACK_FLAG_MAIN_TRACK = 0;

static const std::string EXTRA_KEY_BUSINESS = "business";
static const std::string EXTRA_KEY_CUTSAME_MATERIAL_ID = "material_id"; // 这个需要保留，剪同款业务需要通过这个寻回节点
static const std::string EXTRA_KEY_CUTSAME_IS_MUTABLE = "is_mutable";
static const std::string EXTRA_KEY_CUTSAME_ALIGN_MODE = "align_mode";
static const std::string EXTRA_KEY_ORIGIN_VIDEO_PATH = "originVideoPath"; // 素材原路径

static const std::string EXTRA_VAL_CUTSAME = "cutsame";
static const std::string EXTRA_VAL_ALIGN_MODE_CANVAS = "align_canvas";
static const std::string EXTRA_VAL_ALIGN_MODE_VIDEO = "align_video";

static const std::string TRUE = "true";
static const std::string FALSE = "false";

const static int32_t TYPE_OPTION_JP_CARTOON = 1;
const static int32_t TYPE_OPTION_HK_CARTOON = 2;
const static int32_t TYPE_OPTION_TC_CARTOON = 4;
const static int32_t TYPE_OPTION_PAPER_CUT = 8;

const static int32_t APPLY_TARGET_MAIN = 0;
const static int32_t APPLY_TARGET_SUB = 1;
const static int32_t APPLY_TARGET_ALL = 2;

#endif //CUTSAMECONSUMERCONST_HPP
