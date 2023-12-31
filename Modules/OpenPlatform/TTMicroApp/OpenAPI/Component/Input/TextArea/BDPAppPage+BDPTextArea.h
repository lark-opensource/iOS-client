//
//  BDPAppPage+BDPTextArea.h
//  Timor
//
//  Created by lixiaorui on 2020/7/23.
//

#import <UIKit/UIKit.h>
#import "BDPAppPage.h"

NS_ASSUME_NONNULL_BEGIN

@interface BDPAppPage (BDPTextArea)

// autosize的TextArea在编辑的时候，会修改apppage的frame，从而触发BDPAppPageController的layoutsubviews, 导致apppage的frame又被改回去了，所以需要编辑的时候不让BDPAppPageController修改apppage的frame
@property (nonatomic, assign) BOOL bap_lockFrameForEditing;

@end

NS_ASSUME_NONNULL_END
