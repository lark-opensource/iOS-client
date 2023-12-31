﻿/*M///////////////////////////////////////////////////////////////////////////////////////
//
//  IMPORTANT: READ BEFORE DOWNLOADING, COPYING, INSTALLING OR USING.
//
//  By downloading, copying, installing or using the software you agree to this license.
//  If you do not agree to this license, do not download, install,
//  copy or use the software.
//
//
//                           License Agreement
//                For Open Source Computer Vision Library
//
// Copyright (C) 2000-2008, Intel Corporation, all rights reserved.
// Copyright (C) 2009, Willow Garage Inc., all rights reserved.
// Third party copyrights are property of their respective owners.
//
// Redistribution and use in source and binary forms, with or without modification,
// are permitted provided that the following conditions are met:
//
//   * Redistribution's of source code must retain the above copyright notice,
//     this list of conditions and the following disclaimer.
//
//   * Redistribution's in binary form must reproduce the above copyright notice,
//     this list of conditions and the following disclaimer in the documentation
//     and/or other materials provided with the distribution.
//
//   * The name of the copyright holders may not be used to endorse or promote products
//     derived from this software without specific prior written permission.
//
// This software is provided by the copyright holders and contributors "as is" and
// any express or implied warranties, including, but not limited to, the implied
// warranties of merchantability and fitness for a particular purpose are disclaimed.
// In no event shall the Intel Corporation or contributors be liable for any direct,
// indirect, incidental, special, exemplary, or consequential damages
// (including, but not limited to, procurement of substitute goods or services;
// loss of use, data, or profits; or business interruption) however caused
// and on any theory of liability, whether in contract, strict liability,
// or tort (including negligence or otherwise) arising in any way out of
// the use of this software, even if advised of the possibility of such damage.
//
//M*/

#ifndef MOBILECV2_FLANN_HPP
#define MOBILECV2_FLANN_HPP

#include "mobilecv2/core.hpp"
#include "mobilecv2/flann/miniflann.hpp"
#include "mobilecv2/flann/flann_base.hpp"

/**
@defgroup flann Clustering and Search in Multi-Dimensional Spaces

This section documents OpenCV's interface to the FLANN library. FLANN (Fast Library for Approximate
Nearest Neighbors) is a library that contains a collection of algorithms optimized for fast nearest
neighbor search in large datasets and for high dimensional features. More information about FLANN
can be found in @cite Muja2009 .
*/

namespace mobilecv2flann
{
    CV_EXPORTS flann_distance_t flann_distance_type();
    FLANN_DEPRECATED CV_EXPORTS void set_distance_type(flann_distance_t distance_type, int order);
}


namespace mobilecv2
{
namespace flann
{


//! @addtogroup flann
//! @{

template <typename T> struct CvType {};
template <> struct CvType<unsigned char> { static int type() { return CV_8U; } };
template <> struct CvType<char> { static int type() { return CV_8S; } };
template <> struct CvType<unsigned short> { static int type() { return CV_16U; } };
template <> struct CvType<short> { static int type() { return CV_16S; } };
template <> struct CvType<int> { static int type() { return CV_32S; } };
template <> struct CvType<float> { static int type() { return CV_32F; } };
template <> struct CvType<double> { static int type() { return CV_64F; } };


// bring the flann parameters into this namespace
using ::mobilecv2flann::get_param;
using ::mobilecv2flann::print_params;

// bring the flann distances into this namespace
using ::mobilecv2flann::L2_Simple;
using ::mobilecv2flann::L2;
using ::mobilecv2flann::L1;
using ::mobilecv2flann::MinkowskiDistance;
using ::mobilecv2flann::MaxDistance;
using ::mobilecv2flann::HammingLUT;
using ::mobilecv2flann::Hamming;
using ::mobilecv2flann::Hamming2;
using ::mobilecv2flann::HistIntersectionDistance;
using ::mobilecv2flann::HellingerDistance;
using ::mobilecv2flann::ChiSquareDistance;
using ::mobilecv2flann::KL_Divergence;


/** @brief The FLANN nearest neighbor index class. This class is templated with the type of elements for which
the index is built.
 */
template <typename Distance>
class GenericIndex
{
public:
        typedef typename Distance::ElementType ElementType;
        typedef typename Distance::ResultType DistanceType;

