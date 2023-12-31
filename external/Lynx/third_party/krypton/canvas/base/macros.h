#ifndef CANVAS_BASE_MACROS_H_
#define CANVAS_BASE_MACROS_H_

#define LYNX_CANVAS_EXPORT __attribute__((visibility("default")))

#define LYNX_CANVAS_DISALLOW_ASSIGN(CLASS) \
  void operator=(const CLASS&) = delete;
#define LYNX_CANVAS_DISALLOW_COPY(CLASS) CLASS(const CLASS&) = delete;

#define LYNX_CANVAS_DISALLOW_ASSIGN_COPY(CLASS) \
  LYNX_CANVAS_DISALLOW_ASSIGN(CLASS)            \
  LYNX_CANVAS_DISALLOW_COPY(CLASS)

#endif  // CANVAS_BASE_MACROS_H_
