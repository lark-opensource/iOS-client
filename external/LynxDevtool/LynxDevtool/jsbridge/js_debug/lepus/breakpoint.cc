// Copyright 2019 The Lynx Authors. All rights reserved.
#include "breakpoint.h"

namespace lynx {
namespace lepus {

bool Breakpoint::ResolveBreakpoint(debugProtocols::SetBreakpointByUrl* protocol,
                                   template_vector<Function*>& functions,
                                   const std::string& url) {
  if (protocol->GetUrl().find("lepus.js") == std::string::npos) return false;

  // using the breakpoint line and column, traverse all the function pc, find
  // the pc this breakpoint belongs, save to breakpoints_location_info_
  for (auto& function : functions) {
    for (size_t pc_index = 0; pc_index < function->OpCodeSize(); pc_index++) {
      int32_t line_number = 0, column_number = 0;
      tools_->GetPCLineCol(function, static_cast<int32_t>(pc_index),
                           line_number, column_number);
      if (line_number == protocol->GetLineNumber() &&
          column_number >= protocol->GetColumnNumber()) {
        // construct breakpoint id:  1:line_number:column_number:lepus.js
        std::string breakpoint_id =
            "1:" + std::to_string(protocol->GetLineNumber()) + ":" +
            std::to_string(protocol->GetColumnNumber()) + ":lepus.js";
        breakpoints_location_info_.emplace_back(
            std::make_unique<BreakpointLocation>(
                function, pc_index, line_number, column_number,
                protocol->GetColumnNumber(), breakpoint_id, true));
        return true;
      }
    }
  }
  return false;
}

bool Breakpoint::FindBreakpointUsingCurrentPC(
    std::pair<Function*, int32_t>& curr_pc_info, std::string& bp_id,
    int32_t& line_number, int32_t& col_number) {
  // traverse all breakpoints, find if there is a breakpoint corresponding to
  // current pc
  for (auto& bp_loc : breakpoints_location_info_) {
    if (bp_loc->GetFunction() == curr_pc_info.first &&
        bp_loc->GetIndex() == curr_pc_info.second && bp_loc->IsEnabled()) {
      bp_id = bp_loc->ConstructBreakpointId();
      line_number = bp_loc->GetLine();
      col_number = bp_loc->GetColumn();
      return true;
    }
  }
  return false;
}

bool Breakpoint::RemoveBreakpointById(const std::string& breakpoint_id) {
  for (size_t i = 0; i < breakpoints_location_info_.size(); i++) {
    if (breakpoints_location_info_[i]->ConstructBreakpointId() ==
        breakpoint_id) {
      breakpoints_location_info_.erase(breakpoints_location_info_.begin() + i);
      return true;
    }
  }
  return false;
}

bool Breakpoint::FindAllPossibleBreakpointPos(
    debugProtocols::GetPossibleBreakpoints* protocol,
    template_vector<Function*> all_functions) {
  debugProtocols::Location& range_start(protocol->start_);
  debugProtocols::Location& range_end(protocol->end_);
  if (range_end.line_number_ == -1)
    range_end.line_number_ = range_start.line_number_;
  if (range_end.column_number_ == -1) range_end.column_number_ = INT32_MAX;

  bool res = false;
  if (range_start.script_id_ != range_end.script_id_ ||
      range_start.script_id_ != "0")
    return res;

#define ADD_RET_LOCATION                                  \
  do {                                                    \
    res = true;                                           \
    debugProtocols::BreakLocation bp_location(line, col); \
    protocol->AddRetLocations(bp_location);               \
  } while (0)

  // traverse all the function pc position, return the position between
  // range_start and range_end
  for (auto& function : all_functions) {
    for (size_t i = 0; i < function->OpCodeSize(); i++) {
      int32_t line = 0, col = 0;
      tools_->GetPCLineCol(function, static_cast<int32_t>(i), line, col);
      if (line == range_start.line_number_ && line < range_end.line_number_) {
        if (col >= range_start.column_number_) {
          ADD_RET_LOCATION;
        }
      } else if (line == range_start.line_number_ &&
                 line == range_end.line_number_) {
        if (col >= range_start.column_number_ &&
            col <= range_end.column_number_) {
          ADD_RET_LOCATION;
        }
      } else if (line > range_start.line_number_ &&
                 line < range_end.line_number_) {
        ADD_RET_LOCATION;
      } else if (line > range_start.line_number_ &&
                 line == range_end.line_number_) {
        if (col <= range_end.column_number_) {
          ADD_RET_LOCATION;
        }
      }
    }
  }
#undef ADD_RET_LOCATION
  return res;
}

}  // namespace lepus
}  // namespace lynx
