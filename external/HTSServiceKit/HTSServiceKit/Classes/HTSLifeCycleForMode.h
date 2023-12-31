//
//  HTSAppContext.h
//  HTSBootLoader
//
//  Created by Huangwenchen on 2019/11/14.
//  Copyright © 2019 bytedance. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "HTSAppLifeCycle.h"

#define HTS_APP_LIFECYCLE_FOR_MODE(_class_name,_mode_)\
__attribute((used, section("HTS_"_mode_ "," _HTS_LIFE_CIRCLE_SECTION)))\
static const char * _HTS_UNIQUE_VAR = #_class_name;

