// Copyright 2021 The Lynx Authors. All rights reserved.

#include "command_recorder.h"

namespace lynx {
namespace canvas {

CommandRecorder::CommandRecorder(
    std::function<void(CommandRecorder*, bool is_sync)> commit_func)
    : commit_func_(commit_func) {}

std::shared_ptr<command_buffer::RunnableBuffer>
CommandRecorder::FinishRecordingAndRestart() {
  std::unique_ptr<DataHolder> buffer = writable_buffer_.GetAndClearContents();
  return std::make_shared<command_buffer::RunnableBuffer>(std::move(buffer));
}

bool CommandRecorder::HasCommandToCommit() const {
  return writable_buffer_.Offset() > 0;
}
}  // namespace canvas
}  // namespace lynx
