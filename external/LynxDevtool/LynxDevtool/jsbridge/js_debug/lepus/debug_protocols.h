// Copyright 2019 The Lynx Authors. All rights reserved.
#ifndef LEPUS_DEBUG_PROTOCOLS_H
#define LEPUS_DEBUG_PROTOCOLS_H

#include <cstring>
#include <iostream>
#include <string>
#include <utility>
#include <vector>

#include "lepus/array.h"
#include "lepus/function.h"
#include "lepus/table.h"
#include "lepus_debugger_tools.h"
#include "third_party/rapidjson/document.h"
#include "third_party/rapidjson/error/en.h"
#include "third_party/rapidjson/reader.h"
#include "third_party/rapidjson/stringbuffer.h"
#include "third_party/rapidjson/writer.h"

template <typename T>
using template_vector = std::vector<T>;

#define ADD_JSON_STRING_VALUE(Name, Value, Dom)               \
  Dom->AddMember(Name, rapidjson::StringRef((Value).c_str()), \
                 (Dom)->GetAllocator())
#define ADD_JSON_STRING_VALUE2(Name, DataValue, Dom)             \
  do {                                                           \
    rapidjson::Value str;                                        \
    str.SetString(DataValue.c_str(),                             \
                  static_cast<unsigned int>(DataValue.length()), \
                  Dom->GetAllocator());                          \
    Dom->AddMember(Name, str, Dom->GetAllocator());              \
  } while (0)
#define ADD_JSON_COMMON_VALUE(Name, Value, Dom) \
  Dom->AddMember(Name, Value, (Dom)->GetAllocator())
#define ADD_JSON_OBJECT_VALUE(Name, Value, Dom) \
  Dom->AddMember(Name, (Value).GetDom()->GetObject(), (Dom)->GetAllocator())
#define ADD_JSON_OBJECT_ARRAY(Value, Srcs, Dom, Method)            \
  do {                                                             \
    for (auto &s : (Srcs)) {                                       \
      (Value).PushBack(s.GetDom()->Method, (Dom)->GetAllocator()); \
    }                                                              \
  } while (0)
