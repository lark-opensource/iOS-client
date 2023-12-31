// Copyright 2020 The Lynx Authors. All rights reserved.

#include "protocol_message.h"
#include <log/logging.h>
#include <json/reader.h>

namespace debugrouter {
namespace protocol {

bool ProtocolMessage::is_use_protocol_message_ = false;

ProtocolMessage::ProtocolMessage(Json::Value &&json) {
  this->root_ptr_ = std::make_unique<Json::Value>(std::move(json));
}

ProtocolMessage::ProtocolMessage(std::string &&str) {
  this->content_ptr_ = std::make_unique<std::string>(std::move(str));
}

// message copy
ProtocolMessage::ProtocolMessage(const ProtocolMessage &message) {
  if (message.content_ptr_) {
    this->content_ptr_ = std::make_unique<std::string>(*message.content_ptr_);
  }
  if (message.root_ptr_) {
    this->root_ptr_ = std::make_unique<Json::Value>(*message.root_ptr_);
  }
  if (message.content_ptr_ == nullptr && message.root_ptr_ == nullptr) {
    LOGE("ProtocolMessage: message status is not invalid");
  }
}

ProtocolMessage::ProtocolMessage(ProtocolMessage &&message) {
  this->content_ptr_.swap(message.content_ptr_);
  this->root_ptr_.swap(message.root_ptr_);
}

const std::string &ProtocolMessage::GetStringValue() {
  if (content_ptr_ == nullptr && root_ptr_) {
    content_ptr_ = std::make_unique<std::string>(root_ptr_->toStyledString());
    return *content_ptr_;
  }
  return *content_ptr_;
}

const Json::Value &ProtocolMessage::GetJsonValue() {
  if (root_ptr_ == nullptr && content_ptr_) {
    root_ptr_ = std::make_unique<Json::Value>();
    Json::Reader reader;
    reader.parse(*content_ptr_, *root_ptr_);
  }
  return *root_ptr_;
}

bool ProtocolMessage::IsNull() {
  return content_ptr_ == nullptr && root_ptr_ == nullptr;
}

ProtocolMessage::~ProtocolMessage() {}

} // namespace protocol
} // namespace debugrouter