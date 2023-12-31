//
//  TrackUtils.hpp
//  LVTemplate
//
//  Created by ZhangYuanming on 2020/2/13.
//

#ifndef TrackUtils_hpp
#define TrackUtils_hpp

#include <stdio.h>
#include <string>
#include <TemplateConsumer/Track.h>
#include <cdom/ModelType.h>

namespace cut {

struct TrackUtils {
    const static std::string TYPE_VIDEO;
    const static std::string TYPE_AUDIO;
    const static std::string TYPE_STICKER;
    const static std::string TYPE_VIDEO_EFFECT;
    const static std::string TYPE_FILTER;
    const static std::string TYPE_ARTICLEVIDEO;
    
public:
    static bool isMainVideo(const std::shared_ptr<CutSame::Track> &track);

    // 副轨/画中画
    static bool isSubVideo(const std::shared_ptr<CutSame::Track> &track);
    
    static cdom::TrackType getTrackType(const std::shared_ptr<CutSame::Track> &track);
    
    static cdom::TrackType getTrackTypeForString(const std::string &trackString);
    
    static std::string getTypeStringForType(const cdom::TrackType &type);
};

}

#endif /* TrackUtils_hpp */