        /** @brief Constructs a nearest neighbor search index for a given dataset.

        @param features Matrix of containing the features(points) to index. The size of the matrix is
        num_features x feature_dimensionality and the data type of the elements in the matrix must
        coincide with the type of the index.
        @param params Structure containing the index parameters. The type of index that will be
        constructed depends on the type of this parameter. See the description.
        @param distance

        The method constructs a fast search structure from a set of features using the specified algorithm
        with specified parameters, as defined by params. params is a reference to one of the following class
        IndexParams descendants:

        - **LinearIndexParams** When passing an object of this type, the index will perform a linear,
        brute-force search. :
        @code
        struct LinearIndexParams : public IndexParams
        {
        };
        @endcode
        - **KDTreeIndexParams** When passing an object of this type the index constructed will consist of
        a set of randomized kd-trees which will be searched in parallel. :
        @code
        struct KDTreeIndexParams : public IndexParams
        {
            KDTreeIndexParams( int trees = 4 );
        };
        @endcode
        - **KMeansIndexParams** When passing an object of this type the index constructed will be a
        hierarchical k-means tree. :
        @code
        struct KMeansIndexParams : public IndexParams
        {
            KMeansIndexParams(
                int branching = 32,
                int iterations = 11,
                flann_centers_init_t centers_init = CENTERS_RANDOM,
                float cb_index = 0.2 );
        };
        @endcode
        - **CompositeIndexParams** When using a parameters object of this type the index created
        combines the randomized kd-trees and the hierarchical k-means tree. :
        @code
        struct CompositeIndexParams : public IndexParams
        {
            CompositeIndexParams(
                int trees = 4,
                int branching = 32,
                int iterations = 11,
                flann_centers_init_t centers_init = CENTERS_RANDOM,
                float cb_index = 0.2 );
        };
        @endcode
        - **LshIndexParams** When using a parameters object of this type the index created uses
        multi-probe LSH (by Multi-Probe LSH: Efficient Indexing for High-Dimensional Similarity Search
        by Qin Lv, William Josephson, Zhe Wang, Moses Charikar, Kai Li., Proceedings of the 33rd
        International Conference on Very Large Data Bases (VLDB). Vienna, Austria. September 2007) :
        @code
        struct LshIndexParams : public IndexParams
        {
            LshIndexParams(
                unsigned int table_number,
                unsigned int key_size,
                unsigned int multi_probe_level );
        };
        @endcode
        - **AutotunedIndexParams** When passing an object of this type the index created is
        automatically tuned to offer the best performance, by choosing the optimal index type
        (randomized kd-trees, hierarchical kmeans, linear) and parameters for the dataset provided. :
        @code
        struct AutotunedIndexParams : public IndexParams
        {
            AutotunedIndexParams(
                float target_precision = 0.9,
                float build_weight = 0.01,
                float memory_weight = 0,
                float sample_fraction = 0.1 );
        };
        @endcode
        - **SavedIndexParams** This object type is used for loading a previously saved index from the
        disk. :
        @code
        struct SavedIndexParams : public IndexParams
        {
            SavedIndexParams( String filename );
        };
        @endcode
         */
        GenericIndex(const Mat& features, const ::mobilecv2flann::IndexParams& params, Distance distance = Distance());

        ~GenericIndex();

        /** @brief Performs a K-nearest neighbor search for a given query point using the index.

        @param query The query point
        @param indices Vector that will contain the indices of the K-nearest neighbors found. It must have
        at least knn size.
        @param dists Vector that will contain the distances to the K-nearest neighbors found. It must have
        at least knn size.
        @param knn Number of nearest neighbors to search for.
        @param params SearchParams
         */
        void knnSearch(const std::vector<ElementType>& query, std::vector<int>& indices,
                       std::vector<DistanceType>& dists, int knn, const ::mobilecv2flann::SearchParams& params);
        void knnSearch(const Mat& queries, Mat& indices, Mat& dists, int knn, const ::mobilecv2flann::SearchParams& params);

