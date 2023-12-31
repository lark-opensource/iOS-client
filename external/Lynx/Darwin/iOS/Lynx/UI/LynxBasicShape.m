//  Copyright 2023 The Lynx Authors. All rights reserved.

#import "LynxBasicShape.h"
#import "LynxBackgroundInfo.h"
#import "LynxBackgroundUtils.h"

typedef NS_ENUM(NSInteger, LBSCornerType) {
  LBSCornerTypeDefault = 0,
  LBSCornerTypeRect = 1,
  LBSCornerTypeRounded = 2,
  LBSCornerTypeSuperElliptical = 3,
};

@implementation LynxBasicShape {
 @public
  LynxBorderRadii* _cornerRadii;
 @public
  LBSCornerType _cornerType;
 @public
  LynxBorderUnitValue* _params;
 @public
  LynxBasicShapeType _type;
  UIBezierPath* _path;
  CGSize _size;
}
- (UIBezierPath*)pathWithFrameSize:(CGSize)frameSize {
  if (CGSizeEqualToSize(_size, frameSize) && _path) {
    return _path;
  }
  _size = frameSize;
  CGPathRef cPath = LBSCreatePathFromBasicShape(self, frameSize);
  if (cPath) {
    _path = [UIBezierPath bezierPathWithCGPath:cPath];
    CGPathRelease(cPath);
  }
  return _path;
}
- (void)dealloc {
  if (_cornerRadii) {
    free(_cornerRadii);
    _cornerRadii = NULL;
  }
  if (_params) {
    free(_params);
    _params = NULL;
  }
}
@end

