//
//  ACCEditPageTextStorage.h
//  CameraClient
//
//  Created by resober on 2020/3/3.
//

#import <UIKit/UIKit.h>
@class ACCEditPageTextView;

NS_ASSUME_NONNULL_BEGIN

@interface ACCEditPageTextStorage : NSTextStorage
/// the textView which owns this storage.
@property (nonatomic, weak) ACCEditPageTextView *textView;
@end

NS_ASSUME_NONNULL_END
