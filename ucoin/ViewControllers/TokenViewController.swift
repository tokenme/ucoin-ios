//
//  TokenViewController.swift
//  ucoin
//
//  Created by Syd on 2018/6/15.
//  Copyright © 2018年 ucoin.io. All rights reserved.
//

import UIKit
import SwiftyUserDefaults
import Moya
import PullToRefreshKit
import Bartinter

fileprivate let DefaultPageSize: UInt = 10
fileprivate let DefaultFabHeight = 40.0

class TokenViewController: UIViewController {
    
    private var userInfo: APIUser? {
        get {
            if let userInfo: DefaultsUser = Defaults[.user] {
                if CheckValidAccessToken() {
                    return APIUser.init(user: userInfo)
                }
                return nil
            }
            return nil
        }
    }
    
    private var tokenAddress: String?
    private var tokenInfo: APIToken?
    fileprivate var sectionsMap: [String] = ["stats", "entities"]
    fileprivate let segmentControl = TokenSegmentView()
    fileprivate var currentSegment: Int = 0
    
    fileprivate var headerColors: UIImageColors?
    
    fileprivate let tableView = UITableView(frame: CGRect.zero, style: UITableViewStyle.plain)
    
    fileprivate var currentProductPage: UInt = 0
    fileprivate var isLoadingProducts = false
    fileprivate var products: [APITokenProduct] = []
    fileprivate var productsFooterState: FooterRefresherState = .normal
    
    fileprivate var currentTaskPage: UInt = 0
    fileprivate var isLoadingTasks = false
    fileprivate var tasks: [APITokenTask] = []
    fileprivate var tasksFooterState: FooterRefresherState = .normal
    
    fileprivate let fabButton = UIButton(type: .custom)
    
    fileprivate let spinner = LoaderModal(backgroundColor: UIColor.white)!
    
    fileprivate let tokenHeaderViewController = TokenHeaderViewController()
    fileprivate let refreshHeader = DefaultRefreshHeader.header()
    fileprivate let refreshFooter = DefaultRefreshFooter.footer()
    
    private var tokenServiceProvider = MoyaProvider<UCTokenService>(plugins: [networkActivityPlugin, AccessTokenPlugin(tokenClosure: AccessTokenClosure())])
    private var tokenProductServiceProvider = MoyaProvider<UCTokenProductService>(plugins: [networkActivityPlugin, AccessTokenPlugin(tokenClosure: AccessTokenClosure())])
    private var tokenTaskServiceProvider = MoyaProvider<UCTokenTaskService>(plugins: [networkActivityPlugin, AccessTokenPlugin(tokenClosure: AccessTokenClosure())])
    
    public func setTokenAddress(_ tokenAddress: String?) {
        self.tokenAddress = tokenAddress
        if self.tokenAddress != nil {
            self.refresh()
        }
    }
    
    public func setToken(_ token: APIToken?) {
        self.tokenInfo = token
        self.tokenHeaderViewController.delegate = self
        self.tokenHeaderViewController.setToken(self.tokenInfo)
        if token?.totalSupply == nil {
            guard let address = token?.address else {
                return
            }
            self.getToken(address)
        }
    }
    
