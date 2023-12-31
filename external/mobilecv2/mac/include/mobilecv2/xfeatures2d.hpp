/*
By downloading, copying, installing or using the software you agree to this
license. If you do not agree to this license, do not download, install,
copy or use the software.

                          License Agreement
               For Open Source Computer Vision Library
                       (3-clause BSD License)

Copyright (C) 2013, OpenCV Foundation, all rights reserved.
Third party copyrights are property of their respective owners.

Redistribution and use in source and binary forms, with or without modification,
are permitted provided that the following conditions are met:

  * Redistributions of source code must retain the above copyright notice,
    this list of conditions and the following disclaimer.

  * Redistributions in binary form must reproduce the above copyright notice,
    this list of conditions and the following disclaimer in the documentation
    and/or other materials provided with the distribution.

  * Neither the names of the copyright holders nor the names of the contributors
    may be used to endorse or promote products derived from this software
    without specific prior written permission.

This software is provided by the copyright holders and contributors "as is" and
any express or implied warranties, including, but not limited to, the implied
warranties of merchantability and fitness for a particular purpose are
disclaimed. In no event shall copyright holders or contributors be liable for
any direct, indirect, incidental, special, exemplary, or consequential damages
(including, but not limited to, procurement of substitute goods or services;
loss of use, data, or profits; or business interruption) however caused
and on any theory of liability, whether in contract, strict liability,
or tort (including negligence or otherwise) arising in any way out of
the use of this software, even if advised of the possibility of such damage.
*/

#ifndef __MOBILECV2_XFEATURES2D_HPP__
#define __MOBILECV2_XFEATURES2D_HPP__

#include "mobilecv2/features2d.hpp"
#include "mobilecv2/xfeatures2d/nonfree.hpp"

/** @defgroup xfeatures2d Extra 2D Features Framework
@{
    @defgroup xfeatures2d_experiment Experimental 2D Features Algorithms

This section describes experimental algorithms for 2d feature detection.

    @defgroup xfeatures2d_nonfree Non-free 2D Features Algorithms

This section describes two popular algorithms for 2d feature detection, SIFT and SURF, that are
known to be patented. Use them at your own risk.

@}
*/

namespace mobilecv2
{
namespace xfeatures2d
{

//! @addtogroup xfeatures2d_experiment
//! @{

/*
 * BRIEF Descriptor
 */

/** @brief Class for computing BRIEF descriptors described in @cite calon2010 .

@param bytes legth of the descriptor in bytes, valid values are: 16, 32 (default) or 64 .
@param use_orientation sample patterns using keypoints orientation, disabled by default.

 */
class CV_EXPORTS_W BriefDescriptorExtractor : public Feature2D
{
public:
    CV_WRAP static Ptr<BriefDescriptorExtractor> create( int bytes = 32, bool use_orientation = false );
};


//! @}

}
}

#endif
