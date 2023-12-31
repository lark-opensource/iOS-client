//
//  IESEffectSectionCollectionViewCell.h
//  EffectPlatformSDK
//
//  Created by Kun Wang on 2018/3/6.
//

#import <UIKit/UIKit.h>

@class IESEffectUIConfig;
@interface IESEffectSectionCollectionViewCell : UICollectionViewCell
- (void)updateWithTitle:(NSString *)title
               imageURL:(NSURL *)url
            selectedURL:(NSURL *)selectedURL
             showRedDot:(BOOL)showRedDot
             cellConfig:(IESEffectUIConfig *)uiConfig;
- (void)setItemSelected:(BOOL)selected;
@end
