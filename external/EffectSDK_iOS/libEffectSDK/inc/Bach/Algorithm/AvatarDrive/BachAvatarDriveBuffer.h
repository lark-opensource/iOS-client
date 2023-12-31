#ifdef __cplusplus
#ifndef BACH_AVATAR_DRIVE_BUFFER_H
#define BACH_AVATAR_DRIVE_BUFFER_H

#include "Bach/Base/BachAlgorithmBuffer.h"

#include "Gaia/AMGPrimitiveVector.h"

NAMESPACE_BACH_BEGIN

#define BEF_AM_E_DIM 52
#define BEF_AM_U_DIM 75
#define BEF_AM_LANDMARK_SIZE (240 * 2)
//#pragma mark - AvatarDriveInfo
/**
*1. alpha 身份系数, 用于结合PCA core恢复完整的实时人脸mesh重建, 驱动AvatarDrive动画时不需要, 忽略即可
*2.beta 表情blendshape系数, blendshape定义与Apple Arkit相同(https://developer.apple.com/documentation/arkit/arfaceanchor/blendshapelocation)  , 下标到名字的映射见下方附录
*3. landmarks 240关键点, 与faceSDK的240关键点定义相同(前106个点为标准的106点), 顺序为xyxyxy..单位为像素(对应接口的输入图像尺寸), 可以用这个来配合自己的制作素材时候参考的固定头模来求解solvepnp(参考其他3D头套素材的渲染).
*4. rot 旋转的欧拉角, 用于完整的实时人脸mesh重建, 对于目前驱动AvatarDrive动画的实现方式不需要, 忽略即可.
*5. mvp 实时人脸mesh重建渲染回画面的mvp矩阵(列优先存储), 对应的是渲染到256人脸窗口内的mvp, 对于目前驱动AvatarDrive动画的实现方式不需要, 忽略即可.
*6. mv 实时人脸mesh重建渲染回画面的mv矩阵(列优先存储), 即不含投影变化, 对应的是渲染到256人脸窗口内的mv, 对于目前驱动AvatarDrive动画的实现方式不需要, 忽略即可.
*7. affine_mat 实时人脸mesh重建渲染回画面的2D变换矩阵(列优先存储), 将上方mvp渲染到256尺寸上的画面用此矩阵affine变换回输入画面等大, 即为3D mesh与画面人脸的对应, 对于目前驱动AvatarDrive动画的实现方式不需要, 忽略即可
*8. succ标志位: 只有当标志位值为2的时候, 说明人脸被有效追踪, 这时才做AvatarDrive素材的渲染, 标志为其他值不要做任何渲染到屏幕上.

* #beta的下标和对应的定义: 前面是名字, 后面是下标, 请注意后面的下标不是有序排列的
* #define eyeLookDown_L 0
* #define noseSneer_L 1
* #define eyeLookIn_L 2
* #define browInnerUp 3
* #define browDown_L 25
* #define mouthClose 5
* #define mouthLowerDown_R 6
* #define jawOpen 7
* #define mouthLowerDown_L 9
* #define mouthFunnel 10
* #define eyeLookIn_R 11
* #define eyeLookDown_R 12
* #define noseSneer_R 13
* #define mouthRollUpper 14
* #define jawRight 15
* #define mouthDimple_L 16
* #define mouthRollLower 17
* #define mouthSmile_L 18
* #define mouthPress_L 19
* #define mouthSmile_R 20
* #define mouthPress_R 21
* #define mouthDimple_R 22
* #define mouthLeft 23
* #define eyeSquint_R 41
* #define eyeSquint_L 4
* #define mouthFrown_L 26
* #define eyeBlink_L 27
* #define cheekSquint_L 28
* #define browOuterUp_L 29
* #define eyeLookUp_L 30
* #define jawLeft 31
* #define mouthStretch_L 32
* #define mouthStretch_R 33
* #define mouthPucker 34
* #define eyeLookUp_R 35
* #define browOuterUp_R 36
* #define cheekSquint_R 37
* #define eyeBlink_R 38
* #define mouthUpperUp_L 39
* #define mouthFrown_R 40
* #define browDown_R 24
* #define jawForward 42
* #define mouthUpperUp_R 43
* #define cheekPuff 44//
* #define eyeLookOut_L 45
* #define eyeLookOut_R 46
* #define eyeWide_R 47
* #define eyeWide_L 49
* #define mouthRight 48
* #define mouthShrugLower 8
* #define mouthShrugUpper 50
* #define tongueOut 51
**/
class BACH_EXPORT AvatarDriveInfo : public AmazingEngine::RefBase
{
public:
    AmazingEngine::FloatVector alpha;    //[AM_U_DIM];
    AmazingEngine::FloatVector beta;     //[AM_E_DIM];
    AmazingEngine::Vec2Vector landmarks; //[240], 人脸240个点，归一化
    AmazingEngine::Vector3f rot;
    AmazingEngine::Matrix4x4f mvp;
    AmazingEngine::Matrix4x4f mv;
    AmazingEngine::Matrix3x3f affine_mat;
    int succ = -1;
    int ID = -1;
    unsigned int action = 0; //貌似没有用
    int width = 0;           //貌似没有用
    int height = 0;          //貌似没有用
};

class BACH_EXPORT AvatarDriveBuffer : public BachBuffer
{
public:
    std::vector<AmazingEngine::SharePtr<AvatarDriveInfo>> m_avatarDriveInfos;

    double xScale = 1.0;
    double yScale = 1.0;
};

NAMESPACE_BACH_END
#endif
#endif