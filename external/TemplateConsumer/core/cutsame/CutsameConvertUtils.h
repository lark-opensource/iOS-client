//
// Created by Steven on 2021/1/21.
//

#ifndef TEMPLATECONSUMERAPP_CUTSAMECONVERTUTILS_H
#define TEMPLATECONSUMERAPP_CUTSAMECONVERTUTILS_H

#include <string>
#include <vector>
#include <MaterialVideo.h>
#include <Segment.h>
#include <MaskConfig.h>
#include <Segment.h>
#include <GamePlay.h>

namespace TemplateConsumer {
    class CutsameConvertUtils {
    public:
        // 剪同款模版时间单位可能变化，具体转换规则收敛到这
        static int64_t cutsameToUs(int64_t cutsameTime);

        // 根据seg的一些tag(exp: 倒放)设置material对应的视频path
        static std::string getPlayVideoPath(const std::shared_ptr<CutSame::Segment> &seg,
                                            const std::shared_ptr<CutSame::MaterialVideo> &material);

        static std::string getOptionTypePath(const std::shared_ptr<CutSame::MaterialVideo> &materialVideo);
        static std::string getGameplayPath(std::shared_ptr<CutSame::MaterialVideo> const &materialVideo);

        static void processMaskConfig(
                const std::shared_ptr<CutSame::Segment> &segment,
                const std::shared_ptr<CutSame::MaskConfig> &maskConfig,
                const std::shared_ptr<CutSame::MaterialVideo> &materialVideo);

        static std::vector<double> getVideoCroppedSize(
                int32_t videoWidth, int32_t videoHeight,
                const std::shared_ptr<CutSame::MaterialVideo> &materialVideo);
    };
}


#endif // TEMPLATECONSUMERAPP_CUTSAMECONVERTUTILS_H
