//
//  UserViewController.swift
//  ucoin
//
//  Created by Syd on 2018/6/5.
//  Copyright © 2018年 ucoin.io. All rights reserved.
//

import UIKit
import SwiftyUserDefaults
import Moya
import PullToRefreshKit

class UserViewController: UITableViewController {
    
    private var userInfo: APIUser?
    private var ownedTokens: [APIToken] = []
    private var sectionsMap: [String] = ["actions", "ownedTokens"]
    
    private var loadingUserInfo = false
    private var loadingOwnedTokens = false
    
    private var userHeaderViewController = UserHeaderViewController()
    
    private var userServiceProvider = MoyaProvider<UCUserService>(plugins: [networkActivityPlugin, AccessTokenPlugin(tokenClosure: AccessTokenClosure())])
    
    private var tokenServiceProvider = MoyaProvider<UCTokenService>(plugins: [networkActivityPlugin, AccessTokenPlugin(tokenClosure: AccessTokenClosure())])
    
    //=============
    // MARK: - denit
    //=============
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.transitioningDelegate = self
        self.navigationController?.navigationBar.isTranslucent = true
        self.navigationController?.navigationBar.setBackgroundImage(UIImage(), for: .default)
        self.navigationController?.navigationBar.shadowImage = UIImage()
        /*
        if !validUser {
            let loginVC = LoginViewController.instantiate()
            loginVC.delegate = self
            self.navigationController?.pushViewController(loginVC, animated: true)
        }
        */
        
        self.setupTableView()
        
        self.setupPullRefresh()
        DispatchQueue.main.async {
            self.tableView.reloadDataWithAutoSizingCellWorkAround()
        }
        
