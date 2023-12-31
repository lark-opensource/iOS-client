/**
 * @file AMGRect.h
 * @author fanjiaqi (fanjiaqi.837@bytedance.com)
 * @brief Defination of rectangle .
 * @version 0.1
 * @date 2019-12-05
 * 
 * @copyright Copyright (c) 2019
 * 
 */
#ifndef RECT_H
#define RECT_H

#include "Gaia/Math/AMGVector2.h"

NAMESPACE_AMAZING_ENGINE_BEGIN

/**
 * @brief Rect is the class to describe a rectangle.
 * 
 */
class GAIA_LIB_EXPORT Rect
{
public:
    /**
     * @brief Rect type.
     * 
     */
    typedef Rect RectType;
    /**
     * @brief The type of value in rect.
     * 
     */
    typedef float BaseType;
    /**
     * @brief Rectangle x coordinate.
     * 
     */
    BaseType x = 0.f;
    /**
     * @brief Rectangle y coordinate.
     * 
     */
    BaseType y = 0.f;
    /**
     * @brief Rectangle width.
     * 
     */
    BaseType width = 0.f;
    /**
     * @brief Rectangle height.
     * 
     */
    BaseType height = 0.f;

#define TRANSFER(x) (x = rect.x)
    /**
     * @brief Transfer the attributes of other rectangle to current rectangle.
     * 
     * @param rect Other rectangle.
     */
    void Transfer(Rect& rect)
    {
        TRANSFER(x);
        TRANSFER(y);
        TRANSFER(width);
        TRANSFER(height);
    }

    /**
     * @brief Construct an empty rectangle.
     */
    Rect()
    {
        Reset();
    }

    /**
     * @brief Construct a rectangle with attributes.
     * 
     * @param inX Rectangle x coordinate, left border.
     * @param inY Rectangle y coordinate, bottom border.
     * @param iWidth Rectangle width.
     * @param iHeight Rectangle height.
     */
    Rect(BaseType inX, BaseType inY, BaseType iWidth, BaseType iHeight)
    {
        x = inX;
        width = iWidth;
        y = inY;
        height = iHeight;
    }

    /**
     * @brief Gets a pointer to the first address of member
     *
     * @return Returns a pointer to the first address of member
     */
    float* GetPtr() { return &x; }

    /**
     * @brief Gets a pointer to the first address of member
     *
     * @return Returns a pointer to the first address of member
     */
    const float* GetPtr() const { return &x; }

    /**
     * @brief Get the Left border of rectangle.
     * 
     * @return BaseType Left border of current rectangle.
     */
    BaseType GetLeft() const { return x; }

    /**
     * @brief Get the Right border of rectangle.
     * 
     * @return BaseType Right border of current rectangle.
     */
    BaseType GetRight() const { return x + width; }

    /**
     * @brief Get the Bottom border of rectangle.
     * 
     * @return BaseType Bottom border of current rectangle.
     */
    BaseType GetBottom() const { return y; }

    /**
     * @brief Get the Top border of rectangle.
     * 
     * @return BaseType Top border of current rectangle.
     */
    BaseType GetTop() const { return y + height; }

    /**
     * @brief Set the Left border of rectangle.
     * 
     * @param l The left border set to current rectangle.
     */
    void SetLeft(BaseType l)
    {
        BaseType oldRight = GetRight();
        x = l;
        width = oldRight - x;
    }

    /**
     * @brief Set the Bottom border of rectangle.
     * 
     * @param t The bottom border set to current rectangle.
     */
    void SetBottom(BaseType t)
    {
        BaseType oldTop = GetTop();
        y = t;
        height = oldTop - y;
    }

    /**
     * @brief Set the Right border of rectangle.
     * 
     * @param r The right border set to current rectangle.
     */
    void SetRight(BaseType r) { width = r - x; }

    /**
     * @brief Set the Top border of rectangle.
     * 
     * @param b The top border set to current rectangle.
     */
    void SetTop(BaseType b) { height = b - y; }

    /**
     * @brief Get the max x coordinate value inside current rectangle.
     * 
     * @return BaseType The max x coordinate value inside current rectangle.
     */
    BaseType GetXMax() const { return x + width; }

    /**
     * @brief Get the max y coordinate value inside current rectangle.
     * 
     * @return BaseType The max y coordinate value inside current rectangle.
     */
    BaseType GetYMax() const { return y + height; }

    /**
     * @brief Judge if the rectangle is empty.
     * 
     * @return true Current rectangle is empty.
     * @return false Current rectangle is not empty.
     */
    inline bool IsEmpty() const { return width <= 0 || height <= 0; }

    /**
     * @brief Set left-bottom position of current rectangle.
     * 
     * @param position The left-bottom position set to current rectangle.
     */
    inline void SetPosition(const Vector2f& position)
    {
        x = position.x;
        y = position.y;
    }

    /**
     * @brief Get left-bottom position of current rectangle.
     * 
     * @return Vector2f The left-bottom position of current rectangle.
     */
    inline Vector2f GetPosition() const { return Vector2f(x, y); }

    /**
     * @brief Set the size to current rectangle.
     * 
     * @param size The size set to current rectangle.
     */
    inline void SetSize(const Vector2f& size)
    {
        width = size.x;
        height = size.y;
    }

    /**
     * @brief Get the size of current rectangle.
     * 
     * @return Vector2f The size of current rectangle.
     */
    inline Vector2f GetSize() const { return Vector2f(width, height); }

    /**
     * @brief Reset current rectangle to empty rectangle.
     * 
     */
    inline void Reset() { x = y = width = height = 0; }

