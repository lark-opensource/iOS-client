#ifndef __RFCNDETECTOR__
#define __RFCNDETECTOR__
#include <algorithm>
#include <cmath>
#include <functional>
#include <map>
#include <string>
#include <vector>

#include <mobilecv2/core.hpp>
#include "Blob.hpp"
#include "espresso.h"
using namespace std;

struct Box {
  float left;
  float right;
  float top;
  float bottom;
  Box(float x1, float x2, float y1, float y2) {
    left = x1;
    right = x2;
    top = y1;
    bottom = y2;
  }
  Box(const Box& box) {
    left = box.left;
    right = box.right;
    top = box.top;
    bottom = box.bottom;
  }
};

struct Anchor {
  int spatial_ratio_x;
  int spatial_ratio_y;
  float anchor_height;
  float anchor_width;
  Anchor(int v1, int v2, float v3, float v4)
      : spatial_ratio_x(v1),
        spatial_ratio_y(v2),
        anchor_height(v3),
        anchor_width(v4) {}
};

struct ROIPooling {
  int pooled_h;
  int pooled_w;
  float scale;
  ROIPooling(int v1, int v2, float v3)
      : pooled_h(v1), pooled_w(v2), scale(v3) {}
};

struct Regression {
  float spatial_ratio_x;
  float spatial_ratio_y;
  float spatial_ratio_w;
  float spatial_ratio_h;
  Regression(float v1, float v2, float v3, float v4)
      : spatial_ratio_x(v1),
        spatial_ratio_y(v2),
        spatial_ratio_w(v3),
        spatial_ratio_h(v4) {}
};

struct Proposal {
  int threshold;
  int number;
  float nms_threshold;
  Proposal(float v1, int v2, float v3)
      : threshold(v1), number(v2), nms_threshold(v3) {}
};

namespace smash {
class RfcnDetector {
 public:
  void sort_box(float list_cpu[],
                const int start,
                const int end,
                const int num_top);

  void first_filter(Blob* bottom,
                    Proposal& proposal,
                    vector<pair<int, pair<int, int> > >& top);

  void first_anchor(const vector<pair<int, pair<int, int> > >& bottom,
                    const Anchor& anchor,
                    int height,
                    int width,
                    vector<pair<int, Box> >& top);

  void nms(const vector<pair<int, Box> >& bottom,
           float threshold,
           vector<int>& top);

  void detect(const espresso::LayerOutput& input,
              const vector<espresso::LayerOutput>& first_blobs,
              const vector<espresso::LayerOutput>& second_blobs,
              vector<pair<int, Box> >& output);

  void first_score(const espresso::LayerOutput& bottom_blob,
                   ROIPooling& roipooling,
                   Blob* top_blob);

  void first_proposal(const espresso::LayerOutput& bottom,
                      const ROIPooling& roipooling,
                      const Regression& regression,
                      const vector<pair<int, pair<int, int> > >& score,
                      vector<pair<int, Box> >& top);

  void second_proposal(const espresso::LayerOutput& bottom,
                       const ROIPooling& roipooling,
                       const Regression& regression,
                       const Proposal& proposal,
                       vector<pair<int, Box> >& list_proposal,
                       vector<pair<int, Box> >& top);
};
}  // namespace smash
#endif
