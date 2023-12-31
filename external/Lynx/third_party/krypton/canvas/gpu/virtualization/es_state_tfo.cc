
#include "es_state_tfo.h"

#include "canvas/base/log.h"
namespace lynx {
namespace canvas {

void EsStateTfo::Save() {
  ::glGetIntegerv(GL_TRANSFORM_FEEDBACK_BINDING, &tfo_);
  ::glGetBooleanv(GL_TRANSFORM_FEEDBACK_ACTIVE, &tfo_active_);
  ::glGetBooleanv(GL_TRANSFORM_FEEDBACK_PAUSED, &tfo_paused_);
  GLint max_transform_feedback_separate_attribs = 0;
  ::glGetIntegerv(GL_MAX_TRANSFORM_FEEDBACK_SEPARATE_ATTRIBS,
                  &max_transform_feedback_separate_attribs);
  tfo_0_buffers_.resize(max_transform_feedback_separate_attribs);
  ::glBindTransformFeedback(GL_TRANSFORM_FEEDBACK, 0);
  for (int i = 0; i < (int)tfo_0_buffers_.size(); ++i) {
    auto& item = tfo_0_buffers_[i];
#ifndef TRANSFORM_FEEDBACK_BUFFER
#define TRANSFORM_FEEDBACK_BUFFER(attr, val) \
  ::glGetInteger64i_v(GL_TRANSFORM_FEEDBACK_##attr, i, val);
    TRANSFORM_FEEDBACK_BUFFER(BUFFER_BINDING, &item.buffer_);
    TRANSFORM_FEEDBACK_BUFFER(BUFFER_SIZE, &item.size_);
    TRANSFORM_FEEDBACK_BUFFER(BUFFER_START, &item.offset_);
#undef TRANSFORM_FEEDBACK_BUFFER
#endif  // TRANSFORM_FEEDBACK_BUFFER
  }
  ::glBindTransformFeedback(GL_TRANSFORM_FEEDBACK, tfo_);

  // pause current tfo
  if (tfo_active_ && !tfo_paused_) {
    ::glPauseTransformFeedback();
  }

  DCHECK(::glGetError() == GL_NO_ERROR);
}

void EsStateTfo::SetCurrent() {
  ::glBindTransformFeedback(GL_TRANSFORM_FEEDBACK, 0);
  for (int i = 0; i < (int)tfo_0_buffers_.size(); ++i) {
    auto& item = tfo_0_buffers_[i];
    if (0 == item.buffer_ || 0 == item.size_) {
      ::glBindBufferBase(GL_TRANSFORM_FEEDBACK_BUFFER, i, item.buffer_);
    } else {
      ::glBindBufferRange(GL_TRANSFORM_FEEDBACK_BUFFER, i, item.buffer_,
                          item.offset_, item.size_);
    }
  }
  ::glBindTransformFeedback(GL_TRANSFORM_FEEDBACK, tfo_);

  // resume current tfo
  if (tfo_active_ && !tfo_paused_) {
    ::glResumeTransformFeedback();
  }

  DCHECK(::glGetError() == GL_NO_ERROR);
}
}  // namespace canvas
}  // namespace lynx
