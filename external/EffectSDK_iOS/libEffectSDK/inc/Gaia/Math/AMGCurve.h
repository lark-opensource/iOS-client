#pragma once

#include "Gaia/Math/AMGVector2.h"
#include "Gaia/Math/AMGVector3.h"

#include <vector>

NAMESPACE_AMAZING_ENGINE_BEGIN

template <int N>
class CubicCurve
{
public:
    static_assert(N == 2 || N == 3, "Only 2 and 3-dimensional curves are supported");
    using VecT = std::conditional_t<N == 2, Vector2f, Vector3f>;

    CubicCurve(const VecT& start,
               const VecT& end,
               const VecT& c0,
               const VecT& c1);

    VecT const& start() const;
    VecT const& end() const;

    VecT interp(float t) const;
    VecT tangent(float t) const;

private:
    VecT m_p0, m_p1; // anchor points
    VecT m_c0, m_c1; // control points
};

template <int N>
class QuadraticCurve
{
public:
    static_assert(N == 2 || N == 3, "Only 2 and 3-dimensional curves are supported");
    using VecT = std::conditional_t<N == 2, Vector2f, Vector3f>;

    QuadraticCurve(const VecT& start, const VecT& end, const VecT& c0);

    VecT interp(float t) const;
    VecT tangent(float t) const;

private:
    VecT m_p0, m_p1; // anchor points
    VecT m_c0;       // control points
};

template <class Curve>
std::vector<class Curve::VecT> uniformCurveSample(const Curve&,
                                                  int segs = 0);

template <class Curve, class VecT = typename Curve::VecT>
std::vector<VecT> adaptiveCurveSample(const Curve&,
                                      float thres,
                                      float start,
                                      float end);

template <class Curve, class VecT = typename Curve::VecT>
std::vector<VecT> adaptiveCurveSample(const Curve&, float thres = 0.9f);

// -------------------------------------------------------------------
// --------- Implementation ------------------------------------------

template <int N>
CubicCurve<N>::CubicCurve(const VecT& start,
                          const VecT& end,
                          const VecT& c0,
                          const VecT& c1)
    : m_p0(start)
    , m_p1(end)
    , m_c0(c0)
    , m_c1(c1){};

template <int N>
auto CubicCurve<N>::start() const -> const VecT&
{
    return m_p0;
}
template <int N>
auto CubicCurve<N>::end() const -> const VecT&
{
    return m_p1;
}

template <int N>
auto CubicCurve<N>::interp(float t) const -> VecT
{
    float r = 1 - t;
    float r2 = r * r;
    float t2 = t * t;
    return m_p0 * r2 * r + 3.0f * m_c0 * r2 * t + 3.0f * m_c1 * t2 * r +
           m_p1 * t2 * t;
}

template <int N>
auto CubicCurve<N>::tangent(float t) const -> VecT
{
    float r = 1.0f - t;
    float r2 = r * r;
    float t2 = t * t;
    return m_p0 * -3.0f * r2 + 3.0f * m_c0 * (r2 - 2.0f * r * t) +
           3.0f * m_c1 * (2.0f * r * t - t2) + 3.0f * m_p1 * t2;
}

template <int N>
QuadraticCurve<N>::QuadraticCurve(const VecT& start,
                                  const VecT& end,
                                  const VecT& c0)
    : m_p0(start)
    , m_p1(end)
    , m_c0(c0){};

template <int N>
auto QuadraticCurve<N>::interp(float t) const -> VecT
{
    float r = 1 - t;
    return m_p0 * r * r + m_c0 * r * t * 2.0f + m_p1 * t * t;
}

template <int N>
auto QuadraticCurve<N>::tangent(float t) const -> VecT
{
    return m_p0 * (2 * t - 2) + m_c0 * (2 - 4 * t) + m_p1 * 2 * t;
}

template <class Curve>
std::vector<class Curve::VecT> uniformCurveSample(const Curve& curve,
                                                  int segs)
{
    std::vector<class Curve::VecT> res;
    res.reserve(segs + 2);
    res.emplace_back(curve.interp(0.0f));
    for (int i = 0; i < segs; ++i)
    {
        res.emplace_back(curve.interp(i / static_cast<float>(segs + 1)));
    }
    res.emplace_back(curve.interp(1.0f));
}

template <class Curve, class VecT>
std::vector<VecT> adaptiveCurveSample(const Curve& curve,
                                      float thres,
                                      float start,
                                      float end)
{
    float mid = 0.5f * (start + end);

    auto pStart = curve.interp(start);
    auto pMid = curve.interp(mid);
    auto pEnd = curve.interp(end);

    if (Magnitude(pEnd - pStart) < 1e-6)
        return {pEnd};

    float ang = Dot(NormalizeSafe(pMid - pStart), NormalizeSafe(pEnd - pMid));
    if (ang < thres)
    {
        auto res = adaptiveCurveSample(curve, thres, start, mid);
        auto tail = adaptiveCurveSample(curve, thres, mid, end);
        res.insert(res.end(),
                   std::make_move_iterator(tail.begin()),
                   std::make_move_iterator(tail.end()));
        return res;
    }
    else
    {
        return {pMid, pEnd};
    }
}

template <class Curve, class VecT>
std::vector<VecT> adaptiveCurveSample(const Curve& curve, float thres)
{
    thres = std::min(0.99f, thres);
    return adaptiveCurveSample<Curve>(curve, thres, 0.0f, 1.0f);
}

NAMESPACE_AMAZING_ENGINE_END
