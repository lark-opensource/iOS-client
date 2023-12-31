//
//  BDTuringVerifyView+UI.h
//  BDTuring
//
//  Created by bob on 2020/7/12.
//

#import "BDTuringVerifyView.h"

NS_ASSUME_NONNULL_BEGIN

@interface BDTuringVerifyView (UI)

- (NSDictionary *)customTheme;
- (NSDictionary *)customText;
- (void)adjustWebViewPosition;
- (void)handleDialogSize:(NSDictionary *)params;

@end

NS_ASSUME_NONNULL_END
