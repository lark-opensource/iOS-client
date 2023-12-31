//
//  TTVideoEngineEventListModel.h
//  TTVideoEngine
//
//  Created by bytedance on 2021/6/16.
//

#import <Foundation/Foundation.h>


@interface TTVideoEngineEventListModel : NSObject

- (void)addEventModel:(id)eventModel;

- (NSArray *)eventModels;

@end

