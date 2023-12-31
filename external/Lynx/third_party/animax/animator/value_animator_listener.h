// Copyright 2023 The Lynx Authors. All rights reserved.

#ifndef ANIMAX_ANIMATOR_VALUE_ANIMATOR_LISTENER_H_
#define ANIMAX_ANIMATOR_VALUE_ANIMATOR_LISTENER_H_

#include <cstdint>

namespace lynx {
namespace animax {

class ValueAnimatorListener {
 public:
  virtual ~ValueAnimatorListener() = default;

  /**
   * Notify the start event.
   * You will be notified every time you call ValueAnimator::Play()
   */
  virtual void OnStart() = 0;
  /**
   * Notify new frame comes.
   * You will be notified every frame.
   * @param progress      a progress between origin start frame and origin end
   * frame. 0.0 means origin start frame, 1.0 means origin end frame.
   * @param current_frame current frame. This value is related with progress.
   */
  virtual void OnProgress(double progress, double current_frame) = 0;
  /**
   * Notify entering to new loop.
   * The first turn wouldn't trigger this event, that is current_loop = 0. For
   * instance, you set loop count to 3, then you get OnStart(), OnNewLoop(1),
   * OnNewLoop(2) for each turn.
   * @param current_loop current loop counting from 0, the first turn wouldn't
   * trigger this.
   */
  virtual void OnNewLoop(int32_t current_loop) = 0;
  /**
   * Notify the end event.
   * You will be notified when the value animator finish, there are not any
   * other events more.
   */
  virtual void OnEnd() = 0;
};

}  // namespace animax
}  // namespace lynx

#endif  // ANIMAX_ANIMATOR_VALUE_ANIMATOR_LISTENER_H_
