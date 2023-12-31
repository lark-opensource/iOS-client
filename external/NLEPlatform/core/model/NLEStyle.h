//
// Created by bytedance on 2020/6/7.
//

#ifndef NLEPLATFORM_NLESTYLE_H
#define NLEPLATFORM_NLESTYLE_H

#include "NLENode.h"
#include "NLEResourceNode.h"
#include <memory>
#include <string>

namespace cut::model {

#ifndef SET_GET_COLOR_VECTOR
#define SET_GET_COLOR_VECTOR(FIELD)                             \
public:                                                         \
    void set##FIELD##Vector(const std::vector<float>& rgba) {   \
        set##FIELD(RGBA2ARGB(rgba));                            \
    }                                                           \
    std::vector<float> get##FIELD##Vector() const {             \
        return ARGB2RGBA(get##FIELD());                         \
    }
#endif

    // https://bytedance.feishu.cn/docs/doccnMVuy4bd2g4nscq0pkzosTh?new_source=message#
    class NLE_EXPORT_CLASS NLEStyText : public NLENode {
    NLENODE_RTTI(NLEStyText);

        static uint32_t RGBA2ARGB(std::vector<float> rgba) {
            uint32_t argb = 0;
            argb = argb | ((static_cast<uint32_t>(rgba[0] * 255.0f) & 0xFFu) << 16u);     // R
            argb = argb | ((static_cast<uint32_t>(rgba[1] * 255.0f) & 0xFFu) << 8u);      // G
            argb = argb | ((static_cast<uint32_t>(rgba[2] * 255.0f) & 0xFFu) << 0u);      // B
            argb = argb | ((static_cast<uint32_t>(rgba[3] * 255.0f) & 0xFFu) << 24u);     // A
            return argb;
        }

        /**
         * ARGB int -> RGBA float
         */
        static std::vector<float> ARGB2RGBA(uint32_t argb) {
            std::vector<float> color;
            color.push_back(static_cast<float>(((argb & 0xff0000u) >> 16u)) / 255.0f);      // R
            color.push_back(static_cast<float>((argb & 0xff00u) >> 8u) / 255.0f);           // G
            color.push_back(static_cast<float>(argb & 0xffu) / 255.0f);                     // B
            color.push_back(static_cast<float>(argb >> 24u) / 255.0f);                      // A
            return color;
        }

        static std::string rgbaArray2hex(std::vector<float> rgba) {
            char hexcol[16];
            int r = (int) (rgba[0] * 255.0f);
            int g = (int) (rgba[1] * 255.0f);
            int b = (int) (rgba[2] * 255.0f);
            int a = (int) (rgba[3] * 255.0f);
            snprintf(hexcol, sizeof hexcol, "#%02x%02x%02x%02x", r, g, b, a);
            return std::string(hexcol);
        }

        static std::string rgbaArray2RgbHex(std::vector<float> rgba) {
            char hexcol[16];
            int r = (int) (rgba[0] * 255.0f);
            int g = (int) (rgba[1] * 255.0f);
            int b = (int) (rgba[2] * 255.0f);
            snprintf(hexcol, sizeof hexcol, "#%02x%02x%02x", r, g, b);
            return std::string(hexcol);
        }

        static std::string argb2hex(uint32_t argb) {
            std::vector<float> argbArray = ARGB2RGBA(argb);
            return rgbaArray2hex(argbArray);
        }

        // 字体大小，行高，单位 pt，转换： px = pt / 72*300
    NLE_PROPERTY_DEC(NLEStyText, FontSize, uint32_t, 0x12, NLEFeature::E) ///< 字体大小，行高，单位 pt，转换： px = pt / 72*300

    NLE_PROPERTY_DEC(NLEStyText, Background, bool, false, NLEFeature::E) ///< true 代表启用背景标签，背景标签是在文字的编辑框内填上特定颜色背景

    NLE_PROPERTY_DEC(NLEStyText, BackgroundColor, uint32_t, 0xF0F8FF32, NLEFeature::E) ///<

    SET_GET_COLOR_VECTOR(BackgroundColor)

    NLE_PROPERTY_DEC(NLEStyText, TextColor, uint32_t, 0x000000E0, NLEFeature::E) ///< 文字显示颜色, 0xFFFFFFFF -> AARRGGBB, Alpha, Red, Green, Blue

    SET_GET_COLOR_VECTOR(TextColor)

        // 横竖排
    public:
        static const int TypeSettingKind_Horizontal = 0;
        static const int TypeSettingKind_Vertical = 1;
    NLE_PROPERTY_DEC(NLEStyText, TypeSettingKind, int, 1, NLEFeature::E)

        // 对齐方式
    public:
        static const int AlignType_LEFT = 0;
        static const int AlignType_CENTER = 1;
        static const int AlignType_RIGHT = 2;
        static const int AlignType_TOP = 3;
        static const int AlignType_BOTTOM = 4;
    NLE_PROPERTY_DEC(NLEStyText, AlignType, int, 1, NLEFeature::E)

    NLE_PROPERTY_DEC(NLEStyText, Shadow, bool, false, NLEFeature::E) ///< true 代表开启阴影效果（花字开启后，此选项失效）

    NLE_PROPERTY_DEC(NLEStyText, ShadowColor, uint32_t, 0, NLEFeature::E) ///< 阴影的颜色，, 0xFFFFFFFF -> AARRGGBB, Alpha, Red, Green, Blue（花字开启后，此选项失效）

    SET_GET_COLOR_VECTOR(ShadowColor)

    NLE_PROPERTY_DEC(NLEStyText, ShadowSmoothing, float, 0.0f, NLEFeature::E)
    /**<
      *代表阴影的模糊半径，单位是相对于文字行高的比例值。比如0.1代表模糊半径会是行高的0.1倍。
      *hadowSmoothing越大，阴影边缘看起来越模糊。shadowSmoothing如果是0，阴影就会和本体一样的形状。（花字开启后，此选项失效）
     */

    NLE_PROPERTY_DEC(NLEStyText, ShadowOffsetX, float, 0.0f, NLEFeature::E) ///<代表阴影相对于文字本体的偏移量，xy两个分量。单位是相对于文字行高的比例值。[0.1, -0.1]会使阴影往右下角偏移。（花字开启后，此选项失效）

    NLE_PROPERTY_DEC(NLEStyText, ShadowOffsetY, float, 0.0f, NLEFeature::E)

    NLE_PROPERTY_DEC(NLEStyText, Bold, bool, false, NLEFeature::E) ///< 加粗

    NLE_PROPERTY_DEC(NLEStyText, BoldWidth, float, false, NLEFeature::E) ///< 粗体宽度，单位是相对于文字行高的比例值。范围-0.05～0.05，为0时为正常样式，大于0时变粗，小于0时变细。Effect 770

    NLE_PROPERTY_DEC(NLEStyText, ItalicDegree, uint32_t, false, NLEFeature::E) ///<斜体倾斜角度，范围0～45度，为0时为正常样式。Effect 770

    NLE_PROPERTY_DEC(NLEStyText, Underline, bool, false, NLEFeature::E) ///< true代表开启下划线。Effect 770

    NLE_PROPERTY_DEC(NLEStyText, UnderlineWidth, float, 0.0f, NLEFeature::E) ///< 下划线宽度，单位是相对于文字行高的比例值。范围0.0～1.0。Effect 770

    NLE_PROPERTY_DEC(NLEStyText, UnderlineOffset, float, 0.0f, NLEFeature::E) ///< 下划线偏移基线的距离，单位是相对于文字行高的比例值。范围0.0～1.0。Effect 770

    NLE_PROPERTY_DEC(NLEStyText, LineGap, float, 0.0f, NLEFeature::E) ///< 排版的行间距，单位是相对于文字行高的比例值。0倍行距代表上下两行文字是依据行高紧密依靠的。

    NLE_PROPERTY_DEC(NLEStyText, CharSpacing, float, 0.0f, NLEFeature::E)
    /**<
     * 字符间距，单位是相对于文字行高的比例值。0倍间距代表每行前后两个字符会按照标准排版紧密排列。
     * 英文单词是以单个letter为单位受影响的。中文则是一个汉字。
     */

    NLE_PROPERTY_DEC(NLEStyText, InnerPadding, float, 0.0f, NLEFeature::E)
    /**<
     * 内边距，单位是相对于文字行高的比例值。编辑框会比文字内容的最小包围盒外扩内边距大小。
     * 内边距如果是0，编辑框会在上下左右四个方向紧贴文字内容。文字内容的最小包围盒是不考虑文字描边，阴影这些带来的影响。
     * 所以内边距为0且同时设置了一定描边宽度，会导致描边内容在编辑框范围外。如果此时开启了背景标签效果，则描边内容也会超出背景标签。
     * 客户端需要自行设置innerPadding>=outlineWidth来保证描边始终在编辑框内部。
     */

    NLE_PROPERTY_DEC(NLEStyText, LineMaxWidth, float, 0.0f, NLEFeature::E)
    /**<
     * 自动换行宽度，显示窗口宽度的百分比，-1代表永远不会自动换行（实际上是内部有一个较大值4000像素）。
     * 横排时超过最大宽度会自动换行到下一行。竖排时超过最大宽度会自动换列到下一列。（>0显示窗口宽度的百分比，<0不限制）
     */

    NLE_PROPERTY_DEC(NLEStyText, Outline, bool, true, NLEFeature::E) ///< true代表开启轮廓效果（花字开启后，此选项失效）

    NLE_PROPERTY_DEC(NLEStyText, OutlineWidth, float, 0.0f, NLEFeature::E) ///< 描边宽度，单位是相对于文字行高的比例值。0.1会使文字具有0.1倍行高的描边。描边上限宽度是0.2（花字开启后，此选项失效）

    NLE_PROPERTY_DEC(NLEStyText, OutlineColor, uint32_t, 0xFFFFFFEB, NLEFeature::E) ///< 描边颜色，rgba4分量描述（花字开启后，此选项失效）

    SET_GET_COLOR_VECTOR(OutlineColor)

    NLE_PROPERTY_OBJECT(NLEStyText, Font, NLEResourceNode, NLEFeature::E)
    /**<
     * 字体路径，字体文件的绝对路径（ttf，otf，ttc均支持）Loki后台下载字体资源包先解压，然后填写到后缀是.ttf .otf .ttc的路径。
     * ios端可以填空字符串代表使用系统默认字体，android端必须填有效值，否则显示无效果。
     */


    NLE_PROPERTY_OBJECT(NLEStyText, FallbackFont, NLEResourceNode, NLEFeature::E)
    /**<
     * 回退字体路径，字体文件的绝对路径（ttf，otf，ttc均支持），首选字体查找字形数据失败时的回退方案。
     * Loki后台下载字体资源包先解压，然后填写到后缀是.ttf .otf .ttc的路径。
     * ios端可以填空字符串代表使用系统默认字体，android端必须填有效值，否则显示无效果。
     */

    NLE_PROPERTY_OBJECT_LIST(NLEStyText, FallbackFontList, NLEResourceNode, NLEFeature::E) ///< 回退字体路径列表，字体文件的绝对路径（ttf，otf，ttc均支持），首选字体查找字形数据失败时的回退方案。Effect 670

    NLE_PROPERTY_OBJECT(NLEStyText, Shape, NLEResourceNode, NLEFeature::E)
    /**<
     * 气泡包绝对路径，填写解压后资源根目录。一旦填入有效气泡包那么排版将会执行固定框排版模式，文字将会自适应调整字体大小到充满气泡内部。
     * 编辑框也会永远等于气泡所标定的框大小。  附上气泡资源制作文档气泡资源制作
     */

    NLE_PROPERTY_DEC(NLEStyText, ShapeFlipX, bool, false, NLEFeature::E) ///< true代表气泡图片X轴翻转。Effect 540

    NLE_PROPERTY_DEC(NLEStyText, ShapeFlipY, bool, false, NLEFeature::E) ///< true代表气泡图片Y轴翻转。Effect 540

    NLE_PROPERTY_DEC(NLEStyText, KTVColor, uint32_t, 0x0, NLEFeature::E) ///< 卡拉ok效果的变化后字体颜色，必须配合卡拉ok脚本资源才会生效。Effect 590

    SET_GET_COLOR_VECTOR(KTVColor)

    NLE_PROPERTY_DEC(NLEStyText, KTVOutlineColor, uint32_t, 0x0, NLEFeature::E) ///< 卡拉ok效果的变化后描边颜色，必须配合卡拉ok脚本资源才会生效。Effect 590

    SET_GET_COLOR_VECTOR(KTVOutlineColor)

    NLE_PROPERTY_DEC(NLEStyText, KTVShadowColor, uint32_t, 0x0, NLEFeature::E) ///< 卡拉ok效果的变化后阴影颜色，必须配合卡拉ok脚本资源才会生效。Effect 590

    SET_GET_COLOR_VECTOR(KTVShadowColor)


    NLE_PROPERTY_OBJECT(NLEStyText, Flower, NLEResourceNode, NLEFeature::E)
    /**<
     * 花字特效包绝对路径，填写解压后资源根目录。
     * 一旦填入有效花字特效包那么渲染效果就会走花字渲染，那么之前的shadow相关参数，outline相关参数均失效。
     */

    NLE_PROPERTY_DEC(NLEStyText, UseFlowerDefaultColor, bool, false, NLEFeature::E)
    /**<
     * true代表花字效果将会使用花字包内的默认初始颜色。用户使用花字包之后是依然可以更改文本颜色的。
     * 更改文本颜色会使花字特效以一种特定方式产生变化。
     * 用户首次应用花字的时候往往希望使用花字包内的默认初始颜色，但是后续使用过程以及从草稿箱恢复时均需要此参数进行配合。
     * 剪映产品中此功能使用率不高，绝大多数用户仅会想使用花字包内的默认初始颜色。因此建议其他客户端接入此功能时，useEffectDefaultColor常置true。
     */

    SET_GET_COLOR_VECTOR(UseFlowerDefaultColor)

    NLE_PROPERTY_DEC(NLEStyText, OneLineTruncated, bool, false, NLEFeature::E) ///< 是不是开启 一行自动截断模式，到达自动换行宽度后会自动截断文字并填充尾字符串

    NLE_PROPERTY_DEC(NLEStyText, TruncatedPostfix, std::string, std::string(), NLEFeature::E) ///< 自动截断时填充的尾字符串

    NLE_PROPERTY_DEC(NLEStyText, BackgroundRoundCorner, bool, false, NLEFeature::E) ///< true 表示启用背景标签的圆角效果，将直角顶点用圆角代替，系统默认值为 false。Effect 990

    NLE_PROPERTY_DEC(NLEStyText, BackgroundRoundRadius, float, 0.0f, NLEFeature::E) ///< 背景标签顶点圆角的半径大小，单位为像素点数，非负浮点数，系统默认值为 0.0f，如果设定值超过了当前能够画出的最大圆角半径，则会自动将半径设定为当前最大值；Effect 990

    public:
        NLEStyText() = default;

        explicit NLEStyText(const std::string &effectSDKJsonString);

        nlohmann::json toEffectJson() const;

        std::string toEffectJsonString() const;

    };

    class NLE_EXPORT_CLASS NLEPoint : public NLENode {
    NLENODE_RTTI(NLEPoint);

    NLE_PROPERTY_DEC(NLEPoint, X, float, 0.0f, NLEFeature::E)

    NLE_PROPERTY_DEC(NLEPoint, Y, float, 0.0f, NLEFeature::E)
    };


    /**
     *
     *   0,0                        1,0
     *    +--------------------------+
     *    |                          |
     *    |           P0             |
     *    |           *              |
     *    |        *     *           |
     *    |     *           *     P1 |
     *    | P2     *           *     |
     *    |           *     *        |               +-----> X
     *    |              *           |               |
     *    |             P3           |               |
     *    |                          |               Y
     *    |                          |
     *    |                          |
     *    |                          |
     *    |                          |
     *    +--------------------------+
     *   0,1                        1,1
     *
     * 假如没有 P1, P2 数据：
     * 则 P1 = (P3.x, P0.y)
     * 则 P2 = (P0.x, P3.y)
     *
     * @deprecated (0,1)坐标系，右下为正，已废弃，请使用NLEStyClip
     */
    class NLE_EXPORT_CLASS NLEStyCrop : public NLENode {
    NLENODE_RTTI(NLEStyCrop);

    // P0.x  XLeftUpper
    NLE_PROPERTY_DEC(NLEStyCrop, XLeft, float, 0.0f, NLEFeature::CROP_4) ///< P0.x  XLeftUpper
    public:
    void setXLeftUpper(float xLeftUpper) {
        setXLeft(xLeftUpper);
    }
    float getXLeftUpper() const {
        return getXLeft();
    }

    NLE_PROPERTY_DEC(NLEStyCrop, YUpper, float, 0.0f, NLEFeature::CROP_4) ///< P0.y  YLeftUpper
    public:
    void setYLeftUpper(float yLeftUpper) {
         setYUpper(yLeftUpper);
    }
    float getYLeftUpper() const {
        return getYUpper();
    }

    NLE_PROPERTY_DEC(NLEStyCrop, XRightUpper, float, 1.0f, NLEFeature::CROP_4) ///< P1.x  XRightUpper

    NLE_PROPERTY_DEC(NLEStyCrop, YRightUpper, float, 0.0f, NLEFeature::CROP_4) ///< P1.y  YRightUpper

    NLE_PROPERTY_DEC(NLEStyCrop, XLeftLower, float, 0.0f, NLEFeature::CROP_4) ///< P2.x  XLeftLower

    NLE_PROPERTY_DEC(NLEStyCrop, YLeftLower, float, 1.0f, NLEFeature::CROP_4) ///< P2.y  YLeftLower

    NLE_PROPERTY_DEC(NLEStyCrop, XRight, float, 1.0f, NLEFeature::CROP_4) ///< P3.x  XRightLower
    public:
    void setXRightLower(float xRightLower) {
        setXRight(xRightLower);
    }
    float getXRightLower() const {
        return getXRight();
    }

    NLE_PROPERTY_DEC(NLEStyCrop, YLower, float, 1.0f, NLEFeature::CROP_4) ///< P3.y  YRightLower
    public:
    void setYRightLower(float yRightLower) {
        setYLower(yRightLower);
    }
    float getYRightLower() const {
        return getYLower();
    }

    };

    /**
     *
     *  -1,1                        1,1
     *    +--------------------------+
     *    |                          |
     *    |           P0             |
     *    |           *              |
     *    |        *     *           |                    Y
     *    |     *           *     P1 |                    |
     *    | P2     *           *     |                    |
     *    |           *     *        |               -----+-----> X
     *    |              *           |                    |
     *    |             P3           |                    |
     *    |                          |
     *    |                          |
     *    |                          |
     *    |                          |
     *    |                          |
     *    +--------------------------+
     *  -1,-1                       1,-1
     *
     * 假如没有 P1, P2 数据：
     * 则 P1 = (P3.x, P0.y)
     * 则 P2 = (P0.x, P3.y)
     *
     *  (-1,1)坐标系，右上为正
     */
    class NLE_EXPORT_CLASS NLEStyClip : public NLENode {
    NLENODE_RTTI(NLEStyClip);

    public:
        NLEStyClip();

    NLE_PROPERTY_OBJECT(NLEStyClip, LeftUpper, NLEPoint, NLEFeature::CLIP) ///< P0
    NLE_PROPERTY_OBJECT(NLEStyClip, RightUpper, NLEPoint, NLEFeature::CLIP) ///< P1
    NLE_PROPERTY_OBJECT(NLEStyClip, LeftLower, NLEPoint, NLEFeature::CLIP) ///< P2
    NLE_PROPERTY_OBJECT(NLEStyClip, RightLower, NLEPoint, NLEFeature::CLIP) ///< P3

    /**
      * 优先读取clip然后进行转换，如果没有clip则读取crop；
      */
    std::shared_ptr<NLEStyCrop> toCrop() {
        auto crop = std::make_shared<NLEStyCrop>();
        // 左上
        crop->setXLeftUpper(clip_x_to_crop_x(getLeftUpper()->getX()));
        crop->setYLeftUpper(clip_y_to_crop_y(getLeftUpper()->getY()));
        // 右上
        crop->setXRightUpper(clip_x_to_crop_x(getRightUpper()->getX()));
        crop->setYRightUpper(clip_y_to_crop_y(getRightUpper()->getY()));
        // 左下
        crop->setXLeftLower(clip_x_to_crop_x(getLeftLower()->getX()));
        crop->setYLeftLower(clip_y_to_crop_y(getLeftLower()->getY()));
        // 右下
        crop->setXRightLower(clip_x_to_crop_x(getRightLower()->getX()));
        crop->setYRightLower(clip_y_to_crop_y(getRightLower()->getY()));
        return crop;
    }

    private:
        static inline float clip_x_to_crop_x(float x) {
            return x * 0.5f + 0.5f;
        }

        static inline float clip_y_to_crop_y(float y) {
            return -y * 0.5f + 0.5f;
        }
    };

    class NLE_EXPORT_CLASS NLEStyCanvas : public NLENode {
    NLENODE_RTTI(NLEStyCanvas);

    NLE_PROPERTY_DEC(NLEStyCanvas, Type, NLECanvasType, NLECanvasType::COLOR, NLEFeature::E) ///< 画布类型 默认颜色

    NLE_PROPERTY_DEC(NLEStyCanvas, Color, uint32_t, 0xFF000000, NLEFeature::E) ///< 画布颜色 type=COLOR 时，此字段才会生效，ARGB格式 默认黑色；

    NLE_PROPERTY_OBJECT(NLEStyCanvas, Image, NLEResourceNode, NLEFeature::E) ///< 画布背景图 type=IMAGE 时，此字段才会生效

    NLE_PROPERTY_DEC(NLEStyCanvas, BlurRadius, float, 0.f, NLEFeature::E)  ///< 画布背景模糊半径 type=VIDEO_FRAME 时，此字段才生效；模糊程度 1-14档，0为不模糊；默认 0

    NLE_PROPERTY_DEC(NLEStyCanvas, StartColor, uint32_t, 0xFF000000, NLEFeature::E) ///< 画布渐变起始颜色 type=GRADIENT_COLOR 时，此字段才会生效

    NLE_PROPERTY_DEC(NLEStyCanvas, EndColor, uint32_t, 0xFF000000, NLEFeature::E) ///< 画布渐变结束颜色 type=GRADIENT_COLOR 时，此字段才会生效

    NLE_PROPERTY_DEC(NLEStyCanvas, Antialiasing, bool, false, NLEFeature::E) ///< 抗锯齿 - 有性能损耗，默认 false

        // 画布框颜色 ARGB
    NLE_PROPERTY_DEC(NLEStyCanvas, BorderColor, uint32_t, 0xFF000000, NLEFeature::CANVAS_BORDER)
    NLE_PROPERTY_DEC(NLEStyCanvas, BorderWidth, uint32_t, 0, NLEFeature::CANVAS_BORDER)

    };

    class NLE_EXPORT_CLASS NLEStyStickerAnim : public NLENode {
    NLENODE_RTTI(NLEStyStickerAnim);

    NLE_PROPERTY_DEC(NLEStyStickerAnim, Loop, bool, false, NLEFeature::E) ///< 是否为循环动画，若为循环动画，则将inPath作为动画路径

    NLE_PROPERTY_DEC(NLEStyStickerAnim, InDuration, int32_t, 0, NLEFeature::E) ///< 入场动画持续时间，单位微秒

    NLE_PROPERTY_DEC(NLEStyStickerAnim, OutDuration, int32_t, 0, NLEFeature::E) ///< 出场动画持续时间，单位微秒

    NLE_PROPERTY_OBJECT(NLEStyStickerAnim, InAnim, NLEResourceNode, NLEFeature::E) ///< 入场(或循环)动画

    NLE_PROPERTY_OBJECT(NLEStyStickerAnim, OutAnim, NLEResourceNode, NLEFeature::E) ///< 出场动画

    };

    class NLE_EXPORT_CLASS NLEStringFloatPair : public NLENode {
    NLENODE_RTTI(NLEStringFloatPair);

    NLE_PROPERTY_DEC(NLEStringPair, First, std::string, std::string(), NLEFeature::E)

    NLE_PROPERTY_DEC(NLEStringPair, Second, float, 0.0f, NLEFeature::E)
    };

    class NLE_EXPORT_CLASS NLETextTemplateClip : public NLENode {
    NLENODE_RTTI(NLETextTemplateClip);

        // 文本内容
    NLE_PROPERTY_DEC(NLETextTemplateClip, Content, std::string, std::string(), NLEFeature::E)
    // 对应的索引值
    NLE_PROPERTY_DEC(NLETextTemplateClip, Index, int32_t, 0, NLEFeature::E)

    };

}
#endif //NLEPLATFORM_NLESTYLE_H
