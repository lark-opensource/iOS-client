//
//  ACCRecordFilterDefines.h
//  CameraClient
//
//  Created by guochenxiang on 2020/3/16.
//

#ifndef ACCRecordFilterDefines_h
#define ACCRecordFilterDefines_h

FOUNDATION_EXPORT void * const ACCRecordFilterContext;

typedef NS_ENUM(NSUInteger, AWEFilterCellIconStyle) {
    AWEFilterCellIconStyleRound = 0,
    AWEFilterCellIconStyleSquare = 1
};

typedef NS_ENUM(NSUInteger, ACCFilterPanelType) {
    ACCFilterPanelTypeDefault,
    ACCFilterPanelTypeStory = 2,
};

#endif /* ACCRecordFilterDefines_h */
