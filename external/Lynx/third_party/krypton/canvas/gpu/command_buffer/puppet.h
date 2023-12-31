#ifndef CANVAS_GPU_COMMAND_BUFFER_PUPPET_H_
#define CANVAS_GPU_COMMAND_BUFFER_PUPPET_H_

#include "canvas/base/macros.h"
#include "puppet_content.h"

namespace lynx {
namespace canvas {
template <class cls>
class Puppet final {
 public:
  ~Puppet() { Dispose(); }
  Puppet() = default;
  void* operator new(size_t) = delete;

  LYNX_CANVAS_DISALLOW_ASSIGN_COPY(Puppet)

 public:
  // Forced push release,
  // content pointer will be invalid after release
  inline void Dispose() {
    if (nullptr != content_) {
      DCHECK(command_recorder_);
      content_->Release(*command_recorder_);
      content_ = nullptr;
    }
    command_recorder_ = nullptr;
  }

  // Execute the construct and send it to the consumer
  // to construct the relevant data
  inline void Build(CommandRecorder* command_recorder) {
    DCHECK(command_recorder);
    Dispose();
    command_recorder_ = command_recorder;
    content_ = new PuppetContent<cls>();
  }

 public:
  // Helpfulness function
  inline bool IsAvailable() const { return content_ != nullptr; }
  inline PuppetContent<cls>* Get() const { return content_; }
  inline operator PuppetContent<cls>*() const { return content_; }

 private:
  PuppetContent<cls>* content_ = nullptr;
  CommandRecorder* command_recorder_;
};

}  // namespace canvas
}  // namespace lynx

#endif  // CANVAS_GPU_COMMAND_BUFFER_PUPPET_H_
