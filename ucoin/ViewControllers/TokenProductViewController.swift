//
//  TokenProductViewController.swift
//  ucoin
//
//  Created by Syd on 2018/7/2.
//  Copyright © 2018年 ucoin.io. All rights reserved.
//

import UIKit
import SwiftyUserDefaults
import Moya
import PullToRefreshKit

fileprivate let DefaultPageSize: UInt = 10

class TokenProductViewController: UITableViewController {
    
    fileprivate var userInfo: APIUser?
    fileprivate var productAddress: String?
    fileprivate var tokenProduct: APITokenProduct?
    
    fileprivate var sectionsMap: [String] = ["info", "content", "entities"]
    fileprivate let segmentControl = TokenProductSegmentView()
    fileprivate var currentSegment: Int = 0
    
    private var creatingOrder = false
    fileprivate let contentHeaderView = TokenProductContentHeaderView()
    
    fileprivate var currentOrderPage: UInt = 0
    fileprivate var isLoadingOrders = false
    fileprivate var orders: [APIOrder] = []
    fileprivate var ordersFooterState: FooterRefresherState = .normal
    
    fileprivate var currentCommentPage: UInt = 0
    fileprivate var isLoadingComments = false
    fileprivate var comments: [String] = []
    fileprivate var commentsFooterState: FooterRefresherState = .normal
    
    fileprivate let refreshFooter = DefaultRefreshFooter.footer()
    fileprivate let spinner = LoaderModal(backgroundColor: UIColor.white)!
    
    private var tokenProductServiceProvider = MoyaProvider<UCTokenProductService>(plugins: [networkActivityPlugin, AccessTokenPlugin(tokenClosure: AccessTokenClosure())])
    private var orderServiceProvider = MoyaProvider<UCOrderService>(plugins: [networkActivityPlugin, AccessTokenPlugin(tokenClosure: AccessTokenClosure())])
    
    public func setProductAddress(_ address: String?) {
        self.productAddress = address
        if self.productAddress != nil {
            self.refresh()
        }
    }
    
    public func setProduct(_ product: APITokenProduct?) {
        self.tokenProduct = product
        self.contentHeaderView.setProduct(product)
        self.contentHeaderView.delegate = self
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
        self.navigationItem.title = "代币权益"
        self.extendedLayoutIncludesOpaqueBars = true
        
        if let userInfo: DefaultsUser = Defaults[.user] {
            self.userInfo = APIUser.init(user: userInfo)
        }
        
        if let tokenProduct = self.tokenProduct {
            if tokenProduct.isOwnedByUser(wallet: userInfo?.wallet) {
                let editButton = UIBarButtonItem(barButtonSystemItem: .edit, target: self, action: #selector(showEdit))
                self.navigationItem.rightBarButtonItem = editButton
            }
        }
        
        self.segmentControl.frame = CGRect(x: 0, y: 0, width: tableView.bounds.size.width, height:TokenSegmentView.height)
        self.segmentControl.delegate = self
        
        self.tableView.addSubview(spinner)
        if self.productAddress != "" && self.tokenProduct == nil {
            self.spinner.start()
        }
        
        self.setupTableView()
        
        self.setupPullRefresh()
        
        self.onSegmentControlUpdated()
        
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
        self.tableView.contentOffset = CGPoint(x: 0, y: 0)
        self.tableView.reloadDataWithAutoSizingCellWorkAround()
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    static func instantiate() -> TokenProductViewController
    {
        return UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "TokenProductViewController") as! TokenProductViewController
    }
    
    private func setupTableView() {
        self.tableView.register(cellType: EmptyTokenDescriptionCell.self)
        self.tableView.register(cellType: TokenProductInfoTableCell.self)
        self.tableView.register(cellType: TokenProductContentTableCell.self)
        self.tableView.register(cellType: TokenProductOrderSimpleCell.self)
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
            var address: String?
            if let addr = weakSelf.productAddress {
                address = addr
            } else if let addr = weakSelf.tokenProduct?.address {
                address = addr
            }
            if address == nil {
                return
            }
            if weakSelf.currentSegment == 0 {
                weakSelf.getOrders(address, refresh: false)
            } else if weakSelf.currentSegment == 1 {
                weakSelf.getComments(address, refresh: false)
            } else {
                DispatchQueue.main.async {
                    weakSelf.tableView.switchRefreshFooter(to: .normal)
                }
            }
        }
    }
    
