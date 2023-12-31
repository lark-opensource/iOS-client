//
//  ACCMVTextEditorInputView.h
//  CameraClient
//
//  Created by long.chen on 2020/3/19.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface ACCMVTextEditorInputView : UIView

@property (nonatomic, copy) NSString *initialContent;
@property (nonatomic, copy) void(^textDidChangedBlock)(NSString *content);
@property (nonatomic, copy) void(^didEndEditBlock)(BOOL hasChanged);

- (void)becomeActive;
- (void)resignActive;

@end

NS_ASSUME_NONNULL_END
