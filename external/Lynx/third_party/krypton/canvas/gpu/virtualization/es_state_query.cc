
#include "es_state_query.h"

#include "canvas/base/log.h"

namespace lynx {
namespace canvas {

EsStateQuery::EsStateQuery(int _id) : virtual_id_(_id) {
  GLuint service_id = 0;
  ::glGenQueries(1, &service_id);
  DCHECK(0 != service_id);
  service_ids_.push_back(service_id);
  state_ = kInited;
}

EsStateQuery::~EsStateQuery() { EsStateQuery::Destory(); }

void EsStateQuery::Save() {
  if (kAnySamplesPassed == target_) {
    ::glEndQuery(GL_ANY_SAMPLES_PASSED);
  } else if (kAnySamplesPassedConservative == target_) {
    ::glEndQuery(GL_ANY_SAMPLES_PASSED_CONSERVATIVE);
  } else if (kTransformFeedbackPrimitivesWritten == target_) {
    ::glEndQuery(GL_TRANSFORM_FEEDBACK_PRIMITIVES_WRITTEN);
  }
  state_ = kPaused;
  DCHECK(::glGetError() == GL_NO_ERROR);
}

void EsStateQuery::SetCurrent() {
  GLuint service_id = 0;
  ::glGenQueries(1, &service_id);
  DCHECK(0 != service_id);
  service_ids_.push_back(service_id);
  if (kAnySamplesPassed == target_) {
    ::glBeginQuery(GL_ANY_SAMPLES_PASSED, service_id);
  } else if (kAnySamplesPassedConservative == target_) {
    ::glBeginQuery(GL_ANY_SAMPLES_PASSED_CONSERVATIVE, service_id);
  } else if (kTransformFeedbackPrimitivesWritten == target_) {
    ::glBeginQuery(GL_TRANSFORM_FEEDBACK_PRIMITIVES_WRITTEN, service_id);
  }
  state_ = kActive;
  DCHECK(::glGetError() == GL_NO_ERROR);
}

void EsStateQuery::Begin(GLenum target) {
  if (GL_ANY_SAMPLES_PASSED == target) {
    target_ = kAnySamplesPassed;
  } else if (GL_ANY_SAMPLES_PASSED_CONSERVATIVE == target) {
    target_ = kAnySamplesPassedConservative;
  } else if (GL_TRANSFORM_FEEDBACK_PRIMITIVES_WRITTEN == target) {
    target_ = kTransformFeedbackPrimitivesWritten;
  } else {
    DCHECK(false);
  }

  if (service_ids_.size() > 1) {
    ::glDeleteQueries(static_cast<int>(service_ids_.size() - 1),
                      &service_ids_[1]);
    service_ids_.resize(1);
  }
  ::glBeginQuery(target, service_ids_.back());

  // mark result
  cached_for_all_available_ = 0;
  cached_for_integer_query_ = 0;
  cached_for_boolean_query_ = 0;

  // mark state
  state_ = kActive;
}

void EsStateQuery::End() {
  if (kAnySamplesPassed == target_) {
    ::glEndQuery(GL_ANY_SAMPLES_PASSED);
  } else if (kAnySamplesPassedConservative == target_) {
    ::glEndQuery(GL_ANY_SAMPLES_PASSED_CONSERVATIVE);
  } else if (kTransformFeedbackPrimitivesWritten == target_) {
    ::glEndQuery(GL_TRANSFORM_FEEDBACK_PRIMITIVES_WRITTEN);
  }
  state_ = kCompleted;
  RefreshCache();
}

void EsStateQuery::Destory() {
  if (service_ids_.size() > 0) {
    ::glDeleteQueries(static_cast<int>(service_ids_.size()), &service_ids_[0]);
  }
  service_ids_.clear();
  state_ = kDeleted;
}

void EsStateQuery::IsActiveAndMatch(GLenum target, bool* ret) {
  if (ret) {
    if (kActive != state_) {
      *ret = false;
      return;
    }

    if (GL_ANY_SAMPLES_PASSED == target) {
      *ret = (target_ == kAnySamplesPassed);
    } else if (GL_ANY_SAMPLES_PASSED_CONSERVATIVE == target) {
      *ret = (target_ == kAnySamplesPassedConservative);
    } else if (GL_TRANSFORM_FEEDBACK_PRIMITIVES_WRITTEN == target) {
      *ret = (target_ == kTransformFeedbackPrimitivesWritten);
    } else {
      *ret = false;
    }
  }
}

bool EsStateQuery::RefreshCache() {
  DCHECK(service_ids_.size() > 0);
  GLuint available = 0;
  ::glGetQueryObjectuiv(service_ids_.back(), GL_QUERY_RESULT_AVAILABLE,
                        &available);
  if (available == GL_FALSE) return false;

  cached_for_all_available_ = available;
  // check for boolean query
  // For example, for occlusion query, as long as one is true, the whole result
  // is true
  for (const GLuint& service_id : service_ids_) {
    GLuint result = 0;
    ::glGetQueryObjectuiv(service_id, GL_QUERY_RESULT, &result);
    if (0 != result) {
      cached_for_boolean_query_ = 1;
      break;
    }
  }

  // check for integer query
  // Sum the whole result
  for (const GLuint& service_id : service_ids_) {
    GLuint result = 0;
    ::glGetQueryObjectuiv(service_id, GL_QUERY_RESULT, &result);
    cached_for_integer_query_ += result;
  }

  return true;
}

int EsStateQuery::GetVirtualId() const { return virtual_id_; }

bool EsStateQuery::IsActive() const { return kActive == state_; }

bool EsStateQuery::IsAvailable() const { return kDeleted != state_; }

bool EsStateQuery::IsCanbeUseforBoolean() const {
  if (kDeleted == state_) return false;
  if (kNone == target_ || kAnySamplesPassed == target_ ||
      kAnySamplesPassedConservative == target_) {
    return true;
  }
  return false;
}

bool EsStateQuery::IsCanbeUseforInteger() const {
  if (kDeleted == state_) return false;
  if (kNone == target_ || kPrimitivesGenerated == target_ ||
      kTransformFeedbackPrimitivesWritten == target_) {
    return true;
  }
  return false;
}

bool EsStateQuery::IsResultAvailable() const {
  return kCompleted == state_ && 0 != cached_for_all_available_;
}

GLuint EsStateQuery::GetIntegerQueryResult() const {
  return cached_for_integer_query_;
}

GLuint EsStateQuery::GetBooleanQueryResult() const {
  return cached_for_boolean_query_;
}

}  // namespace canvas
}  // namespace lynx