LynxBasicShape* LBSCreateBasicShapeFromArray(NSArray* array) {
  if (!array || [array count] < 1) {
    return NULL;
  }
  LynxBasicShapeType type = [[array objectAtIndex:0] intValue];
  if (type == LynxBasicShapeTypeInset) {
    LynxBasicShape* clipPath = [[LynxBasicShape alloc] init];
    clipPath->_params = (LynxBorderUnitValue*)malloc(sizeof(LynxBorderUnitValue) * 6);
    clipPath->_type = LynxBasicShapeTypeInset;
    unsigned long paramCount = [array count];
    // clang-format off
    // The first param is shape type, `inset`
    // The following 8 fields is inset on four sides.
    // [top, unit, right, unit, bottom, unit, left, unit].
    // The next two fields is optional for exponents of super-ellipse. [ex, ey]
    // The last 16 fields is the optional <border-radius> :
    // [top-left-x,     unit, top-left-y,     unit, top-right-x,   unit, top-right-y,   unit,
    //  bottom-right-x, unit, bottom-right-y, unit, bottom-left-x, unit, bottom-left-y, unit
    // ]
    // clang-format on
    switch (paramCount) {
      case 9:
        clipPath->_cornerType = LBSCornerTypeRect;
        break;
      case 25:
        clipPath->_cornerType = LBSCornerTypeRounded;
        break;
      case 27:
        clipPath->_cornerType = LBSCornerTypeSuperElliptical;
        break;
      default:
        // Error generating basic shape.
        return NULL;
    }

    // get insets values from params array
    for (int i = 0; i < 4; i++) {
      clipPath->_params[i].val = [[array objectAtIndex:(2 * i + 1)] doubleValue];
      clipPath->_params[i].unit = [[array objectAtIndex:(2 * i + 2)] doubleValue];
    }

    int radiusOffset = 9;
    switch (clipPath->_cornerType) {
      case LBSCornerTypeDefault:
      case LBSCornerTypeRect:
        break;
      case LBSCornerTypeSuperElliptical:
        // Exponents value
        clipPath->_params[4].val = [[array objectAtIndex:9] doubleValue];
        clipPath->_params[5].val = [[array objectAtIndex:10] doubleValue];
        radiusOffset = 11;
      case LBSCornerTypeRounded:
        // clang-format off
        // Get border radius value from next 16 values.
        // [top-left-x,     unit, top-left-y,     unit, top-right-x,   unit, top-right-y,   unit,
        //  bottom-right-x, unit, bottom-right-y, unit, bottom-left-x, unit, bottom-left-y, unit
        // ]
        // clang-format on
        clipPath->_cornerRadii = (LynxBorderRadii*)malloc(sizeof(LynxBorderRadii));
        // top left corner
        clipPath->_cornerRadii->topLeftX.val = [[array objectAtIndex:radiusOffset] doubleValue];
        clipPath->_cornerRadii->topLeftX.unit = [[array objectAtIndex:radiusOffset + 1] intValue];
        if (clipPath->_cornerRadii->topLeftX.unit == LynxBorderValueUnitPercent) {
          // Adapt to LynxCornerRadii, percentage value is in [0, 100];
          clipPath->_cornerRadii->topLeftX.val *= 100;
        }
        clipPath->_cornerRadii->topLeftY.val = [[array objectAtIndex:radiusOffset + 2] doubleValue];
        clipPath->_cornerRadii->topLeftY.unit = [[array objectAtIndex:radiusOffset + 3] intValue];
        if (clipPath->_cornerRadii->topLeftY.unit == LynxBorderValueUnitPercent) {
          // Adapt to LynxCornerRadii, percentage value is in [0, 100];
          clipPath->_cornerRadii->topLeftY.val *= 100;
        }

        // top right corner
        clipPath->_cornerRadii->topRightX.val =
            [[array objectAtIndex:radiusOffset + 4] doubleValue];
        clipPath->_cornerRadii->topRightX.unit = [[array objectAtIndex:radiusOffset + 5] intValue];
        if (clipPath->_cornerRadii->topRightX.unit == LynxBorderValueUnitPercent) {
          // Adapt to LynxCornerRadii, percentage value is in [0, 100];
          clipPath->_cornerRadii->topRightX.val *= 100;
        }

        clipPath->_cornerRadii->topRightY.val =
            [[array objectAtIndex:radiusOffset + 6] doubleValue];
        clipPath->_cornerRadii->topRightY.unit = [[array objectAtIndex:radiusOffset + 7] intValue];
        if (clipPath->_cornerRadii->topRightY.unit == LynxBorderValueUnitPercent) {
          // Adapt to LynxCornerRadii, percentage value is in [0, 100];
          clipPath->_cornerRadii->topRightY.val *= 100;
        }

        // bottom right corner
        clipPath->_cornerRadii->bottomRightX.val =
            [[array objectAtIndex:radiusOffset + 8] doubleValue];
        clipPath->_cornerRadii->bottomRightX.unit =
            [[array objectAtIndex:radiusOffset + 9] intValue];
        if (clipPath->_cornerRadii->bottomRightX.unit == LynxBorderValueUnitPercent) {
          // Adapt to LynxCornerRadii, percentage value is in [0, 100];
          clipPath->_cornerRadii->bottomRightX.val *= 100;
        }

        clipPath->_cornerRadii->bottomRightY.val =
            [[array objectAtIndex:radiusOffset + 10] doubleValue];
        clipPath->_cornerRadii->bottomRightY.unit =
            [[array objectAtIndex:radiusOffset + 11] intValue];
        if (clipPath->_cornerRadii->bottomRightY.unit == LynxBorderValueUnitPercent) {
          // Adapt to LynxCornerRadii, percentage value is in [0, 100];
          clipPath->_cornerRadii->bottomRightY.val *= 100;
        }

        // bottom left corner
        clipPath->_cornerRadii->bottomLeftX.val =
            [[array objectAtIndex:radiusOffset + 12] doubleValue];
        clipPath->_cornerRadii->bottomLeftX.unit =
            [[array objectAtIndex:radiusOffset + 13] intValue];
        if (clipPath->_cornerRadii->bottomLeftX.unit == LynxBorderValueUnitPercent) {
          // Adapt to LynxCornerRadii, percentage value is in [0, 100];
          clipPath->_cornerRadii->bottomLeftX.val *= 100;
        }

        clipPath->_cornerRadii->bottomLeftY.val =
            [[array objectAtIndex:radiusOffset + 14] doubleValue];
        clipPath->_cornerRadii->bottomLeftY.unit =
            [[array objectAtIndex:radiusOffset + 15] intValue];
        if (clipPath->_cornerRadii->bottomLeftY.unit == LynxBorderValueUnitPercent) {
          // Adapt to LynxCornerRadii, percentage value is in [0, 100];
          clipPath->_cornerRadii->bottomLeftY.val *= 100;
        }
    }
    return clipPath;
  }
  return NULL;
}

