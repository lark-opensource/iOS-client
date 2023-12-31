//
//  BDUGVideoShareUniversalDialog.h
//  AFgzipRequestSerializer
//
//  Created by 杨阳 on 2019/5/17.
//

#import <UIKit/UIKit.h>

@interface BDUGVideoShareDialogInfo : NSObject

@property (nonatomic, copy) NSString *titleString;
@property (nonatomic, copy) NSString *tipString;
@property (nonatomic, copy) NSString *buttonString;

@end

@interface BDUGVideoShareUniversalDialog : UIView

- (void)refreshContent:(BDUGVideoShareDialogInfo *)contentModel;

@end

