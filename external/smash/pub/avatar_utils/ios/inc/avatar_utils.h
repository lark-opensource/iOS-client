#ifndef avatar_utils_h
#define avatar_utils_h

NAMESPACE_OPEN(smash)
NAMESPACE_OPEN(avatar_utils)

#ifndef M_PI
    #define M_PI 3.1415926
#endif

/* 以下函数为算法跟踪框的工具函数 */

// 重置框
void ResetRect(mobilecv2::Rect &rect);

// 计算两个框在X和Y轴上的重合比例
void GetAxisOverlap(const mobilecv2::Rect &rect1,
                    const mobilecv2::Rect &rect2,
                    float &x_iou,
                    float &y_iou);

/* 当前矩形框是否有效 */
bool IsBoxValid(const mobilecv2::Rect &bbox);

// 计算两个点之间的距离
float CalcPointDist(const float* A,
                    const float* B,
                    const bool is_sqrt=true);

// 计算两个框中心点之间的距离
float CalcBoxCenterDist(const mobilecv2::Rect &bbox1,
                        const mobilecv2::Rect &bbox2);

/* 根据历史框平滑当前框结果
  Param:
   cur_bbox: 当前框
   prev_bbox: 历史框
   track_bbox: 平滑后的输出框
*/
void SmoothBox(const mobilecv2::Rect cur_bbox,
               const mobilecv2::Rect prev_bbox,
               mobilecv2::Rect &track_bbox) ;

/* 计算两个框的IOU */
float GetIOU(const mobilecv2::Rect &box1, const mobilecv2::Rect &box2);

/* 以下函数为跟踪算法，2d关键点算法等的输入处理或输出处理函数 */

/* 将局部图像中与其他框重合区域的像素擦出
  Param:
   img: 输入矩形框
   box1: 输出方框
   box2: 其他框
   input_side: 图像的边长
*/
void EraseImageWithBoxOverlap(mobilecv2::Mat &img,
                              const mobilecv2::Rect& box1,
                              const mobilecv2::Rect& box2);

// 手部跟踪模型输出后处理
void PostPower(float *prob, float scale, float shift, float power, int size);

/* 解析手跟踪模型的跟踪框输出
  Param:
    bb_data: 跟踪模型的输出
    box_input: 模型输入图像对应的裁剪框
    box_ret: 解析后得到的手部跟踪框
    image_w: 算法输入图像的宽
    image_h: 算法输入图像的高
*/
void ParseBoxRegData(float* bb_data,
                     const mobilecv2::Rect &box_input,
                     mobilecv2::Rect &box_ret,
                     const int image_w,
                     const int image_h);

/* 将矩形框根据相机旋转参数做对应旋转
  Param:
    rect: 原始矩形框
    w: 输入图像的宽
    h: 输入图像的高
    out: 旋转后的矩形框
    rotation: 屏幕的旋转参数
*/
int TransBbox(const mobilecv2::Rect_<float> &rect,
              const int w,
              const int h,
              mobilecv2::Rect_<float> &out,
              const int rotation);

/* 将矩阵型做扩充并进行边界检查
  Param:
   rotmats: 3x3的旋转矩阵
   offset: 3x1的平移向量
   transmat: 4x4的旋转平移矩阵
*/
int GetExpandBoxAndCheck(const mobilecv2::Mat &input_image,
                 const mobilecv2::Rect &box,
                 mobilecv2::Rect &init_box,
                 const float exp_ratio,
                 bool is_square = false);

/* 将矩形框扩展成方框，并获取缩放后矩形框在方框中的相对位置框
  Param:
   init_box: 输入矩形框
   square_box: 输出方框
   init_box_local: 矩形框在方框中的相对位置（缩放后）
   resize_h: 缩放后的图像高度
   resize_w: 缩放后的图像宽度
*/
int GetSquareBox(mobilecv2::Rect &init_bbox,
                 mobilecv2::Rect &square_bbox,
                 mobilecv2::Rect &init_box_local,
                 int resize_h,
                 int resize_w);

/* 给定框，裁剪局部图像并后处理得到网络的输入图像
  Param:
    src_image: 原始图像
    param: 图像相关参数
    rotator: 旋转器
    init_box: 裁剪图像对应的矩形框
    final_img: 裁剪并后处理后的图像
    input_h: 输入图像的高
    input_w: 输入图像的宽
    need_rotate: 是否需要旋转
    need_filp: 是否需要横向反转
    to_bgr: 是否转换成bgr
 */
int GetInputImageWithBox(const mobilecv2::Mat &input_image,
                  const smash::InputParameter &param,
                  smash::utils::Rotator &rotator,
                  const mobilecv2::Rect &init_box,
                  mobilecv2::Mat &final_img,
                  int input_h,
                  int input_w,
                  const bool need_rotate=false,
                  const bool need_filp=false,
                  const bool to_bgr=false);

/* 裁剪图像框，不做边界判定
  Param:
   input_img: 跟踪模型的输出
   output_img: 裁剪
   box: 用于裁剪的初始框
   out_box: 扩张后的框
   expand_ratio: 裁剪扩张比例
   do_rot: 是否进行旋转
   rot_theta: 旋转角
   crop_h: 裁剪图像的高
   crop_w: 裁剪图像的宽
*/
mobilecv2::Mat GetCropImage(const mobilecv2::Mat& input_img,
                            mobilecv2::Mat& output_img,
                            const mobilecv2::Rect_<float> &box,
                            mobilecv2::Rect_<float> &out_box,
                            float expand_ratio,
                            bool do_rot,
                            float rot_theta,
                            int input_h,
                            int input_w);


