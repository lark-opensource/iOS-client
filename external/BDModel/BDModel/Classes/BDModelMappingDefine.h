
//
//  BDModelMappingDefine.h
//  Pods
//
//  Created by 马钰峰 on 2019/3/28.
//

#ifndef BDModelMappingDefine_h
#define BDModelMappingDefine_h

typedef NS_OPTIONS(NSUInteger, BDModelMappingOptions) {
    
    BDModelMappingOptionsNone = 0,
    //  snake_case -> snakeCase
    BDModelMappingOptionsSnakeCaseToCamelCase = 1 << 0,
    //  camelCase -> camel_case
    BDModelMappingOptionsCamelCaseToSnakeCase = 1 << 1,
};


#endif /* BDModelMappingDefine_h */
