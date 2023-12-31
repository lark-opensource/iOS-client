//
//  CAKAlbumBottomViewConfig.h
//  CreativeAlbumKit-Pods-Aweme
//
//  Created by yuanchang on 2020/12/15.
//

#import <Foundation/Foundation.h>

@interface CAKAlbumBottomViewConfig : NSObject

@property (nonatomic, assign) BOOL enableSwitchMultiSelect;

@property (nonatomic, copy, nullable) NSString *titleLabelText;
@property (nonatomic, assign) BOOL shouldHideBottomViewWhenNotSelect;

@end