        self.getOwnedTokens()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.navigationController?.navigationBar.isTranslucent = true
        self.navigationController?.navigationBar.setBackgroundImage(UIImage(), for: .default)
        self.navigationController?.navigationBar.shadowImage = UIImage()
        self.navigationController?.setNavigationBarHidden(false, animated: animated)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        self.navigationController?.navigationBar.tintColor = UIColor.primaryBlue
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    private func setupTableView() {
        let top = (self.navigationController?.navigationBar.bounds.height)! + 5
        self.tableView.contentInset = UIEdgeInsets(top: -1 * top, left: 0, bottom: 0, right: 0)
        self.tableView.register(cellType: UserActionsTableCell.self)
        self.tableView.register(cellType: OwnedTokenCell.self)
        self.tableView.register(cellType: EmptyOwnedTokenCell.self)
        self.tableView.register(cellType: LoadingCell.self)
        //self.tableView.separatorStyle = .none
        self.tableView.separatorInset = UIEdgeInsetsMake(0, 0, 0, 0)
        self.tableView.estimatedRowHeight = 44.0
        self.tableView.rowHeight = UITableViewAutomaticDimension
        
        self.userHeaderViewController.delegate = self
        if let userInfo: DefaultsUser = Defaults[.user] {
            self.userInfo = APIUser.init(user: userInfo)
            self.userHeaderViewController.setUser(self.userInfo)
            let settingButton = UIBarButtonItem(image: UIImage(named: "Setting")?.withRenderingMode(.alwaysTemplate), style: UIBarButtonItemStyle.plain, target: self, action: #selector(gotoSetting))
            self.navigationItem.rightBarButtonItem = settingButton
        } else if CheckValidAccessToken() {
            self.getUserInfo(false)
        } else {
            self.userHeaderViewController.setUser(nil)
        }
        
        self.tableView.tableHeaderView = self.userHeaderViewController.view
        
        self.userHeaderViewController.view.snp.remakeConstraints { [unowned self] (maker) -> Void in
            maker.centerX.equalToSuperview()
            maker.width.equalTo(self.tableView.snp.width)
            maker.top.equalToSuperview()
            maker.bottom.equalToSuperview()
        }
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
        self.tableView.configRefreshHeader(with: refreshHeader, container:self) { [weak self] in
            guard let weakSelf = self else {
                return
            }
            weakSelf.refresh()
        }
    }
    
    public func refresh(_ refreshUser: Bool = true) {
        self.getUserInfo(refreshUser)
        self.getOwnedTokens()
    }
    
    private func refreshDone() {
        if (!self.loadingUserInfo && !self.loadingOwnedTokens) {
            DispatchQueue.main.async {
                self.tableView.switchRefreshHeader(to: .normal(.success, 0.3))
            }
        }
    }
}

extension UserViewController {
    private func getUserInfo(_ refresh: Bool) {
        if self.loadingUserInfo {
            return
        }
        self.loadingUserInfo = true
        self.userHeaderViewController.loadingUserInfo()
        
        UCUserService.getUserInfo(
            refresh,
            provider: self.userServiceProvider,
            success: {[weak self] user in
                guard let weakSelf = self else {
                    return
                }
                weakSelf.userInfo = user
                weakSelf.userHeaderViewController.setUser(user)
                weakSelf.userHeaderViewController.stopLoadingUserInfo()
                
                if weakSelf.navigationItem.rightBarButtonItem == nil {
                    let settingButton = UIBarButtonItem(image: UIImage(named: "Setting")?.withRenderingMode(.alwaysTemplate), style: UIBarButtonItemStyle.plain, target: weakSelf, action: #selector(weakSelf.gotoSetting))
                    weakSelf.navigationItem.rightBarButtonItem = settingButton
                }
            },
            failed: {[weak self] error in
                guard let weakSelf = self else {
                    return
                }
                switch error {
                case UCAPIError.unauthorized:
                    weakSelf.userInfo = nil
                    weakSelf.userHeaderViewController.setUser(nil)
                    weakSelf.userHeaderViewController.stopLoadingUserInfo()
                default:
                    DispatchQueue.main.async {
                        UCAlert.showAlert(imageName: "Error", title: "错误", desc: error.description, closeBtn: "关闭")
                    }
                }
            },
            complete: {[weak self] in
                guard let weakSelf = self else {
                    return
                }
                weakSelf.loadingUserInfo = false
                weakSelf.refreshDone()
            }
        )
    }
    
    private func getOwnedTokens() {
        if self.loadingOwnedTokens {
            return
        }
        self.loadingOwnedTokens = true
        
        UCTokenService.getOwnedTokens(
            provider: self.tokenServiceProvider,
            success: {[weak self] tokens in
                guard let weakSelf = self else {
                    return
                }
                weakSelf.ownedTokens = tokens
            },
            failed: {[weak self] error in
                guard let weakSelf = self else {
                    return
                }
                switch error {
                case UCAPIError.unauthorized:
                    weakSelf.userInfo = nil
                    weakSelf.userHeaderViewController.setUser(nil)
                    weakSelf.userHeaderViewController.stopLoadingUserInfo()
                default:
                    DispatchQueue.main.async {
                        UCAlert.showAlert(imageName: "Error", title: "错误", desc: error.description, closeBtn: "关闭")
                    }
                }
            },
            complete: {[weak self] in
                guard let weakSelf = self else {
                    return
                }
                weakSelf.loadingOwnedTokens = false
                DispatchQueue.main.async {
                    weakSelf.tableView.reloadDataWithAutoSizingCellWorkAround()
                }
                weakSelf.refreshDone()
            }
        )
    }
    
}

extension UserViewController {
    
    override func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        switch self.sectionsMap[section] {
        case "ownedTokens":
            return SimpleHeaderView.height
        default:
            return 0
        }
    }
    
    override func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        var headerTitle: String?
        switch self.sectionsMap[section] {
        case "ownedTokens":
            headerTitle = "我创建的代币"
        default:
            break
        }
        if headerTitle == nil {
            return nil
        }
        let frame = CGRect(x: 0, y: 0, width: tableView.bounds.size.width, height: self.tableView(tableView, heightForHeaderInSection: section))
        let view = SimpleHeaderView(frame: frame)
        