CGPathRef LBSCreatePathFromBasicShape(LynxBasicShape* shape, CGSize viewport) {
  CGMutablePathRef path = NULL;
  if (shape->_type == LynxBasicShapeTypeInset) {
    path = CGPathCreateMutable();
    CGRect bounds = CGRectMake(0, 0, viewport.width, viewport.height);
    UIEdgeInsets insets;
    insets.top = shape->_params[0].unit == LynxBorderValueUnitPercent
                     ? shape->_params[0].val * viewport.height
                     : shape->_params[0].val;
    insets.right = shape->_params[1].unit == LynxBorderValueUnitPercent
                       ? shape->_params[1].val * viewport.height
                       : shape->_params[1].val;
    insets.bottom = shape->_params[2].unit == LynxBorderValueUnitPercent
                        ? shape->_params[2].val * viewport.height
                        : shape->_params[2].val;
    insets.left = shape->_params[3].unit == LynxBorderValueUnitPercent
                      ? shape->_params[3].val * viewport.height
                      : shape->_params[3].val;
    UIEdgeInsets adjustedInsets = LynxGetEdgeInsets(bounds, insets, 1.0);
    CGRect innerBounds = LynxGetRectWithEdgeInsets(bounds, adjustedInsets);
    switch (shape->_cornerType) {
      case LBSCornerTypeRounded:
        LynxPathAddRoundedRect(
            path, innerBounds,
            LynxGetCornerInsets(innerBounds, *(shape->_cornerRadii), UIEdgeInsetsZero));
        break;
      case LBSCornerTypeSuperElliptical: {
        LynxCornerInsets cornerRadius =
            LynxGetCornerInsets(innerBounds, *(shape->_cornerRadii), UIEdgeInsetsZero);
        float left = innerBounds.origin.x;
        float top = innerBounds.origin.y;
        float right = left + innerBounds.size.width;
        float bottom = top + innerBounds.size.height;
        float rx = cornerRadius.bottomRight.width;
        float ry = cornerRadius.bottomRight.height;
        float cx = right - rx;
        float cy = bottom - ry;
        float ex = shape->_params[4].val;
        float ey = shape->_params[5].val;
        // Add ellipse to the target rect at
        double x, y, sinI, cosI;
        for (float i = 0; i < M_PI_2; i += 0.01) {
          cosI = cos(i);
          sinI = sin(i);
          x = rx * pow(cosI, 2 / ex) + cx;
          y = ry * pow(sinI, 2 / ey) + cy;
          if (i == 0) {
            CGPathMoveToPoint(path, nil, x, y);
          } else {
            CGPathAddLineToPoint(path, nil, x, y);
          }
        }

        rx = cornerRadius.bottomLeft.width;
        ry = cornerRadius.bottomLeft.height;
        cx = left + rx;
        cy = bottom - ry;
        for (float i = M_PI_2; i < M_PI; i += 0.01) {
          cosI = cos(i);
          sinI = sin(i);
          x = -rx * pow(-cosI, 2 / ex) + cx;
          y = ry * pow(sinI, 2 / ey) + cy;
          CGPathAddLineToPoint(path, nil, x, y);
        }

        rx = cornerRadius.topLeft.width;
        ry = cornerRadius.topLeft.height;
        cx = left + rx;
        cy = top + ry;
        for (float i = M_PI; i < 1.5 * M_PI; i += 0.01) {
          cosI = cos(i);
          sinI = sin(i);
          x = -rx * pow(-cosI, 2 / ex) + cx;
          y = -ry * pow(-sinI, 2 / ey) + cy;
          CGPathAddLineToPoint(path, nil, x, y);
        }

        rx = cornerRadius.topRight.width;
        ry = cornerRadius.topRight.height;
        cx = right - rx;
        cy = top + ry;
        for (float i = 1.5 * M_PI; i < 2 * M_PI; i += 0.01) {
          cosI = cos(i);
          sinI = sin(i);
          x = rx * pow(cosI, 2 / ex) + cx;
          y = -ry * pow(-sinI, 2 / ey) + cy;
          CGPathAddLineToPoint(path, nil, x, y);
        }
        CGPathCloseSubpath(path);
        break;
      }
      default:
        CGPathAddRect(path, NULL, innerBounds);
        break;
    }
  }
  return path;
}