    //=============
    // MARK: - denit
    //=============
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    static func instantiate() -> TokenViewController
    {
        return UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "TokenViewController") as! TokenViewController
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.transitioningDelegate = self
        if let navigationController = self.navigationController {
            if #available(iOS 11.0, *) {
                navigationController.navigationBar.prefersLargeTitles = false
                self.navigationItem.largeTitleDisplayMode = .automatic;
            }
            navigationController.navigationBar.isTranslucent = true
            navigationController.navigationBar.setBackgroundImage(UIImage(), for: .default)
            navigationController.navigationBar.shadowImage = UIImage()
        }
        self.extendedLayoutIncludesOpaqueBars = true
        self.segmentControl.frame = CGRect(x: 0, y: 0, width: tableView.bounds.size.width, height:TokenSegmentView.height)
        self.segmentControl.delegate = self
        
        self.setupTableView()
        self.setupPullRefresh()
        self.setupFabButton()
        self.onSegmentControlUpdated()
        
        self.view.addSubview(spinner)
        if self.tokenAddress != nil && self.tokenInfo == nil {
            self.spinner.start()
        }
        
        self.refresh(true)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        if let navigationController = self.navigationController {
            if #available(iOS 11.0, *) {
                navigationController.navigationBar.prefersLargeTitles = false
                self.navigationItem.largeTitleDisplayMode = .automatic;
            }
            navigationController.navigationBar.isTranslucent = true
            navigationController.setNavigationBarHidden(false, animated: animated)
        }
        self.tableView.reloadDataWithAutoSizingCellWorkAround()
        self.updatedImageColors(self.headerColors)
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
        self.view.addSubview(tableView)
        self.tableView.snp.remakeConstraints { (maker) -> Void in
            maker.leading.equalToSuperview()
            maker.trailing.equalToSuperview()
            maker.top.equalToSuperview()
            maker.bottom.equalToSuperview()
        }
        self.tableView.delegate = self
        self.tableView.dataSource = self
        
        self.tableView.register(cellType: TokenStatsTableCell.self)
        self.tableView.register(cellType: TokenActionsTableCell.self)
        self.tableView.register(cellType: TokenDescriptionCell.self)
        self.tableView.register(cellType: EmptyCell.self)
        self.tableView.register(cellType: EmptyTokenOwnedDescriptionCell.self)
        self.tableView.register(cellType: EmptyTokenOwnedProductCell.self)
        self.tableView.register(cellType: EmptyTokenOwnedTaskCell.self)
        self.tableView.register(cellType: TokenProductSimpleCell.self)
        self.tableView.register(cellType: TokenTaskSimpleCell.self)
        //self.tableView.separatorStyle = .none
        self.tableView.separatorInset = UIEdgeInsetsMake(0, 0, 0, 0)
        self.tableView.estimatedRowHeight = 44.0
        self.tableView.rowHeight = UITableViewAutomaticDimension
        let top = (self.navigationController?.navigationBar.bounds.height)! + 5
        self.tableView.contentInset = UIEdgeInsets(top: -1 * top, left: 0, bottom: 0, right: 0)
        
        self.tableView.tableHeaderView = self.tokenHeaderViewController.view
        
        self.tokenHeaderViewController.view.snp.remakeConstraints { [unowned self] (maker) -> Void in
            maker.centerX.equalToSuperview()
            maker.width.equalTo(self.tableView.snp.width)
            maker.top.equalToSuperview()
            maker.bottom.equalToSuperview()
        }
    }
    
    private func setupPullRefresh() {
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
            var tokenAddress: String?
            if let tokenAddr = weakSelf.tokenAddress {
                tokenAddress = tokenAddr
            } else if let tokenAddr = weakSelf.tokenInfo?.address {
                tokenAddress = tokenAddr
            }
            guard let tAddress = tokenAddress else {
                return
            }
            if weakSelf.currentSegment == 1 && weakSelf.productsFooterState != .noMoreData{
                weakSelf.getTokenProducts(tAddress, refresh: false)
            } else if weakSelf.currentSegment == 2 && weakSelf.tasksFooterState != .noMoreData {
                weakSelf.getTokenTasks(tAddress, refresh: false)
            } else {
                DispatchQueue.main.async {
                    weakSelf.tableView.switchRefreshFooter(to: .normal)
                }
            }
        }
    }
    
    private func refresh(_ ignoreToken: Bool = false) {
        var tokenAddress: String?
        if let tokenAddr = self.tokenAddress {
            tokenAddress = tokenAddr
        } else if let tokenAddr = self.tokenInfo?.address {
            tokenAddress = tokenAddr
        }
        guard let tAddress = tokenAddress else {
            return
        }
        if !ignoreToken {
            self.getToken(tAddress)
        }
        if self.currentSegment == 1 || self.products.count == 0 {
            self.currentProductPage = 0
            self.getTokenProducts(tAddress, refresh: true)
        }
        
        if self.currentSegment == 2 || self.tasks.count == 0 {
            self.currentTaskPage = 0
            self.getTokenTasks(tAddress, refresh: true)
        }
    }
    
    private func onSegmentControlUpdated() {
        DispatchQueue.main.async {[weak self] in
            guard let weakSelf = self else {
                return
            }
            if weakSelf.currentSegment == 0 {
                weakSelf.refreshFooter.isHidden = true
                weakSelf.fabButton.isHidden = true
            } else if weakSelf.currentSegment == 1 {
                if weakSelf.products.count == 0 {
                    weakSelf.refreshFooter.isHidden = true
                } else {
                    weakSelf.refreshFooter.isHidden = false
                    var isOwned = false
                    if let tokenInfo = weakSelf.tokenInfo {
                        isOwned = tokenInfo.isOwnedByUser(wallet: weakSelf.userInfo?.wallet)
                    }
                    if isOwned {
                        weakSelf.fabButton.isHidden = false
                    }
                }
                weakSelf.tableView.switchRefreshFooter(to: weakSelf.productsFooterState)
            } else if weakSelf.currentSegment == 2 {
                if weakSelf.tasks.count == 0 {
                    weakSelf.refreshFooter.isHidden = true
                } else {
                    weakSelf.refreshFooter.isHidden = false
                    var isOwned = false
                    if let tokenInfo = weakSelf.tokenInfo {
                        isOwned = tokenInfo.isOwnedByUser(wallet: weakSelf.userInfo?.wallet)
                    }
                    if isOwned {
                        weakSelf.fabButton.isHidden = false
                    }
                }
                weakSelf.tableView.switchRefreshFooter(to: weakSelf.tasksFooterState)
            } else {
                weakSelf.refreshFooter.isHidden = true
                var isOwned = false
                if let tokenInfo = weakSelf.tokenInfo {
                    isOwned = tokenInfo.isOwnedByUser(wallet: weakSelf.userInfo?.wallet)
                }
                if isOwned {
                    weakSelf.fabButton.isHidden = false
                }
            }
            weakSelf.tableView.reloadDataWithAutoSizingCellWorkAround()
        }
    }
    
    private func setupFabButton() {
        fabButton.backgroundColor = UIColor.darkDefault
        fabButton.clipsToBounds = true
        fabButton.contentMode = .scaleAspectFit
        fabButton.tintColor = UIColor.white
        let img = UIImage(named: "Add")?.withRenderingMode(.alwaysTemplate)
        fabButton.setImage(img, for: .normal)
        fabButton.layer.cornerRadius = CGFloat(DefaultFabHeight / 2.0)
        fabButton.shadowRadius = 5
        fabButton.shadowOffset = CGSize.zero
        fabButton.shadowColor = UIColor.black
        fabButton.shadowOpacity = 0.3
        self.view.addSubview(fabButton)
        
        fabButton.snp.remakeConstraints {[unowned self] (maker) -> Void in
            maker.trailing.equalToSuperview().offset(-16)
            if #available(iOS 11.0, *) {
                maker.bottom.equalTo(self.view.safeAreaLayoutGuide.snp.bottom).offset(-16)
            } else {
                maker.bottom.equalToSuperview().offset(-80)
            }
            maker.width.equalTo(DefaultFabHeight)
            maker.height.equalTo(DefaultFabHeight)
        }
        
        fabButton.addTarget(self, action: #selector(onFabButtonClick), for: .touchUpInside)
    }
    
    @objc private func onFabButtonClick() {
        if self.tokenInfo?.txStatus ?? 0 == 0 {
            UCAlert.showAlert(imageName: "Warn", title: "警告", desc: "代币未创建完成，请等待", closeBtn: "关闭")
            return
        } else if self.tokenInfo?.txStatus ?? 0 == 1 {
            UCAlert.showAlert(imageName: "Error", title: "错误", desc: "代币创建失败", closeBtn: "关闭")
            return
        }
        if currentSegment == 1 {
            showCreateTokenProduct()
        }else if currentSegment == 2 {
            showCreateTokenTask()
        }
    }
}

