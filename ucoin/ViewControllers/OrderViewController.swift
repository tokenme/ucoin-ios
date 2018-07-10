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

class OrderViewController: UIViewController {
    
    private var userInfo: APIUser?
    private var orderInfo: APIOrder?
    
    private let tableView = UITableView(frame: CGRect.zero, style: UITableViewStyle.plain)
    
    private var sectionsMap = ["info", "qrcode"]
    private let spinner = LoaderModal(backgroundColor: UIColor.white)!
    
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
        
        if let navigationController = self.navigationController {
            navigationController.navigationBar.isTranslucent = false
            navigationController.navigationBar.setBackgroundImage(UIImage(), for: .default)
            
            let size = navigationController.navigationBar.frame.size
            UIGraphicsBeginImageContextWithOptions(size, false, UIScreen.main.scale)
            let context = UIGraphicsGetCurrentContext()
            UIColor.dimmedLightBackground.setFill()
            context?.addRect(CGRect(x: 0, y: 0, width: size.width, height: 1))
            context?.drawPath(using: .fill)
            let image = UIGraphicsGetImageFromCurrentImageContext()
            UIGraphicsEndImageContext()
            navigationController.navigationBar.shadowImage = image
        }
        
        self.navigationItem.title = "订单详情"
        
        self.extendedLayoutIncludesOpaqueBars = true
        
        if let userInfo: DefaultsUser = Defaults[.user] {
            self.userInfo = APIUser.init(user: userInfo)
        }
        
        guard let orderInfo = self.orderInfo else {
            return
        }
        
        self.setupTableView()
        
        self.setupPullRefresh()
        DispatchQueue.main.async {
            self.tableView.reloadDataWithAutoSizingCellWorkAround()
        }
        
        self.view.addSubview(spinner)
        
        if orderInfo.product!.token == nil {
            self.spinner.start()
        }
        
        self.refresh()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        if let navigationController = self.navigationController {
            if #available(iOS 11.0, *) {
                navigationController.navigationBar.prefersLargeTitles = false
                self.navigationItem.largeTitleDisplayMode = .automatic;
            }
            
            navigationController.navigationBar.isTranslucent = false
            navigationController.setNavigationBarHidden(false, animated: animated)
        }
        
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
        self.view.addSubview(tableView)
        self.tableView.snp.remakeConstraints { (maker) -> Void in
            maker.leading.equalToSuperview()
            maker.trailing.equalToSuperview()
            maker.top.equalToSuperview()
            maker.bottom.equalToSuperview()
        }
        self.tableView.delegate = self
        self.tableView.dataSource = self
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

extension OrderViewController: UITableViewDelegate, UITableViewDataSource {
    
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 0
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.sectionsMap.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
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
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        switch self.sectionsMap[indexPath.row] {
        case "info":
            guard let product = self.orderInfo?.product else {
                return
            }
            let vc = TokenProductViewController.instantiate()
            vc.setProduct(product)
            DispatchQueue.main.async {
                self.navigationController?.pushViewController(vc, animated: true)
            }
        default:
            break
        }
    }
    
    func tableView(_ tableView: UITableView, shouldHighlightRowAt indexPath: IndexPath) -> Bool {
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
        } else if let token = self.orderInfo?.product?.token {
            tokenVC.setToken(token)
        } else {
            return
        }
        DispatchQueue.main.async {
            self.navigationController?.pushViewController(tokenVC, animated: true)
        }
    }
    
    func gotoProduct(_ productAddress: String?) {}
    
    
}
