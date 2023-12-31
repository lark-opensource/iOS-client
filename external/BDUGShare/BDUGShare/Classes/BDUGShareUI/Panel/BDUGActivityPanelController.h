//
//   BDUGActivityPanelController.h
//  Article
//
//  Created by zhaopengwei on 15/7/26.
//
//

#import <Foundation/Foundation.h>
#import "BDUGActivityPanelControllerProtocol.h"

@interface  BDUGActivityPanelController : NSObject<BDUGActivityPanelControllerProtocol>

@property (nonatomic, weak) id<BDUGActivityPanelDelegate> delegate;

@end
