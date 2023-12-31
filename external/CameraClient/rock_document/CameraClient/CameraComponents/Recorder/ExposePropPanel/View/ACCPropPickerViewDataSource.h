//
//  ACCPropPickerViewDataSource.h
//  CameraClient
//
//  Created by Shen Chen on 2020/4/11.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import "ACCPropPickerItem.h"

NS_ASSUME_NONNULL_BEGIN

@interface ACCPropPickerViewDataSource : NSObject<UICollectionViewDataSource>
@property (nonatomic, strong) NSArray<ACCPropPickerItem *> *items;
@end

NS_ASSUME_NONNULL_END
