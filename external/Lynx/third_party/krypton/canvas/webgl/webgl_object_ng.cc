// Copyright 2021 The Lynx Authors. All rights reserved.

#include "webgl_object_ng.h"

namespace lynx {
namespace canvas {

WebGLObjectNG::~WebGLObjectNG() { DCHECK(destruction_in_progress_); }

void WebGLObjectNG::DeleteObject(CommandRecorder* recorder) {
  marked_for_deletion_ = true;

  if (!HasObject()) {
    return;
  }

  if (!attachment_count_) {
    if (!recorder) recorder = GetRecorder();
    if (recorder) {
      DeleteObjectImpl(recorder);
      // Ensure the inherited class no longer claims to have a valid object
      DCHECK(!HasObject());
    }
  }
}

void WebGLObjectNG::Detach() {
  attachment_count_ = 0;  // Make sure OpenGL resource is eventually deleted.
}

void WebGLObjectNG::DetachAndDeleteObject() {
  // To ensure that all platform objects are deleted after being detached,
  // this method does them together.
  Detach();
  DeleteObject(nullptr);
}

void WebGLObjectNG::Dispose() {
  DCHECK(!destruction_in_progress_);
  // This boilerplate pre-finalizer is sufficient for all subclasses, as long
  // as they implement DeleteObjectImpl properly, and don't try to touch
  // other objects on the Oilpan heap if the destructor's been entered.
  destruction_in_progress_ = true;
  DetachAndDeleteObject();
}

void WebGLObjectNG::OnDetached(CommandRecorder* recorder) {
  if (attachment_count_) {
    --attachment_count_;
  }
  if (marked_for_deletion_) {
    DeleteObject(recorder);
  }
}

bool WebGLObjectNG::DestructionInProgress() const {
  return destruction_in_progress_;
}

WebGLObjectNG::WebGLObjectNG()
    : attachment_count_(0),
      marked_for_deletion_(false),
      destruction_in_progress_(false) {}

}  // namespace canvas
}  // namespace lynx