extension TokenViewController: UITableViewDelegate, UITableViewDataSource {
    
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        switch self.sectionsMap[section] {
        case "entities":
            return TokenSegmentView.height
        default:
            return 0
        }
    }
    
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        switch self.sectionsMap[section] {
        case "entities":
            return self.segmentControl
        default:
            break
        }
        return nil
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return self.sectionsMap.count
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch self.sectionsMap[section] {
        case "stats":
            return 2
        case "entities":
            if currentSegment == 1 {
                if self.products.count == 0 {
                    return 1
                } else {
                    return self.products.count
                }
            } else if currentSegment == 2 {
                if self.tasks.count == 0 {
                    return 1
                } else {
                    return self.tasks.count
                }
            }
            return 1
        default:
            fatalError("Out of bounds, should not happen")
        }
        return 1
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        var isOwned = false
        if let tokenInfo = self.tokenInfo {
            isOwned = tokenInfo.isOwnedByUser(wallet: self.userInfo?.wallet)
        }
        switch self.sectionsMap[indexPath.section] {
        case "stats":
            if indexPath.row == 0 {
                let cell = tableView.dequeueReusableCell(for: indexPath) as TokenStatsTableCell
                cell.fill(self.tokenInfo)
                return cell
            }
            let cell = tableView.dequeueReusableCell(for: indexPath) as TokenActionsTableCell
            cell.delegate = self
            cell.fill()
            return cell
        case "entities":
            if currentSegment == 1 {
                if self.products.count == 0 {
                    if isOwned {
                        let cell = tableView.dequeueReusableCell(for: indexPath) as EmptyTokenOwnedProductCell
                        cell.fill(self.isLoadingProducts)
                        cell.delegate = self
                        return cell
                    }
                    let cell = tableView.dequeueReusableCell(for: indexPath) as EmptyCell
                    cell.fill("该代币还没有声明权益", isLoading: self.isLoadingProducts)
                    return cell
                }
                let cell = tableView.dequeueReusableCell(for: indexPath) as TokenProductSimpleCell
                cell.fill(self.products[indexPath.row])
                return cell
            }  else if currentSegment == 2 {
                if self.tasks.count == 0 {
                    if isOwned {
                        let cell = tableView.dequeueReusableCell(for: indexPath) as EmptyTokenOwnedTaskCell
                        cell.fill(self.isLoadingTasks)
                        cell.delegate = self
                        return cell
                    }
                    let cell = tableView.dequeueReusableCell(for: indexPath) as EmptyCell
                    cell.fill("还没有设置获取代币任务", isLoading: self.isLoadingProducts)
                    return cell
                }
                let cell = tableView.dequeueReusableCell(for: indexPath) as TokenTaskSimpleCell
                cell.fill(self.tasks[indexPath.row])
                return cell
            }
            if let desc = self.tokenInfo?.desc {
                let cell = tableView.dequeueReusableCell(for: indexPath) as TokenDescriptionCell
                cell.delegate = self
                cell.fill(desc)
                return cell
            } else if isOwned {
                let cell = tableView.dequeueReusableCell(for: indexPath) as EmptyTokenOwnedDescriptionCell
                cell.fill()
                cell.delegate = self
                return cell
            } else {
                let cell = tableView.dequeueReusableCell(for: indexPath) as EmptyCell
                cell.fill("该代币还没有描述", isLoading: false)
                return cell
            }
        default:
            fatalError("Out of bounds, should not happen")
        }
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        switch self.sectionsMap[indexPath.section] {
        case "entities":
            if currentSegment == 0 {
                if let _ = self.tokenInfo?.desc {
                    let vc = ShowTokenDescriptionViewController()
                    vc.tokenInfo = self.tokenInfo
                    vc.delegate = self
                    DispatchQueue.main.async {
                        self.navigationController?.pushViewController(vc, animated: true)
                    }
                }
            } else if currentSegment == 1 && self.products.count > 0 {
                let vc = TokenProductViewController.instantiate()
                let product = self.products[indexPath.row]
                if product.txStatus ?? 0 == 0 {
                    UCAlert.showAlert(imageName: "Warn", title: "警告", desc: "未创建完成，请等待", closeBtn: "关闭")
                    return
                }else if product.txStatus == -1 {
                    UCAlert.showAlert(imageName: "Error", title: "错误", desc: "创建失败", closeBtn: "关闭")
                    return
                }
                vc.setProduct(product)
                DispatchQueue.main.async {
                    self.navigationController?.pushViewController(vc, animated: true)
                }
            } else if currentSegment == 2 && self.tasks.count > 0 {
                let vc = TokenTaskViewController.instantiate()
                vc.setTask(self.tasks[indexPath.row])
                DispatchQueue.main.async {
                    self.navigationController?.pushViewController(vc, animated: true)
                }
            }
        default:
            break
        }
    }
    
    func tableView(_ tableView: UITableView, shouldHighlightRowAt indexPath: IndexPath) -> Bool {
        switch self.sectionsMap[indexPath.section] {
        case "entities":
            if (currentSegment == 1 && self.products.count == 0) || (currentSegment == 2 && self.tasks.count == 0) {
                return false
            }
            return true
        default:
            return false
        }
    }
    
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        guard let navigationController = self.navigationController else {
            return
        }
        statusBarUpdater?.refreshStatusBarStyle()
        if scrollView.contentOffset.y >= 118 && navigationItem.title == nil {
            navigationItem.title = self.tokenInfo?.name
            navigationController.navigationBar.tintColor = UIColor.primaryBlue
            navigationController.navigationBar.isTranslucent = false
            
            let size = navigationController.navigationBar.frame.size
            UIGraphicsBeginImageContextWithOptions(size, false, UIScreen.main.scale)
            let context = UIGraphicsGetCurrentContext()
            UIColor.dimmedLightBackground.setFill()
            context?.addRect(CGRect(x: 0, y: 0, width: size.width, height: 1))
            context?.drawPath(using: .fill)
            let image = UIGraphicsGetImageFromCurrentImageContext()
            UIGraphicsEndImageContext()
            navigationController.navigationBar.shadowImage = image
            
            self.tableView.contentInset = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)
            /*let statusBarWindow: UIWindow = UIApplication.shared.value(forKeyPath: "statusBarWindow") as! UIWindow
            let statusBar: UIView = statusBarWindow.value(forKeyPath: "statusBar") as! UIView
            statusBar.backgroundColor = UIColor(displayP3Red: 255, green: 255, blue: 255, alpha: 0.8)
            */
        } else if scrollView.contentOffset.y < 118 &&  navigationItem.title != nil {
            navigationItem.title = nil
            self.updatedImageColors(self.headerColors)
            navigationController.navigationBar.isTranslucent = true
            navigationController.navigationBar.shadowImage = UIImage()
            let top = navigationController.navigationBar.bounds.height + 5
            self.tableView.contentInset = UIEdgeInsets(top: -1 * top, left: 0, bottom: 0, right: 0)
            /*let statusBarWindow: UIWindow = UIApplication.shared.value(forKeyPath: "statusBarWindow") as! UIWindow
            let statusBar: UIView = statusBarWindow.value(forKeyPath: "statusBar") as! UIView
            statusBar.backgroundColor = UIColor.clear
            */
        }
    }
    
    override var childViewControllerForStatusBarStyle: UIViewController? {
        return statusBarUpdater
    }
}

