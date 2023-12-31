
// Copyright 2021 The Lynx Authors. All rights reserved.

#ifndef LYNX_STARLIGHT_STYLE_GRID_DATA_H_
#define LYNX_STARLIGHT_STYLE_GRID_DATA_H_

#include <vector>

#include "base/ref_counted.h"
#include "starlight/style/css_type.h"
#include "starlight/types/nlength.h"

namespace lynx {
namespace starlight {

class GridData : public base::RefCountedThreadSafeStorage {
 public:
  void ReleaseSelf() const override { delete this; }
  static base::scoped_refptr<GridData> Create() {
    return base::AdoptRef(new GridData());
  }
  base::scoped_refptr<GridData> Copy() const {
    return base::AdoptRef(new GridData(*this));
  }
  GridData();
  GridData(const GridData& data);
  ~GridData() = default;
  void Reset();

  // grid container
  std::vector<NLength> grid_template_columns_;
  std::vector<NLength> grid_template_rows_;
  std::vector<NLength> grid_auto_columns_;
  std::vector<NLength> grid_auto_rows_;
  NLength grid_column_gap_;
  NLength grid_row_gap_;
  JustifyType justify_items_;
  GridAutoFlowType grid_auto_flow_;

  // grid item
  int32_t grid_row_span_;
  int32_t grid_column_span_;
  int32_t grid_column_end_;
  int32_t grid_column_start_;
  int32_t grid_row_end_;
  int32_t grid_row_start_;
  JustifyType justify_self_;
};

}  // namespace starlight
}  // namespace lynx

#endif  // LYNX_STARLIGHT_STYLE_GRID_DATA_H_
