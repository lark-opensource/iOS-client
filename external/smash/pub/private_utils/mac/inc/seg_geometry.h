//
//  seg_geometry.h
//  smash_algo-private_utils
//
//  Created by liqing on 2020/9/10.
//

#ifndef seg_geometry_h
#define seg_geometry_h

SMASH_NAMESPACE_OPEN
NAMESPACE_OPEN(private_utils)

const double kDPI = CV_PI;
const uchar kGray = 128;

//两点是否重合
template <typename T1, typename T2>
inline bool isOverlap(const Point2D(T1) & p1, const Point2D(T2) & p2) {
  return (p1.x == p2.x) && (p1.y == p2.y);
}
//是否为空线段(起点与终点重合) 可以认为是一个线段退化而成的点
template <typename T>
inline bool isEmpty(const Segment2D(T) & seg) {
  return isOverlap(seg.first, seg.second);
}

//根据比例获得线段上某点, s=0时返回起点, s=1时返回终点
template <typename T, typename ScaleT, typename T0>
    inline Point2D(T0) & pointByScale(const Point2D(T) & sp,
                                      const Point2D(T) & ep,
                                      Point2D(T0) & p0,
                                      const ScaleT s) {
  p0.x = sp.x * (1 - s) + ep.x * s;
  p0.y = sp.y * (1 - s) + ep.y * s;
  return p0;
}
template <typename T, typename ScaleT, typename T0>
    inline Point2D(T0) &
    pointByScale(const Segment2D(T) & seg, Point2D(T0) & p0, const ScaleT s) {
  return pointByScale(seg.first, seg.second, p0, s);
}
//线段中点
template <typename T, typename T0>
    inline Point2D(T0) &
    midPoint(const Point2D(T) & sp, const Point2D(T) & ep, Point2D(T0) & p0) {
  return pointByScale(sp, ep, p0, 0.5);
}
template <typename T, typename T0>
    inline Point2D(T0) & midPoint(const Segment2D(T) & seg, Point2D(T0) & p0) {
  return midPoint(seg.first, seg.second, p0);
}

// 以当前线段方向为x轴方向单位向量,
// 当前线段逆时针旋转90度后的向量为y轴方向单位向量,获得新的点 注意:
// 图像坐标系y方向为从上到下, 与通常坐标系相反, 因此注意y的符号问题
template <typename T, typename T0, typename CoordT>
    inline Point2D(T0) & pointAsAxis(const Point2D(T) & sp,
                                     const Point2D(T) & ep,
                                     Point2D(T0) & p0,
                                     const CoordT x,
                                     const CoordT y) {
  Point2D(T) cp = ep - sp;
  // 相当于线段AB先绕A点逆时针旋转而成为AC作为Y轴,AB为X轴
  p0.x = sp.x + x * cp.x - y * cp.y;
  p0.y = sp.y + x * cp.y + y * cp.x;
  return p0;
}
template <typename T, typename T0, typename CoordT>
    inline Point2D(T0) & pointAsAxis(const Segment2D(T) & seg,
                                     Point2D(T0) & p0,
                                     const CoordT x,
                                     const CoordT y) {
  return pointAsAxis(seg.first, seg.second, p0, x, y);
}

// 以sp为原心, sp->xp为单位x向量, sp->yp为单位y向量,
// 得到输入点p0在坐标轴上对应的x,y值
template <typename T, typename T0>
inline bool pointToAxisCoord(const Point2D(T) & sp,
                             const Point2D(T) & xp,
                             const Point2D(T) & yp,
                             const Point2D(T0) & p0,
                             double& x,
                             double& y) {
  Point2D(T) A = xp - sp;
  Point2D(T) B = yp - sp;
  T k = A.x * B.y - A.y * B.x;
  if (k == 0) {
    return false;
  } else {
    Point2D(double) p = p0 - sp;
    x = (double)(p.x * B.y - p.y * B.x) / k;
    y = (double)(p.y * A.x - p.x * A.y) / k;
    return true;
  }
}

////////distance//////////////////////////////////

//两点距离的平方 (不用进行根号运算 在距离大小判断时更准确)
template <typename T1, typename T2>
inline double distanceSquare(const Point2D(T1) & p1, const Point2D(T2) & p2) {
  double dx = p1.x - p2.x;
  double dy = p1.y - p2.y;
  return dx * dx + dy * dy;
}
//两点距离
template <typename T1, typename T2>
inline double distance(const Point2D(T1) & p1, const Point2D(T2) & p2) {
  double dx = p1.x - p2.x;
  double dy = p1.y - p2.y;
  return std::sqrt(dx * dx + dy * dy);
}
//返回线段长度
template <typename T>
inline double length(const Segment2D(T) & seg) {
  return distance(seg.first, seg.second);
}

