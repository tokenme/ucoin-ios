//
//  OrderViewController.swift
//  ucoin
//
//  Created by Syd on 2018/7/6.
//  Copyright © 2018年 ucoin.io. All rights reserved.
//

import UIKit
import SwiftyUserDefaults
import Moya
import PullToRefreshKit
import swiftScan

fileprivate let DefaultPageSize: UInt = 10
fileprivate let DefaultFabHeight = 40.0

class OrderViewController: UITableViewController {
    
    fileprivate var userInfo: APIUser?
    fileprivate var orderInfo: APIOrder?
    fileprivate var sectionsMap = ["info", "qrcode"]
    fileprivate let spinner = LoaderModal(backgroundColor: UIColor.white)!
    
    private var orderServiceProvider = MoyaProvider<UCOrderService>(plugins: [networkActivityPlugin, AccessTokenPlugin(tokenClosure: AccessTokenClosure())])
    
    public func setOrder(_ order: APIOrder?) {
        self.orderInfo = order
        if order == nil || order?.product!.token == nil {
            refresh()
        }
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
        self.navigationItem.title = "订单详情"
        
        self.extendedLayoutIncludesOpaqueBars = true
        
        if let userInfo: DefaultsUser = Defaults[.user] {
            self.userInfo = APIUser.init(user: userInfo)
        }
        
        guard let orderInfo = self.orderInfo else {
            return
        }
        
        self.tableView.addSubview(spinner)
        
        if orderInfo.product!.token == nil {
            self.spinner.start()
        }
        
        self.setupTableView()
        
        self.setupPullRefresh()
        DispatchQueue.main.async {
            self.tableView.reloadDataWithAutoSizingCellWorkAround()
        }
        
        self.refresh()
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
    
    static func instantiate() -> OrderViewController
    {
        return UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "OrderViewController") as! OrderViewController
    }
    
    private func setupTableView() {
        self.tableView.register(cellType: OrderQrcodeTableCell.self)
        self.tableView.register(cellType: OrderInfoTableCell.self)
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
        self.tableView.configRefreshHeader(with: refreshHeader, container:self) { [weak self] in
            guard let weakSelf = self else {
                return
            }
            weakSelf.refresh()
        }
    }
    
    private func refresh() {
        guard let order = self.orderInfo else {
            return
        }
        guard let tokenId = order.tokenId else {
            return
        }
        guard let product = order.product else {
            return
        }
        guard let address = product.address else {
            return
        }
        self.getOrder(tokenId, address)
    }
}

extension OrderViewController: UIViewControllerTransitioningDelegate {
    
    public func animationController(forPresented presented: UIViewController, presenting: UIViewController, source: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        return FadeTransition(transitionDuration: 0.5, startingAlpha: 0.8)
    }
    
    public func animationController(forDismissed dismissed: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        return FadeTransition(transitionDuration: 0.5, startingAlpha: 0.8)
    }
    
}

extension OrderViewController {
    
    override func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 0
    }
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.sectionsMap.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        switch self.sectionsMap[indexPath.row] {
        case "info":
            let cell = tableView.dequeueReusableCell(for: indexPath) as OrderInfoTableCell
            cell.delegate = self
            cell.fill(self.orderInfo)
            return cell
        case "qrcode":
            let cell = tableView.dequeueReusableCell(for: indexPath) as OrderQrcodeTableCell
            cell.fill(self.orderInfo)
            return cell
        default:
            fatalError("Out of bounds, should not happen")
        }
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        switch self.sectionsMap[indexPath.row] {
        case "info":
            guard let product = self.orderInfo?.product else {
                return
            }
            let vc = TokenProductViewController.instantiate()
            vc.setProductAddress(product.address)
            DispatchQueue.main.async {
                self.navigationController?.pushViewController(vc, animated: true)
            }
        default:
            break
        }
    }
    
    override func tableView(_ tableView: UITableView, shouldHighlightRowAt indexPath: IndexPath) -> Bool {
        return true
    }
}

extension OrderViewController {
    private func getOrder(_ tokenId: UInt64!, _ productAddress: String!) {
        UCOrderService.getOrder(
            tokenId,
            productAddress,
            provider: self.orderServiceProvider,
            success: {[weak self] order in
                guard let weakSelf = self else {
                    return
                }
                weakSelf.setOrder(order)
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
}

extension OrderViewController: OrderViewDelegate {
    func gotoToken(_ tokenAddress: String?) {
        let tokenVC = TokenViewController.instantiate()
        if tokenAddress != nil {
            tokenVC.setTokenAddress(tokenAddress)
        } else if let tokenAddress = self.orderInfo?.product?.token?.address {
            tokenVC.setTokenAddress(tokenAddress)
        } else {
            return
        }
        DispatchQueue.main.async {
            self.navigationController?.pushViewController(tokenVC, animated: true)
        }
    }
    
    func gotoProduct(_ productAddress: String?) {}
    
    
}
