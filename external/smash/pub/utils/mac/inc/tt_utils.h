#ifndef TT_UTILS_H_
#define TT_UTILS_H_

#include <string>
#include "internal_smash.h"
#include "tt_common.h"
#include "tt_log.h"


SMASH_NAMESPACE_OPEN

void ToChars(char* buf, ...);

int GetParameterData(const char* model_path, char** network_parameter);

void UpdateOrient(ScreenOrient& orient_need_update,
                  const ScreenOrient& curr_orient,
                  bool& need_change);

unsigned long GetCurrentMillis();

unsigned long GetCurrentMicros();

bool checkModuleBaseArgsValid(const unsigned char* image,PixelFormatType pixel_fmt,int image_width,int image_height,int image_stride,ScreenOrient orient);

int ReadFileToBuf(const char *filePath, uint8_t **buf, int &buf_len);
int CvtOutputAsUint8(float* output_data, uint8_t* imageData, int size, float avg);
int CvtInputAsFloat(uint8_t* imageData, float* input_data, int inSize, float avg);
void ConvertInt8ToUint8(const int8_t *inData, uint8_t *outData, int len, int fl);
void ConvertInt16ToUint8(const int16_t *inData, uint8_t *outData, int len, int fl);
NAMESPACE_OPEN(time)

class TimeMaster {
 public:
  explicit TimeMaster() {}

  explicit TimeMaster(std::string& tag, int print_every)
      : tag_(tag), print_every_(print_every), count_(0), elapsed_(0) {}

  void Setting(std::string tag, int print_every) {
    tag_ = tag;
    print_every_ = print_every;
  }

  void Reset() {
    count_ = 0;
    elapsed_ = 0;
  }

  void TickAndDisplay(double elapsed) {
    elapsed_ += elapsed;
    count_ += 1;
    if (count_ == print_every_) {
      LOGD("module:%s, time elapsed:%.4lf in every %d times", tag_.c_str(),
           elapsed_ / count_, count_);
      count_ = 0;
      elapsed_ = 0;
    }
  }

 private:
  std::string tag_;
  int print_every_;
  int count_;
  double elapsed_;
};

NAMESPACE_CLOSE(time)

SMASH_NAMESPACE_CLOSE

#endif  // NET_DECODE_H_
