#pragma once

#ifdef __cplusplus

#define NS_LIVER_BEGIN namespace com{ namespace ss{ namespace ttm { namespace liver{
#define NS_LIVER_END }}}}
#define USING_LIVER_NS using namespace com::ss::ttm::liver;

#define NS_BASE_BEGIN namespace com{ namespace ss{ namespace ttm {
#define NS_BASE_END }}}
#define USING_BASE_NS using namespace com::ss::ttm;
#define NS_BASE_CLASS(a) namespace com{ namespace ss{ namespace ttm {class a;}}}
#define NS_BASE_PREFIX(a) com::ss::ttm::a

#define NS_PLAYER_BEGIN namespace com{ namespace ss{ namespace ttm { namespace player{
#define NS_PLAYER_END }}}}
#define USING_PLAYER_NS using namespace com::ss::ttm::player;
#define NS_PLAYER_CLASS(a) namespace com{ namespace ss{ namespace ttm{ namespace player {class a;}}}}

#define NS_UTILS_BEGIN  namespace com{ namespace ss{ namespace ttm{ namespace utils{
#define NS_UTILS_END }}}}
#define USING_UTILS_NS using namespace com::ss::ttm::utils;
#define NS_UTILS_CLASS(a) namespace com{ namespace ss{ namespace ttm { namespace utils{class a;}}}}

#define NS_TCF_BEGIN  namespace com{ namespace ss{ namespace ttm { namespace tcf{
#define NS_TCF_END }}}}
#define USING_TCF_NS using namespace com::ss::ttm::tcf;

#define NS_WRITER_BEGIN namespace com{ namespace ss{ namespace ttm { namespace writer{
#define NS_WRITER_END  }}}}
#define USING_WRITER_NS using namespace com::ss::ttm::writer;

#define NS_READER_BEGIN namespace com{ namespace ss{ namespace ttm { namespace reader{
#define NS_READER_END  }}}}
#define USING_READER_NS using namespace com::ss::ttm::reader;

#define NS_THUMBNAIL_BEGIN namespace com{ namespace ss{ namespace ttm { namespace thumbnail{
#define NS_THUMBNAIL_END  }}}}
#define USING_THUMBNAIL_NS using namespace com::ss::ttm::thumbnail;

#define NS_FFMPEG_BEGIN namespace com{ namespace ss{ namespace ttm { namespace ffmpeg{
#define NS_FFMPEG_END  }}}}
#define USING_FFMPEG_NS using namespace com::ss::ttm::ffmpeg;

#define NS_PRELOADER_BEGIN namespace com{ namespace ss{ namespace ttm { namespace preloader{
#define NS_PRELOADER_END  }}}}
#define USING_PRELOADER_NS using namespace com::ss::ttm::preloader;

#define NS_EDITOR_BEGIN namespace com{ namespace ss{ namespace ttm { namespace editor{
#define NS_EDITOR_END  }}}}
#define USING_EDITOR_NS using namespace com::ss::ttm::editor;
#define EDITOR_CLASS(a) namespace com{ namespace ss{ namespace ttm { namespace editor{class a;}}}}

#define NS_RECORDER_BEGIN namespace com{ namespace ss{ namespace ttm { namespace recorder{
#define NS_RECORDER_END  }}}}
#define USING_RECORDER_NS using namespace com::ss::ttm::recorder;
#define RECORDER_CLASS(a) namespace com{ namespace ss{ namespace ttm { namespace recorder{class a;}}}}

#define NS_DRM_BEGIN namespace com{ namespace ss{ namespace ttm { namespace drm{
#define NS_DRM_END  }}}}
#define USING_DRM_NS using namespace com::ss::ttm::drm;
#define DRM_CLASS(a) namespace com{ namespace ss{ namespace ttm { namespace drm{class a;}}}}



/**
 * Force Vanguard Namespace
 */

#define NS_LIVER_VAN_BEGIN namespace com{ namespace ss{ namespace ttm { namespace liver{
#define NS_LIVER_VAN_END }}}}
#define USING_LIVER_VAN_NS using namespace com::ss::ttm::liver;