////////relationship//////////////////////////////////

//点p0在sp,ep构成直线的哪一边,用0和±1表示,左手方向为正
template <typename T, typename T0>
inline int pointSide(const Point2D(T) & sp,
                     const Point2D(T) & ep,
                     const Point2D(T0) & p0) {
  double cross = (ep.x - sp.x) * (p0.y - sp.y) - (ep.y - sp.y) * (p0.x - sp.x);
  return (cross > 0) - (cross < 0);
}
//点p在直线的哪一边,同上
template <typename T1, typename T2>
inline int pointSide(const Segment2D(T1) & seg, const Point2D(T2) & p) {
  return pointSide(seg.first, seg.second, p);
}

//计算两条线段的是否平行 (所在直线不相交不共线,根据定义空线段一定不平行)
template <typename T1, typename T2>
inline bool isParallel(const Segment2D(T1) & seg1, const Segment2D(T2) & seg2) {
  double a1 = seg1.second.x - seg1.first.x;
  double b1 = seg2.first.x - seg2.second.x;
  double c1 = seg2.first.x - seg1.first.x;

  double a2 = seg1.second.y - seg1.first.y;
  double b2 = seg2.first.y - seg2.second.y;
  double c2 = seg2.first.y - seg1.first.y;

  return (a1 * b2 == a2 * b1) && (a1 * c2 != a2 * c1);  //!浮点相等判断
}
//计算当前线段与输入线段的是否垂直 (空线段与任意线段皆垂直)
template <typename T1, typename T2>
inline bool isVertical(const Segment2D(T1) & seg1, const Segment2D(T2) & seg2) {
  double a1 = seg1.second.x - seg1.first.x;
  double b1 = seg2.second.x - seg2.first.x;

  double a2 = seg1.second.y - seg1.first.y;
  double b2 = seg2.second.y - seg2.first.y;

  return (a1 * a2 + b1 * b2) == 0;  //!浮点相等判断
}
//计算点到当前线段的垂足
//如果点在线段上则返回true, 否则返回false(此时返回的fp为点到直线的垂足)
//对于空线段,垂足为空线段对应的点
template <typename T1, typename T2, typename T0>
inline bool footPoint(const Segment2D(T1) & seg,
                      const Point2D(T2) & p,
                      Point2D(T0) & fp) {
  if (isEmpty(seg)) {
    fp = seg.first;
    return true;
  }

  double a = seg.second.x - seg.first.x;
  double b = seg.second.y - seg.first.y;
  //在isEmpty() != 0时 a*a+b*b != 0
  double k =
      (a * (p.x - seg.first.x) + b * (p.y - seg.first.y)) / (a * a + b * b);
  pointByScale(seg, fp, k);

  if (k >= 0 && k <= 1) {
    return true;
  } else {
    return false;
  }
}

//计算当前线段与输入线段的<!所在直线!>的交点, 对于空线段也能正确处理
//注意判断返回值是否为true, 此时的输出值ip才有意义!
template <typename T1, typename T2, typename T0>
inline bool lineIntersectionPoint(const Segment2D(T1) & seg1,
                                  const Segment2D(T2) & seg2,
                                  Point2D(T0) & ip) {
  double a1 = seg1.second.x - seg1.first.x;
  double b1 = seg2.first.x - seg2.second.x;
  double c1 = seg2.first.x - seg1.first.x;

  double a2 = seg1.second.y - seg1.first.y;
  double b2 = seg2.first.y - seg2.second.y;
  double c2 = seg2.first.y - seg1.first.y;

  double k = a1 * b2 - a2 * b1;
  if (k == 0) {
    return false;
  } else {
    double m = (b2 * c1 - b1 * c2) / k;
    pointByScale(seg1, ip, m);
    return true;
  }
}