extension TokenViewController: UIViewControllerTransitioningDelegate {
    
    public func animationController(forPresented presented: UIViewController, presenting: UIViewController, source: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        return FadeTransition(transitionDuration: 0.5, startingAlpha: 0.8)
    }
    
    public func animationController(forDismissed dismissed: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        return FadeTransition(transitionDuration: 0.5, startingAlpha: 0.8)
    }
    
}

extension TokenViewController: LoginViewDelegate {
    func loginSucceeded(token: APIAccessToken?) {
        self.onSegmentControlUpdated()
    }
}

extension TokenViewController {
    
    private func showLogin() {
        let loginVC = LoginViewController.instantiate()
        loginVC.delegate = self
        self.navigationController?.pushViewController(loginVC, animated: true)
    }
    
    private func getToken(_ tokenAddress: String) {
        UCTokenService.getInfo(
            tokenAddress,
            provider: self.tokenServiceProvider)
        .then(in: .main, {[weak self] token in
            guard let weakSelf = self else {
                return
            }
            weakSelf.setToken(token)
        }).catch(in: .main, { error in
            UCAlert.showAlert(imageName: "Error", title: "错误", desc: (error as! UCAPIError).description, closeBtn: "关闭")
        }).always(in: .main, body: { [weak self] in
            guard let weakSelf = self else {
                return
            }
            weakSelf.spinner.stop()
            weakSelf.tableView.switchRefreshHeader(to: .normal(.success, 0.3))
            weakSelf.tableView.reloadDataWithAutoSizingCellWorkAround()
        })
    }
    
