//
//  ACCLayoutDefines.h
//  CreativeKit
//
//  Created by Liu Deping on 2021/3/15.
//

#ifndef ACCLayoutDefines_h
#define ACCLayoutDefines_h

typedef NSString * ACCViewType NS_STRING_ENUM;

#define ACCViewTypeEnumDefine(key) FOUNDATION_EXPORT ACCViewType ACCViewType ## key
#define ACCViewTypeEnumImpl(key) ACCViewType ACCViewType ## key = @#key

#endif /* ACCLayoutDefines_h */
