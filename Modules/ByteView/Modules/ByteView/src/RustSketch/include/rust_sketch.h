#include <stdarg.h>
#include <stdbool.h>
#include <stdint.h>
#include <stdlib.h>

typedef enum ClearType {
  SELF = 1,
  OTHERS = 2,
  ALL = 3,
} ClearType;

typedef enum PencilType {
  SKETCH_PENCIL_TYPE_DEFAULT = 1,
  SKETCH_PENCIL_TYPE_MARKER = 2,
} PencilType;

typedef enum RemoveType {
  RemoveAll = 1,
  StoreByDeviceId = 2,
  RemoveByDeviceId = 3,
  RemoveByShapeId = 4,
} RemoveType;

typedef enum ShapeType {
  PENCIL = 1,
  RECTANGLE = 2,
  COMET = 3,
  OVAL = 4,
  ARROW = 5,
} ShapeType;

typedef enum UndoType {
  Remove = 1,
  Add = 2,
  Update = 3,
} UndoType;

typedef struct SketchLogInstance {
  void (*log)(const char *msg);
  void (*info)(const char *msg);
  void (*warn)(const char *msg);
  void (*error)(const char *msg);
  void (*monitor)(const char *obj);
} SketchLogInstance;

typedef struct UndoRedoInfo {
  bool undo_status;
  bool redo_status;
} UndoRedoInfo;

typedef struct ExtInfoFFI {
  const char *device_id;
  const char *user_id;
  uintptr_t user_type;
  uintptr_t current_step;
  struct UndoRedoInfo undo_redo_info;
  bool visible;
} ExtInfoFFI;

typedef struct PencilConfig {
  float min_distance;
  float k;
  float error_gap;
  uint64_t fitting_interval;
  uint64_t snippet_interval;
} PencilConfig;

typedef struct CometConfig {
  float weak_speed;
  float min_distance;
  bool enable_webgl;
  float reduce_times;
  uint64_t fitting_interval;
  uint64_t snippet_interval;
} CometConfig;

typedef struct GlobalShapeConfig {
  struct PencilConfig pencil_config;
  struct CometConfig comet_config;
} GlobalShapeConfig;

typedef struct PencilStyle {
  int64_t color;
  float size;
  enum PencilType pencil_type;
} PencilStyle;

typedef struct FFIArrayFloat2 {
  const float (*ptr)[2];
  uintptr_t len;
} FFIArrayFloat2;

typedef struct PencilDrawableData {
  const char *id;
  struct PencilStyle style;
  struct FFIArrayFloat2 points;
  int32_t duration;
  struct ExtInfoFFI ext_info;
  bool finish;
  int32_t dimension;
  bool pause;
  bool need_compatible;
  struct FFIArrayFloat2 compatible_points;
  int32_t compatible_dimension;
} PencilDrawableData;

typedef struct StrokePencilStyle {
  int64_t color;
  float min_distance;
  float k;
  float error_gap;
  float size;
  float max_size;
  float min_size;
  float max_speed_step;
} StrokePencilStyle;

typedef struct StrokePencilDrawableData {
  const char *id;
  struct FFIArrayFloat2 points;
  struct StrokePencilStyle style;
  enum PencilType pencil_type;
} StrokePencilDrawableData;

typedef struct RectangleStyle {
  int64_t color;
  float size;
} RectangleStyle;

typedef struct RectangleDrawableData {
  const char *id;
  const float *left_top;
  const float *right_bottom;
  struct RectangleStyle style;
  struct ExtInfoFFI ext_info;
} RectangleDrawableData;

typedef struct OvalStyle {
  int64_t color;
  float size;
} OvalStyle;

typedef struct OvalDrawableData {
  const char *id;
  const float *origin;
  float long_axis;
  float short_axis;
  struct OvalStyle style;
  struct ExtInfoFFI ext_info;
} OvalDrawableData;

typedef struct ArrowStyle {
  int64_t color;
  float size;
} ArrowStyle;

typedef struct ArrowDrawableData {
  const char *id;
  const float *origin;
  const float *end;
  struct ArrowStyle style;
  struct ExtInfoFFI ext_info;
} ArrowDrawableData;

typedef struct StoreDrawableData {
  const struct PencilDrawableData *pencil;
  uintptr_t pencil_len;
  const struct StrokePencilDrawableData *stroke_pencil;
  uintptr_t stroke_pencil_len;
  const struct RectangleDrawableData *rectangle;
  uintptr_t rectangle_len;
  const struct OvalDrawableData *oval;
  uintptr_t oval_len;
  const struct ArrowDrawableData *arrow;
  uintptr_t arrow_len;
  const enum ShapeType *order_list;
  uintptr_t order_list_len;
} StoreDrawableData;

