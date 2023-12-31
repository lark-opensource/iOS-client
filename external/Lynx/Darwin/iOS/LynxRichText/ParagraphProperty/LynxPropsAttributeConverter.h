//  Copyright 2022 The Lynx Authors. All rights reserved.

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN
/*
 handle node props for the html attribute string,
 convert props dictionary to NSDictionary<NSAttributedStringKey, id>

 */

@interface LynxPropsAttributeConverter : NSObject

// convert props dictionary to NSDictionary<NSAttributedStringKey, id>
// @param props Dictionary, the props should convert to the attributes of string
- (NSDictionary<NSAttributedStringKey, id> *)convertDynamicAttributes:
    (NSDictionary<NSString *, id> *)props;
// convert props dictionary to NSDictionary<NSAttributedStringKey, id> , and add the result with
// originAttributes
// @param props Dictionary, the props should convert to the attributes of string
// @param attributes Dictionary, the origin attribute of the string that should merge
- (NSDictionary<NSAttributedStringKey, id> *)
    convertDynamicAttribute:(NSDictionary<NSString *, id> *)props
       withOriginAttributes:(NSDictionary<NSAttributedStringKey, id> *)attributes;

@end

NS_ASSUME_NONNULL_END