    private func getTokenProducts(_ tokenAddress: String, refresh: Bool = false) {
        if self.isLoadingProducts {
            return
        }
        self.isLoadingProducts = true
        
        UCTokenProductService.listTokenProduct(
            tokenAddress,
            self.currentProductPage,
            DefaultPageSize,
            provider: self.tokenProductServiceProvider)
        .then(in: .main, {[weak self] products in
            guard let weakSelf = self else {
                return
            }
            if refresh {
                weakSelf.products = products
            } else {
                weakSelf.products.append(contentsOf: products)
            }
            if products.count > 0 && products.count >= DefaultPageSize {
                weakSelf.currentProductPage += 1
                weakSelf.productsFooterState = .normal
            } else {
                weakSelf.productsFooterState = .noMoreData
            }
        }).catch(in: .main,  { error in
            UCAlert.showAlert(imageName: "Error", title: "错误", desc: (error as! UCAPIError).description, closeBtn: "关闭")
        }).always(in: .main, body: { [weak self] in
            guard let weakSelf = self else {
                return
            }
            weakSelf.isLoadingProducts = false
            weakSelf.tableView.switchRefreshHeader(to: .normal(.success, 0.3))
            weakSelf.onSegmentControlUpdated()
        })
    }
    
    private func getTokenTasks(_ tokenAddress: String, refresh: Bool = false) {
        if self.isLoadingTasks {
            return
        }
        self.isLoadingTasks = true
        
        UCTokenTaskService.listTokenTask(
            tokenAddress,
            self.currentTaskPage,
            DefaultPageSize,
            provider: self.tokenTaskServiceProvider)
        .then(in: .main, {[weak self] tasks in
            guard let weakSelf = self else {
                return
            }
            if refresh {
                weakSelf.tasks = tasks
            } else {
                weakSelf.tasks.append(contentsOf: tasks)
            }
            if tasks.count > 0 && tasks.count >= DefaultPageSize {
                weakSelf.currentTaskPage += 1
                weakSelf.tasksFooterState = .normal
            } else {
                weakSelf.tasksFooterState = .noMoreData
            }
        }).catch(in: .main, { error in
            UCAlert.showAlert(imageName: "Error", title: "错误", desc: (error as! UCAPIError).description, closeBtn: "关闭")
        }).always(in: .main, body: { [weak self] in
            guard let weakSelf = self else {
                return
            }
            weakSelf.isLoadingTasks = false
            weakSelf.tableView.switchRefreshHeader(to: .normal(.success, 0.3))
            weakSelf.onSegmentControlUpdated()
        })
    }
}

