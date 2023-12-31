// Copyright 2021 The Lynx Authors. All rights reserved.
#include "starlight/style/grid_data.h"

#include "starlight/style/default_css_style.h"

namespace lynx {
namespace starlight {

GridData::GridData()
    : grid_template_columns_(DefaultCSSStyle::SL_DEFAULT_GRID_TRACK()),
      grid_template_rows_(DefaultCSSStyle::SL_DEFAULT_GRID_TRACK()),
      grid_auto_columns_(DefaultCSSStyle::SL_DEFAULT_GRID_AUTO_TRACK()),
      grid_auto_rows_(DefaultCSSStyle::SL_DEFAULT_GRID_AUTO_TRACK()),
      grid_column_gap_(DefaultCSSStyle::SL_DEFAULT_GRID_GAP()),
      grid_row_gap_(DefaultCSSStyle::SL_DEFAULT_GRID_GAP()),
      justify_items_(DefaultCSSStyle::SL_DEFAULT_JUSTIFY_ITEMS),
      grid_auto_flow_(DefaultCSSStyle::SL_DEFAULT_GRID_AUTO_FLOW),
      grid_row_span_(DefaultCSSStyle::SL_DEFAULT_GRID_SPAN),
      grid_column_span_(DefaultCSSStyle::SL_DEFAULT_GRID_SPAN),
      grid_column_end_(DefaultCSSStyle::SL_DEFAULT_GRID_ITEM_POSITION),
      grid_column_start_(DefaultCSSStyle::SL_DEFAULT_GRID_ITEM_POSITION),
      grid_row_end_(DefaultCSSStyle::SL_DEFAULT_GRID_ITEM_POSITION),
      grid_row_start_(DefaultCSSStyle::SL_DEFAULT_GRID_ITEM_POSITION),
      justify_self_(DefaultCSSStyle::SL_DEFAULT_JUSTIFY_SELF) {}

GridData::GridData(const GridData& data)
    : grid_template_columns_(data.grid_template_columns_),
      grid_template_rows_(data.grid_template_rows_),
      grid_auto_columns_(data.grid_auto_columns_),
      grid_auto_rows_(data.grid_auto_rows_),
      grid_column_gap_(data.grid_column_gap_),
      grid_row_gap_(data.grid_row_gap_),
      justify_items_(data.justify_items_),
      grid_auto_flow_(data.grid_auto_flow_),
      grid_row_span_(data.grid_row_span_),
      grid_column_span_(data.grid_column_span_),
      grid_column_end_(data.grid_column_end_),
      grid_column_start_(data.grid_column_start_),
      grid_row_end_(data.grid_row_end_),
      grid_row_start_(data.grid_row_start_),
      justify_self_(data.justify_self_) {}

void GridData::Reset() {
  grid_template_columns_ = DefaultCSSStyle::SL_DEFAULT_GRID_TRACK();
  grid_template_rows_ = DefaultCSSStyle::SL_DEFAULT_GRID_TRACK();
  grid_auto_columns_ = DefaultCSSStyle::SL_DEFAULT_GRID_AUTO_TRACK();
  grid_auto_rows_ = DefaultCSSStyle::SL_DEFAULT_GRID_AUTO_TRACK();
  grid_column_gap_ = DefaultCSSStyle::SL_DEFAULT_GRID_GAP();
  grid_row_gap_ = DefaultCSSStyle::SL_DEFAULT_GRID_GAP();
  justify_items_ = DefaultCSSStyle::SL_DEFAULT_JUSTIFY_ITEMS;
  grid_auto_flow_ = DefaultCSSStyle::SL_DEFAULT_GRID_AUTO_FLOW;
  grid_row_span_ = DefaultCSSStyle::SL_DEFAULT_GRID_SPAN;
  grid_column_span_ = DefaultCSSStyle::SL_DEFAULT_GRID_SPAN;
  grid_column_end_ = DefaultCSSStyle::SL_DEFAULT_GRID_ITEM_POSITION;
  grid_column_start_ = DefaultCSSStyle::SL_DEFAULT_GRID_ITEM_POSITION;
  grid_row_end_ = DefaultCSSStyle::SL_DEFAULT_GRID_ITEM_POSITION;
  grid_row_start_ = DefaultCSSStyle::SL_DEFAULT_GRID_ITEM_POSITION;
  justify_self_ = DefaultCSSStyle::SL_DEFAULT_JUSTIFY_SELF;
}

}  // namespace starlight
}  // namespace lynx
