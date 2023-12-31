// Copyright 2019 The Lynx Authors. All rights reserved.
#ifndef LEPUS_BREAKPOINT_H
#define LEPUS_BREAKPOINT_H

#include <list>
#include <string>

#include "jsbridge/js_debug/lepus/event.h"

namespace lynx {
namespace lepus {

// class for breakpoint location
class BreakpointLocation {
 public:
  // function: function this breakpoint belongs to
  // index: pc index of this breakpoint
  // line, col: line and column number of this breakpoint
  // pc_col: column number of this pc
  // breakpoint_id: 1:line_number:column_number:lepus.js
  BreakpointLocation(Function *function, int32_t pc_index, int32_t line,
                     int32_t pc_col, int32_t col, std::string breakpoint_id,
                     bool enable = true)
      : pc_(function, pc_index),
        line_(line),
        pc_col_(pc_col),
        col_(col),
        breakpoint_id_(std::move(breakpoint_id)),
        is_enabled_(enable) {}

  ~BreakpointLocation() = default;

  // get function the pc belongs
  Function *GetFunction() const { return pc_.first; }
  // get pc index of current function
  int32_t GetIndex() const { return pc_.second; }
  // <function, pc_index>
  std::pair<Function *, int32_t> GetAddress() const { return pc_; }

  bool IsEnabled() const { return is_enabled_; }

  void SetEnabled(bool enable) { is_enabled_ = enable; }

  int32_t GetLine() { return line_; }

  int32_t GetColumn() { return col_; }

  int32_t GetPCColumn() { return pc_col_; }

  std::string ConstructBreakpointId() const { return breakpoint_id_; }

  BreakpointLocation() = delete;
  BreakpointLocation(const BreakpointLocation &) = delete;
  BreakpointLocation &operator=(const BreakpointLocation &) = delete;

 private:
  // breakpoint pc address
  std::pair<Function *, int32_t> pc_;
  // line for this breakpoint
  int32_t line_;
  // column for the pc stopped at this breakpoint
  int32_t pc_col_;
  // column for this breakpoint
  int32_t col_;
  // breakpointId not exactly equals to its address
  std::string breakpoint_id_;
  bool is_enabled_;
};

class Breakpoint {
 public:
  Breakpoint() : enabled_(true) { tools_ = new DebugTool(); }
  ~Breakpoint() {
    delete tools_;
    tools_ = nullptr;
  }
  void SetEnabled(bool enable) { enabled_ = enable; }
  bool IsEnabled() { return enabled_; }

  /// \brief Resolve breakpoint from bp protocol
  // when set a breakpoint, call this function, save the corresponding pc info
  // which need to break at
  bool ResolveBreakpoint(debugProtocols::SetBreakpointByUrl *,
                         template_vector<Function *> &, const std::string &);
  // find if there is a breakpoint is in current pc, if find the breakpoint,
  // return true
  bool FindBreakpointUsingCurrentPC(std::pair<Function *, int32_t> &,
                                    std::string &bp_id, int32_t &line_number,
                                    int32_t &col_number);
  // given the start and end location, return all possible position that can be
  // a breakpoint
  bool FindAllPossibleBreakpointPos(
      debugProtocols::GetPossibleBreakpoints *protocol,
      template_vector<Function *> all_functions);

  // remove breakpoint by id
  bool RemoveBreakpointById(const std::string &breakpoint_id);

 private:
  // Breakpoint locations, save all the breakpoints
  template_vector<std::unique_ptr<BreakpointLocation>>
      breakpoints_location_info_;
  bool enabled_;
  lynx::lepus::DebugTool *tools_;
};

}  // namespace lepus
}  // namespace lynx

#endif  // LEPUS_BREAKPOINT_H