#define HAS_STR_MEMBER(Value, Member) \
  Value.HasMember(#Member) ? (Value)[#Member].GetString() : ""
#define HAS_INT_MEMBER(Value, Member) \
  Value.HasMember(#Member) ? (Value)[#Member].GetInt() : (-1)
#define HAS_BOOL_MEMBER(Value, Member) \
  Value.HasMember(#Member) ? (Value)[#Member].GetBool() : (false)
#define GET_MESSAGE_OVERRIDE()                                 \
  std::string GetMessage() override {                          \
    rapidjson::StringBuffer buffer;                            \
    rapidjson::Writer<rapidjson::StringBuffer> writer(buffer); \
    dom_->Accept(writer);                                      \
    return buffer.GetString();                                 \
  }
#define GET_DOM_OVERRIDE() \
  std::shared_ptr<rapidjson::Document> &GetDom() override { return dom_; }
#define GET_RETURN_DOM_OVERRIDE()                                      \
  void GetRetDom(std::shared_ptr<rapidjson::Document> &ret) override { \
    ret = ret_.GetDom();                                               \
  }

// protocols ref:
// debug protocol:
// https://chromedevtools.github.io/devtools-protocol/tot/Debugger/, runtime
// protocol: https://chromedevtools.github.io/devtools-protocol/tot/Runtime/
namespace debugProtocols {

class StackTrace;
class CallFrame;

enum ProtocolType { Debug = 1000, Runtime };

class BaseProtocol {
 public:
  BaseProtocol(const BaseProtocol &object) = default;
  explicit BaseProtocol(const ProtocolType &type);
  explicit BaseProtocol(std::string script_id = "0",
                        ProtocolType type = ProtocolType::Debug);
  virtual ~BaseProtocol() = default;

  ProtocolType GetProtoType() { return type_; }
  // get protocol message
  virtual std::shared_ptr<rapidjson::Document> &GetDom();
  // get return protocol message
  virtual void GetRetDom(std::shared_ptr<rapidjson::Document> &res);
  virtual std::string GetMessage();
  virtual std::string GetReturnMsg();
  std::shared_ptr<rapidjson::Document> dom_;

 protected:
  std::string script_id_;
  ProtocolType type_;
};

/// Runtime protocols
// Runtime.enable
class REnable : public BaseProtocol {
 public:
  REnable() : BaseProtocol(ProtocolType::Runtime) {}
  ~REnable() override = default;
};

// Runtime.disable
class RDisable : public BaseProtocol {
 public:
  RDisable() : BaseProtocol(ProtocolType::Runtime) {}
};

class StackTraceId : public BaseProtocol {
 public:
  StackTraceId() = default;
  ~StackTraceId() override = default;
  GET_DOM_OVERRIDE();

 private:
  std::string id_;
  std::string debugger_id_;
};

class StackTrace : public BaseProtocol {
 public:
  StackTrace() = default;
  ~StackTrace() override = default;
  GET_DOM_OVERRIDE();

 private:
  std::string description_;
  template_vector<CallFrame> callframes_;
  StackTraceId parent_id_;
};

// Runtime.propertyPreview: for property display
// https://chromedevtools.github.io/devtools-protocol/tot/Runtime/#type-PropertyPreview
class PropertyPreview : public BaseProtocol {
 public:
  PropertyPreview() = default;
  PropertyPreview(const std::string &name, const std::string &type,
                  const std::string &value);
  PropertyPreview(const PropertyPreview &preview);
  PropertyPreview &operator=(const PropertyPreview &other);
  ~PropertyPreview() override = default;

  GET_MESSAGE_OVERRIDE();
  GET_DOM_OVERRIDE();

 private:
  std::string name_;
  std::string type_;
  std::string value_;
};

// Runtime.ObjectPreview
// ref:
// https://chromedevtools.github.io/devtools-protocol/tot/Runtime/#type-ObjectPreview
class ObjectPreview : public BaseProtocol {
 public:
  ObjectPreview();
  ObjectPreview(const std::string &type, bool overflow,
                const std::string &description,
                const template_vector<PropertyPreview> &property_previews,
                const std::string &subtype = "");
  ObjectPreview(const ObjectPreview &preview);
  ObjectPreview &operator=(const ObjectPreview &other);
  ~ObjectPreview() override = default;

  GET_MESSAGE_OVERRIDE();
  GET_DOM_OVERRIDE();
  std::string GetDescription();

 private:
  std::string type_;
  std::string description_;
  bool overflow_;
  std::string subtype_;
  template_vector<PropertyPreview> property_previews_;
};

// Runtime.RemoteObject
// ref:
// https://chromedevtools.github.io/devtools-protocol/tot/Runtime/#type-RemoteObject
class RemoteObject : public BaseProtocol {
 public:
  // scope object initialization, object value should not here
  RemoteObject(std::string type, const std::string &object_id);
  // getProperties initialization
  // objectId only available when it is an object
  explicit RemoteObject(const lynx::lepus::Value &value,
                        std::string object_id = "-1");
  RemoteObject() = default;
  RemoteObject(const RemoteObject &object);
  ~RemoteObject() override = default;

  RemoteObject &operator=(const RemoteObject &other);
  GET_MESSAGE_OVERRIDE();
  GET_DOM_OVERRIDE();
  // input: lepus value, output: corresponding value in string type
  std::string GetValueStr(const lynx::lepus::Value &value);
  // input: lepus value, output: corresponding value type
  std::string GetType(const lynx::lepus::Value &value);

 private:
  // if the value need to display is an object, use this function
  // to get all the properties needed to display
  void SetObjectInfo();
  // if the value need to display is a function, use this function
  // to get all the properties needed to display
  void SetFunctionInfo();
  // if the value need to display is an array, use this function
  // to get all the properties needed to display
  void SetArrayInfo();
  // if the value need to display is a Date, use this function
  // to get all the properties needed to display
  void SetDateInfo();
  // if the value need to display is a reg expression, use this function
  // to get all the properties needed to display
  void SetRegExpInfo();

  // properties needed to display
  std::string type_;
  std::string subtype_;
  std::string class_name_;
  lynx::lepus::Value value_;
  std::string description_;
  std::string object_id_;
  ObjectPreview preview_;
};

// Runtime.PropertyDescriptor
// ref:
// https://chromedevtools.github.io/devtools-protocol/tot/Runtime/#type-PropertyDescriptor
class PropertyDescriptor : public BaseProtocol {
 public:
  PropertyDescriptor(std::string name, const RemoteObject &value,
                     bool configurable, bool enumerable);
  PropertyDescriptor(const PropertyDescriptor &other);
  PropertyDescriptor &operator=(const PropertyDescriptor &other);
  PropertyDescriptor() = default;
  ~PropertyDescriptor() override = default;

  GET_MESSAGE_OVERRIDE();

  GET_DOM_OVERRIDE();

 private:
  std::string name_;
  RemoteObject value_;
  bool configurable_;
  bool enumerable_;
};

// Runtime.GetProperties
// ref:
// https://chromedevtools.github.io/devtools-protocol/tot/Runtime/#method-getProperties
class GetProperties : public BaseProtocol {
 public:
  GetProperties();
  explicit GetProperties(const std::string &object_id);
  ~GetProperties() override = default;
  void InitReturn(const std::string &name, const RemoteObject &object);
  // remoteobject id
  std::string GetObjectId() { return object_id_; }

  GET_DOM_OVERRIDE();
  GET_RETURN_DOM_OVERRIDE();
  GET_MESSAGE_OVERRIDE();

  class Return : public BaseProtocol {
   public:
    Return();
    ~Return() override = default;
    void AddResult(const std::string &name, const RemoteObject &object);
    std::shared_ptr<rapidjson::Document> &GetDom() override;

   private:
    template_vector<PropertyDescriptor> result_;
  };

 private:
  std::string object_id_;
  Return ret_;
};

/// Debug protocols
class PausedObject : public BaseProtocol {
 public:
  PausedObject() = default;
  PausedObject(PausedObject &_obj) = default;
  ~PausedObject() override = default;

  GET_DOM_OVERRIDE();
};

// ref:
// https://chromedevtools.github.io/devtools-protocol/tot/Debugger/#method-enable
class Enable : public BaseProtocol {
 public:
  Enable();
  explicit Enable(int32_t max_size);
  ~Enable() override = default;

  void InitReturn(int32_t debugger_id);
  std::string GetReturnMsg() override;
  GET_RETURN_DOM_OVERRIDE();

  class Return : public BaseProtocol {
   public:
    explicit Return(int32_t debugger_id = -1);
    ~Return() override = default;
    void SetDebuggerId(int32_t debugger_id);
    GET_DOM_OVERRIDE();
    GET_MESSAGE_OVERRIDE();

   private:
    std::string debugger_id_;
  };

 private:
  Return ret_;
};

// ref:
// https://chromedevtools.github.io/devtools-protocol/tot/Debugger/#method-disable
class Disable : public BaseProtocol {
 public:
  Disable() : BaseProtocol(ProtocolType::Debug) {}
  ~Disable() override = default;
};

// ref:
// https://chromedevtools.github.io/devtools-protocol/tot/Debugger/#type-ScriptPosition
class ScriptPosition : public BaseProtocol {
 public:
  ScriptPosition();
  ScriptPosition(const ScriptPosition &position);
  ScriptPosition &operator=(const ScriptPosition &other);
  ~ScriptPosition() override = default;

  GET_DOM_OVERRIDE();

 private:
  int32_t line_number_;
  int32_t column_number_;
};

// ref:
// https://chromedevtools.github.io/devtools-protocol/tot/Debugger/#type-LocationRange
class LocationRange : public BaseProtocol {
 public:
  LocationRange();
  LocationRange(const LocationRange &location);
  LocationRange &operator=(const LocationRange &other);
  ~LocationRange() override = default;

  GET_DOM_OVERRIDE()

 private:
  std::string script_id_;
  ScriptPosition start_;
  ScriptPosition end_;
};

// ref:
// https://chromedevtools.github.io/devtools-protocol/tot/Debugger/#method-stepInto
class StepInto : public BaseProtocol {
 public:
  StepInto();
  ~StepInto() override = default;

 private:
  template_vector<LocationRange> skip_list_;
};

// ref:
// https://chromedevtools.github.io/devtools-protocol/tot/Debugger/#method-stepOver
class StepOver : public BaseProtocol {
 public:
  StepOver();
  ~StepOver() override = default;

 private:
  template_vector<LocationRange> skip_list_;
};

// ref:
// https://chromedevtools.github.io/devtools-protocol/tot/Debugger/#method-stepOut
class StepOut : public BaseProtocol {
 public:
  StepOut() = default;
  ~StepOut() override = default;
};

// ref:
// https://chromedevtools.github.io/devtools-protocol/tot/Debugger/#method-resume
class Resume : public BaseProtocol {
 public:
  Resume();
  ~Resume() override = default;
};

// ref:
// https://chromedevtools.github.io/devtools-protocol/tot/Debugger/#method-getScriptSource
class GetScriptSource : public BaseProtocol {
 public:
  GetScriptSource();
  explicit GetScriptSource(std::string script_id);
  ~GetScriptSource() override = default;

  class Return : public BaseProtocol {
   public:
    explicit Return(std::string script_source = "");
    ~Return() override = default;
    void SetSource(const std::string &script_source);
    GET_DOM_OVERRIDE();
    GET_MESSAGE_OVERRIDE();

   private:
    std::string script_source_;
  };

  void InitReturn(const std::string &script_source);
  std::string GetReturnMsg() override;
  GET_DOM_OVERRIDE();
  GET_RETURN_DOM_OVERRIDE();
  GET_MESSAGE_OVERRIDE();

 private:
  std::string script_id_;
  Return ret_;
};

// ref:
// https://chromedevtools.github.io/devtools-protocol/tot/Debugger/#event-resumed
class Resumed : public BaseProtocol {
 public:
  Resumed() = default;
  ~Resumed() override = default;

  GET_DOM_OVERRIDE();
};

// ref:
// https://chromedevtools.github.io/devtools-protocol/tot/Debugger/#type-Location
class Location : public BaseProtocol {
 public:
  Location();
  Location(std::string script_id, int32_t line_number,
           int32_t column_number = 0);
  Location(const Location &location);
  Location &operator=(const Location &other);
  ~Location() override = default;

  GET_DOM_OVERRIDE();

  std::string script_id_;
  int32_t line_number_;
  // optional
  int32_t column_number_;
};

// ref:
// https://chromedevtools.github.io/devtools-protocol/tot/Debugger/#type-Scope
class Scope : public BaseProtocol {
 public:
  Scope(const std::string &type, const RemoteObject &object);
  Scope(const Scope &scope);
  Scope &operator=(const Scope &other);
  ~Scope() override = default;

  GET_DOM_OVERRIDE();

 private:
  std::string type_;
  RemoteObject object_;
};

// ref:
// https://chromedevtools.github.io/devtools-protocol/tot/Debugger/#type-CallFrame
class CallFrame : public BaseProtocol {
 public:
  CallFrame() = default;
  CallFrame(std::string callframe_id, std::string function_name,
            const Location &location, std::string url,
            template_vector<Scope> scope_chain,
            const RemoteObject &this_object);
  CallFrame(const CallFrame &callframe);
  CallFrame &operator=(const CallFrame &other);
  ~CallFrame() override = default;

  GET_DOM_OVERRIDE();

 private:
  std::string call_frame_id_;
  std::string function_name_;
  Location location_;
  std::string url_;
  template_vector<Scope> scope_chain_;
  RemoteObject this_object_;
};

// ref:
// https://chromedevtools.github.io/devtools-protocol/tot/Debugger/#event-paused
class Paused : public BaseProtocol {
 public:
  Paused() = default;
  Paused(template_vector<CallFrame> callframes, std::string reason);
  Paused(const lynx::lepus::Value &callframes, const std::string &reason);
  ~Paused() override = default;

  GET_DOM_OVERRIDE();

 private:
  Location GetCallframeLocation(const lynx::lepus::Value &callframe);
  template_vector<Scope> GetCallFrameScopeChain(
      const lynx::lepus::Value &callframe);
  template_vector<CallFrame> callframes_;
  std::string reason_;
  // optional
  PausedObject data_;
  template_vector<std::string> hit_breakpoints_;
  StackTrace async_stack_trace_;
  StackTraceId async_stack_trace_id_;
  StackTraceId async_call_stack_trace_id_;
};

// ref:
// https://chromedevtools.github.io/devtools-protocol/tot/Debugger/#event-scriptParsed
class ScriptParsed : public BaseProtocol {
 public:
  ScriptParsed() = default;
  ScriptParsed(std::string script_id, std::string url, int32_t start_line,
               int32_t start_column, int32_t end_line, int32_t end_column,
               int32_t eid, std::string hash);
  ~ScriptParsed() override = default;
  // functions
  GET_DOM_OVERRIDE();

  std::string GetReturnMsg() override {
    rapidjson::Document res;
    res.SetObject();
    res.AddMember("method", "Debugger.scriptParsed", res.GetAllocator());
    res.AddMember("params", dom_->GetObject(), res.GetAllocator());
    rapidjson::StringBuffer buffer;
    rapidjson::Writer<rapidjson::StringBuffer> writer(buffer);
    res.Accept(writer);
    return buffer.GetString();
  }

 private:
  std::string script_id_;
  std::string url_;
  int32_t start_line_;
  int32_t start_column_;
  int32_t end_line_;
  int32_t end_column_;
  int32_t execution_context_id_;
  std::string hash_;
};

// ref:
// https://chromedevtools.github.io/devtools-protocol/tot/Debugger/#method-setBreakpointsActive
class SetBreakpointsActive : public BaseProtocol {
 public:
  explicit SetBreakpointsActive(bool active = true);
  ~SetBreakpointsActive() override = default;

  bool GetActive() { return active_; }

 private:
  bool active_;
};

// ref:
// https://chromedevtools.github.io/devtools-protocol/tot/Debugger/#method-setBreakpointByUrl
class SetBreakpointByUrl : public BaseProtocol {
 public:
  SetBreakpointByUrl();
  SetBreakpointByUrl(int32_t line_number, std::string url,
                     std::string url_regex, std::string hash,
                     int32_t column_number, std::string condition);
  ~SetBreakpointByUrl() override = default;

  // return object
  class Return : public BaseProtocol {
   public:
    Return();
    Return(std::string breakpoint_id, template_vector<Location> locations);
    ~Return() override = default;

    std::shared_ptr<rapidjson::Document> &GetDom() override;

   private:
    std::string breakpoint_id_;
    template_vector<Location> locations_;
  };

  GET_RETURN_DOM_OVERRIDE();
  std::string GetUrl() { return url_; }
  int32_t GetLineNumber() { return line_number_; }
  int32_t GetColumnNumber() { return column_number_; }
  void InitRet(std::string id, template_vector<Location> locations) {
    ret_ = Return(std::move(id), std::move(locations));
  }

 private:
  int32_t line_number_;
  // optional
  std::string url_;
  std::string url_regex_;
  std::string script_hash_;
  int32_t column_number_;
  std::string condition_;
  Return ret_;
};

// ref:
// https://chromedevtools.github.io/devtools-protocol/tot/Debugger/#type-BreakLocation
class BreakLocation : public BaseProtocol {
 public:
  explicit BreakLocation(int32_t line_number, int32_t column_number = -1,
                         std::string type = "");
  BreakLocation(const BreakLocation &break_location);
  ~BreakLocation() override = default;

  BreakLocation &operator=(const BreakLocation &break_location);
  GET_DOM_OVERRIDE();

 private:
  int32_t line_number_;
  // optional
  int32_t column_number_;
  std::string type_;
};

// ref:
// https://chromedevtools.github.io/devtools-protocol/tot/Debugger/#method-getPossibleBreakpoints
class GetPossibleBreakpoints : public BaseProtocol {
 public:
  GetPossibleBreakpoints(const Location &start, const Location &end,
                         bool restrict_to_function = false);
  ~GetPossibleBreakpoints() override = default;

  class Return : public BaseProtocol {
   public:
    Return();
    ~Return() override = default;
    void AddLocations(const BreakLocation &break_location);
    std::shared_ptr<rapidjson::Document> &GetDom() override;

   private:
    template_vector<BreakLocation> locations_;
  };

  void AddRetLocations(const BreakLocation &break_location);
  void GetRetDom(std::shared_ptr<rapidjson::Document> &res) override;
  GET_DOM_OVERRIDE();
  Location start_;
  Location end_;

 private:
  Return ret_;
  bool restrict_to_function_;
};

// Debug.RemoveBreakpoint
// ref:
// https://chromedevtools.github.io/devtools-protocol/tot/Debugger/#method-removeBreakpoint
class RemoveBreakpoint : public BaseProtocol {
 public:
  explicit RemoveBreakpoint(std::string breakpoint_id);
  ~RemoveBreakpoint() override = default;
  GET_DOM_OVERRIDE();
  std::string GetBreakpointId() { return breakpoint_id_; }

 private:
  std::string breakpoint_id_;
};
}  // namespace debugProtocols
#endif
