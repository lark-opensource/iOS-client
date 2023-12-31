//
//  CanvasMaterialUtils.h
//  LVTemplate
//
//  Created by ZhangYuanming on 2020/2/14.
//

#ifndef CanvasMaterialUtils_hpp
#define CanvasMaterialUtils_hpp

#include <stdio.h>
#include <string>
#include <TemplateConsumer/MaterialCanvas.h>

namespace cut {

struct CanvasMaterialUtils {
    
    static const std::string MATERIAL_CANVAS_BLACK();

    static const std::string TYPE_COLOR();
    
    /**
     * 生成黑底画布
     * @return MaterialCanvas
     */
    static CutSame::MaterialCanvas genBlackCanvas();
};


}

#endif /* CanvasMaterialUtils_hpp */
