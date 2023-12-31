//
//  LVMediaDrat+Private.h
//  LVTemplate
//
//  Created by luochaojing on 2020/2/25.
//

#ifndef LVMediaDrat_Private_h
#define LVMediaDrat_Private_h

#import "LVDraftModels.h"
#include <TemplateConsumer/TemplateModel.h>
#include <TemplateConsumer/Segment.h>
#include <TemplateConsumer/Keyframe.h>
#include <TemplateConsumer/MaterialCanvas.h>
#include <TemplateConsumer/Clip.h>
#include <TemplateConsumer/Animations.h>
#include <TemplateConsumer/Crop.h>
#include <TemplateConsumer/MaterialVideo.h>

@interface LVMediaDraft (Private)

- (std::shared_ptr<CutSame::TemplateModel>)cppmodel;
- (instancetype)initWithCPPModel:(std::shared_ptr<CutSame::TemplateModel>)cppmodel;

@end

@interface LVMediaSegment (Private)

- (std::shared_ptr<CutSame::Segment>)cppmodel;

@end

@interface LVKeyframe (Private)

- (std::shared_ptr<CutSame::Keyframe>)cppmodel;

@end

@interface LVDraftCanvasPayload (Private)

- (std::shared_ptr<CutSame::MaterialCanvas>)cppmodel;

@end

@interface LVSegmentClipInfo (Private)

- (std::shared_ptr<CutSame::Clip>)cppmodel;

@end

@interface LVDraftAnimationPayload (Private)

- (std::shared_ptr<CutSame::Animations>)cppmodel;

@end

@interface LVVideoCropInfo (Private)

- (std::shared_ptr<CutSame::Crop>)cppmodel;

@end

@interface LVCanvasConfig (Private)

- (std::shared_ptr<CutSame::CanvasConfig>)cppmodel;

@end

@interface LVDraftVideoPayload (Conversion)

- (instancetype)initWithCPPModel:(std::shared_ptr<CutSame::MaterialVideo>)cppmodel;

- (std::shared_ptr<CutSame::MaterialVideo>)cppmodel;
@end

#endif /* LVMediaDrat_Private_h */