        int radiusSearch(const std::vector<ElementType>& query, std::vector<int>& indices,
                         std::vector<DistanceType>& dists, DistanceType radius, const ::mobilecv2flann::SearchParams& params);
        int radiusSearch(const Mat& query, Mat& indices, Mat& dists,
                         DistanceType radius, const ::mobilecv2flann::SearchParams& params);

        void save(String filename) { nnIndex->save(filename); }

        int veclen() const { return nnIndex->veclen(); }

        int size() const { return nnIndex->size(); }

        ::mobilecv2flann::IndexParams getParameters() { return nnIndex->getParameters(); }

        FLANN_DEPRECATED const ::mobilecv2flann::IndexParams* getIndexParameters() { return nnIndex->getIndexParameters(); }

private:
        ::mobilecv2flann::Index<Distance>* nnIndex;
};

//! @cond IGNORED

#define FLANN_DISTANCE_CHECK \
    if ( ::mobilecv2flann::flann_distance_type() != mobilecv2flann::FLANN_DIST_L2) { \
        printf("[WARNING] You are using mobilecv2::flann::Index (or mobilecv2::flann::GenericIndex) and have also changed "\
        "the distance using mobilecv2flann::set_distance_type. This is no longer working as expected "\
        "(mobilecv2::flann::Index always uses L2). You should create the index templated on the distance, "\
        "for example for L1 distance use: GenericIndex< L1<float> > \n"); \
    }


template <typename Distance>
GenericIndex<Distance>::GenericIndex(const Mat& dataset, const ::mobilecv2flann::IndexParams& params, Distance distance)
{
    CV_Assert(dataset.type() == CvType<ElementType>::type());
    CV_Assert(dataset.isContinuous());
    ::mobilecv2flann::Matrix<ElementType> m_dataset((ElementType*)dataset.ptr<ElementType>(0), dataset.rows, dataset.cols);

    nnIndex = new ::mobilecv2flann::Index<Distance>(m_dataset, params, distance);

    FLANN_DISTANCE_CHECK

    nnIndex->buildIndex();
}

template <typename Distance>
GenericIndex<Distance>::~GenericIndex()
{
    delete nnIndex;
}

template <typename Distance>
void GenericIndex<Distance>::knnSearch(const std::vector<ElementType>& query, std::vector<int>& indices, std::vector<DistanceType>& dists, int knn, const ::mobilecv2flann::SearchParams& searchParams)
{
    ::mobilecv2flann::Matrix<ElementType> m_query((ElementType*)&query[0], 1, query.size());
    ::mobilecv2flann::Matrix<int> m_indices(&indices[0], 1, indices.size());
    ::mobilecv2flann::Matrix<DistanceType> m_dists(&dists[0], 1, dists.size());

    FLANN_DISTANCE_CHECK

    nnIndex->knnSearch(m_query,m_indices,m_dists,knn,searchParams);
}


template <typename Distance>
void GenericIndex<Distance>::knnSearch(const Mat& queries, Mat& indices, Mat& dists, int knn, const ::mobilecv2flann::SearchParams& searchParams)
{
    CV_Assert(queries.type() == CvType<ElementType>::type());
    CV_Assert(queries.isContinuous());
    ::mobilecv2flann::Matrix<ElementType> m_queries((ElementType*)queries.ptr<ElementType>(0), queries.rows, queries.cols);

    CV_Assert(indices.type() == CV_32S);
    CV_Assert(indices.isContinuous());
    ::mobilecv2flann::Matrix<int> m_indices((int*)indices.ptr<int>(0), indices.rows, indices.cols);

    CV_Assert(dists.type() == CvType<DistanceType>::type());
    CV_Assert(dists.isContinuous());
    ::mobilecv2flann::Matrix<DistanceType> m_dists((DistanceType*)dists.ptr<DistanceType>(0), dists.rows, dists.cols);

    FLANN_DISTANCE_CHECK

    nnIndex->knnSearch(m_queries,m_indices,m_dists,knn, searchParams);
}

template <typename Distance>
int GenericIndex<Distance>::radiusSearch(const std::vector<ElementType>& query, std::vector<int>& indices, std::vector<DistanceType>& dists, DistanceType radius, const ::mobilecv2flann::SearchParams& searchParams)
{
    ::mobilecv2flann::Matrix<ElementType> m_query((ElementType*)&query[0], 1, query.size());
    ::mobilecv2flann::Matrix<int> m_indices(&indices[0], 1, indices.size());
    ::mobilecv2flann::Matrix<DistanceType> m_dists(&dists[0], 1, dists.size());

    FLANN_DISTANCE_CHECK

    return nnIndex->radiusSearch(m_query,m_indices,m_dists,radius,searchParams);
}

template <typename Distance>
int GenericIndex<Distance>::radiusSearch(const Mat& query, Mat& indices, Mat& dists, DistanceType radius, const ::mobilecv2flann::SearchParams& searchParams)
{
    CV_Assert(query.type() == CvType<ElementType>::type());
    CV_Assert(query.isContinuous());
    ::mobilecv2flann::Matrix<ElementType> m_query((ElementType*)query.ptr<ElementType>(0), query.rows, query.cols);

    CV_Assert(indices.type() == CV_32S);
    CV_Assert(indices.isContinuous());
    ::mobilecv2flann::Matrix<int> m_indices((int*)indices.ptr<int>(0), indices.rows, indices.cols);

    CV_Assert(dists.type() == CvType<DistanceType>::type());
    CV_Assert(dists.isContinuous());
    ::mobilecv2flann::Matrix<DistanceType> m_dists((DistanceType*)dists.ptr<DistanceType>(0), dists.rows, dists.cols);

    FLANN_DISTANCE_CHECK

    return nnIndex->radiusSearch(m_query,m_indices,m_dists,radius,searchParams);
}

//! @endcond

/**
 * @deprecated Use GenericIndex class instead
 */
template <typename T>
class Index_
{
public:
    typedef typename L2<T>::ElementType ElementType;
    typedef typename L2<T>::ResultType DistanceType;