extension TokenViewController: TokenViewDelegate {
    func updatedImageColors(_ colors: UIImageColors?) {
        self.headerColors = colors
        self.refreshHeader.backgroundColor = UIColor.clear
        DispatchQueue.main.async {[weak self] in
            guard let weakSelf = self else {
                return
            }
            if weakSelf.navigationItem.title == nil, let colors = weakSelf.headerColors {
                weakSelf.navigationController?.navigationBar.tintColor = colors.background
                weakSelf.refreshHeader.tintColor = colors.background
            } else if weakSelf.navigationItem.title != nil {
                weakSelf.navigationController?.navigationBar.tintColor = UIColor.primaryBlue
                weakSelf.refreshHeader.tintColor = .primaryBlue
            } else {
                weakSelf.navigationController?.navigationBar.tintColor = UIColor.white
                weakSelf.refreshHeader.tintColor = .primaryBlue
            }
        }
    }
    
    func showEditDescription() {
        if self.userInfo == nil {
            self.showLogin()
            return
        }
        let editorVC = EditTokenDescriptionViewController()
        editorVC.tokenInfo = self.tokenInfo
        editorVC.delegate = self
        DispatchQueue.main.async {[weak self] in
            guard let weakSelf = self else {
                return
            }
            weakSelf.navigationController?.pushViewController(editorVC, animated: true)
        }
    }
    
