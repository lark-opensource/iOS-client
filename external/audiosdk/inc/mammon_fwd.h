// NOTE: This file has been copied from mammon_engine as a short term
//       fix for resource io while we wait for the shared fileio library
//       to be developed. PNC 20200520
//
/*
    fwd.h -- Forward declarations for path.h and resolver.h

    Copyright (c) 2015 Wenzel Jakob <wenzel@inf.ethz.ch>

    All rights reserved. Use of this source code is governed by a
    BSD-style license that can be found in the LICENSE file.
*/

#pragma once

#if !defined(NAMESPACE_BEGIN)
#define NAMESPACE_BEGIN(name) namespace name {
#endif
#if !defined(NAMESPACE_END)
#define NAMESPACE_END(name) }
#endif

namespace mammon
{
namespace filesystem
{

class path;
class resolver;

}
}
