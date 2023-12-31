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

#import "adl_serializer.hpp"
#import "binary_reader.hpp"
#import "binary_writer.hpp"
#import "cpp_future.hpp"
#import "detected.hpp"
#import "exceptions.hpp"
#import "from_json.hpp"
#import "hedley.hpp"
#import "hedley_undef.hpp"
#import "input_adapters.hpp"
#import "internal_iterator.hpp"
#import "is_sax.hpp"
#import "iter_impl.hpp"
#import "iteration_proxy.hpp"
#import "iterator_traits.hpp"
#import "json.hpp"
#import "json_fwd.hpp"
#import "json_pointer.hpp"
#import "json_ref.hpp"
#import "json_reverse_iterator.hpp"
#import "json_sax.hpp"
#import "lexer.hpp"
#import "macro_scope.hpp"
#import "macro_unscope.hpp"
#import "output_adapters.hpp"
#import "parser.hpp"
#import "position_t.hpp"
#import "primitive_iterator.hpp"
#import "serializer.hpp"
#import "sha1.hpp"
#import "to_chars.hpp"
#import "to_json.hpp"
#import "type_traits.hpp"
#import "value_t.hpp"
#import "void_t.hpp"

FOUNDATION_EXPORT double TemplateConsumerVersionNumber;
FOUNDATION_EXPORT const unsigned char TemplateConsumerVersionString[];