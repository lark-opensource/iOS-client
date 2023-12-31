//
//  ACCTagsCustomizeViewController.h
//  CameraClient-Pods-AwemeCore
//
//  Created by HuangHongsen on 2021/9/30.
//

#import "ACCTagsItemPickerViewController.h"

@interface ACCTagsCustomizeViewController : ACCTagsItemPickerViewController

@property (nonatomic, assign) BOOL showCreateCustomAlertOnAppear;
@property (nonatomic, copy, nullable) NSString *defaultCustomTag;
@property (nonatomic, assign) ACCEditTagType fromTagType;
@property (nonatomic, copy, nullable) NSString *fromTagTypeString;

@end
