//
//  SearchDomain.swift
//  LKMetric
//
//  Created by Jiayun Huang on 2020/1/14.
//

import Foundation

// MARK: - Search Level 2
public enum Search: Int32, MetricDomainEnum {
    case unknown = 0
    case db = 1
    case remote = 2
    case local = 3
}
