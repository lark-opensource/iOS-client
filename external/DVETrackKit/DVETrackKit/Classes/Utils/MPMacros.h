//
//  MPMacros.h
//  DVETrackKit
//
//  Created by bytedance on 2021/6/3.
//

#ifndef Meepo_h
#define Meepo_h

//LocalizedString
#define DVETrackOptionsStringValue(__value__, __placeholder__) __value__
#define DVETrackNSLocalizedString(key, comment) [[NSBundle mainBundle] localizedStringForKey:key value:@"" table:nil]
#define DVETrackLocString(key, placeholder) ([DVETrackNSLocalizedString(DVETrackOptionsStringValue(key,@""),@"") isEqualToString:DVETrackOptionsStringValue(key,@"")] ? DVETrackOptionsStringValue(placeholder,@"") : (DVETrackNSLocalizedString(DVETrackOptionsStringValue(key,@""),@"")))

#endif /* Meepo_h */
