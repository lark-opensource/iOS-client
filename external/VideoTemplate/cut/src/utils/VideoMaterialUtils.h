//
//  VideoMaterialUtils.hpp
//  LVTemplate
//
//  Created by ZhangYuanming on 2020/2/14.
//

#ifndef VideoMaterialUtils_hpp
#define VideoMaterialUtils_hpp

#include <stdio.h>
#include <TemplateConsumer/MaterialVideo.h>

namespace cut {


struct VideoMaterialUtils {
    static const std::string MATERIAL_VIDEO_BLACK();
    static const std::string MATERIAL_VIDEO_BLACK_PATH();
    
    /**
     * 生成黑底视频素材
     * @param duration 素材的时长
     */
    static CutSame::MaterialVideo genBlackVideo(uint64_t duration);
};


}

#endif /* VideoMaterialUtils_hpp */