//计算当前线段与输入线段的交点<注意与lineIntersectionPoint()区别>,
//对于空线段也能正确处理 注意判断返回值是否为true, 此时的输出值ip才有意义!
template <typename T1, typename T2, typename T0>
inline bool segmentIntersectionPoint(const Segment2D(T1) & seg1,
                                     const Segment2D(T2) & seg2,
                                     Point2D(T0) & ip) {
  double a1 = seg1.second.x - seg1.first.x;
  double b1 = seg2.first.x - seg2.second.x;
  double c1 = seg2.first.x - seg1.first.x;

  double a2 = seg1.second.y - seg1.first.y;
  double b2 = seg2.first.y - seg2.second.y;
  double c2 = seg2.first.y - seg1.first.y;

  double k = a1 * b2 - a2 * b1;
  double d = a1 * c2 - a2 * c1;
  if (k == 0) {
    if (d == 0) {
      Point2D(double) cp;
      midPoint(seg1, cp);
      double r2 = distanceSquare(seg1.first, seg1.second) / 4;
      double d2_seg_sp = distanceSquare(cp, seg2.first);
      double d2_seg_ep = distanceSquare(cp, seg2.second);
      if (d2_seg_sp > r2 && d2_seg_ep > r2) {
        return false;
      } else if (d2_seg_sp <= r2 && d2_seg_ep <= r2) {
        midPoint(seg2, ip);
        return true;
      } else {
        Point2D(T2) outp, inp;
        if (d2_seg_sp > r2) {
          outp = seg2.first;
          inp = seg2.second;
        } else {
          outp = seg2.second;
          inp = seg2.first;
        }

        double d2_outp_sp = distanceSquare(outp, seg1.first);
        double d2_outp_ep = distanceSquare(outp, seg1.second);

        Segment2D(T1) interSeg;
        if (d2_outp_sp < d2_outp_ep) {
          interSeg = Segment2D(T1)(seg1.first, inp);
        } else {
          interSeg = Segment2D(T1)(seg1.second, inp);
        }

        midPoint(interSeg, ip);
        return true;
      }
    } else {
      return false;
    }
  } else {
    double m = (b2 * c1 - b1 * c2) / k;
    double n = d / k;
    if (m >= 0 && m <= 1 && n >= 0 && n <= 1) {
      pointByScale(seg1, ip, m);
      return true;
    } else {
      return false;
    }
  }
}

////////Angle//////////////////////////////////

//// angle
enum AngleUnit { DEGREE, RADIAN };
const double kRad2Degree = 180.0 / kDPI;
const double kDegree2Rad = 1.0 / kRad2Degree;

//获得以弧度为单位的角度值
template <typename AngleT>
inline double radian(const AngleUnit unit, const AngleT ang) {
  if (unit == DEGREE) {
    return ang * kDegree2Rad;
  } else {
    return (double)ang;
  }
}
//角度单位换算, 返回以新单位为标准的角度值
template <typename AngleT>
inline double convertAngle(const AngleUnit unit,
                           const AngleT ang,
                           const AngleUnit unit_new) {
  if (unit_new == unit) {
    return ang;
  } else if (unit_new == RADIAN) {
    return ang * kDegree2Rad;
  } else {
    return ang * kRad2Degree;
  }
}

//两点角度: sp -> ep 方向
template <typename T1, typename T2>
inline double angle(const AngleUnit unit,
                    const Point2D(T1) & sp,
                    const Point2D(T2) & ep) {
  double ang = std::atan2(ep.y - sp.y, ep.x - sp.x);
  return convertAngle(RADIAN, ang, unit);
}
//单点角度: (0,0) -> p 方向
template <typename T>
inline double angle(const AngleUnit unit, const Point2D(T) & p) {
  double ang = std::atan2(p.y, p.x);
  return convertAngle(RADIAN, ang, unit);
}
//线段角度
template <typename T>
inline double angle(const AngleUnit unit, const Segment2D(T) & seg) {
  return angle(unit, seg.first, seg.second);
}
//从当前线段到输入线段的旋转角度
template <typename T1, typename T2>
inline double angle(const AngleUnit unit,
                    const Segment2D(T1) & seg1,
                    const Segment2D(T2) & seg2) {
  if (isEmpty(seg1) || isEmpty(seg2)) return 0.0;

  double ang_src = angle(RADIAN, seg1);
  double ang_dst = angle(RADIAN, seg2);
  double ang = ang_dst - ang_src;

  if (ang < -kDPI) {
    ang += kDPI;
  } else if (ang > kDPI) {
    ang -= kDPI;
  }
  return convertAngle(RADIAN, ang, unit);
}

