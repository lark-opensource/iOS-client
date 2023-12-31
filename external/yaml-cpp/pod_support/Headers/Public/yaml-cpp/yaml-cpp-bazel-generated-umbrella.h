#ifdef __OBJC__
#import <UIKit/UIKit.h>
#else
#ifndef FOUNDATION_EXPORT
#if defined(__cplusplus)
#define FOUNDATION_EXPORT extern "C"
#else
#define FOUNDATION_EXPORT extern
#endif
#endif
#endif

#import "yaml-cpp/anchor.h"
#import "yaml-cpp/binary.h"
#import "yaml-cpp/dll.h"
#import "yaml-cpp/emitfromevents.h"
#import "yaml-cpp/emitter.h"
#import "yaml-cpp/emitterdef.h"
#import "yaml-cpp/emittermanip.h"
#import "yaml-cpp/emitterstyle.h"
#import "yaml-cpp/eventhandler.h"
#import "yaml-cpp/exceptions.h"
#import "yaml-cpp/mark.h"
#import "yaml-cpp/node/convert.h"
#import "yaml-cpp/node/detail/bool_type.h"
#import "yaml-cpp/node/detail/impl.h"
#import "yaml-cpp/node/detail/iterator.h"
#import "yaml-cpp/node/detail/iterator_fwd.h"
#import "yaml-cpp/node/detail/memory.h"
#import "yaml-cpp/node/detail/node.h"
#import "yaml-cpp/node/detail/node_data.h"
#import "yaml-cpp/node/detail/node_iterator.h"
#import "yaml-cpp/node/detail/node_ref.h"
#import "yaml-cpp/node/emit.h"
#import "yaml-cpp/node/impl.h"
#import "yaml-cpp/node/iterator.h"
#import "yaml-cpp/node/node.h"
#import "yaml-cpp/node/parse.h"
#import "yaml-cpp/node/ptr.h"
#import "yaml-cpp/node/type.h"
#import "yaml-cpp/noncopyable.h"
#import "yaml-cpp/null.h"
#import "yaml-cpp/ostream_wrapper.h"
#import "yaml-cpp/parser.h"
#import "yaml-cpp/stlemitter.h"
#import "yaml-cpp/traits.h"
#import "yaml-cpp/yaml.h"

FOUNDATION_EXPORT double yaml_cppVersionNumber;
FOUNDATION_EXPORT const unsigned char yaml_cppVersionString[];