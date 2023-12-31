#ifndef avatar_base_model_h
#define avatar_base_model_h

#include "image_processing.h"

NAMESPACE_OPEN(smash)
NAMESPACE_OPEN(avatar_utils)

class AvatarBaseModel {
public:
  AvatarBaseModel() {
    m_backbone=nullptr;
  }

  virtual ~AvatarBaseModel() {
    if (m_backbone != nullptr) {
      delete m_backbone;
    }
  }

  int LoadModelFromBuf(const uint8_t *param_buf, int param_buf_len);

  int _LoadModelFromBuf(const uint8_t *param_buf,
                        int param_buf_len,
                        std::vector<std::string> &layerOutNames,
                        const std::string netName,
                        espresso::Thrustor **net);

  int CheckIsLoaded();

  espresso::Thrustor *m_backbone;
  smash::utils::Rotator rotator_;
  std::string m_authCode;
  std::string m_modelName;
  std::vector<std::string> m_layerOutNames;
  bool m_isLoaded = false;
};

class LRClassifier: public AvatarBaseModel {
public:
  LRClassifier()  {
    m_authCode = "aW2P5rFogqVXy5TFAr9e848QughlhXMnBhj7DItjPLFz3RCK";
    m_layerOutNames =  {"1478"};
    m_modelName = "net0";
  }

  int GetLeftProb(const mobilecv2::Mat &inputImage,
                  const smash::InputParameter &param,
                  const mobilecv2::Rect &bbox,
                  bool do_expand_box,
                  float &left_prob,
                  bool need_flip,
                  bool to_bgr);
  
  void ReCalcLRProb(float &left_prob0, float &left_prob1);
};

NAMESPACE_CLOSE(avatar_utils)
NAMESPACE_CLOSE(smash)

#endif /* avatar_base_model_h */
