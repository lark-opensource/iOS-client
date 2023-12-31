/*
 * SDK for Door-Opening Trigger
 */
#ifndef SMASH_CAR_DOOR_TRIGGER_H_
#define SMASH_CAR_DOOR_TRIGGER_H_

#include "tt_common.h"
#if defined __cplusplus
extern "C" {
#endif

typedef void* CarDoorHandle;

enum CarDoorParamType {
  TRIGGER_THRESHOLD = 1,
};

/*
 * Status of trigger
 */
enum CarDoorStatus {
  CarDoor_INACTIVE = 0,   // no door-opening is detected
  CarDoor_ACTIVATED = 1,  // detected door-opening
  CarDoor_UNKNOWN = 255,  // cannot figure out
};

/*
 * API parameter
 */
struct CarDoorArgs {
  const unsigned char* image;    // pointer to image data
  PixelFormatType pixel_format;  // image format
  int image_width;               // image width
  int image_height;              // image height
  int image_stride;              // image stride
};

/*
 * API return value
 */
struct CarDoorRet {
  CarDoorStatus status;  // status
  AIPoint pot;  // trigger position, only valid when status == CarDoor_ACTIVATED

  CarDoorRet();
};

/*
 * Create handle
 */
AILAB_EXPORT
int CarDoor_CreateHandle(CarDoorHandle* handle);

/*
 * Init model from file
 */
AILAB_EXPORT
int CarDoor_InitModel(CarDoorHandle handle, const char* model_path);

/*
 * Init model from buffer
 */
AILAB_EXPORT
int CarDoor_InitModelFromBuf(CarDoorHandle handle,
                             const char* model_buff,
                             int model_size);

/*
 * Set parameter by name
 */
AILAB_EXPORT int CarDoor_SetParam(CarDoorHandle handle,
                                  CarDoorParamType ptype,
                                  float value);

/*
 * Detect door-opening events
 * @params
 * handle : must call InitModel before doing detection
 * args : argument
 * ret : must not be a nullptr
 */
AILAB_EXPORT int CarDoor_Detect(CarDoorHandle handle,
                                CarDoorArgs* args,
                                CarDoorRet* ret);

/*
 * Release handle
 */
AILAB_EXPORT int CarDoor_ReleaseHandle(CarDoorHandle handle);
#if defined __cplusplus
};
#endif

#endif  // SMASH_DOOR_TRIGGER_H_
