//
//  ProjectUtils.hpp
//  LVTemplate
//
//  Created by ZhangYuanming on 2020/2/13.
//

#ifndef ProjectUtils_hpp
#define ProjectUtils_hpp

#include <stdio.h>
#include <string>
#include <TemplateConsumer/TemplateModel.h>
#include <TemplateConsumer/Track.h>
#include <TemplateConsumer/Material.h>
#include <TemplateConsumer/Segment.h>
#include <TemplateConsumer/Keyframe.h>
#include "TrackUtils.h"

namespace cut {

struct ProjectUtils {
    static std::shared_ptr<CutSame::Material> getMaterial(const std::shared_ptr<CutSame::TemplateModel>& project, const std::string &materialId);
    
    static std::shared_ptr<CutSame::Track> getMainVideoTrack(std::shared_ptr<CutSame::TemplateModel>& project);
    
    static std::shared_ptr<CutSame::Segment> segment(std::shared_ptr<CutSame::TemplateModel>& project, std::string &segmentID);
    
    static bool isMutableMaterial(std::shared_ptr<CutSame::TemplateModel>& project, const std::string &id);
    
    static int32_t getVersionInt(std::shared_ptr<CutSame::TemplateModel>& project);
    
    static std::vector<std::shared_ptr<CutSame::Track>> getTracks(std::shared_ptr<CutSame::TemplateModel>& project, cdom::TrackType trackType);
    
    static std::vector<std::shared_ptr<CutSame::Segment>> getSegments(std::shared_ptr<CutSame::TemplateModel>& project, cdom::TrackType trackType);
    
    static std::shared_ptr<CutSame::Keyframe> getKeyframe(const std::shared_ptr<CutSame::TemplateModel>& project, const std::string &keyframeId);
};
    
}



#endif /* ProjectUtils_hpp */