//三点sp,ep关于p0的夹角余弦值 值范围为[-1,1]
template <typename T1, typename T2, typename T0>
inline double intersectionCosine(const Point2D(T1) & sp,
                                 const Point2D(T2) & ep,
                                 const Point2D(T0) & p0) {
  double dx1 = sp.x - p0.x;
  double dy1 = sp.y - p0.y;
  double dx2 = ep.x - p0.x;
  double dy2 = ep.y - p0.y;

  double tp = (dx1 * dx1 + dy1 * dy1) * (dx2 * dx2 + dy2 * dy2);
  if (tp <= 0.0) {
    return 0.0;
  } else {
    return (dx1 * dx2 + dy1 * dy2) / std::sqrt(tp);
  }
}
//三点sp,ep关于p0的夹角 值范围为[0,180]度
template <typename T1, typename T2, typename T0>
inline double intersectionAngle(const Point2D(T1) & sp,
                                const Point2D(T2) & ep,
                                const Point2D(T0) & p0,
                                const AngleUnit unit) {
  return convertAngle(RADIAN, std::acos(intersectionCosine(sp, ep, p0)), unit);
}

////////translate//////////////////////////////////

//点平移
template <typename T, typename ShiftT>
    inline Point2D(T) &
    translate(Point2D(T) & p, const Point2D(ShiftT) & shift) {
  p.x += shift.x;
  p.y += shift.y;
  return p;
}
//多点平移
template <typename T, typename ShiftT>
    inline Point2DArray(T) &
    translate(Point2DArray(T) & pa, const Point2D(ShiftT) & shift) {
  for (typename Point2DArray(T)::iterator iter = pa.begin(); iter != pa.end();
       ++iter)
    translate(*iter, shift);
  return pa;
}
//线段平移
template <typename T, typename ShiftT>
    inline Segment2D(T) &
    translate(Segment2D(T) & seg, const Point2D(ShiftT) & shift) {
  translate(seg.first, shift);
  translate(seg.second, shift);
  return seg;
}

template <typename T, typename ShiftT>
inline Point2D(T) operator+(const Point2D(T) & p,
                            const Point2D(ShiftT) & shift) {
  Point2D(T) outp(p);
  return translate(outp, shift);
}
template <typename T, typename ShiftT>
inline Point2DArray(T) operator+(const Point2DArray(T) & pa,
                                 const Point2D(ShiftT) & shift) {
  Point2DArray(T) outpa(pa);
  return translate(outpa, shift);
}
template <typename T, typename ShiftT>
inline Segment2D(T) operator+(const Segment2D(T) & seg,
                              const Point2D(ShiftT) & shift) {
  Segment2D(T) outseg(seg);
  return translate(outseg, shift);
}
template <typename T, typename ShiftT>
inline Point2D(T) operator-(const Point2D(T) & p,
                            const Point2D(ShiftT) & shift) {
  Point2D(T) outp(p);
  return translate(outp, -shift);
}
template <typename T, typename ShiftT>
inline Point2DArray(T) operator-(const Point2DArray(T) & pa,
                                 const Point2D(ShiftT) & shift) {
  Point2DArray(T) outpa(pa);
  return translate(outpa, -shift);
}
template <typename T, typename ShiftT>
inline Segment2D(T) operator-(const Segment2D(T) & seg,
                              const Point2D(ShiftT) & shift) {
  Segment2D(T) outseg(seg);
  return translate(outseg, -shift);
}

////////Rotate//////////////////////////////////

//点绕原心旋转
template <typename T, typename AngleT>
inline void rotate(Point2D(T) & p, const AngleUnit unit, const AngleT ang) {
  double rad = radian(unit, ang);
  double sin_ang = std::sin(rad);
  double cos_ang = std::cos(rad);

  Point2D(T) p0(p);
  p.x = p0.x * cos_ang - p0.y * sin_ang;
  p.y = p0.x * sin_ang + p0.y * cos_ang;
}
//点绕指定点旋转
template <typename T, typename OriginT, typename AngleT>
inline void rotate(Point2D(T) & p,
                   const Point2D(OriginT) & op,
                   const AngleUnit unit,
                   const AngleT ang) {
  Point2D(T) sup(-op.x, -op.y);
  translate(p, sup);
  rotate(p, unit, ang);
  translate(p, op);
}
//多点绕原点旋转
template <typename T, typename AngleT>
inline void rotate(Point2DArray(T) & pa,
                   const AngleUnit unit,
                   const AngleT ang) {
  for (typename Point2DArray(T)::iterator iter = pa.begin(); iter != pa.end();
       ++iter)
    rotate(*iter, unit, ang);
}
//多点绕指定点旋转
template <typename T, typename OriginT, typename AngleT>
inline void rotate(Point2DArray(T) & pa,
                   const Point2D(OriginT) & op,
                   const AngleUnit unit,
                   const AngleT ang) {
  for (typename Point2DArray(T)::iterator iter = pa.begin(); iter != pa.end();
       ++iter)
    rotate(*iter, op, unit, ang);
}
//线段绕原点旋转
template <typename T, typename AngleT>
inline void rotate(Segment2D(T) & seg, const AngleUnit unit, const AngleT ang) {
  rotate(seg.first, unit, ang);
  rotate(seg.second, unit, ang);
}
//线段绕指定点旋转
template <typename T, typename OriginT, typename AngleT>
inline void rotate(Segment2D(T) & seg,
                   const Point2D(OriginT) & op,
                   const AngleUnit unit,
                   const AngleT ang) {
  rotate(seg.first, op, unit, ang);
  rotate(seg.second, op, unit, ang);
}

