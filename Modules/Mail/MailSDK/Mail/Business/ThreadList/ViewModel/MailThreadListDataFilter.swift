//
//  MailThreadListDataFilter.swift
//  MailSDK
//
//  Created by tefeng liu on 2022/5/31.
//

import Foundation
import RxSwift

protocol MailThreadListDataFilter {
    func filterCellViewModelsIfNeeded(cellVMS: [MailThreadListCellViewModel],
                                      labelId: String) -> Observable<[MailThreadListCellViewModel]>
}
