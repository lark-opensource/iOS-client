// Copyright 2019 The Lynx Authors. All rights reserved.
#ifndef LYNX_TASM_REACT_TESTING_PROP_BUNDLE_MOCK_H_
#define LYNX_TASM_REACT_TESTING_PROP_BUNDLE_MOCK_H_

#include <map>
#include <memory>
#include <string>
#include <unordered_set>

#include "tasm/react/prop_bundle.h"

namespace lynx {

namespace tasm {

class PropBundleMock : public PropBundle {
 public:
  PropBundleMock();

  void SetNullProps(const char* key) override;
  void SetProps(const char* key, uint value) override;
  void SetProps(const char* key, int value) override;
  void SetProps(const char* key, const char* value) override;
  void SetProps(const char* key, bool value) override;
  void SetProps(const char* key, double value) override;
  void SetProps(const char* key, const lepus::Value& value) override;
  void SetEventHandler(const EventHandler& handler) override;
  void ResetEventHandler() override;

  static std::unique_ptr<PropBundle> CreateForMock();

  const std::map<std::string, lepus::Value>& GetPropsMap() const;

 private:
  std::unordered_set<std::string> event_handler_;
  std::map<std::string, lepus::Value> props_;
};

}  // namespace tasm

}  // namespace lynx

#endif  // LYNX_TASM_REACT_TESTING_PROP_BUNDLE_MOCK_H_
