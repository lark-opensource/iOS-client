// Copyright 2021 The Lynx Authors. All rights reserved.

#ifndef LYNX_STARLIGHT_LAYOUT_GRID_LAYOUT_ALGORITHM_H_
#define LYNX_STARLIGHT_LAYOUT_GRID_LAYOUT_ALGORITHM_H_

#include <vector>

#include "starlight/layout/grid_item_info.h"
#include "starlight/layout/layout_algorithm.h"

namespace lynx {
namespace starlight {

class LayoutObject;
class GridLayoutAlgorithm : public LayoutAlgorithm {
 public:
  explicit GridLayoutAlgorithm(LayoutObject*);

  void InitializeAlgorithmEnv() override;
  void Reset() override;
  void AlignInFlowItems() override;
  BoxPositions GetAbsoluteOrFixedItemInitialPosition(
      LayoutObject* item) override;
  void SizeDeterminationByAlgorithm() override;
  void SetContainerBaseline() override{};

 private:
  struct PlacementCursor {
    int32_t main_line = kGridLineStart;
    int32_t cross_line = kGridLineStart;
  };

  using PlaceItemCache = std::vector<GridItemInfo*>;
  using MeasureItemCache = std::vector<ItemInfoEntry>;

  void PlacementGridItems();
  void PrePlacementGridItems(PlaceItemCache& place_item);
  // resolve items locked to main axis
  void PlacementLockedCrossGridItems(PlaceItemCache& place_item);
  // resolve items locked to cross axis
  void PlacementLockedMainGridItems(GridItemInfo& grid_info,
                                    PlacementCursor& cursor,
                                    PlaceItemCache& place_item);
  // resolve auto grid item.
  void PlacementAutoGridItems(GridItemInfo& grid_info, PlacementCursor& cursor,
                              PlaceItemCache& place_item);
  int32_t FindNextAvailablePosition(Dimension locked_dimension,
                                    int32_t locked_start, int32_t locked_span,
                                    int32_t not_locked_start,
                                    int32_t not_locked_span,
                                    int32_t not_locked_max_size,
                                    const PlaceItemCache& place_item);

  // measure track size.
  void GridItemSizing();
  void InitTrackSize(Dimension dimension);
  void InitBaseSize(Dimension dimension, std::vector<float>& base_size);
  void ResolveIntrinsicTrackSizes(Dimension dimension,
                                  MeasureItemCache& item_size_infos,
                                  std::vector<float>& base_size);
  void ApplyBaseSizeToTrackSizes(Dimension dimension,
                                 std::vector<float>& base_size);

  // update container size
  void UpdateContainerSize(Dimension dimension, float track_size_sum);
  // measure grid with track size.
  void MeasureGridItems();

  // alignment
  float MainAxisAlignment(const GridItemInfo& item_info);
  float CrossAxisAlignment(const GridItemInfo& item_info);
  Position GetAbsoluteOrFixedItemMainAxisPosition(
      LayoutObject* absolute_or_fixed_item);
  Position GetAbsoluteOrFixedItemCrossAxisPosition(
      LayoutObject* absolute_or_fixed_item);

  float CalculateFloatSizeFromLength(const NLength& length,
                                     const LayoutUnit& percent_base);
  bool IsDense() { return is_dense_; }
  std::vector<LayoutUnit>& GridTracks(Dimension dimension);
  float GridTrackCount(Dimension dimension) const;
  float GridGapSize(Dimension dimension) const;
  const std::vector<NLength>& TemplateTracksStyle(Dimension dimension) const;
  const std::vector<NLength>& AutoTracksStyle(Dimension dimension) const;
  // Valid after ApplyBaseSizeToTrackSizes finish.
  float GridTrackSize(Dimension dimension, int32_t start, int32_t end);
  // Valid after ApplyBaseSizeToTrackSizes finish.
  std::vector<float>& GridTracksPrefixes(Dimension dimension);
  const NLength& GapStyle(Dimension dimension) const;

  // auto flow
  bool is_dense_ = false;
  bool has_placement_ = false;

  // grid item position offset.
  int32_t row_offset_ = 0;
  int32_t column_offset_ = 0;

  // implicit axis count
  int32_t main_track_count_ = 0;
  int32_t cross_track_count_ = 0;

  // justify-content/align-content gap size.
  float main_axis_interval_ = 0;
  float cross_axis_interval_ = 0;
  // start gap for justify-content/align-content.
  float main_axis_start_ = 0;
  float cross_axis_start_ = 0;
  // implicit axis gap size
  float main_gap_size_ = 0;
  float cross_gap_size_ = 0;

  std::vector<GridItemInfo> grid_item_infos_;

  std::vector<LayoutUnit> grid_row_tracks_;
  std::vector<LayoutUnit> grid_column_tracks_;
  // Sum of prefixes grid track , it init after GridItemSizing() finish.
  std::vector<float> grid_row_track_prefixes_;
  std::vector<float> grid_column_track_prefixes_;
};

}  // namespace starlight
}  // namespace lynx
#endif  // LYNX_STARLIGHT_LAYOUT_GRID_LAYOUT_ALGORITHM_H_
