//
//  DVEPickerViewModels.h
//  Pods
//
//  Created by bytedance on 2021/4/9.
//

#ifndef DVEPickerViewModels_h
#define DVEPickerViewModels_h

#import <UIKit/UIKit.h>
#import "DVEEffectValue.h"

@protocol DVEPickerCategoryModel <NSObject>

@property (nonatomic, assign) CGFloat cachedWidth;

-(NSArray<DVEEffectValue*>*)models;

-(NSString*)name;

-(BOOL)isLoading;

-(BOOL)favorite;

- (void)loadModelListIfNeeded;


@end


#endif /* DVEPickerViewModels_h */
