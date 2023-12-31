//
//  TeamMemberViewModel+Search.swift
//  LarkTeam
//
//  Created by chaishenghua on 2022/11/10.
//

import Foundation

extension TeamMemberViewModel {
    func loadSearchData() {
        guard let key = filterKey, !key.isEmpty else {
            isInSearch = false
            statusBehavior.onNext(.viewStatus(.display))
            return
        }
        isInSearch = true
        statusBehavior.onNext(.viewStatus(.loading))
        getSearchTeamMembers(id: self.searchID)
            .observeOn(schedulerType)
            .filter { [weak self] _ in self?.isInSearch ?? false }
            .subscribe(onNext: { [weak self] datas in
                guard let self = self else { return }
                self.statusBehavior.onNext(.viewStatus(datas.isEmpty ? .searchNoResult(key) : .display))
            }, onError: { [weak self] (error) in
                self?.statusBehavior.onNext(.error(error))
            }, onDisposed: { [weak self] in
                self?.isFirstDataLoaded = true
            }).disposed(by: disposeBag)
    }
}
