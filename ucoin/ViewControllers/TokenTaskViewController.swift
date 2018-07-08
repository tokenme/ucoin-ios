//
//  TokenTaskViewController.swift
//  ucoin
//
//  Created by Syd on 2018/7/2.
//  Copyright © 2018年 ucoin.io. All rights reserved.
//

import UIKit
import SwiftyUserDefaults
import Moya
import PullToRefreshKit

class TokenTaskViewController: UITableViewController {
    
    fileprivate var userInfo: APIUser?
    fileprivate var taskId: UInt64?
    fileprivate var tokenTask: APITokenTask?
    fileprivate var comments: [String] = []
    fileprivate var sectionsMap: [String] = ["info", "comments"]
    
    fileprivate let infoHeaderView = TokenTaskInfoHeaderCell()
    
    fileprivate var tasksFooterState: FooterRefresherState = .normal
    fileprivate let refreshFooter = DefaultRefreshFooter.footer()
    fileprivate let spinner = LoaderModal(backgroundColor: UIColor.white)!
    
    private var tokenTaskServiceProvider = MoyaProvider<UCTokenTaskService>(plugins: [networkActivityPlugin, AccessTokenPlugin(tokenClosure: AccessTokenClosure())])
    
    public func setTaskId(_ taskId: UInt64?) {
        self.taskId = taskId
        if self.taskId != nil {
            self.refresh()
        }
    }
    
    public func setTask(_ task: APITokenTask?) {
        self.tokenTask = task
        self.infoHeaderView.setTask(task)
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
        self.navigationController?.navigationBar.isTranslucent = false
        self.navigationController?.navigationBar.setBackgroundImage(UIImage(), for: .default)
        self.navigationController?.navigationBar.shadowImage = UIImage()
        self.navigationItem.title = "代币任务"
        
        self.extendedLayoutIncludesOpaqueBars = true
        
        if let userInfo: DefaultsUser = Defaults[.user] {
            self.userInfo = APIUser.init(user: userInfo)
        }
        
        guard let tokenTask = self.tokenTask else {
            return
        }
        if tokenTask.isOwnedByUser(wallet: userInfo?.wallet) {
            let editButton = UIBarButtonItem(barButtonSystemItem: .edit, target: self, action: #selector(showEdit))
            self.navigationItem.rightBarButtonItem = editButton
        }
        
        self.tableView.addSubview(spinner)
        
        if self.taskId ?? 0 > 0 && self.tokenTask == nil {
            self.spinner.start()
        }
        
        self.setupTableView()
        
        self.setupPullRefresh()
        DispatchQueue.main.async {
            self.tableView.reloadDataWithAutoSizingCellWorkAround()
        }
        
        self.refresh(true)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        if #available(iOS 11.0, *) {
            self.navigationController?.navigationBar.prefersLargeTitles = false
            self.navigationItem.largeTitleDisplayMode = .automatic;
        }
        self.navigationController?.navigationBar.isTranslucent = false
        self.navigationController?.setNavigationBarHidden(false, animated: animated)
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    static func instantiate() -> TokenTaskViewController
    {
        return UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "TokenTaskViewController") as! TokenTaskViewController
    }
    
    private func setupTableView() {
        self.tableView.register(cellType: EmptyCell.self)
        self.tableView.register(cellType: TokenTaskInfoTableCell.self)
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
            weakSelf.refresh(false)
        }
        self.tableView.configRefreshFooter(with: refreshFooter, container:self) { [weak self] in
            guard let weakSelf = self else {
                return
            }
            var taskId: UInt64?
            if let taskID = weakSelf.taskId {
                taskId = taskID
            } else if let taskID = weakSelf.tokenTask?.id {
                taskId = taskID
            }
            if taskId ?? 0 == 0 {
                return
            }
            weakSelf.getTokenTaskComments(taskId, refresh: false)
        }
    }
    
    private func refresh(_ ignoreTask: Bool = false) {
        var taskId: UInt64?
        if let taskID = self.taskId {
            taskId = taskID
        } else if let taskID = self.tokenTask?.id {
            taskId = taskID
        }
        if taskId ?? 0 == 0 {
            return
        }
        if !ignoreTask {
            self.getTokenTask(taskId)
        }
        self.getTokenTaskComments(taskId, refresh: true)
    }
}

extension TokenTaskViewController: UIViewControllerTransitioningDelegate {
    
    public func animationController(forPresented presented: UIViewController, presenting: UIViewController, source: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        return FadeTransition(transitionDuration: 0.5, startingAlpha: 0.8)
    }
    
    public func animationController(forDismissed dismissed: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        return FadeTransition(transitionDuration: 0.5, startingAlpha: 0.8)
    }
    
}

extension TokenTaskViewController {
    
    override func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        switch self.sectionsMap[section] {
        case "info":
            return TokenTaskInfoHeaderCell.height
        default:
            return 0
        }
    }
    
    override func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        switch self.sectionsMap[section] {
        case "info":
            return self.infoHeaderView
        default:
            break
        }
        return nil
    }
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        return self.sectionsMap.count
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch self.sectionsMap[section] {
        case "info":
            return 1
        case "comments":
            return self.comments.count
        default:
            fatalError("Out of bounds, should not happen")
        }
        return 1
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        switch self.sectionsMap[indexPath.section] {
        case "info":
            let cell = tableView.dequeueReusableCell(for: indexPath) as TokenTaskInfoTableCell
            cell.textViewDelegate = self
            cell.fill(self.tokenTask)
            return cell
        case "comments":
            let cell = tableView.dequeueReusableCell(for: indexPath) as EmptyCell
            cell.fill("该代币还没有描述", isLoading: false)
            return cell
        default:
            fatalError("Out of bounds, should not happen")
        }
    }
}

extension TokenTaskViewController {
    private func getTokenTask(_ taskId: UInt64!) {
        UCTokenTaskService.getTokenTask(
            taskId,
            provider: self.tokenTaskServiceProvider,
            success: {[weak self] task in
                guard let weakSelf = self else {
                    return
                }
                weakSelf.setTask(task)
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
                DispatchQueue.main.async {
                    weakSelf.spinner.stop()
                    weakSelf.tableView.switchRefreshHeader(to: .normal(.success, 0.3))
                    weakSelf.tableView.reloadDataWithAutoSizingCellWorkAround()
                }
        })
    }
    
    private func getTokenTaskComments(_ taskId: UInt64!, refresh: Bool) {
        
    }
}

extension TokenTaskViewController {
    @objc private func showEdit() {
        let vc = EditTokenTaskViewController()
        vc.tokenTask = self.tokenTask
        vc.delegate = self
        DispatchQueue.main.async {
            self.navigationController?.pushViewController(vc, animated: true)
        }
    }
}

extension TokenTaskViewController: EditTokenTaskDelegate {
    func tokenTaskUpdated(task: APITokenTask) {
        if let taskId = task.id {
            self.getTokenTask(taskId)
        }
    }
}

extension TokenTaskViewController: UITextViewDelegate {
    func textView(_ textView: UITextView, shouldInteractWith URL: URL, in characterRange: NSRange) -> Bool {
        print("Should interact with: \(URL)")
        return true
    }
}
