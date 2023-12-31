// Copyright 2021 The Lynx Authors. All rights reserved.

#include "starlight/layout/grid_layout_algorithm.h"

#include <algorithm>

#include "starlight/layout/layout_object.h"
#include "starlight/layout/property_resolving_utils.h"

namespace lynx {
namespace starlight {
using namespace logic_direction_utils;  // NOLINT

GridLayoutAlgorithm::GridLayoutAlgorithm(LayoutObject* container)
    : LayoutAlgorithm(container) {}

void GridLayoutAlgorithm::InitializeAlgorithmEnv() {
  main_gap_size_ = CalculateFloatSizeFromLength(GapStyle(MainAxis()),
                                                PercentBase(MainAxis()));
  cross_gap_size_ = CalculateFloatSizeFromLength(GapStyle(CrossAxis()),
                                                 PercentBase(CrossAxis()));

  const auto& auto_flow = container_style_->GetGridAutoFlow();
  is_dense_ = auto_flow == GridAutoFlowType::kDense ||
              auto_flow == GridAutoFlowType::kRowDense ||
              auto_flow == GridAutoFlowType::kColumnDense;
}

void GridLayoutAlgorithm::Reset() {
  main_gap_size_ = CalculateFloatSizeFromLength(GapStyle(MainAxis()),
                                                PercentBase(MainAxis()));
  cross_gap_size_ = CalculateFloatSizeFromLength(GapStyle(CrossAxis()),
                                                 PercentBase(CrossAxis()));
  main_axis_start_ = 0;
  cross_axis_start_ = 0;
  main_axis_interval_ = 0;
  cross_axis_interval_ = 0;

  grid_row_tracks_.clear();
  grid_column_tracks_.clear();
  grid_row_track_prefixes_.clear();
  grid_column_track_prefixes_.clear();
}

void GridLayoutAlgorithm::AlignInFlowItems() {
  for (const auto& item_info : grid_item_infos_) {
    LayoutObject* item = item_info.Item();
    float main_axis_offset =
        GridTrackSize(MainAxis(), 1, item_info.StartLine(MainAxis()));
    float cross_axis_offset =
        GridTrackSize(CrossAxis(), 1, item_info.StartLine(CrossAxis()));

    // if not first track.add a gap
    if (item_info.StartLine(MainAxis()) != kGridLineStart) {
      main_axis_offset += GridGapSize(MainAxis());
    }
    if (item_info.StartLine(CrossAxis()) != kGridLineStart) {
      cross_axis_offset += GridGapSize(CrossAxis());
    }

    // axis offset + justify offset + item offset.
    float offset_main =
        main_axis_offset + main_axis_start_ + MainAxisAlignment(item_info);
    float offset_cross =
        cross_axis_offset + cross_axis_start_ + CrossAxisAlignment(item_info);

    SetBoundOffsetFrom(item, MainFront(), BoundType::kMargin,
                       BoundType::kContent, offset_main);
    SetBoundOffsetFrom(item, CrossFront(), BoundType::kMargin,
                       BoundType::kContent, offset_cross);
  }
}

float GridLayoutAlgorithm::MainAxisAlignment(const GridItemInfo& item_info) {
  const ComputedCSSStyle* item_style = item_info.Item()->GetCSSStyle();
  JustifyType justify_type = item_style->GetJustifySelfType();
  if (justify_type == JustifyType::kAuto) {
    justify_type = container_style_->GetJustifyItemsType();
  }

  // track size - (margin + border box).
  float track_size = GridTrackSize(MainAxis(), item_info.StartLine(MainAxis()),
                                   item_info.EndLine(MainAxis()));
  float available_space =
      track_size - GetMarginBoundDimensionSize(item_info.Item(), MainAxis());
  float item_offset_main = 0.f;
  switch (justify_type) {
    case JustifyType::kAuto:
    case JustifyType::kStretch:
    case JustifyType::kStart:
      break;
    case JustifyType::kCenter: {
      item_offset_main = available_space / 2;
      break;
    }
    case JustifyType::kEnd: {
      item_offset_main = available_space;
      break;
    }
  }

  return item_offset_main;
}

float GridLayoutAlgorithm::CrossAxisAlignment(const GridItemInfo& item_info) {
  const ComputedCSSStyle* item_style = item_info.Item()->GetCSSStyle();
  FlexAlignType align_type = item_style->GetAlignSelf();
  if (align_type == FlexAlignType::kAuto) {
    align_type = container_style_->GetAlignItems();
  }

  float track_size =
      GridTrackSize(CrossAxis(), item_info.StartLine(CrossAxis()),
                    item_info.EndLine(CrossAxis()));
  float available_space =
      track_size - GetMarginBoundDimensionSize(item_info.Item(), CrossAxis());
  float item_offset_cross = 0.f;
  switch (align_type) {
    case FlexAlignType::kFlexStart:
    case FlexAlignType::kStretch:
    case FlexAlignType::kAuto:
    case FlexAlignType::kBaseline:
      // do nothing
      break;
    case FlexAlignType::kCenter: {
      item_offset_cross = available_space / 2;
      break;
    }
    case FlexAlignType::kFlexEnd: {
      item_offset_cross = available_space;
      break;
    }
  }

  return item_offset_cross;
}

BoxPositions GridLayoutAlgorithm::GetAbsoluteOrFixedItemInitialPosition(
    LayoutObject* absolute_or_fixed_item) {
  return BoxPositions{Position::kStart, Position::kStart};
}

void GridLayoutAlgorithm::SizeDeterminationByAlgorithm() {
  if (!has_placement_) {
    // Layout implicit axis
    PlacementGridItems();
    has_placement_ = true;
  }

  // grid item sizing
  GridItemSizing();

  // layout item
  MeasureGridItems();
}

void GridLayoutAlgorithm::PlacementGridItems() {
  PlaceItemCache place_items_cache;
  place_items_cache.reserve(inflow_items_.size());

  // 1.Generate anonymous grid items
  // 2.Position anything that's not auto-positioned.
  PrePlacementGridItems(place_items_cache);
  // 3.Process the items locked to a given cross.
  PlacementLockedCrossGridItems(place_items_cache);
  // 4.Determine the main axis in the implicit grid. Done!!
  // 5.Position the remaining grid items.
  PlacementCursor cursor;
  for (GridItemInfo& item_info : grid_item_infos_) {
    if (item_info.IsBothAxisAuto()) {
      PlacementAutoGridItems(item_info, cursor, place_items_cache);
    } else if (item_info.IsAxisAuto(CrossAxis())) {
      PlacementLockedMainGridItems(item_info, cursor, place_items_cache);
    }
  }
  // Placement grid items has finish.Determine cross axis size.Done !!
}

void GridLayoutAlgorithm::PrePlacementGridItems(PlaceItemCache& place_item) {
  grid_item_infos_.reserve(inflow_items_.size());

  // track end line = track_size + 1.
  int32_t explicit_column_end =
      static_cast<int32_t>(container_style_->GetGridTemplateColumns().size()) +
      1;
  int32_t explicit_row_end =
      static_cast<int32_t>(container_style_->GetGridTemplateRows().size()) + 1;

  int32_t min_row_axis = kGridLineStart;
  int32_t min_column_axis = kGridLineStart;

  const auto& ResolveMinAxis = [](Dimension dimension,
                                  const ComputedCSSStyle* style,
                                  int32_t explicit_end, int32_t& min_axis) {
    int32_t start = dimension == kHorizontal ? style->GetGridColumnStart()
                                             : style->GetGridRowStart();
    int32_t end = dimension == kHorizontal ? style->GetGridColumnEnd()
                                           : style->GetGridRowEnd();
    int32_t span = dimension == kHorizontal ? style->GetGridColumnSpan()
                                            : style->GetGridRowSpan();

    // If a negative integer is given, it instead counts in reverse,
    // starting from the end edge of the explicit grid.
    if (start < 0) {
      start += explicit_end + 1;
      min_axis = std::min(min_axis, start);
    }
    if (end < 0) {
      end += explicit_end + 1;
      min_axis = std::min(min_axis, end - span);
    }
    if (start == kGridLineUnDefine && end > 0) {
      min_axis = std::min(min_axis, end - span);
    }
  };

  // base line.
  for (const auto& inflow_item : inflow_items_) {
    const auto* child_style = inflow_item->GetCSSStyle();
    ResolveMinAxis(kVertical, child_style, explicit_row_end, min_row_axis);
    ResolveMinAxis(kHorizontal, child_style, explicit_column_end,
                   min_column_axis);
  }

  // Move base line.Make the axis start by 1.
  row_offset_ = kGridLineStart - min_row_axis;
  column_offset_ = kGridLineStart - min_column_axis;

  for (const auto& inflow_item : inflow_items_) {
    GridItemInfo item_info(inflow_item);

    item_info.InitSpanInfo(kVertical, explicit_row_end, row_offset_);
    item_info.InitSpanInfo(kHorizontal, explicit_column_end, column_offset_);

    grid_item_infos_.emplace_back(item_info);
  }

  main_track_count_ =
      static_cast<int32_t>(TemplateTracksStyle(MainAxis()).size());
  cross_track_count_ =
      static_cast<int32_t>(TemplateTracksStyle(CrossAxis()).size());
  for (auto& item_info : grid_item_infos_) {
    main_track_count_ =
        std::max(main_track_count_, item_info.EndLine(MainAxis()) - 1);
    main_track_count_ =
        std::max(main_track_count_, item_info.SpanSize(MainAxis()));
    cross_track_count_ =
        std::max(cross_track_count_, item_info.EndLine(CrossAxis()) - 1);
    cross_track_count_ =
        std::max(cross_track_count_, item_info.SpanSize(CrossAxis()));

    if (item_info.IsNoneAxisAuto()) {
      place_item.emplace_back(&item_info);
    }
  }
}

int32_t GridLayoutAlgorithm::FindNextAvailablePosition(
    Dimension locked_dimension, int32_t locked_start, int32_t locked_span,
    int32_t not_locked_start, int32_t not_locked_span,
    int32_t not_locked_max_size, const PlaceItemCache& place_item) {
  Dimension not_locked_dimension =
      locked_dimension == MainAxis() ? CrossAxis() : MainAxis();
  std::vector<int> line_mark(not_locked_max_size + 1, 0);
  // If item intersects the expected value matrix().
  // Record the start/end position of the array at the corresponding position.
  // By the array, we can know which positions are available.
  for (const auto item_cache : place_item) {
    const auto& item_info = *item_cache;
    if (!item_info.IsNoneAxisAuto()) {
      continue;
    }

    if (item_info.StartLine(locked_dimension) >= locked_start + locked_span ||
        item_info.EndLine(locked_dimension) <= locked_start) {
      continue;
    }

    if (item_info.EndLine(not_locked_dimension) <= not_locked_start) {
      continue;
    }

    line_mark[item_info.StartLine(not_locked_dimension)] += 1;
    line_mark[item_info.EndLine(not_locked_dimension)] -= 1;
  }

  int current_item_count = 0;
  for (int i = 1; i <= not_locked_start; ++i) {
    current_item_count += line_mark[i];
  }
  int current_available_size = 0;
  for (int i = not_locked_start + 1; i <= not_locked_max_size; ++i) {
    // No other item.
    if (!current_item_count) {
      ++current_available_size;
      if (current_available_size == not_locked_span) {
        return i - current_available_size;
      }
    } else {
      current_available_size = 0;
    }

    current_item_count += line_mark[i];
  }

  return kGridLineUnDefine;
}

void GridLayoutAlgorithm::PlacementLockedCrossGridItems(
    PlaceItemCache& place_item) {
  std::vector<int32_t> place_cache(cross_track_count_ + 1, kGridLineStart);

  for (GridItemInfo& item_info : grid_item_infos_) {
    if (!item_info.IsAxisAuto(MainAxis()) || item_info.IsBothAxisAuto()) {
      continue;
    }

    int32_t start_main = kGridLineStart;
    if (!IsDense() &&
        place_cache[item_info.StartLine(CrossAxis())] != kGridLineStart) {
      start_main = place_cache[item_info.StartLine(CrossAxis())];
    }

    int32_t main_span = item_info.SpanSize(MainAxis());

    start_main = FindNextAvailablePosition(
        CrossAxis(), item_info.StartLine(CrossAxis()),
        item_info.EndLine(CrossAxis()), start_main, main_span,
        main_track_count_ + 1 + main_span, place_item);

    if (!IsDense()) {
      place_cache[item_info.StartLine(CrossAxis())] = start_main + main_span;
    }
    item_info.SetSpanPosition(MainAxis(), start_main, start_main + main_span);
    main_track_count_ =
        std::max(main_track_count_, item_info.EndLine(MainAxis()) - 1);
    place_item.emplace_back(&item_info);
  }
}

void GridLayoutAlgorithm::PlacementLockedMainGridItems(
    GridItemInfo& item_info, PlacementCursor& cursor,
    PlaceItemCache& place_item) {
  if (IsDense()) {
    cursor.cross_line = kGridLineStart;
  } else if (cursor.main_line > item_info.StartLine(MainAxis())) {
    ++cursor.cross_line;
  }

  int32_t cross_span = item_info.SpanSize(CrossAxis());
  int32_t start_cross = cursor.cross_line;

  start_cross = FindNextAvailablePosition(
      MainAxis(), item_info.StartLine(MainAxis()),
      item_info.SpanSize(MainAxis()), start_cross, cross_span,
      cross_track_count_ + 1 + cross_span, place_item);

  item_info.SetSpanPosition(CrossAxis(), start_cross, start_cross + cross_span);
  cursor.cross_line = start_cross;
  cursor.main_line = item_info.StartLine(MainAxis());
  cross_track_count_ =
      std::max(cross_track_count_, item_info.EndLine(CrossAxis()) - 1);
  place_item.emplace_back(&item_info);
}

void GridLayoutAlgorithm::PlacementAutoGridItems(GridItemInfo& item_info,
                                                 PlacementCursor& cursor,
                                                 PlaceItemCache& place_item) {
  if (IsDense()) {
    cursor.main_line = kGridLineStart;
    cursor.cross_line = kGridLineStart;
  }

  int32_t start_main = cursor.main_line;
  int32_t start_cross = cursor.cross_line;
  int32_t main_span = item_info.SpanSize(MainAxis());
  int32_t cross_span = item_info.SpanSize(CrossAxis());

  // main_axis_count_ + 1 == axis_end.
  while ((start_main = FindNextAvailablePosition(
              CrossAxis(), start_cross, cross_span, start_main, main_span,
              main_track_count_ + 1, place_item)) == kGridLineUnDefine) {
    ++start_cross;
    start_main = kGridLineStart;
  }

  item_info.SetSpanPosition(MainAxis(), start_main, start_main + main_span);
  item_info.SetSpanPosition(CrossAxis(), start_cross, start_cross + cross_span);
  cursor.main_line = start_main;
  cursor.cross_line = start_cross;

  cross_track_count_ =
      std::max(cross_track_count_, item_info.EndLine(CrossAxis()) - 1);
  place_item.emplace_back(&item_info);
}

void GridLayoutAlgorithm::GridItemSizing() {
  InitTrackSize(MainAxis());
  InitTrackSize(CrossAxis());

  MeasureItemCache size_infos;
  // measure for max-content size
  for (auto& item_info : grid_item_infos_) {
    auto* child = item_info.Item();
    auto child_constraints =
        property_utils::GenerateDefaultConstraints(*child, Constraints());
    FloatSize layout_size = child->UpdateMeasure(child_constraints, false);

    child->GetBoxInfo()->UpdateBoxData(Constraints(), *child,
                                       child->GetLayoutConfigs());
    size_infos.emplace_back(ItemInfoEntry{&item_info, layout_size});
  }

  const auto& ResolveTrackGridSize = [this, &size_infos](Dimension dimension) {
    std::vector<float> base_size;
    // apply track list size to base size
    InitBaseSize(dimension, base_size);
    ResolveIntrinsicTrackSizes(dimension, size_infos, base_size);
    ApplyBaseSizeToTrackSizes(dimension, base_size);
    for (auto& item_info : grid_item_infos_) {
      float container_size =
          GridTrackSize(dimension, item_info.StartLine(dimension),
                        item_info.EndLine(dimension));
      item_info.SetContainerConstraints(
          dimension, OneSideConstraint::Definite(container_size));
      // 1. Resolve percentage margin
      // 2. Resolve box data.
      LayoutObject* child = item_info.Item();
      child->GetBoxInfo()->UpdateBoxData(item_info.ContainerConstraints(),
                                         *child, child->GetLayoutConfigs());
    }
  };

  // 1. resolve grid kHorizontal. Resolve percentage margin.
  // 2. resolve grid kVertical.
  ResolveTrackGridSize(kHorizontal);
  ResolveTrackGridSize(kVertical);
}

// Init track size by track list and auto track list.
void GridLayoutAlgorithm::InitTrackSize(Dimension dimension) {
  const auto& tracks_style = TemplateTracksStyle(dimension);
  const auto& auto_tracks_style = AutoTracksStyle(dimension);
  auto& grid_tracks = GridTracks(dimension);

  size_t auto_tracks_size = auto_tracks_style.size();
  int32_t axis_offset = dimension == kHorizontal ? column_offset_ : row_offset_;
  // make sure axis_offset % auto_tracks_size == auto_tracks_size - 1;
  int32_t fill_size = static_cast<int32_t>(auto_tracks_size) - 1 -
                      (axis_offset % auto_tracks_size);
  // apply template auto tracks of negative axis.
  for (int32_t idx = kGridLineStart; idx <= axis_offset; ++idx) {
    if (auto_tracks_size) {
      size_t auto_track_idx = (idx + fill_size) % auto_tracks_size;
      grid_tracks.emplace_back(NLengthToLayoutUnit(
          auto_tracks_style[auto_track_idx], PercentBase(dimension)));
    } else {
      grid_tracks.emplace_back(LayoutUnit::Indefinite());
    }
  }

  // apply template track.
  size_t axis_count = GridTrackCount(dimension);
  for (const auto& track : tracks_style) {
    grid_tracks.emplace_back(
        NLengthToLayoutUnit(track, PercentBase(dimension)));
  }

  // apply template auto tracks of Positive axis.
  size_t template_tracks_size = tracks_style.size();
  size_t last_track_count = template_tracks_size + axis_offset;
  for (size_t idx = last_track_count; idx < axis_count; ++idx) {
    if (auto_tracks_size) {
      size_t auto_track_idx = (idx - last_track_count) % auto_tracks_size;
      grid_tracks.emplace_back(NLengthToLayoutUnit(
          auto_tracks_style[auto_track_idx], PercentBase(dimension)));
    } else {
      grid_tracks.emplace_back(LayoutUnit::Indefinite());
    }
  }
}

void GridLayoutAlgorithm::InitBaseSize(Dimension dimension,
                                       std::vector<float>& base_size) {
  const auto& grid_tracks = GridTracks(dimension);
  const size_t tracks_size = grid_tracks.size();

  base_size.resize(tracks_size);
  for (size_t idx = 0; idx < tracks_size; ++idx) {
    if (grid_tracks[idx].IsDefinite()) {
      base_size[idx] = grid_tracks[idx].ToFloat();
    }
  }
}

void GridLayoutAlgorithm::ResolveIntrinsicTrackSizes(
    Dimension dimension, MeasureItemCache& item_size_infos,
    std::vector<float>& base_size) {
  const auto& grid_tracks = GridTracks(dimension);
  // sort by span
  std::sort(item_size_infos.begin(), item_size_infos.end(),
            [dis = dimension](const ItemInfoEntry& a, const ItemInfoEntry& b) {
              return a.SpanSize(dis) < b.SpanSize(dis);
            });

  // resolve tracks auto size
  for (const auto& item_size : item_size_infos) {
    const GridItemInfo& item_info = *item_size.item_info;
    if (!item_info.SpanSize(dimension)) {
      continue;
    }

    const auto* child = item_info.Item();
    size_t start_line = item_info.StartLine(dimension);
    size_t end_line = item_info.EndLine(dimension);

    size_t updated_track_count = 0;
    size_t track_zero_count = 0;
    float container_size_sum = .0f;
    for (size_t idx = start_line; idx < end_line; ++idx) {
      if (grid_tracks[idx - 1].IsIndefinite()) {
        if (base_size[idx - 1]) {
          ++updated_track_count;
        } else {
          ++track_zero_count;
        }
      }
      container_size_sum += base_size[idx - 1];
    }

    float item_box_sizing = item_size.LayoutSize(dimension);
    float item_side_size =
        dimension == kHorizontal
            ? child->GetOuterWidthFromBorderBoxWidth(item_box_sizing)
            : child->GetOuterHeightFromBorderBoxHeight(item_box_sizing);
    if (container_size_sum >= item_side_size) {
      continue;
    }

    float request_size = item_side_size - container_size_sum;
    float average_size = 0.f;
    if (track_zero_count) {
      average_size = request_size / track_zero_count;
    } else if (updated_track_count) {
      average_size = request_size / updated_track_count;
    }

    for (size_t idx = start_line; idx < end_line; ++idx) {
      if (grid_tracks[idx - 1].IsIndefinite() &&
          (!track_zero_count || !base_size[idx - 1])) {
        base_size[idx - 1] += average_size;
      }
    }
  }
}

void GridLayoutAlgorithm::ApplyBaseSizeToTrackSizes(
    Dimension dimension, std::vector<float>& base_size) {
  auto& grid_tracks = GridTracks(dimension);

  if (!base_size.size()) {
    return;
  }

  float total_track_sum = 0;
  size_t update_track_count = 0;
  for (size_t idx = 0; idx < base_size.size(); ++idx) {
    if (grid_tracks[idx].IsIndefinite()) {
      ++update_track_count;
    }
    total_track_sum += base_size[idx];
  }
  int32_t track_count = GridTrackCount(dimension);
  total_track_sum += GridGapSize(dimension) * (track_count - 1);

  UpdateContainerSize(dimension, total_track_sum);

  float available_space =
      container_constraints_[dimension].Size() - total_track_sum;

  if (base::FloatsLarger(available_space, 0)) {
    bool is_stretch = false;
    if (dimension == CrossAxis()) {
      AlignContentType align_content = container_style_->GetAlignContent();
      is_stretch = align_content == AlignContentType::kStretch;
      if (!is_stretch) {
        ResolveAlignContent(container_style_, track_count, available_space,
                            cross_axis_interval_, cross_axis_start_);
      }
    } else {
      JustifyContentType justify_content =
          container_style_->GetJustifyContent();
      is_stretch = justify_content == JustifyContentType::kStretch;
      if (!is_stretch) {
        ResolveJustifyContent(container_style_, track_count, available_space,
                              main_axis_interval_, main_axis_start_);
      }
    }

    if (is_stretch) {
      float average_size = available_space / update_track_count;
      for (size_t idx = 0; idx < base_size.size(); ++idx) {
        if (grid_tracks[idx].IsIndefinite()) {
          base_size[idx] += average_size;
        }
      }
    }
  }

  // apply base size to grid_track.
  for (size_t idx = 0; idx < base_size.size(); ++idx) {
    if (grid_tracks[idx].IsIndefinite()) {
      grid_tracks[idx] = LayoutUnit(base_size[idx]);
    }
  }

  // pre-calculate track align.
  float track_prefixes_size = grid_tracks.size() + 1;
  auto& track_prefixes = GridTracksPrefixes(dimension);
  track_prefixes.resize(track_prefixes_size);
  track_prefixes[0] = 0.0f;
  for (size_t idx = 1; idx < track_prefixes_size; ++idx) {
    track_prefixes[idx] =
        grid_tracks[idx - 1].ToFloat() + track_prefixes[idx - 1];
  }
}

void GridLayoutAlgorithm::UpdateContainerSize(Dimension dimension,
                                              float track_size_sum) {
  if (IsSLDefiniteMode(container_constraints_[dimension].Mode())) {
    return;
  }

  float border_and_padding_size =
      GetPaddingAndBorderDimensionSize(container_, dimension);
  // clamped by the used min and max cross sizes of the container.
  BoxInfo* box_info = container_->GetBoxInfo();
  float max_container_size =
      box_info->max_size_[dimension] - border_and_padding_size;
  float min_container_size =
      box_info->min_size_[dimension] - border_and_padding_size;

  track_size_sum = std::min(track_size_sum, max_container_size);
  track_size_sum = std::max(track_size_sum, min_container_size);
  track_size_sum = std::max(track_size_sum, 0.0f);

  if (IsSLAtMostMode(container_constraints_[dimension].Mode())) {
    track_size_sum =
        std::min(track_size_sum, container_constraints_[dimension].Size());
  }

  container_constraints_[dimension] =
      OneSideConstraint::Definite(track_size_sum);

  // resolve against the box’s content box when laying out the box’s contents.
  if (dimension == MainAxis()) {
    main_gap_size_ = CalculateFloatSizeFromLength(GapStyle(MainAxis()),
                                                  PercentBase(MainAxis()));
  } else {
    cross_gap_size_ = CalculateFloatSizeFromLength(GapStyle(CrossAxis()),
                                                   PercentBase(CrossAxis()));
  }
}

void GridLayoutAlgorithm::MeasureGridItems() {
  for (const GridItemInfo& item_info : grid_item_infos_) {
    auto* child = item_info.Item();
    auto* child_style = child->GetCSSStyle();

    const Constraints& container_constraints = item_info.ContainerConstraints();
    auto child_constraints = property_utils::GenerateDefaultConstraints(
        *child, container_constraints);

    if (IsSLAtMostMode(child_constraints[CrossAxis()].Mode()) &&
        ((child_style->GetAlignSelf() == FlexAlignType::kAuto &&
          container_style_->GetAlignItems() == FlexAlignType::kStretch) ||
         (child_style->GetAlignSelf() == FlexAlignType::kStretch))) {
      if (!GetMargin(child_style, CrossFront()).IsAuto() &&
          !GetMargin(child_style, CrossBack()).IsAuto()) {
        child_constraints[CrossAxis()] =
            OneSideConstraint::Definite(child_constraints[CrossAxis()].Size());
      }
    }

    if (IsSLAtMostMode(child_constraints[MainAxis()].Mode()) &&
        ((child_style->GetJustifySelfType() == JustifyType::kAuto &&
          container_style_->GetJustifyItemsType() == JustifyType::kStretch) ||
         (child_style->GetJustifySelfType() == JustifyType::kStretch))) {
      if (!GetMargin(child_style, MainFront()).IsAuto() &&
          !GetMargin(child_style, MainBack()).IsAuto()) {
        child_constraints[MainAxis()] =
            OneSideConstraint::Definite(child_constraints[MainAxis()].Size());
      }
    }

    child->UpdateMeasure(child_constraints, true);
    //  resolve margin auto
    ResolveAutoMargins(child, container_constraints[MainAxis()].Size(),
                       MainAxis());
    ResolveAutoMargins(child, container_constraints[CrossAxis()].Size(),
                       CrossAxis());
  }
}

float GridLayoutAlgorithm::CalculateFloatSizeFromLength(
    const NLength& length, const LayoutUnit& percent_base) {
  return NLengthToLayoutUnit(length, percent_base)
      .ClampIndefiniteToZero()
      .ToFloat();
}

const NLength& GridLayoutAlgorithm::GapStyle(Dimension dimension) const {
  return dimension == kHorizontal ? container_style_->GetGridColumnGap()
                                  : container_style_->GetGridRowGap();
}

float GridLayoutAlgorithm::GridTrackCount(Dimension dimension) const {
  return dimension == kMainAxis ? main_track_count_ : cross_track_count_;
}

float GridLayoutAlgorithm::GridGapSize(Dimension dimension) const {
  return dimension == kMainAxis ? main_gap_size_ + main_axis_interval_
                                : cross_gap_size_ + cross_axis_interval_;
}

std::vector<LayoutUnit>& GridLayoutAlgorithm::GridTracks(Dimension dimension) {
  return dimension == kHorizontal ? grid_column_tracks_ : grid_row_tracks_;
}

const std::vector<NLength>& GridLayoutAlgorithm::AutoTracksStyle(
    Dimension dimension) const {
  return dimension == kHorizontal ? container_style_->GetGridAutoColumns()
                                  : container_style_->GetGridAutoRows();
}

const std::vector<NLength>& GridLayoutAlgorithm::TemplateTracksStyle(
    Dimension dimension) const {
  return dimension == kHorizontal ? container_style_->GetGridTemplateColumns()
                                  : container_style_->GetGridTemplateRows();
}

std::vector<float>& GridLayoutAlgorithm::GridTracksPrefixes(
    Dimension dimension) {
  return dimension == kHorizontal ? grid_column_track_prefixes_
                                  : grid_row_track_prefixes_;
}

// parm: start: grid axis line.start with 1.
// parm: end:grid axis line.start with 1.
float GridLayoutAlgorithm::GridTrackSize(Dimension dimension, int32_t start,
                                         int32_t end) {
  // 0: 0 size.==>(start=0,end=1)
  // 1: track1 + 0.==>(start=0,end=2)
  // 1 - 0: track1.==>(start=1,end=2)
  const auto& track_prefixes = GridTracksPrefixes(dimension);
  if (start >= end || start < 1) {
    return 0;
  }
  float track_size = (track_prefixes[end - 1] - track_prefixes[start - 1]);
  float gap_size = (GridGapSize(dimension) * (end - start - 1));

  return track_size + gap_size;
}

}  // namespace starlight
}  // namespace lynx