    /**
     * @brief Set current rectangle attributes.
     * 
     * @param inX Rectangle x coordinate, left border.
     * @param inY Rectangle y coordinate, bottom border.
     * @param iWidth Rectangle width.
     * @param iHeight Rectangle height.
     */
    inline void Set(BaseType inX, BaseType inY, BaseType iWidth, BaseType iHeight)
    {
        x = inX;
        width = iWidth;
        y = inY;
        height = iHeight;
    }

    /**
     * @brief Scale current reactangle.
     * 
     * @param dx Scaling factor in X direction.
     * @param dy Scaling factor in Y direction.
     */
    inline void Scale(BaseType dx, BaseType dy)
    {
        x *= dx;
        width *= dx;
        y *= dy;
        height *= dy;
    }

    /**
     * @brief Set the center point of current rectangle.
     * 
     * @param cx X coordinate of center point.
     * @param cy Y coordinate of center point.
     */
    void SetCenterPos(BaseType cx, BaseType cy)
    {
        x = cx - width / 2;
        y = cy - height / 2;
    }

    /**
     * @brief Get the center point of current rectangle.
     * 
     * @return Vector2f The center point of current rectangle.
     */
    Vector2f GetCenterPos() const { return Vector2f(x + (BaseType)width / 2, y + (BaseType)height / 2); }

    /**
     * @brief Set current rectangle to common rectangular region of current rectangle and r.
     * 
     * @param r Input rectangle r.
     */
    void Clamp(const RectType& r)
    {
        BaseType x2 = x + width;  // right
        BaseType y2 = y + height; // top

        BaseType rx2 = r.x + r.width;  //r right
        BaseType ry2 = r.y + r.height; //r top

        if (x < r.x)
            x = r.x;

        if (x2 > rx2)
            x2 = rx2;

        if (y < r.y)
            y = r.y;

        if (y2 > ry2)
            y2 = ry2;

        width = x2 - x;

        if (width < 0)
            width = 0;

        height = y2 - y;

        if (height < 0)
            height = 0;
    }

    /**
     * @brief Move rectangle by deltaX, deltaY.
     * 
     * @param dX Move distance in X direction.
     * @param dY Move distance in Y direction.
     */
    inline void Move(BaseType dX, BaseType dY)
    {
        x += dX;
        y += dY;
    }

    /**
     * @brief Return the width of rectangle.
     * 
     * @return BaseType The width of current rectangle.
     */
    inline BaseType Width() const { return width; }

    /**
     * @brief Return the height of rectangle.
     * 
     * @return BaseType The height of current rectangle.
     */
    inline BaseType Height() const { return height; }

    /**
     * @brief Return true if a point lies within rectangle bounds.
     * 
     * @param px Value of x coordinate of point.
     * @param py Value of y coordinate of point.
     * @return true The point lies within the rectangle bounds.
     * @return false The point lies outside the rectangle bounds.
     */
    inline bool Contains(BaseType px, BaseType py) const { return (px >= x) && (px < x + width) && (py >= y) && (py < y + height); }

    /**
     * @brief Return true if a point lies within rectangle bounds.
     * 
     * @param p The position of point.
     * @return true The point lies within the rectangle boounds.
     * @return false The point lies outside the rectangle bounds.
     */
    inline bool Contains(const Vector2f& p) const { return Contains(p.x, p.y); }

    /**
     * @brief Return true if a relative point lies within rectangle bounds.
     * The value of point is relative to the left-bottom of rectangle.
     * @param x Value of X coordinate of relative point.
     * @param y Value of Y coordinate of relative point.
     * @return true The relative point lies within rectangle bounds.
     * @return false The relative point lies outside rectangle bounds.
     */
    inline bool ContainsRel(BaseType x, BaseType y) const
    {
        return (x >= 0) && (x < Width()) && (y >= 0) && (y < Height());
    }

    /**
     * @brief Judge whether current rectangle intersects to r.
     * 
     * @param r Rectangle to compare.
     * @return true Current rectangle intersects to r.
     * @return false Current rectangle does not intersect to r.
     */
    inline bool Intersects(const RectType& r) const
    {
        // Rects are disjoint if there's at least one separating axis
        bool disjoint = x + width < r.x;
        disjoint |= r.x + r.width < x;
        disjoint |= y + height < r.y;
        disjoint |= r.y + r.height < y;
        return !disjoint;
    }

    /**
     * @brief Normalize a rectangle such that xmin <= xmax and ymin <= ymax.
     * 
     */
    inline void Normalize()
    {
        width = std::max<BaseType>(width, 0);
        height = std::max<BaseType>(height, 0);
    }

    /**
     * @brief Overload operator==, judge whether current rectangle equals to rectangle r.
     * 
     * @param r Other rectangle to compare.
     * @return true Current rectangle equals to r.
     * @return false Current rectangle does not equal to r.
     */
    bool operator==(const RectType& r) const { return x == r.x && y == r.y && width == r.width && height == r.height; }

    /**
     * @brief Overload operator!=, judge whether current rectangle does not equal to r.
     * 
     * @param r Other rectangle to compare.
     * @return true Current rectangle does not equal to r.
     * @return false Current rectangle equals to r.
     */
    bool operator!=(const RectType& r) const { return x != r.x || y != r.y || width != r.width || height != r.height; }
};

/**
 * @brief Compare wthether two rectangles equal to each other.
 * 
 * @param lhs Input rectangle1.
 * @param rhs Input rectangle2.
 * @return true Input two rectangles equal to each other.
 * @return false Input teo rectangles do not equal to each other.
 */
inline bool CompareApproximately(const Rect& lhs, const Rect& rhs)
{
    return CompareApproximately(lhs.x, rhs.x) && CompareApproximately(lhs.y, rhs.y) &&
           CompareApproximately(lhs.width, rhs.width) && CompareApproximately(lhs.height, rhs.height);
}

NAMESPACE_AMAZING_ENGINE_END

#endif
