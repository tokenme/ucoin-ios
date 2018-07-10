//
//  TokenTaskEvidencesViewController.swift
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

class TokenTaskEvidencesViewController: UIViewController {
    private var tokenTask: APITokenTask?
    
    private var evidences: [APITokenTaskEvidence] = []
    private var tableViews: [Int8:TokenTaskEvidencesTableViewController] = [:]
    fileprivate let segmentControl = TokenTaskEvidenceSegmentView()
    fileprivate var currentSegment: Int = 0
    
    fileprivate var isLoadingEvidences: Bool = false
    fileprivate var currentEvidencePage: UInt = 0
    fileprivate var evidencesFooterState: FooterRefresherState = .normal
    fileprivate let refreshFooter = DefaultRefreshFooter.footer()
    
    private var tokenTaskEvidenceServiceProvider = MoyaProvider<UCTokenTaskEvidenceService>(plugins: [networkActivityPlugin, AccessTokenPlugin(tokenClosure: AccessTokenClosure())])
    
    public func setTask(_ task: APITokenTask?) {
        self.tokenTask = task
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
        
        self.navigationItem.title = "代币任务证明"
        
        self.extendedLayoutIncludesOpaqueBars = true
        
        self.segmentControl.delegate = self
        self.view.addSubview(segmentControl)
        segmentControl.snp.remakeConstraints {[unowned self] (maker) -> Void in
            maker.leading.equalToSuperview()
            maker.trailing.equalToSuperview()
            if #available(iOS 11.0, *) {
                maker.top.equalTo(self.view.safeAreaLayoutGuide.snp.top)
            } else {
                maker.top.equalToSuperview().offset(64)
            }
            maker.height.equalTo(TokenTaskEvidenceSegmentView.height)
        }
        
        guard let task = self.tokenTask else {
            return
        }
        tableViews[-1] = TokenTaskEvidencesTableViewController.instantiate()
        tableViews[-1]?.setTask(task, approveStatus: -1)
        
        tableViews[0] = TokenTaskEvidencesTableViewController.instantiate()
        tableViews[0]?.setTask(task, approveStatus: 0)
        
        tableViews[1] = TokenTaskEvidencesTableViewController.instantiate()
        tableViews[1]?.setTask(task, approveStatus: 1)
        
        onSegmentControlUpdated()
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
    
    static func instantiate() -> TokenTaskEvidencesViewController
    {
        return UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "TokenTaskEvidencesViewController") as! TokenTaskEvidencesViewController
    }
    
    private func onSegmentControlUpdated() {
        DispatchQueue.main.async {[weak self] in
            guard let weakSelf = self else {
                return
            }
            if let tableView = weakSelf.tableViews[weakSelf.currentApproveStatus()]?.view {
                for subview in weakSelf.view.subviews {
                    if subview.tag == 100 {
                        subview.removeFromSuperview()
                    }
                }
                tableView.tag = 100
                weakSelf.view.addSubview(tableView)
                tableView.snp.remakeConstraints {[weak weakSelf] (maker) -> Void in
                    guard let weakSelfSub = weakSelf else {
                        return
                    }
                    maker.leading.equalToSuperview()
                    maker.trailing.equalToSuperview()
                    maker.top.equalTo(weakSelfSub.segmentControl.snp.bottom)
                    if #available(iOS 11.0, *) {
                        maker.bottom.equalTo(weakSelfSub.view.safeAreaLayoutGuide.snp.bottom)
                    } else {
                        maker.bottom.equalToSuperview().offset(-49)
                    }
                }
            }
        }
    }
    
    private func currentApproveStatus() -> Int8 {
        switch self.currentSegment {
        case 0: return 0
        case 1: return 1
        case 2: return -1
        default: return 0
        }
    }
}

extension TokenTaskEvidencesViewController: UIViewControllerTransitioningDelegate {
    
    public func animationController(forPresented presented: UIViewController, presenting: UIViewController, source: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        return FadeTransition(transitionDuration: 0.5, startingAlpha: 0.8)
    }
    
    public func animationController(forDismissed dismissed: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        return FadeTransition(transitionDuration: 0.5, startingAlpha: 0.8)
    }
    
}

extension TokenTaskEvidencesViewController: TokenTaskEvidencesViewDelegate {
    func approveEvidence(_ evidenceId: UInt64, approveStatus: Int8) { }
    
    func segmentChanged(_ index: Int) {
        self.currentSegment = index
        self.onSegmentControlUpdated()
    }
}
