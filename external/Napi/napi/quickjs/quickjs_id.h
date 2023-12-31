#pragma once

/* 这里是 quickjs.c 里内置的数据，需要根据源码变化随时调整 */

enum {
  /* classid tag        */ /* union usage   | properties */
  LEPUS_CLASS_OBJECT = 1,  /* must be first */
  LEPUS_CLASS_ARRAY,       /* u.array       | length */
  LEPUS_CLASS_ERROR,
  LEPUS_CLASS_NUMBER,           /* u.object_data */
  LEPUS_CLASS_STRING,           /* u.object_data */
  LEPUS_CLASS_BOOLEAN,          /* u.object_data */
  LEPUS_CLASS_SYMBOL,           /* u.object_data */
  LEPUS_CLASS_ARGUMENTS,        /* u.array       | length */
  LEPUS_CLASS_MAPPED_ARGUMENTS, /*               | length */
  LEPUS_CLASS_DATE,             /* u.object_data */
  LEPUS_CLASS_MODULE_NS,
  LEPUS_CLASS_C_FUNCTION,          /* u.cfunc */
  LEPUS_CLASS_BYTECODE_FUNCTION,   /* u.func */
  LEPUS_CLASS_BOUND_FUNCTION,      /* u.bound_function */
  LEPUS_CLASS_C_FUNCTION_DATA,     /* u.c_function_data_record */
  LEPUS_CLASS_GENERATOR_FUNCTION,  /* u.func */
  LEPUS_CLASS_FOR_IN_ITERATOR,     /* u.for_in_iterator */
  LEPUS_CLASS_REGEXP,              /* u.regexp */
  LEPUS_CLASS_ARRAY_BUFFER,        /* u.array_buffer */
  LEPUS_CLASS_SHARED_ARRAY_BUFFER, /* u.array_buffer */
  LEPUS_CLASS_UINT8C_ARRAY,        /* u.array (typed_array) */
  LEPUS_CLASS_INT8_ARRAY,          /* u.array (typed_array) */
  LEPUS_CLASS_UINT8_ARRAY,         /* u.array (typed_array) */
  LEPUS_CLASS_INT16_ARRAY,         /* u.array (typed_array) */
  LEPUS_CLASS_UINT16_ARRAY,        /* u.array (typed_array) */
  LEPUS_CLASS_INT32_ARRAY,         /* u.array (typed_array) */
  LEPUS_CLASS_UINT32_ARRAY,        /* u.array (typed_array) */
#ifdef CONFIG_BIGNUM
  LEPUS_CLASS_BIG_INT64_ARRAY,  /* u.array (typed_array) */
  LEPUS_CLASS_BIG_UINT64_ARRAY, /* u.array (typed_array) */
#endif
  LEPUS_CLASS_FLOAT32_ARRAY, /* u.array (typed_array) */
  LEPUS_CLASS_FLOAT64_ARRAY, /* u.array (typed_array) */
  LEPUS_CLASS_DATAVIEW,      /* u.typed_array */
#ifdef CONFIG_BIGNUM
  LEPUS_CLASS_BIG_INT,   /* u.object_data */
  LEPUS_CLASS_BIG_FLOAT, /* u.object_data */
  LEPUS_CLASS_FLOAT_ENV, /* u.float_env */
#endif
  LEPUS_CLASS_MAP,                      /* u.map_state */
  LEPUS_CLASS_SET,                      /* u.map_state */
  LEPUS_CLASS_WEAKMAP,                  /* u.map_state */
  LEPUS_CLASS_WEAKSET,                  /* u.map_state */
  LEPUS_CLASS_MAP_ITERATOR,             /* u.map_iterator_data */
  LEPUS_CLASS_SET_ITERATOR,             /* u.map_iterator_data */
  LEPUS_CLASS_ARRAY_ITERATOR,           /* u.array_iterator_data */
  LEPUS_CLASS_STRING_ITERATOR,          /* u.array_iterator_data */
  LEPUS_CLASS_REGEXP_STRING_ITERATOR,   /* u.regexp_string_iterator_data */
  LEPUS_CLASS_GENERATOR,                /* u.generator_data */
  LEPUS_CLASS_PROXY,                    /* u.proxy_data */
  LEPUS_CLASS_PROMISE,                  /* u.promise_data */
  LEPUS_CLASS_PROMISE_RESOLVE_FUNCTION, /* u.promise_function_data */
  LEPUS_CLASS_PROMISE_REJECT_FUNCTION,  /* u.promise_function_data */
  LEPUS_CLASS_ASYNC_FUNCTION,           /* u.func */
  LEPUS_CLASS_ASYNC_FUNCTION_RESOLVE,   /* u.async_function_data */
  LEPUS_CLASS_ASYNC_FUNCTION_REJECT,    /* u.async_function_data */
  LEPUS_CLASS_ASYNC_FROM_SYNC_ITERATOR, /* u.async_from_sync_iterator_data */
  LEPUS_CLASS_ASYNC_GENERATOR_FUNCTION, /* u.func */
  LEPUS_CLASS_ASYNC_GENERATOR,          /* u.async_generator_data */

  LEPUS_CLASS_INIT_COUNT, /* last entry for predefined classes */
};
