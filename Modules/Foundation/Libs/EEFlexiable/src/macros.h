//
//  macros.h
//  EEFlexiable
//
//  Created by qihongye on 2018/11/26.
//

#define CSS_PROPERTY(css_type, yg_type, lowercased_name, capitalized_name) \
- (css_type)lowercased_name \
{ \
    return (css_type)YGNodeStyleGet##capitalized_name(self.node); \
} \
\
- (void)set##capitalized_name:(css_type)lowercased_name \
{ \
    YGNodeStyleSet##capitalized_name(self.node, (yg_type)lowercased_name); \
}

#define CSS_VALUE_PROPERTY_GETTER(lowercased_name, capitalized_name) \
- (CSSValue)lowercased_name \
{ \
    YGValue value = YGNodeStyleGet##capitalized_name(self.node); \
    return *((CSSValue *) &value); \
} \

#define CSS_VALUE_PROPERTY(lowercased_name, capitalized_name) \
CSS_VALUE_PROPERTY_GETTER(lowercased_name, capitalized_name) \
\
- (void)set##capitalized_name:(CSSValue)lowercased_name \
{ \
    switch (lowercased_name.unit) { \
    case CSSUnitUndefined: \
        YGNodeStyleSet##capitalized_name(self.node, lowercased_name.value); \
        break; \
    case CSSUnitPoint: \
        YGNodeStyleSet##capitalized_name(self.node, lowercased_name.value); \
        break; \
    case CSSUnitPercent:                                                            \
        YGNodeStyleSet##capitalized_name##Percent(self.node, lowercased_name.value); \
        break; \
    default: \
        NSAssert(NO, @"Not implemented"); \
    } \
}

#define CSS_AUTO_VALUE_PROPERTY(lowercased_name, capitalized_name) \
CSS_VALUE_PROPERTY_GETTER(lowercased_name, capitalized_name) \
\
- (void)set##capitalized_name:(CSSValue)lowercased_name \
{ \
    switch (lowercased_name.unit) { \
    case CSSUnitPoint: \
        YGNodeStyleSet##capitalized_name(self.node, lowercased_name.value); \
        break; \
    case CSSUnitPercent: \
        YGNodeStyleSet##capitalized_name##Percent(self.node, lowercased_name.value); \
        break; \
    case CSSUnitAuto: \
        YGNodeStyleSet##capitalized_name##Auto(self.node); \
        break; \
    default: \
        NSAssert(NO, @"Not implemented"); \
    } \
}

#define CSS_EDGE_PROPERTY_GETTER(type, lowercased_name, capitalized_name, property, edge) \
- (type)lowercased_name                                                                  \
{                                                                                        \
    return (type)YGNodeStyleGet##property(self.node, YG##edge);                                      \
}

#define CSS_EDGE_PROPERTY_SETTER(lowercased_name, capitalized_name, property, edge) \
- (void)set##capitalized_name:(CGFloat)lowercased_name                             \
{                                                                                  \
    YGNodeStyleSet##property(self.node, YG##edge, lowercased_name);                      \
}

#define CSS_EDGE_PROPERTY(lowercased_name, capitalized_name, property, edge)         \
CSS_EDGE_PROPERTY_GETTER(CGFloat, lowercased_name, capitalized_name, property, edge) \
CSS_EDGE_PROPERTY_SETTER(lowercased_name, capitalized_name, property, edge)

#define CSS_VALUE_EDGE_PROPERTY_SETTER(objc_lowercased_name, objc_capitalized_name, c_name, edge) \
- (void)set##objc_capitalized_name:(CSSValue)objc_lowercased_name                                 \
{                                                                                                \
switch (objc_lowercased_name.unit) {                                                           \
case YGUnitUndefined:                                                                        \
YGNodeStyleSet##c_name(self.node, YG##edge, objc_lowercased_name.value);                       \
break;                                                                                     \
case YGUnitPoint:                                                                            \
YGNodeStyleSet##c_name(self.node, YG##edge, objc_lowercased_name.value);                       \
break;                                                                                     \
case YGUnitPercent:                                                                          \
YGNodeStyleSet##c_name##Percent(self.node, YG##edge, objc_lowercased_name.value);              \
break;                                                                                     \
default:                                                                                     \
NSAssert(NO, @"Not implemented");                                                          \
}                                                                                              \
}

#define CSS_VALUE_EDGE_PROPERTY(lowercased_name, capitalized_name, property, edge)   \
- (CSSValue)lowercased_name                                                                  \
{                                                                                        \
    YGValue value = YGNodeStyleGet##property(self.node, YG##edge); \
    return *((CSSValue *) &value);                                      \
} \
CSS_VALUE_EDGE_PROPERTY_SETTER(lowercased_name, capitalized_name, property, edge)

#define CSS_VALUE_EDGES_PROPERTIES(lowercased_name, capitalized_name)                                                  \
CSS_VALUE_EDGE_PROPERTY(lowercased_name##Left, capitalized_name##Left, capitalized_name, EdgeLeft)                   \
CSS_VALUE_EDGE_PROPERTY(lowercased_name##Top, capitalized_name##Top, capitalized_name, EdgeTop)                      \
CSS_VALUE_EDGE_PROPERTY(lowercased_name##Right, capitalized_name##Right, capitalized_name, EdgeRight)                \
CSS_VALUE_EDGE_PROPERTY(lowercased_name##Bottom, capitalized_name##Bottom, capitalized_name, EdgeBottom)             \
CSS_VALUE_EDGE_PROPERTY(lowercased_name##Start, capitalized_name##Start, capitalized_name, EdgeStart)                \
CSS_VALUE_EDGE_PROPERTY(lowercased_name##End, capitalized_name##End, capitalized_name, EdgeEnd)                      \
CSS_VALUE_EDGE_PROPERTY(lowercased_name##Horizontal, capitalized_name##Horizontal, capitalized_name, EdgeHorizontal) \
CSS_VALUE_EDGE_PROPERTY(lowercased_name##Vertical, capitalized_name##Vertical, capitalized_name, EdgeVertical)       \
CSS_VALUE_EDGE_PROPERTY(lowercased_name, capitalized_name, capitalized_name, EdgeAll)
