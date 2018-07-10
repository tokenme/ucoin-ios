//
//  TokenTaskEvidencesTableViewController.swift
//  ucoin
//
//  Created by Syd on 2018/7/10.
//  Copyright © 2018年 ucoin.io. All rights reserved.
//

import UIKit
import SwiftyUserDefaults
import Moya
import PullToRefreshKit

fileprivate let DefaultPageSize: UInt = 10

class TokenTaskEvidencesTableViewController: UIViewController {
    private var tokenTask: APITokenTask?
    private var approveStatus: Int8 = 0
    private var evidences: [APITokenTaskEvidence] = []
    fileprivate let tableView = UITableView(frame: CGRect.zero, style: UITableViewStyle.plain)
    
    fileprivate var isLoadingEvidences: Bool = false
    fileprivate var currentEvidencePage: UInt = 0
    fileprivate var evidencesFooterState: FooterRefresherState = .normal
    fileprivate let refreshFooter = DefaultRefreshFooter.footer()
    
    private var tokenTaskEvidenceServiceProvider = MoyaProvider<UCTokenTaskEvidenceService>(plugins: [networkActivityPlugin, AccessTokenPlugin(tokenClosure: AccessTokenClosure())])
    
    public func setTask(_ task: APITokenTask?, approveStatus: Int8) {
        self.tokenTask = task
        self.approveStatus = approveStatus
    }
    
    //=============
    // MARK: - denit
    //=============
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.transitioningDelegate = self
        
        self.setupTableView()
        
        self.setupPullRefresh()
        DispatchQueue.main.async {
            self.tableView.reloadDataWithAutoSizingCellWorkAround()
        }
        
        self.refresh()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    static func instantiate() -> TokenTaskEvidencesTableViewController
    {
        return UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "TokenTaskEvidencesTableViewController") as! TokenTaskEvidencesTableViewController
    }
    
    private func setupTableView() {
        self.view.addSubview(tableView)
        self.tableView.snp.remakeConstraints { (maker) -> Void in
            maker.leading.equalToSuperview()
            maker.trailing.equalToSuperview()
            maker.top.equalToSuperview()
            maker.bottom.equalToSuperview()
        }
        self.tableView.delegate = self
        self.tableView.dataSource = self
        
        self.tableView.register(cellType: EmptyCell.self)
        self.tableView.register(cellType: TokenTaskEvidenceTableCell.self)
        self.tableView.separatorInset = UIEdgeInsetsMake(0, 0, 0, 0)
        self.tableView.estimatedRowHeight = 44.0
        self.tableView.rowHeight = UITableViewAutomaticDimension
    }
    
    private func setupPullRefresh() {
        let refreshHeader = DefaultRefreshHeader.header()
        refreshHeader.setText("下拉刷新", mode: .pullToRefresh)
        refreshHeader.setText("放开刷新", mode: .releaseToRefresh)
        refreshHeader.setText("刷新成功", mode: .refreshSuccess)
        refreshHeader.setText("获取数据中...", mode: .refreshing)
        refreshHeader.setText("刷新失败了", mode: .refreshFailure)
        refreshHeader.tintColor = UIColor.primaryBlue
        refreshHeader.imageRenderingWithTintColor = true
        //refreshHeader.durationWhenHide = 0.4
        
        refreshFooter.refreshMode = .scroll
        refreshFooter.setText("上拉获取更多数据", mode: .pullToRefresh)
        refreshFooter.setText("没有更多了", mode: .noMoreData)
        refreshFooter.setText("获取数据中...", mode: .refreshing)
        self.tableView.configRefreshHeader(with: refreshHeader, container:self) { [weak self] in
            guard let weakSelf = self else {
                return
            }
            weakSelf.refresh()
        }
        self.tableView.configRefreshFooter(with: refreshFooter, container:self) { [weak self] in
            guard let weakSelf = self else {
                return
            }
            guard let task = weakSelf.tokenTask else {
                return
            }
            weakSelf.getEvidences(task.id!, approveStatus: weakSelf.approveStatus, refresh: false)
        }
    }
    
    private func refresh() {
        guard let task = self.tokenTask else {
            return
        }
        self.getEvidences(task.id!, approveStatus: self.approveStatus, refresh: true)
    }
}

extension TokenTaskEvidencesTableViewController: UIViewControllerTransitioningDelegate {
    
