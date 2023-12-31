#ifndef CANVAS_GPU_VIRTUALIZATION_ES_STATE_QUERY_H_
#define CANVAS_GPU_VIRTUALIZATION_ES_STATE_QUERY_H_

#include <vector>

#include "es_state_tracer.h"
#include "third_party/krypton/canvas/gpu/gl/gl_include.h"

namespace lynx {
namespace canvas {
class EsStateQueryManage;
class EsStateQuery : public ESStateTracer {
  friend class EsStateQueryManage;

 public:
  EsStateQuery(int virtual_id);
  virtual ~EsStateQuery();

 public:
  void Save() override;
  void SetCurrent() override;
  void Begin(GLenum);
  void End();
  void Destory();
  void IsActiveAndMatch(GLenum, bool*);

 private:
  bool RefreshCache();
  int GetVirtualId() const;
  bool IsActive() const;
  bool IsAvailable() const;
  bool IsCanbeUseforBoolean() const;
  bool IsCanbeUseforInteger() const;
  bool IsResultAvailable() const;
  GLuint GetIntegerQueryResult() const;
  GLuint GetBooleanQueryResult() const;

  // virtual id
  int virtual_id_ = 0;

  // used to store the result value of the query
  GLuint cached_for_all_available_ = 0;
  GLuint cached_for_integer_query_ = 0;
  GLuint cached_for_boolean_query_ = 0;

  enum Query : unsigned int {
    kNone = 0,

    kAnySamplesPassed,
    kAnySamplesPassedConservative,
    kPrimitivesGenerated,
    kTransformFeedbackPrimitivesWritten,
  };

  enum State : unsigned int {
    kNotInited = 0,
    kInited,
    kActive,
    kPaused,
    kCompleted,
    kDeleted,
  };

  Query target_ = kNone;
  State state_ = kNotInited;

  // chrome gpu/command_buffer/service/gles2_query_manager.cc
  // service side query ids.
  std::vector<GLuint> service_ids_;
};

}  // namespace canvas
}  // namespace lynx

#endif  // CANVAS_GPU_VIRTUALIZATION_ES_STATE_QUERY_H_