#define NS_BASE_VAN_BEGIN namespace com{ namespace ss{ namespace ttm {
#define NS_BASE_VAN_END }}}
#define USING_BASE_VAN_NS using namespace com::ss::ttm;
#define NS_BASE_VAN_CLASS(a) namespace com{ namespace ss{ namespace ttm {class a;}}}
#define NS_BASE_VAN_PREFIX(a) com::ss::ttm::a

#define NS_PLAYER_VAN_BEGIN namespace com{ namespace ss{ namespace ttm { namespace player{
#define NS_PLAYER_VAN_END }}}}
#define USING_PLAYER_VAN_NS using namespace com::ss::ttm::player;
#define NS_PLAYER_VAN_CLASS(a) namespace com{ namespace ss{ namespace ttm{ namespace player {class a;}}}}

#define NS_UTILS_VAN_BEGIN  namespace com{ namespace ss{ namespace ttm{ namespace utils{
#define NS_UTILS_VAN_END }}}}
#define USING_UTILS_VAN_NS using namespace com::ss::ttm::utils;
#define NS_UTILS_VAN_CLASS(a) namespace com{ namespace ss{ namespace ttm { namespace utils{class a;}}}}

#define NS_TCF_VAN_BEGIN  namespace com{ namespace ss{ namespace ttm { namespace tcf{
#define NS_TCF_VAN_END }}}}
#define USING_TCF_VAN_NS using namespace com::ss::ttm::tcf;

#define NS_WRITER_VAN_BEGIN namespace com{ namespace ss{ namespace ttm { namespace writer{
#define NS_WRITER_VAN_END  }}}}
#define USING_WRITER_VAN_NS using namespace com::ss::ttm::writer;

#define NS_READER_VAN_BEGIN namespace com{ namespace ss{ namespace ttm { namespace reader{
#define NS_READER_VAN_END  }}}}
#define USING_READER_VAN_NS using namespace com::ss::ttm::reader;

#define NS_THUMBNAIL_VAN_BEGIN namespace com{ namespace ss{ namespace ttm { namespace thumbnail{
#define NS_THUMBNAIL_VAN_END  }}}}
#define USING_THUMBNAIL_VAN_NS using namespace com::ss::ttm::thumbnail;

#define NS_FFMPEG_VAN_BEGIN namespace com{ namespace ss{ namespace ttm { namespace ffmpeg{
#define NS_FFMPEG_VAN_END  }}}}
#define USING_FFMPEG_VAN_NS using namespace com::ss::ttm::ffmpeg;

#define NS_PRELOADER_VAN_BEGIN namespace com{ namespace ss{ namespace ttm { namespace preloader{
#define NS_PRELOADER_VAN_END  }}}}
#define USING_PRELOADER_VAN_NS using namespace com::ss::ttm::preloader;

#define NS_EDITOR_VAN_BEGIN namespace com{ namespace ss{ namespace ttm { namespace editor{
#define NS_EDITOR_VAN_END  }}}}
#define USING_EDITOR_VAN_NS using namespace com::ss::ttm::editor;
#define EDITOR_VAN_CLASS(a) namespace com{ namespace ss{ namespace ttm { namespace editor{class a;}}}}

#define NS_RECORDER_VAN_BEGIN namespace com{ namespace ss{ namespace ttm { namespace recorder{
#define NS_RECORDER_VAN_END  }}}}
#define USING_RECORDER_VAN_NS using namespace com::ss::ttm::recorder;
#define RECORDER_VAN_CLASS(a) namespace com{ namespace ss{ namespace ttm { namespace recorder{class a;}}}}

#define NS_DRM_VAN_BEGIN namespace com{ namespace ss{ namespace ttm { namespace drm{
#define NS_DRM_VAN_END  }}}}
#define USING_DRM_VAN_NS using namespace com::ss::ttm::drm;
#define DRM_VAN_CLASS(a) namespace com{ namespace ss{ namespace ttm { namespace drm{class a;}}}}

#endif