    public func animationController(forPresented presented: UIViewController, presenting: UIViewController, source: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        return FadeTransition(transitionDuration: 0.5, startingAlpha: 0.8)
    }
    
    public func animationController(forDismissed dismissed: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        return FadeTransition(transitionDuration: 0.5, startingAlpha: 0.8)
    }
    
}

extension TokenTaskEvidencesTableViewController: UITableViewDelegate, UITableViewDataSource {
    
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 0
    }
    
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        return nil
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if self.evidences.count == 0 {
            return 1
        }
        return self.evidences.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if self.evidences.count == 0 {
            let cell = tableView.dequeueReusableCell(for: indexPath) as EmptyCell
            var txt: String?
            switch self.approveStatus {
            case -1: txt = "没有审核拒绝证明"
            case 0: txt = "没有人提交证明"
            case 1: txt = "没有审核通过证明"
            default: txt = "没有人提交证明"
            }
            cell.fill(txt!, isLoading: self.isLoadingEvidences)
            return cell
        }
        let cell = tableView.dequeueReusableCell(for: indexPath) as TokenTaskEvidenceTableCell
        cell.textViewDelegate = self
        cell.delegate = self
        cell.fill(self.evidences[indexPath.row])
        return cell
    }
    
    func tableView(_ tableView: UITableView, shouldHighlightRowAt indexPath: IndexPath) -> Bool {
        return false
    }
}

extension TokenTaskEvidencesTableViewController {
    
    private func getEvidences(_ taskId: UInt64, approveStatus: Int8, refresh: Bool) {
        if self.isLoadingEvidences {
            return
        }
        self.isLoadingEvidences = true
        
        UCTokenTaskEvidenceService.listEvidence(
            taskId,
            approveStatus,
            self.currentEvidencePage,
            DefaultPageSize,
            provider: self.tokenTaskEvidenceServiceProvider,
            success: {[weak self] evidences in
                guard let weakSelf = self else {
                    return
                }
                if refresh {
                    weakSelf.evidences = evidences
                } else {
                    weakSelf.evidences.append(contentsOf: evidences)
                }
                if evidences.count > 0 && evidences.count >= DefaultPageSize {
                    weakSelf.currentEvidencePage += 1
                    weakSelf.evidencesFooterState = .normal
                } else {
                    weakSelf.evidencesFooterState = .noMoreData
                }
            },
            failed: { error in
                DispatchQueue.main.async {
                    UCAlert.showAlert(imageName: "Error", title: "错误", desc: error.description, closeBtn: "关闭")
                }
        },
            complete: { [weak self] in
                guard let weakSelf = self else {
                    return
                }
                weakSelf.isLoadingEvidences = false
                DispatchQueue.main.async {[weak self] in
                    guard let weakSelf = self else {
                        return
                    }
                    if weakSelf.evidences.count == 0 {
                        weakSelf.refreshFooter.isHidden = true
                    } else {
                        weakSelf.refreshFooter.isHidden = false
                    }
                    weakSelf.tableView.switchRefreshHeader(to: .normal(.success, 0.3))
                    weakSelf.tableView.switchRefreshFooter(to: weakSelf.evidencesFooterState)
                    weakSelf.tableView.reloadDataWithAutoSizingCellWorkAround()
                }
        })
    }
}

extension TokenTaskEvidencesTableViewController: UITextViewDelegate {
    func textView(_ textView: UITextView, shouldInteractWith URL: URL, in characterRange: NSRange) -> Bool {
        print("Should interact with: \(URL)")
        return true
    }
}

extension TokenTaskEvidencesTableViewController: TokenTaskEvidencesViewDelegate {
    func approveEvidence(_ evidenceId: UInt64, approveStatus: Int8) {
        var idx: Int = 0
        var found: Bool = false
        for evidence in self.evidences {
            if evidence.id == evidenceId {
                found = true
                break
            }
            idx += 1
        }
        if found {
            self.evidences.remove(at: idx)
            if self.evidences.count == 0 {
                self.tableView.reloadDataWithAutoSizingCellWorkAround()
            } else {
                self.tableView.beginUpdates()
                self.tableView.deleteRows(at: [IndexPath(row: idx, section: 0)], with: .fade)
                self.tableView.endUpdates()
            }
        }
    }
    
    func segmentChanged(_ index: Int) { }
}