typedef struct SketchByteviewUserFFI {
  const char *device_id;
  const char *user_id;
  uintptr_t user_type;
} SketchByteviewUserFFI;

typedef struct RemoveTransportData {
  enum RemoveType remove_type;
  const char *const *ids_ptr;
  uintptr_t ids_len;
  const struct SketchByteviewUserFFI *users_ptr;
  uintptr_t users_len;
  uintptr_t current_step;
} RemoveTransportData;

typedef struct ClearTransportData {
  struct StoreDrawableData store_data;
  struct RemoveTransportData transport_data;
  struct UndoRedoInfo undo_redo_info;
} ClearTransportData;

typedef struct CometStyle {
  int64_t color;
  float size;
  float opacity;
} CometStyle;

typedef struct FFIArrayFloat1 {
  const float *ptr;
  uintptr_t len;
} FFIArrayFloat1;

typedef struct CometDrawableData {
  const char *id;
  struct CometStyle style;
  struct FFIArrayFloat2 points;
  struct FFIArrayFloat1 radii;
  int32_t duration;
  struct ExtInfoFFI ext_info;
  bool pause;
  bool exit;
} CometDrawableData;

typedef struct CometDrawableData CometTransportData;

typedef struct CometExitDataFFI {
  const char *id;
  struct ExtInfoFFI ext_info;
} CometExitDataFFI;

typedef struct CombinedAllPencilDataFFI {
  struct PencilDrawableData transport_data;
} CombinedAllPencilDataFFI;

typedef struct PencilDrawableData PencilTransportData;

typedef struct PencilDrawableDataGroup {
  const struct PencilDrawableData *ptr;
  uintptr_t len;
} PencilDrawableDataGroup;

typedef struct UndoTransportData {
  struct RemoveTransportData remove_data;
  struct StoreDrawableData add_data;
  enum UndoType undo_type;
  bool should_fetch_history;
  struct UndoRedoInfo undo_redo_info;
} UndoTransportData;

typedef struct UndoTransportData RedoTransportData;

typedef struct ResumeFinishDataFFI {
  const char *const *missing_ids_ptr;
  uintptr_t missing_ids_len;
  bool still_should_fetch;
  struct UndoRedoInfo undo_redo_info;
} ResumeFinishDataFFI;

typedef struct RemoteAddDataFFI {
  struct StoreDrawableData add_data;
  const char *const *missing_ids_ptr;
  uintptr_t missing_ids_len;
  uintptr_t current_step;
} RemoteAddDataFFI;

typedef struct RemoteAddIdsFFI {
  const char *const *ids_ptr;
  uintptr_t ids_len;
} RemoteAddIdsFFI;

const char *sketch_create_instance(void);

void sketch_create_instance_drop(const char *s);

int32_t sketch_switch_instance(const char *id);

void init_sketch(const char *instance_id,
                 struct SketchLogInstance sketch_option,
                 struct ExtInfoFFI ext_info,
                 struct GlobalShapeConfig global_config);

struct StoreDrawableData get_all_drawable_data(const char *instance_id);

void get_all_drawable_data_drop(struct StoreDrawableData data);

int64_t get_sketch_default_color(const char *instance_id);

/**
 * 标记图像是否隐藏，如果设置成功返回0失败返回-1
 */
int64_t set_shape_visible(const char *instance_id, const char *shape_id, bool visible);

/**
 * 标记所以图像是否隐藏，如果设置成功返回0失败返回-1
 */
int64_t set_all_shape_visible(const char *instance_id, bool visible);

void sketch_destroy(const char *instance_id);

void set_current_step(const char *instance_id, uintptr_t current_step);

struct StoreDrawableData fetch_up_missing_data(const char *instance_id,
                                               struct StoreDrawableData data);

void fetch_up_missing_data_drop(struct StoreDrawableData data);

struct ArrowDrawableData arrow_finish(const char *instance_id,
                                      const float *origin,
                                      const float *end,
                                      struct ArrowStyle style);

void arrow_finish_drop(struct ArrowDrawableData drawable_data);

bool arrow_receive_remote_data(const char *instance_id, struct ArrowDrawableData drawable_data);

struct ClearTransportData clear(const char *instance_id, enum ClearType clear_type);

void clear_drop(struct ClearTransportData transport_data);

struct ClearTransportData sketch_clear_v2(const char *instance_id, enum ClearType clear_type);

void sketch_clear_v2_drop(struct ClearTransportData transport_data);

struct StoreDrawableData sketch_remove(const char *instance_id,
                                       struct RemoveTransportData remove_data);

void remove_drop(struct StoreDrawableData data);

struct StoreDrawableData sketch_remove_v2(const char *instance_id,
                                          struct RemoveTransportData remove_data);

void sketch_remove_v2_drop(struct StoreDrawableData data);

void eraser_receive_operation(const char *instance_id, struct RemoveTransportData data);