    private func refresh(_ ignoreTask: Bool = false) {
        var address: String?
        if let addr = self.productAddress {
            address = addr
        } else if let addr = self.tokenProduct?.address {
            address = addr
        }
        if address == nil {
            return
        }
        if !ignoreTask {
            self.getTokenProduct(address)
        }
        if self.currentSegment == 0 || self.orders.count == 0 {
            self.currentOrderPage = 0
            self.getOrders(address, refresh: true)
        }
        
        if self.currentSegment == 1 || self.comments.count == 0 {
            self.currentCommentPage = 0
            self.getComments(address, refresh: true)
        }
    }
    
    private func onSegmentControlUpdated() {
        DispatchQueue.main.async {[weak self] in
            guard let weakSelf = self else {
                return
            }
            if weakSelf.currentSegment == 0 {
                if weakSelf.orders.count == 0 {
                    weakSelf.refreshFooter.isHidden = true
                } else {
                    weakSelf.refreshFooter.isHidden = false
                }
                weakSelf.tableView.switchRefreshFooter(to: weakSelf.ordersFooterState)
            } else if weakSelf.currentSegment == 1 {
                if weakSelf.comments.count == 0 {
                    weakSelf.refreshFooter.isHidden = true
                } else {
                    weakSelf.refreshFooter.isHidden = false
                }
                weakSelf.tableView.switchRefreshFooter(to: weakSelf.commentsFooterState)
            }
            weakSelf.tableView.reloadDataWithAutoSizingCellWorkAround()
        }
    }
}

extension TokenProductViewController: UIViewControllerTransitioningDelegate {
    
    public func animationController(forPresented presented: UIViewController, presenting: UIViewController, source: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        return FadeTransition(transitionDuration: 0.5, startingAlpha: 0.8)
    }
    
    public func animationController(forDismissed dismissed: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        return FadeTransition(transitionDuration: 0.5, startingAlpha: 0.8)
    }
    
}

extension TokenProductViewController {
    
    override func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        switch self.sectionsMap[section] {
        case "content":
            return TokenProductContentHeaderView.height
        case "entities":
            return TokenProductSegmentView.height
        default:
            return 0
        }
    }
    
    override func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        switch self.sectionsMap[section] {
        case "content":
            return self.contentHeaderView
        case "entities":
            return self.segmentControl
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
        case "content":
            return 1
        case "entities":
            if currentSegment == 0 {
                if self.orders.count == 0 {
                    return 1
                } else {
                    return self.orders.count
                }
            } else if currentSegment == 1 {
                if self.comments.count == 0 {
                    return 1
                } else {
                    return self.comments.count
                }
            }
            return 1
        default:
            fatalError("Out of bounds, should not happen")
        }
        return 1
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        switch self.sectionsMap[indexPath.section] {
        case "info":
            let cell = tableView.dequeueReusableCell(for: indexPath) as TokenProductInfoTableCell
            cell.fill(self.tokenProduct)
            return cell
        case "content":
            let cell = tableView.dequeueReusableCell(for: indexPath) as TokenProductContentTableCell
            cell.textViewDelegate = self
            cell.fill(self.tokenProduct)
            return cell
        case "entities":
            if self.currentSegment == 0 {
                if self.orders.count == 0 {
                    let cell = tableView.dequeueReusableCell(for: indexPath) as EmptyTokenDescriptionCell
                    cell.fill("还没人下单哦", isLoading: false)
                    return cell
                }
                let cell = tableView.dequeueReusableCell(for: indexPath) as TokenProductOrderSimpleCell
                cell.fill(self.orders[indexPath.row])
                return cell
            } else if self.currentSegment == 1 {
                if self.comments.count == 0 {
                    let cell = tableView.dequeueReusableCell(for: indexPath) as EmptyTokenDescriptionCell
                    cell.fill("还没有评论哦", isLoading: false)
                    return cell
                }
            }
            let cell = tableView.dequeueReusableCell(for: indexPath) as EmptyTokenDescriptionCell
            cell.fill("该代币还没有描述", isLoading: false)
            return cell
        default:
            fatalError("Out of bounds, should not happen")
        }
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        switch self.sectionsMap[indexPath.section] {
        case "entities":
            if currentSegment == 0 && self.orders.count > 0 {
                let vc = OrderViewController.instantiate()
                vc.setOrder(self.orders[indexPath.row])
                DispatchQueue.main.async {
                    self.navigationController?.pushViewController(vc, animated: true)
                }
            }
        default:
            break
        }
    }
    
    override func tableView(_ tableView: UITableView, shouldHighlightRowAt indexPath: IndexPath) -> Bool {
        switch self.sectionsMap[indexPath.section] {
        case "entities":
            if (currentSegment == 0 && (orders[indexPath.row].isOwnedByUser(wallet: userInfo?.wallet) || orders[indexPath.row].isSelledByUser(wallet: userInfo?.wallet))) {
                return true
            }
            return false
        default:
            return false
        }
    }
}

