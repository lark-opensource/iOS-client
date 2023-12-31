//
// Created by zhangyeqi on 2019-12-20.
//

#ifndef CUT_ANDROID_TEMPLATEERROR_H
#define CUT_ANDROID_TEMPLATEERROR_H

#include <cstdint>

namespace cut {

    /**
     * 错误码是一个 int32_t 类型; 负数; 7位10进制: -1234567;
     *
     * 分段逻辑:  -1234567
     * 1234: 附加段，记录VESDK返回的错误码
     * 567: 主段，剪同款组件定义的错误
     *
     * 例子：
     * 业务方输入的文件路径不存在，返回错误码     -18 (18:INVALID_FILE_PATH)
     * 剪同款调用VE接口出现异常-501，返回错误码  -501000 (主段错误码为000, 附加段错误码为501)
     */
    class TemplateError {
    public:
        static const int32_t SUCCESS = 0;

        static const int32_t PREPARE_FAILED = -10;
        /**
         * 下载Zip包失败
         */
        static const int32_t PREPARE_DOWNLOAD_FAILED = -11;
        /**
         * 解压Zip包失败
         */
        static const int32_t PREPARE_UNZIP_FAILED = -12;
        /**
         * 生成Project对象失败
         */
        static const int32_t PREPARE_DECODE_FAILED = -13;
        /**
         * 获取视频(选择视频)失败
         */
        static const int32_t PREPARE_FETCH_VIDEO_FAILED = -14;
        /**
         * 获取特效失败
         */
        static const int32_t PREPARE_FETCH_EFFECT_FAILED = -15;

        /**
         * 播放器状态异常, 当前状态不支持此操作
         */
        static const int32_t PLAYER_STATE_ERROR = -16;

        /**
         * materialId 有误, Project对象中找不到
         */
        static const int32_t INVALID_MATERIAL_ID = -17;
        /**
         * filePath 有误, 文件不存在
         */
        static const int32_t INVALID_FILE_PATH = -18;
        /**
         * 缺少必要的参数, 部分参数为空, 无法执行
         */
        static const int32_t INVALID_PARAM_EMPTY = -19;
        /**
         * segmentId无效，无法根据segmentId找到相应的视频段
         */
        static const int32_t INVALID_SEGMENT_ID = -20;
        /**
         * TemplateSource一旦进入播放器之后，就不再允许写操作；
         */
        static const int32_t TEMPLATE_SOURCE_WRITE_LOCK = -21;
        /**
         * 不支持的操作，比如多次重复修改某值，未播放时调用暂停
         */
        static const int32_t OPERATION_NOT_SUPPORT = -22;


        static int32_t extra(int32_t extraErrorCode) {
            extraErrorCode = extraErrorCode >= 0 ? extraErrorCode : (0-extraErrorCode);
            return - extraErrorCode * 1000;
        }
    };
}

#endif //CUT_ANDROID_TEMPLATEERROR_H
