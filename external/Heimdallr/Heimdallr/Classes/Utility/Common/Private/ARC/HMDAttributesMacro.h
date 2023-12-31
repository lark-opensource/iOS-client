//
//  HMDAttributesMacro.h
//  Pods
//
//  Created by Nickyo on 2023/6/6.
//

#ifndef HMDAttributesMacro_h
#define HMDAttributesMacro_h

#define HMD_ATTRIBUTE_ARRAY(key, value) @[@#key, value]
#define HMD_ATTRIBUTE_DICT(key, cls) @{@#key: [cls class]}
#define HMD_ATTRIBUTE_MAP_DEFAULT(prop, key, default) @#prop: HMD_ATTRIBUTE_ARRAY(key, default)
#define HMD_ATTRIBUTE_MAP(prop, key) @#prop: @#key
#define HMD_ATTRIBUTE_MAP_CLASS(prop, key, cls) @#prop: HMD_ATTRIBUTE_DICT(key, cls)

#if RANGERSAPM
#    define HMD_ATTR_MAP_DEFAULT_TOD(prop, key, default)
#    define HMD_ATTR_MAP_TOD(prop, key)

#    define HMD_ATTR_MAP_DEFAULT_TOB(prop, key, default) HMD_ATTRIBUTE_MAP_DEFAULT(prop, key, default),
#    define HMD_ATTR_MAP_TOB(prop, key) HMD_ATTRIBUTE_MAP(prop, key),

#    define HMD_ATTR_MAP_DEFAULT(prop, key, default_d, default_b) HMD_ATTRIBUTE_MAP_DEFAULT(prop, key, default_b),
#    define HMD_ATTR_MAP_DEFAULT2(prop, key_d, default_d, key_b, default_b) HMD_ATTRIBUTE_MAP_DEFAULT(prop, key_b, default_b),
#else
#    define HMD_ATTR_MAP_DEFAULT_TOD(prop, key, default) HMD_ATTRIBUTE_MAP_DEFAULT(prop, key, default),
#    define HMD_ATTR_MAP_TOD(prop, key) HMD_ATTRIBUTE_MAP(prop, key),

#    define HMD_ATTR_MAP_DEFAULT_TOB(prop, key, default)
#    define HMD_ATTR_MAP_TOB(prop, key)

#    define HMD_ATTR_MAP_DEFAULT(prop, key, default_d, default_b) HMD_ATTRIBUTE_MAP_DEFAULT(prop, key, default_d),
#    define HMD_ATTR_MAP_DEFAULT2(prop, key_d, default_d, key_b, default_b) HMD_ATTRIBUTE_MAP_DEFAULT(prop, key_d, default_d),
#endif /* RANGERSAPM */

#define HMD_ATTR_MAP(prop, key) HMD_ATTRIBUTE_MAP(prop, key),
#define HMD_ATTR_MAP_CLASS(prop, key, cls) HMD_ATTRIBUTE_MAP_CLASS(prop, key, cls),

#endif /* HMDAttributesMacro_h */