extension TokenProductViewController {
    private func getTokenProduct(_ address: String!) {
        UCTokenProductService.getTokenProduct(
            address,
            provider: self.tokenProductServiceProvider,
            success: {[weak self] product in
                guard let weakSelf = self else {
                    return
                }
                if weakSelf.tokenProduct == nil && product.isOwnedByUser(wallet: weakSelf.userInfo?.wallet) {
                    let editButton = UIBarButtonItem(barButtonSystemItem: .edit, target: weakSelf, action: #selector(weakSelf.showEdit))
                    weakSelf.navigationItem.rightBarButtonItem = editButton
                }
                weakSelf.setProduct(product)
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
    
    private func buyProduct(_ product: APITokenProduct!) {
        if creatingOrder {
            contentHeaderView.failedBuy()
            return
        }
        if product.isOwnedByUser(wallet: userInfo?.wallet) {
            contentHeaderView.failedBuy()
            DispatchQueue.main.async {
                UCAlert.showAlert(imageName: "Error", title: "错误", desc: "您不能购买自己创建的权益", closeBtn: "关闭")
            }
            return
        }
        guard let address = product.address else {
            contentHeaderView.failedBuy()
            return
        }
        creatingOrder = true
        UCOrderService.createOrder(
            address,
            provider: self.orderServiceProvider,
            success: { order in
                print(order.toJSONString())
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
                weakSelf.creatingOrder = false
                DispatchQueue.main.async {
                    weakSelf.spinner.stop()
                    weakSelf.contentHeaderView.failedBuy()
                    weakSelf.tableView.switchRefreshHeader(to: .normal(.success, 0.3))
                    weakSelf.tableView.reloadDataWithAutoSizingCellWorkAround()
                }
        })
    }
    
    private func getComments(_ address: String!, refresh: Bool) {
        
    }
    
    private func getOrders(_ address: String!, refresh: Bool) {
        if self.isLoadingOrders {
            return
        }
        self.isLoadingOrders = true
        
        UCOrderService.listOrders(
            address,
            0,
            self.currentOrderPage,
            DefaultPageSize,
            provider: self.orderServiceProvider,
            success: {[weak self] orders in
                guard let weakSelf = self else {
                    return
                }
                if refresh {
                    weakSelf.orders = orders
                } else {
                    weakSelf.orders.append(contentsOf: orders)
                }
                if orders.count > 0 && orders.count >= DefaultPageSize {
                    weakSelf.currentOrderPage += 1
                    weakSelf.ordersFooterState = .normal
                } else {
                    weakSelf.ordersFooterState = .noMoreData
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
                weakSelf.isLoadingOrders = false
                DispatchQueue.main.async {
                    weakSelf.tableView.switchRefreshHeader(to: .normal(.success, 0.3))
                    weakSelf.onSegmentControlUpdated()
                }
        })
    }
}

extension TokenProductViewController {
    @objc private func showEdit() {
        let vc = EditTokenProductViewController()
        vc.tokenProduct = self.tokenProduct
        vc.delegate = self
        DispatchQueue.main.async {
            self.navigationController?.pushViewController(vc, animated: true)
        }
    }
}

extension TokenProductViewController: UITextViewDelegate {
    func textView(_ textView: UITextView, shouldInteractWith URL: URL, in characterRange: NSRange) -> Bool {
        print("Should interact with: \(URL)")
        return true
    }
}

extension TokenProductViewController: EditTokenProductDelegate {
    func tokenProductUpdated(product: APITokenProduct) {
        if let address = product.address {
            self.getTokenProduct(address)
        }
    }
}

extension TokenProductViewController: TokenProductViewDelegate {
    func segmentChanged(_ index: Int) {
        self.currentSegment = index
        self.onSegmentControlUpdated()
    }
    
    func gotoToken(_ tokenAddress: String?) {
        let tokenVC = TokenViewController.instantiate()
        if tokenAddress != nil {
            tokenVC.setTokenAddress(tokenAddress)
        } else if let tokenAddress = self.tokenProduct?.token?.address {
            tokenVC.setTokenAddress(tokenAddress)
        } else {
            return
        }
        DispatchQueue.main.async {
            self.navigationController?.pushViewController(tokenVC, animated: true)
        }
    }
    
    func buy(_ product: APITokenProduct?) {
        if product != nil {
            buyProduct(product)
            return
        } else if self.tokenProduct != nil {
            buyProduct(self.tokenProduct)
        }
        return
    }
}