        view.fill(headerTitle!)
        return view
    }
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        return 2
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch self.sectionsMap[section] {
        case "actions":
            return 1
        case "ownedTokens":
            return self.ownedTokens.count == 0 ? 1 : self.ownedTokens.count
        default:
            fatalError("Out of bounds, should not happen")
        }
        return 1
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        switch self.sectionsMap[indexPath.section] {
        case "actions":
            let actionsCell = tableView.dequeueReusableCell(for: indexPath) as UserActionsTableCell
            actionsCell.delegate = self
            actionsCell.fill()
            return actionsCell
        case "ownedTokens":
            if self.loadingOwnedTokens && self.ownedTokens.count == 0 {
                let actionsCell = tableView.dequeueReusableCell(for: indexPath) as LoadingCell
                actionsCell.fill()
                return actionsCell
            } else if self.ownedTokens.count == 0 {
                let actionsCell = tableView.dequeueReusableCell(for: indexPath) as EmptyOwnedTokenCell
                actionsCell.delegate = self
                actionsCell.fill(self.loadingOwnedTokens)
                return actionsCell
            }
            let actionsCell = tableView.dequeueReusableCell(for: indexPath) as OwnedTokenCell
            actionsCell.fill(self.ownedTokens[indexPath.row])
            return actionsCell
        default:
            fatalError("Out of bounds, should not happen")
        }
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        switch self.sectionsMap[indexPath.section] {
        case "ownedTokens":
            if self.loadingOwnedTokens && self.ownedTokens.count == 0 {
                break
            }
            let token = self.ownedTokens[indexPath.row]
            let tokenVC = TokenViewController.instantiate()
            tokenVC.setToken(token)
            DispatchQueue.main.async {
                self.navigationController?.pushViewController(tokenVC, animated: true)
            }
        default:
            break
        }
    }
    
    override func tableView(_ tableView: UITableView, shouldHighlightRowAt indexPath: IndexPath) -> Bool {
        switch self.sectionsMap[indexPath.section] {
        case "ownedTokens":
            if self.ownedTokens.count == 0 {
                return false
            }
            return true
        default:
            return false
        }
    }
}

extension UserViewController: UIViewControllerTransitioningDelegate {
    
    public func animationController(forPresented presented: UIViewController, presenting: UIViewController, source: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        return FadeTransition(transitionDuration: 0.5, startingAlpha: 0.8)
    }
    
    public func animationController(forDismissed dismissed: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        return FadeTransition(transitionDuration: 0.5, startingAlpha: 0.8)
    }
    
}

extension UserViewController: LoginViewDelegate {
    func loginSucceeded(token: APIAccessToken) {
        self.refresh(false)
    }
}

extension UserViewController: UserHeaderViewDelegate {
    func showLogin() {
        let loginVC = LoginViewController.instantiate()
        loginVC.delegate = self
        DispatchQueue.main.async {
            self.navigationController?.pushViewController(loginVC, animated: true)
        }
    }
    
    func logoutSucceeded() {
        self.userInfo = nil
        self.userHeaderViewController.setUser(nil)
    }
    
    @objc private func gotoSetting() {
        self.navigationItem.rightBarButtonItem = nil
        self.userInfo = nil
        self.userHeaderViewController.setUser(nil)
    }
}

extension UserViewController: UserActionsTableCellDelegate {
    func showCreateToken() {
        let vc = CreateTokenViewController.instantiate()
        DispatchQueue.main.async {
            self.navigationController?.pushViewController(vc, animated: true)
        }
    }
    
    func showScan() {
        let vc = CreateTokenViewController.instantiate()
        DispatchQueue.main.async {
            self.navigationController?.pushViewController(vc, animated: true)
        }
    }
}

extension UserViewController: CreateTokenViewDelegate {
    func tokenCreated(token: APIToken) {
        self.getOwnedTokens()
    }
}
