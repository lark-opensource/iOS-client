//
//  ACCMVTextEditorTableViewCell.h
//  CameraClient
//
//  Created by long.chen on 2020/3/18.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@class ACCTemplateTextFragment;
@interface ACCMVTextEditorTableViewCell : UITableViewCell

@property (nonatomic, strong, readonly) ACCTemplateTextFragment *textFragment;
@property (nonatomic, assign, readonly) BOOL isCellSelected;


+ (NSString *)cellIdentifier;

- (void)setTextFragment:(ACCTemplateTextFragment *)textFragment
             topContent:(BOOL)topContent
          bottomContent:(BOOL)bottomContent
               selected:(BOOL)selected;

- (void)prepareForUnSelectedAnimation;

- (void)updateCover:(UIImage *)cover;

@end

NS_ASSUME_NONNULL_END