    func shouldReload() {
        DispatchQueue.main.async { [weak self] in
            guard let weakSelf = self else {
                return
            }
            weakSelf.tableView.reloadDataWithAutoSizingCellWorkAround()
        }
    }
    
    func updatedTokenDescription(_ desc: String) {
        self.tokenInfo?.desc = desc
        DispatchQueue.main.async { [weak self] in
            guard let weakSelf = self else {
                return
            }
            weakSelf.tableView.reloadDataWithAutoSizingCellWorkAround()
        }
    }
    
    func descriptionSelected() {
        if let _ = self.tokenInfo?.desc {
            let vc = ShowTokenDescriptionViewController()
            vc.tokenInfo = self.tokenInfo
            vc.delegate = self
            DispatchQueue.main.async { [weak self] in
                guard let weakSelf = self else {
                    return
                }
                weakSelf.navigationController?.pushViewController(vc, animated: true)
            }
        }
    }
    
    func segmentChanged(_ index: Int) {
        self.currentSegment = index
        self.onSegmentControlUpdated()
    }
    
    func showCreateTokenProduct() {
        if self.userInfo == nil {
            self.showLogin()
            return
        }
        let vc = CreateTokenProductViewController.instantiate()
        vc.tokenInfo = self.tokenInfo
        vc.delegate = self
        DispatchQueue.main.async { [weak self] in
            guard let weakSelf = self else {
                return
            }
            weakSelf.navigationController?.pushViewController(vc, animated: true)
        }
    }
    
    func showCreateTokenTask() {
        if self.userInfo == nil {
            self.showLogin()
            return
        }
        let vc = CreateTokenTaskViewController.instantiate()
        vc.tokenInfo = self.tokenInfo
        vc.delegate = self
        DispatchQueue.main.async { [weak self] in
            guard let weakSelf = self else {
                return
            }
            weakSelf.navigationController?.pushViewController(vc, animated: true)
        }
    }
}

extension TokenViewController: CreateTokenProductDelegate {
    func tokenProductCreated(product: APITokenProduct) {
        var tokenAddress: String?
        if let tokenAddr = self.tokenAddress {
            tokenAddress = tokenAddr
        } else if let tokenAddr = self.tokenInfo?.address {
            tokenAddress = tokenAddr
        }
        guard let tAddress = tokenAddress else {
            return
        }
        self.currentProductPage = 0
        self.getTokenProducts(tAddress, refresh: true)
    }
}

extension TokenViewController: CreateTokenTaskDelegate {
    func tokenTaskCreated(task: APITokenTask) {
        var tokenAddress: String?
        if let tokenAddr = self.tokenAddress {
            tokenAddress = tokenAddr
        } else if let tokenAddr = self.tokenInfo?.address {
            tokenAddress = tokenAddr
        }
        guard let tAddress = tokenAddress else {
            return
        }
        self.currentTaskPage = 0
        self.getTokenTasks(tAddress, refresh: true)
    }
}

extension TokenViewController: TokenActionsTableCellDelegate {
    func showPay() {
        guard let userInfo = self.userInfo else {
            self.showLogin()
            return
        }
        if userInfo.canPay == 1 {
            
        } else {
            let vc = SettingPaymentPasswdViewController.instantiate()
            DispatchQueue.main.async { [weak self] in
                guard let weakSelf = self else {
                    return
                }
                weakSelf.present(vc, animated: true, completion: nil)
            }
        }
    }
    
    func showCollect() {
        let vc = QRCodeCollectViewController.instantiate()
        vc.tokenInfo = self.tokenInfo
        DispatchQueue.main.async { [weak self] in
            guard let weakSelf = self else {
                return
            }
            weakSelf.navigationController?.pushViewController(vc, animated: true)
        }
    }
    
    func showScan() {
        let vc = ScanViewController()
        DispatchQueue.main.async { [weak self] in
            guard let weakSelf = self else {
                return
            }
            weakSelf.present(vc, animated: true, completion: nil)
        }
    }
}