    FLANN_DEPRECATED Index_(const Mat& dataset, const ::mobilecv2flann::IndexParams& params)
    {
        printf("[WARNING] The mobilecv2::flann::Index_<T> class is deperecated, use mobilecv2::flann::GenericIndex<Distance> instead\n");

        CV_Assert(dataset.type() == CvType<ElementType>::type());
        CV_Assert(dataset.isContinuous());
        ::mobilecv2flann::Matrix<ElementType> m_dataset((ElementType*)dataset.ptr<ElementType>(0), dataset.rows, dataset.cols);

        if ( ::mobilecv2flann::flann_distance_type() == mobilecv2flann::FLANN_DIST_L2 ) {
            nnIndex_L1 = NULL;
            nnIndex_L2 = new ::mobilecv2flann::Index< L2<ElementType> >(m_dataset, params);
        }
        else if ( ::mobilecv2flann::flann_distance_type() == mobilecv2flann::FLANN_DIST_L1 ) {
            nnIndex_L1 = new ::mobilecv2flann::Index< L1<ElementType> >(m_dataset, params);
            nnIndex_L2 = NULL;
        }
        else {
            printf("[ERROR] mobilecv2::flann::Index_<T> only provides backwards compatibility for the L1 and L2 distances. "
                   "For other distance types you must use mobilecv2::flann::GenericIndex<Distance>\n");
            CV_Assert(0);
        }
        if (nnIndex_L1) nnIndex_L1->buildIndex();
        if (nnIndex_L2) nnIndex_L2->buildIndex();
    }
    FLANN_DEPRECATED ~Index_()
    {
        if (nnIndex_L1) delete nnIndex_L1;
        if (nnIndex_L2) delete nnIndex_L2;
    }