/* 解析Heatmap输出的2D关键点
  Param:
    heatmap_data: heatmap矩阵的地址
    height: 矩阵高
    widht: 矩阵宽
    channel: 通道数（点的个数）
    is_flip: 是否进行横向反转
    init_box: 局部图像对应的位置框
    orient: 图像的反转朝向
    key_points: 2D关键点
    key_point_scores: 2D关键点置信度
    heatmap_aChannels: 用来存储heatmap的矩阵数组
*/
int ParseHeatmap(float *heatmap_data,
                 int input_h,
                 int input_w,
                 int channel_num,
                 bool is_flip,
                 const mobilecv2::Rect &init_box,
                 const ScreenOrient &orient,
                 float *key_points,
                 float *key_point_scores,
                 mobilecv2::Mat *heatmap_aChannels);

/* 骨骼级联刚性变换
  Param:
   rotmats: 关节的旋转矩阵
   bones: 骨架模板
   parent_idxs: 父节点序号列表
   joints: 3D关键点坐标
   joint_num: 关节数目
   transform: 各关节的全局旋转平移矩阵
*/
int RigidTransform(const float* rotmats,
                   const float* bones,
                   const int* parent_idxs,
                   float* joints,
                   const int joint_num,
                   float* transform=nullptr);

/* rot6D的数据转换成旋转矩阵 */
void Rot6dToMatrix(float *rot6d, float *rotMat);

/* 以下是最小二乘、特征点跟踪，四元数操作相关的工具函数*/

/* 计算为伪逆矩阵，用于最小二乘估计 */
mobilecv2::Mat CalPseudoInverse(int data_num,
                                int data_dim,
                                int degree,
                                mobilecv2::Mat alpha=mobilecv2::Mat(),
                                mobilecv2::Mat weights=mobilecv2::Mat());

/* 用于最小二乘估计 */
mobilecv2::Mat CalT(int data_num, int latency, int fit_len, int degree);

/* 归一化四元数 */
void NormalizeQuat(float *quat);

/* 四元数插值
  Param:
   a: 输入四元数
   b: 输入四元数
   c: 输出四元数
   t: 差值权重
*/
void Slerp(float *a, float *b, float *c, float t);

/* 自适应四元数插值
 Param:
   last: 输入四元数
   cur: 输入四元数
   coutput: 输出四元数
   pre_t: 差值权重
   is_auto: 是否开启自适应策略
 Return:
   t: 插值权重
*/
float AutoAdjustingSlerp(const mobilecv2::Mat &last, const mobilecv2::Mat &cur, mobilecv2::Mat &output,
                         float pre_t, bool is_auto);

/* 获取相机内参矩阵
  Param:
    fov: 相机的fov，角度制
    image_w: 输入图像的宽
    image_h: 输入图像的高
    use_max_side: 是否使用最长边计算fov
  Return
    P: 相机的内参矩阵, 3x3, CV_32F
*/
void GetIntrinsicMat(float fov, int image_w, int image_h, mobilecv2::Mat& P, bool use_max_side = false);

/* 根据预测的2D点计算出相机坐标系下的3D模板的ModelViewMatrix(trans)
  Param:
    joints2d: 图像中的2D点坐标, Jx2, CV_32F
    model3d:  3D模板初始坐标, Jx3, CV_32F
    fovy: 相机的fovy，角度制
    image_w: 输入图像的宽
    image_h: 输入图像的高
  Return
     model_view_matrix: model3d到output的变换矩, 3x4, CV_32F
*/
int GetModelViewMatrix(const mobilecv2::Mat& joints2d,
                       const mobilecv2::Mat& model3d,
                       float fovy,
                       int image_w,
                       int image_h,
                       mobilecv2::Mat& model_view_matrix,
                       bool use_max_side=false);

/* 根据光流计算特征点在当前帧中的位置
  Param:
   local_pre_image_gray: 上一帧局部图像
   local_image_gray: 当前帧局部图像
   box_local: 局部图像对应全局图像的框
   pre_tracking_points: 上一帧全部的特征点
   src_tracking_points: 上一帧特征点中误差小于阈值的点
   tracking_points: 当前帧特征点中误差小于阈值的点
   err_threshold: 误差阈值
*/
int TrackFeaturePointsByOptFlow(mobilecv2::Mat &local_pre_image_gray,
                                mobilecv2::Mat &local_image_gray,
                                const mobilecv2::Rect &box_local,
                                std::vector<mobilecv2::Point2f> &pre_tracking_points,
                                std::vector<mobilecv2::Point2f> &src_tracking_points,
                                std::vector<mobilecv2::Point2f> &tracking_points,
                                int err_threshold);

/* 根据距离过滤掉多余的特征点
  Param:
    tracking_points: 跟踪到的历史特征点
    new_tracking_points: 新检测到的特征点
    feature_point_num: 最多的特征点数量
    min_distance: 特征点之间的最小距离
*/
void NMSForFeaturePoints(std::vector<mobilecv2::Point2f> &tracking_points,
                         std::vector<mobilecv2::Point2f> &new_tracking_points,
                         int feature_point_num,
                         float min_distance);

NAMESPACE_CLOSE(avatar_utils)
NAMESPACE_CLOSE(smash)

#endif /* avatar_utils_h */
