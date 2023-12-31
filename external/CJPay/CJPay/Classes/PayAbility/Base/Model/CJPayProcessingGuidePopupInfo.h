//
//  CJPayProcessingGuidePopupInfo.h
//  Pods
//
//  Created by xutianxi on 2021/11/12.
//

#import <Foundation/Foundation.h>
#import <JSONModel/JSONModel.h>

NS_ASSUME_NONNULL_BEGIN

@interface CJPayProcessingGuidePopupInfo : JSONModel

@property (nonatomic, copy) NSString *title;
@property (nonatomic, copy) NSString *desc;
@property (nonatomic, copy) NSString *btnText;

- (BOOL)isValid;

@end

NS_ASSUME_NONNULL_END
