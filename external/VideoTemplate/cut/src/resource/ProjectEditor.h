//
// Created by wangchengyi on 2019-11-29.
//

#ifndef CUTSAMEAPP_PROJECTEDITOR_H
#define CUTSAMEAPP_PROJECTEDITOR_H

#include <TemplateConsumer/model.hpp>
#include "TemplateSource.h"
#include <string>
#include <memory>
#include <vector>

namespace cut {

    /**
     * Project 对象编辑帮助类
     */
    class ProjectEditor {
    private:
        static bool isMutableMaterial(const shared_ptr<CutSame::TemplateModel> &project, const string &materialID);

    public:

        /**
         * Project 中需要替换的元素，由于生产端的原因存在一些脏数据，清干净
         * @param project
         */
        static void cleanMutableMaterials(const shared_ptr<CutSame::TemplateModel> &project);

        /**
         * 判断是否所有需要替换的元素 都已经全部替换完成
         * @param project
         * @return 0表示全部完成, 否则返回负数错误码
         */
        static int checkAllMutable(const shared_ptr<CutSame::TemplateModel> &project);

        /**
         * 获取 选择Video的约束描述
         */
        static std::vector<shared_ptr<CutSame::VideoSegment>>
        getVideoSegments(const shared_ptr<CutSame::TemplateModel> &project, bool mutableOnly);

        /**
         * 填充更换 materialId 对应的 视频；此视频必须满足 时长/宽高/分辨率/码率 等等限制；目前由业务方保证;
         *
         * 返回true, 表示设置成功；返回false, 表示设置失败（一般materialId非法）；
         */
        static int32_t setVideoPath(const shared_ptr<CutSame::TemplateModel> &project, const string &materialId,
                                 const string &videoPath);
        
        static int32_t setVideoType(const shared_ptr<CutSame::TemplateModel> &project, const string &materialId,
                                    const string &type);

        /**
         * 设置视频的时长裁剪区；单位 ms
         *
         * 返回true, 表示设置成功；返回false, 表示设置失败（一般materialId非法）；
         */
        static int32_t setVideoTimeClip(const shared_ptr<CutSame::TemplateModel> &project, const string &materialId,
                                     int64_t startTime);

        /**
         * 设置视频的空间裁剪区；
         * 输入视频剪裁框四个顶点的x，y坐标，按照左上，右上，左下，右下顺序传输
         *
         *   uint32_t * cropParams = {
         *       LT-X, LT-Y,
         *       RT-X, RT-Y,
         *       LB-X, LB-Y,
         *       RB-X, RB-Y
         *   }
         */
        static int32_t setVideoSpaceClip(const shared_ptr<CutSame::TemplateModel> &project, const string &materialId,
                                         const CutSame::Crop &crop);

        static std::vector<CutSame::TextSegment> getTextSegments(const shared_ptr<CutSame::TemplateModel> &project);

        /**
         * 删除所有转场
         */
        static void deleteAllTransition(const shared_ptr<CutSame::TemplateModel> &project);

        /**
         * 删除所有视频动画
         */
        static void deleteAllVideoAnim(const shared_ptr<CutSame::TemplateModel> &project);

        static shared_ptr<CutSame::TailSegment> getTailSegment(const shared_ptr<CutSame::TemplateModel> &project);
    };
}


#endif //CUTSAMEAPP_PROJECTEDITOR_H
