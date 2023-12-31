// Copyright 2019 The Lynx Authors. All rights reserved.
#ifndef LEPUS_LEPUS_DEBUGGER_H
#define LEPUS_LEPUS_DEBUGGER_H

#include <list>
#include <memory>
#include <queue>
#include <string>

#include "jsbridge/js_debug/lepus/breakpoint.h"
#include "jsbridge/js_debug/lepus/debug_protocols.h"
#include "jsbridge/js_debug/lepus/event.h"
#include "lepus/debugger_base.h"
#include "third_party/rapidjson/document.h"

namespace lynx {
namespace lepus {

class VMContext;
class DebugTool;

enum DebuggerStepMode {
  LEPUS_DEBUGGER_STEP = 1,      // step over
  LEPUS_DEBUGGER_STEP_IN,       // step in
  LEPUS_DEBUGGER_STEP_OUT,      // step out
  LEPUS_DEBUGGER_STEP_CONTINUE  // continue
};

struct SteppingState {
  int32_t stepping_mode;    // step mode when press step button
  int32_t stepping_line;    // line number when press step button
  int32_t stepping_column;  // column number when press step button
  int32_t stepping_depth;   // function stack depth when press step button
  SteppingState(int32_t mode, int32_t line, int32_t col, int32_t depth) {
    stepping_mode = mode;
    stepping_line = line;
    stepping_column = col;
    stepping_depth = depth;
  }
};
using DebuggerStep = struct SteppingState;

class Debugger : public DebuggerBase,
                 public std::enable_shared_from_this<Debugger> {
  friend class VMContext;

 public:
  Debugger();
  ~Debugger();
  // All debug thread states
  enum StateType {
    eStateInvalid = 0,
    eStateUnloaded,   ///< Process is object is valid, but not currently loaded
    eStateConnected,  ///< Process is connected to remote debug services, but
    ///< not launched or attached to anything yet
    eStateAttaching,  ///< Process is currently trying to attach
    eStateLaunching,  ///< Process is in the process of launching
    // The state changes eStateAttaching and eStateLaunching are both sent while
    // the private state thread is either not yet started or paused. For that
    // reason, they should only be signaled as public state changes, and not
    // private state changes.
    eStateStopped,   ///< Process or thread is stopped and can be examined.
    eStateRunning,   ///< Process or thread is running and can't be examined.
    eStateStepping,  ///< Process or thread is in the process of stepping and
    ///< cannot be examined.
    eStateCrashed,    ///< Process or thread has crashed and can be examined.
    eStateDetached,   ///< Process has been detached and can't be examined.
    eStateExited,     ///< Process has exited and can't be examined.
    eStateSuspended,  ///< Process or thread is in a suspended state as far
    ///< as the debugger is concerned while other processes
    ///< or threads get the chance to run.
    kLastStateType = eStateSuspended
  };

 public:
  // About process state. {
  ///< \brief Update process state and receive new messages.
  Debugger::StateType UpdateDebugger(const std::string &message);

  /// \brief Handle the event and return new state.
  void HandleDebugEvent(Event &curr_event, StateType &current_state);

  /// \brief Core state machine to control debug process
  void SendMessagesToDebugger(const std::string &message) override;
  // }

  void SendProtocolMessages(std::shared_ptr<rapidjson::Document> &dom,
                            int32_t event_id = -1,
                            const std::string &method = "");

  /// \brief Construct return message
  /// \return Message to return
  std::string ConstructReturnMessage(
      const std::shared_ptr<rapidjson::Document> &dom, int32_t id = -1,
      const std::string &method = "");

  // init VMContext.
  void SetVMContext(VMContext *ctx) override;

  // using root_function, get all the functions in this context. save to
  // all_functions_
  void GetAllFunctions(Function *root_function) override;

  void SetDebugInfo(const std::string &debug_info) override;

  // get all the debug info we needed from template_debug.json
  void PrepareDebugInfo() override;

  // set function and pc index
  void SetCurrentPC(Function *function, int32_t pc) {
    curr_pc_info_.first = function;
    curr_pc_info_.second = pc;
  }

  bool IsHitBreakpoint(std::string &, int32_t &, int32_t &);

  bool IsFuncsEmpty() override { return all_functions_.empty(); }

  // call when paused, return Debugger.paused event
  void Paused();
  // call when resumed, return Debugger.resumed event
  void Resumed();

  void HandleStepping();

  void GetVariablesProperties(debugProtocols::GetProperties *protocol,
                              const Value &variables, Frame *frame);

  lynx::base::scoped_refptr<Function> GetCurrentFunction();

  // parse protocol messages to event.
  void HandleMsg(const std::string &);

  // pop protocol event from the queue
  void PopEvent() { events_.pop_front(); }

  bool EventEmpty() { return events_.empty(); }

  // add protocol event into the queue
  void AddEvent(std::shared_ptr<Event> &event);

  /// \brief Call back function. {
  void SendResponseMessage(int32_t id, const std::string &return_message);
  /// \brief Send response event
  void SendNotificationMessage(const std::string &return_message);

  std::shared_ptr<Event> &GetEvent() { return events_.front(); }

  void ProcessDebuggerMessages(int32_t current_pc) override;

  void ProcessPausedMessages(lepus::Context *context,
                             const std::string &message) override;

 private:
  std::list<std::shared_ptr<Event>> events_;

  // all the functions in this context
  template_vector<Function *> all_functions_;
  // current pc information, includes: <function this pc belongs, pc index>
  std::pair<Function *, int32_t> curr_pc_info_;

  // Debugger is enabled
  bool is_enabled_;
  // hold vm context point
  VMContext *context_;
  // debugger process state
  StateType state_;
  // hold breakpoints
  Breakpoint *breakpoint_;
  // stepping mode: step over, step in, step out, continue
  DebuggerStep step_mode_;
  lynx::lepus::DebugTool *tools_;

  // debuginfo
  std::string debug_info_;
};

}  // namespace lepus
}  // namespace lynx

#endif  // LEPUS_LEPUS_DEBUGGER_H