    FLANN_DEPRECATED void knnSearch(const std::vector<ElementType>& query, std::vector<int>& indices, std::vector<DistanceType>& dists, int knn, const ::mobilecv2flann::SearchParams& searchParams)
    {
        ::mobilecv2flann::Matrix<ElementType> m_query((ElementType*)&query[0], 1, query.size());
        ::mobilecv2flann::Matrix<int> m_indices(&indices[0], 1, indices.size());
        ::mobilecv2flann::Matrix<DistanceType> m_dists(&dists[0], 1, dists.size());

        if (nnIndex_L1) nnIndex_L1->knnSearch(m_query,m_indices,m_dists,knn,searchParams);
        if (nnIndex_L2) nnIndex_L2->knnSearch(m_query,m_indices,m_dists,knn,searchParams);
    }
    FLANN_DEPRECATED void knnSearch(const Mat& queries, Mat& indices, Mat& dists, int knn, const ::mobilecv2flann::SearchParams& searchParams)
    {
        CV_Assert(queries.type() == CvType<ElementType>::type());
        CV_Assert(queries.isContinuous());
        ::mobilecv2flann::Matrix<ElementType> m_queries((ElementType*)queries.ptr<ElementType>(0), queries.rows, queries.cols);

        CV_Assert(indices.type() == CV_32S);
        CV_Assert(indices.isContinuous());
        ::mobilecv2flann::Matrix<int> m_indices((int*)indices.ptr<int>(0), indices.rows, indices.cols);

        CV_Assert(dists.type() == CvType<DistanceType>::type());
        CV_Assert(dists.isContinuous());
        ::mobilecv2flann::Matrix<DistanceType> m_dists((DistanceType*)dists.ptr<DistanceType>(0), dists.rows, dists.cols);

        if (nnIndex_L1) nnIndex_L1->knnSearch(m_queries,m_indices,m_dists,knn, searchParams);
        if (nnIndex_L2) nnIndex_L2->knnSearch(m_queries,m_indices,m_dists,knn, searchParams);
    }

    FLANN_DEPRECATED int radiusSearch(const std::vector<ElementType>& query, std::vector<int>& indices, std::vector<DistanceType>& dists, DistanceType radius, const ::mobilecv2flann::SearchParams& searchParams)
    {
        ::mobilecv2flann::Matrix<ElementType> m_query((ElementType*)&query[0], 1, query.size());
        ::mobilecv2flann::Matrix<int> m_indices(&indices[0], 1, indices.size());
        ::mobilecv2flann::Matrix<DistanceType> m_dists(&dists[0], 1, dists.size());

        if (nnIndex_L1) return nnIndex_L1->radiusSearch(m_query,m_indices,m_dists,radius,searchParams);
        if (nnIndex_L2) return nnIndex_L2->radiusSearch(m_query,m_indices,m_dists,radius,searchParams);
    }

    FLANN_DEPRECATED int radiusSearch(const Mat& query, Mat& indices, Mat& dists, DistanceType radius, const ::mobilecv2flann::SearchParams& searchParams)
    {
        CV_Assert(query.type() == CvType<ElementType>::type());
        CV_Assert(query.isContinuous());
        ::mobilecv2flann::Matrix<ElementType> m_query((ElementType*)query.ptr<ElementType>(0), query.rows, query.cols);

        CV_Assert(indices.type() == CV_32S);
        CV_Assert(indices.isContinuous());
        ::mobilecv2flann::Matrix<int> m_indices((int*)indices.ptr<int>(0), indices.rows, indices.cols);

        CV_Assert(dists.type() == CvType<DistanceType>::type());
        CV_Assert(dists.isContinuous());
        ::mobilecv2flann::Matrix<DistanceType> m_dists((DistanceType*)dists.ptr<DistanceType>(0), dists.rows, dists.cols);

        if (nnIndex_L1) return nnIndex_L1->radiusSearch(m_query,m_indices,m_dists,radius,searchParams);
        if (nnIndex_L2) return nnIndex_L2->radiusSearch(m_query,m_indices,m_dists,radius,searchParams);
    }

    FLANN_DEPRECATED void save(String filename)
    {
        if (nnIndex_L1) nnIndex_L1->save(filename);
        if (nnIndex_L2) nnIndex_L2->save(filename);
    }

    FLANN_DEPRECATED int veclen() const
    {
        if (nnIndex_L1) return nnIndex_L1->veclen();
        if (nnIndex_L2) return nnIndex_L2->veclen();
    }

