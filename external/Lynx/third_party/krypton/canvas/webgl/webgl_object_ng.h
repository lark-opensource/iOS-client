// Copyright 2021 The Lynx Authors. All rights reserved.

#ifndef CANVAS_WEBGL_WEBGL_OBJECT_NG_H_
#define CANVAS_WEBGL_WEBGL_OBJECT_NG_H_

#include "jsbridge/napi/base.h"
#include "third_party/krypton/canvas/gpu/command_buffer/command_recorder.h"
#include "third_party/krypton/canvas/gpu/gl/gl_include.h"

namespace lynx {
namespace canvas {
class WebGLRenderingContext;

using piper::BridgeBase;
using piper::ImplBase;

class WebGLObjectNG : public ImplBase {
 public:
  ~WebGLObjectNG() override;

  // deleteObject may not always delete the OpenGL resource.  For programs and
  // shaders, deletion is delayed until they are no longer attached.
  void DeleteObject(CommandRecorder*);

  void OnAttached() { ++attachment_count_; }
  void OnDetached(CommandRecorder*);

  // This indicates whether the client side has already issued a delete call,
  // not whether the OpenGL resource is deleted. Object()==0, or !HasObject(),
  // indicates that the OpenGL resource has been deleted.
  bool MarkedForDeletion() { return marked_for_deletion_; }

  // True if this object belongs to the group or context.
  virtual bool Validate(const WebGLRenderingContext*) const = 0;
  virtual bool HasObject() const = 0;

  // called when js object is gone to free gl resource to prevent call virtual
  // function in destructor
  void Dispose();

 protected:
  WebGLObjectNG();

  // deleteObjectImpl should be only called once to delete the OpenGL resource.
  // After calling deleteObjectImpl, hasObject() should return false.
  virtual void DeleteObjectImpl(CommandRecorder*) = 0;

  void Detach();
  void DetachAndDeleteObject();

  virtual CommandRecorder* GetRecorder() const = 0;

  // Indicates to subclasses that the destructor is being run.
  bool DestructionInProgress() const;

 private:
  unsigned attachment_count_;

  // Indicates whether the WebGL context's deletion function for this object
  // (deleteBuffer, deleteTexture, etc.) has been called. It does *not* indicate
  // whether the underlying OpenGL resource has been destroyed; !HasObject()
  // indicates that.
  bool marked_for_deletion_;

  // Indicates whether the destructor has been entered and we therefore
  // need to be careful in subclasses to not touch other on-heap objects.
  bool destruction_in_progress_;
};

}  // namespace canvas
}  // namespace lynx

#endif  // CANVAS_WEBGL_WEBGL_OBJECT_NG_H_
