//
//  SCPasteboardDefine.h
//  LarkEMM
//
//  Created by ByteDance on 2023/12/26.
//

#ifndef SCPasteboardDefine_h
#define SCPasteboardDefine_h

typedef NS_ENUM(NSInteger, SCPasteboardDataType) {
    SCPasteboardDataTypeString = 0,
    SCPasteboardDataTypeColor,
    SCPasteboardDataTypeImage,
    SCPasteboardDataTypeUrl,
    SCPasteboardDataTypeStrings,
    SCPasteboardDataTypeColors,
    SCPasteboardDataTypeImages,
    SCPasteboardDataTypeUrls,
    SCPasteboardDataTypeValue,
    SCPasteboardDataTypeValues,
    SCPasteboardDataTypeData,
    SCPasteboardDataTypeItems,
    SCPasteboardDataTypeItemProviders,
};

#endif /* SCPasteboardDefine_h */
