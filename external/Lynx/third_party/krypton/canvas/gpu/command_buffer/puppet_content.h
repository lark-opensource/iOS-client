#ifndef CANVAS_GPU_COMMAND_BUFFER_PUPPET_CONTENT_H_
#define CANVAS_GPU_COMMAND_BUFFER_PUPPET_CONTENT_H_

#include "third_party/krypton/canvas/gpu/command_buffer/command_recorder.h"
#include "third_party/krypton/canvas/gpu/command_buffer_ng/runnable_buffer.h"

namespace lynx {
namespace canvas {
template <class cls>
class PuppetContent final {
 public:
  inline void Set(cls v) { related_data_ = v; }
  inline cls& Get() { return related_data_; }
  inline cls* operator->() const { return &related_data_; }

 public:
  // To perform the release operation, you need to switch to the consumer
  // to perform the release operation
  // !!!it can only be executed once after construction
  void Release(CommandRecorder& recorder) {
    struct Command {
      PuppetContent<cls>* content_ = nullptr;
      void Run(command_buffer::RunnableBuffer*) {
        DCHECK(content_);
        delete content_;
      }
    };
    auto _buffer = recorder.Alloc<Command>();
    _buffer->content_ = this;
  }

 private:
  cls related_data_;
};

}  // namespace canvas
}  // namespace lynx

#endif  // CANVAS_GPU_COMMAND_BUFFER_PUPPET_CONTENT_H_