    FLANN_DEPRECATED int size() const
    {
        if (nnIndex_L1) return nnIndex_L1->size();
        if (nnIndex_L2) return nnIndex_L2->size();
    }

    FLANN_DEPRECATED ::mobilecv2flann::IndexParams getParameters()
    {
        if (nnIndex_L1) return nnIndex_L1->getParameters();
        if (nnIndex_L2) return nnIndex_L2->getParameters();

    }

    FLANN_DEPRECATED const ::mobilecv2flann::IndexParams* getIndexParameters()
    {
        if (nnIndex_L1) return nnIndex_L1->getIndexParameters();
        if (nnIndex_L2) return nnIndex_L2->getIndexParameters();
    }

private:
    // providing backwards compatibility for L2 and L1 distances (most common)
    ::mobilecv2flann::Index< L2<ElementType> >* nnIndex_L2;
    ::mobilecv2flann::Index< L1<ElementType> >* nnIndex_L1;
};


/** @brief Clusters features using hierarchical k-means algorithm.

@param features The points to be clustered. The matrix must have elements of type
Distance::ElementType.
@param centers The centers of the clusters obtained. The matrix must have type
Distance::ResultType. The number of rows in this matrix represents the number of clusters desired,
however, because of the way the cut in the hierarchical tree is chosen, the number of clusters
computed will be the highest number of the form (branching-1)\*k+1 that's lower than the number of
clusters desired, where branching is the tree's branching factor (see description of the
KMeansIndexParams).
@param params Parameters used in the construction of the hierarchical k-means tree.
@param d Distance to be used for clustering.

The method clusters the given feature vectors by constructing a hierarchical k-means tree and
choosing a cut in the tree that minimizes the cluster's variance. It returns the number of clusters
found.
 */
template <typename Distance>
int hierarchicalClustering(const Mat& features, Mat& centers, const ::mobilecv2flann::KMeansIndexParams& params,
                           Distance d = Distance())
{
    typedef typename Distance::ElementType ElementType;
    typedef typename Distance::ResultType DistanceType;

    CV_Assert(features.type() == CvType<ElementType>::type());
    CV_Assert(features.isContinuous());
    ::mobilecv2flann::Matrix<ElementType> m_features((ElementType*)features.ptr<ElementType>(0), features.rows, features.cols);

    CV_Assert(centers.type() == CvType<DistanceType>::type());
    CV_Assert(centers.isContinuous());
    ::mobilecv2flann::Matrix<DistanceType> m_centers((DistanceType*)centers.ptr<DistanceType>(0), centers.rows, centers.cols);

    return ::mobilecv2flann::hierarchicalClustering<Distance>(m_features, m_centers, params, d);
}

/** @deprecated
*/
template <typename ELEM_TYPE, typename DIST_TYPE>
FLANN_DEPRECATED int hierarchicalClustering(const Mat& features, Mat& centers, const ::mobilecv2flann::KMeansIndexParams& params)
{
    printf("[WARNING] mobilecv2::flann::hierarchicalClustering<ELEM_TYPE,DIST_TYPE> is deprecated, use "
        "mobilecv2::flann::hierarchicalClustering<Distance> instead\n");

    if ( ::mobilecv2flann::flann_distance_type() == mobilecv2flann::FLANN_DIST_L2 ) {
        return hierarchicalClustering< L2<ELEM_TYPE> >(features, centers, params);
    }
    else if ( ::mobilecv2flann::flann_distance_type() == mobilecv2flann::FLANN_DIST_L1 ) {
        return hierarchicalClustering< L1<ELEM_TYPE> >(features, centers, params);
    }
    else {
        printf("[ERROR] mobilecv2::flann::hierarchicalClustering<ELEM_TYPE,DIST_TYPE> only provides backwards "
        "compatibility for the L1 and L2 distances. "
        "For other distance types you must use mobilecv2::flann::hierarchicalClustering<Distance>\n");
        CV_Assert(0);
    }
}

//! @} flann

} } // namespace mobilecv2::flann

#endif
