#ifndef _SMASH_MODULES_AVATAR_DETECTOR_H_
#define _SMASH_MODULES_AVATAR_DETECTOR_H_

#include "internal_smash.h"
#include "smash_base.h"
#include "ssd_detector_pytorch.h"
#include "tt_common.h"

NAMESPACE_OPEN(smash)
NAMESPACE_OPEN(avatar_utils)

using namespace smash::private_utils::ssd;

class AvatarDetector : public DetectorTorch {
public:
  bool m_inited;
  bool m_isLoaded;

public:
  explicit AvatarDetector() : DetectorTorch() {
    m_inited = false;
    m_isLoaded = false;
  }

  int Init(float nms_thresh,
           float prob_thresh,
           int bit);

  int LoadModelFromBuf(const uint8_t *param_buf,
                        int param_buf_len,
                        int max_side,
                        const std::string &auth_code,
                        const std::string &model_name,
                        float nms_thresh,
                        float prob_thresh,
                        int bits);
};

NAMESPACE_CLOSE(avatar_utils)
NAMESPACE_CLOSE(smash)

#endif  // _SMASH_MODULES_AVATAR_DETECTOR_H_