////////Scale//////////////////////////////////

//点绕原心缩放
template <typename T, typename ScaleT>
    inline Point2D(T) & scale(Point2D(T) & p, const ScaleT s) {
  p.x *= s;
  p.y *= s;
  return p;
}
//点绕指定点缩放
template <typename T, typename OriginT, typename ScaleT>
    inline Point2D(T) &
    scale(Point2D(T) & p, const Point2D(OriginT) & op, const ScaleT s) {
  Point2D(T) sup(-op.x, -op.y);
  translate(p, sup);
  scale(p, s);
  translate(p, op);
  return p;
}
//多点绕原点缩放
template <typename T, typename ScaleT>
    inline Point2DArray(T) & scale(Point2DArray(T) & pa, const ScaleT s) {
  for (typename Point2DArray(T)::iterator iter = pa.begin(); iter != pa.end();
       ++iter)
    scale(*iter, s);
  return pa;
}
//多点绕指定点缩放
template <typename T, typename OriginT, typename ScaleT>
    inline Point2DArray(T) &
    scale(Point2DArray(T) & pa, const Point2D(OriginT) & op, const ScaleT s) {
  for (typename Point2DArray(T)::iterator iter = pa.begin(); iter != pa.end();
       ++iter)
    scale(*iter, op, s);
  return pa;
}
//线段绕原点缩放
template <typename T, typename ScaleT>
    inline Segment2D(T) & scale(Segment2D(T) & seg, const ScaleT s) {
  scale(seg.first, s);
  scale(seg.second, s);
  return seg;
}
//线段绕指定点缩放
template <typename T, typename OriginT, typename ScaleT>
    inline Segment2D(T) &
    scale(Segment2D(T) & seg, const Point2D(OriginT) & op, const ScaleT s) {
  scale(seg.first, op, s);
  scale(seg.second, op, s);
  return seg;
}

template <typename T, typename ScaleT>
inline Point2D(T) operator*(const Point2D(T) & p, const ScaleT s) {
  Point2D(T) outp(p);
  return scale(outp, s);
}
template <typename T, typename ScaleT>
inline Point2DArray(T) operator*(const Point2DArray(T) & pa, const ScaleT s) {
  Point2DArray(T) outpa(pa);
  return scale(outpa, s);
}
template <typename T, typename ScaleT>
inline Segment2D(T) operator*(const Segment2D(T) & seg, const ScaleT s) {
  Segment2D(T) outseg(seg);
  return scale(outseg, s);
}

////////Centroid//////////////////////////////////

//多点质心
template <typename T>
inline Point2D(T) centroid(const Point2DArray(T) & pa) {
  Point2D(T) cp(0, 0);
  for (typename Point2DArray(T)::const_iterator iter = pa.begin();
       iter != pa.end(); ++iter)
    cp += (*iter);
  cp.x /= (int)pa.size();
  cp.y /= (int)pa.size();
  return cp;
}
//多点根据质心缩放
template <typename T, typename ScaleT>
    inline Point2DArray(T) &
    scaleByCentroid(Point2DArray(T) & pa, const ScaleT s) {
  Point2D(double) cp = centroid(pa);
  return scale(pa, cp, s);
}
//多点根据质心旋转
template <typename T, typename AngleT>
    inline Point2DArray(T) & rotateByCentroid(Point2DArray(T) & pa,
                                              const AngleUnit unit,
                                              const AngleT ang) {
  Point2D(double) cp = centroid(pa);
  ;
  return rotate(pa, cp, unit, ang);
}

NAMESPACE_CLOSE(private_utils)
SMASH_NAMESPACE_CLOSE

#endif /* seg_geometry_h */