void clear_receive_operation(const char *instance_id, struct RemoveTransportData data);

void sketch_eraser_set_target_shape(const char *instance_id, uint8_t target);

struct RemoveTransportData sketch_eraser_start(const char *instance_id, float x, float y);

struct RemoveTransportData sketch_eraser_move(const char *instance_id,
                                              struct FFIArrayFloat2 ffi_array);

void sketch_eraser_finish(const char *instance_id);

bool comet_receive_remote_data(const char *instance_id, CometTransportData data);

struct CometDrawableData comet_get_remote_snippet(const char *instance_id);

void comet_get_remote_snippet_drop(struct CometDrawableData data);

void comet_receive_remote_exit(const char *instance_id);

void comet_start(const char *instance_id, struct CometStyle style);

struct CometDrawableData comet_append(const char *instance_id, struct FFIArrayFloat2 ffi_array);

void comet_append_drop(struct CometDrawableData transport_data);

struct CometDrawableData comet_update(const char *instance_id, struct FFIArrayFloat2 ffi_array);

void comet_update_drop(struct CometDrawableData transport_data);

CometTransportData comet_fitting(const char *instance_id);

void comet_fitting_drop(CometTransportData transport_data);

struct CometExitDataFFI comet_exit(const char *instance_id);

void comet_exit_drop(struct CometExitDataFFI transport_data);

struct OvalDrawableData oval_finish(const char *instance_id,
                                    const float *origin_ffi,
                                    float long_axis,
                                    float short_axis,
                                    struct OvalStyle style);

void oval_finish_drop(struct OvalDrawableData drawable_data);

bool oval_receive_remote_data(const char *instance_id, struct OvalDrawableData drawable_data);

void oval_receive_operation(const char *instance_id, struct OvalDrawableData drawable_data);

void pencil_set_cubic_fitting_enable(const char *instance_id, bool enable);

void pencil_start(const char *instance_id, struct PencilStyle style);

struct PencilDrawableData pencil_append(const char *instance_id, struct FFIArrayFloat2 ffi_array);

void pencil_append_drop(struct PencilDrawableData transport_data);

struct CombinedAllPencilDataFFI pencil_finish(const char *instance_id);

void pencil_finish_drop(struct CombinedAllPencilDataFFI combined_data);

PencilTransportData pencil_fitting(const char *instance_id);

void pencil_fitting_drop(PencilTransportData transport_data);

bool pencil_receive_remote_data(const char *instance_id, PencilTransportData data);

struct PencilDrawableDataGroup pencil_get_remote_snippet(const char *instance_id);

void pencil_get_remote_snippet_drop(struct PencilDrawableDataGroup group_data);

struct PencilDrawableData pencil_get_drawable_data_by_id(const char *instance_id, const char *id);

void pencil_get_drawable_data_by_id_drop(struct PencilDrawableData ffi_data);

void pencil_receive_operation(const char *instance_id, struct PencilDrawableData ffi_data);

struct RectangleDrawableData rectangle_finish(const char *instance_id,
                                              const float *left_top_ffi,
                                              const float *right_bottom_ffi,
                                              struct RectangleStyle style);

void rectangle_finish_drop(struct RectangleDrawableData drawable_data);

bool rectangle_receive_remote_data(const char *instance_id,
                                   struct RectangleDrawableData drawable_data);

void rectangle_receive_operation(const char *instance_id,
                                 struct RectangleDrawableData drawable_data);

struct UndoTransportData sketch_undo(const char *instance_id);

void sketch_undo_drop(struct UndoTransportData data);

struct UndoTransportData sketch_undo_v2(const char *instance_id);

void sketch_undo_v2_drop(struct UndoTransportData data);

RedoTransportData sketch_redo(const char *instance_id);

void sketch_redo_drop(RedoTransportData data);

void resume_init(const char *instance_id);

struct ResumeFinishDataFFI resume_finish(const char *instance_id, bool is_finish);

void resume_finish_drop(struct ResumeFinishDataFFI data);

struct RemoteAddDataFFI undo_receive_remote_add_data(const char *instance_id,
                                                     struct RemoteAddIdsFFI data);

struct RemoteAddDataFFI redo_receive_remote_add_data(const char *instance_id,
                                                     struct RemoteAddIdsFFI data);

void receive_remote_add_for_undo_drop(struct RemoteAddIdsFFI data);

void redo_receive_operation_for_add(const char *instance_id, struct RemoteAddIdsFFI data);

void redo_receive_operation_for_remove(const char *instance_id, struct RemoveTransportData data);

void undo_receive_operation_for_add(const char *instance_id, struct RemoteAddIdsFFI data);

void undo_receive_operation_for_remove(const char *instance_id, struct RemoveTransportData data);

int64_t get_undo_stack_len(const char *instance_id);
