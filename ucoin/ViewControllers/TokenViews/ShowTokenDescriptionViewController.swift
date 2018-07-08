//
//  ShowTokenDescriptionViewController.swift
//  ucoin
//
//  Created by Syd on 2018/6/20.
//  Copyright © 2018年 ucoin.io. All rights reserved.
//

import UIKit
import SwiftyMarkdown
import SnapKit

class ShowTokenDescriptionViewController: UIViewController {
    weak public var delegate: TokenViewDelegate?
    
    public var userInfo: APIUser?
    public var tokenInfo: APIToken?
    fileprivate var textView  = UITextView()
    //=============
    // MARK: - denit
    //=============
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.title = "代币介绍"
        self.transitioningDelegate = self
        self.navigationController?.navigationBar.setBackgroundImage(UIImage(), for: .default)
        self.navigationController?.navigationBar.shadowImage = UIImage()
        
        guard let tokenInfo = self.tokenInfo else {
            return
        }
        if tokenInfo.isOwnedByUser(wallet: userInfo?.wallet) {
            let editButton = UIBarButtonItem(barButtonSystemItem: .edit, target: self, action: #selector(showEdit))
            self.navigationItem.rightBarButtonItem = editButton
        }
        
        textView.isUserInteractionEnabled = true
        textView.isEditable = false
        textView.isSelectable = false
        textView.dataDetectorTypes = .all
        
        self.view.addSubview(textView)
        textView.snp.remakeConstraints { (maker) -> Void in
            maker.leading.equalToSuperview().offset(28)
            maker.trailing.equalToSuperview().offset(-28)
            maker.top.equalToSuperview().offset(28)
            maker.bottom.equalToSuperview().offset(-28)
        }
        
        if let description = self.tokenInfo?.desc {
            textView.attributedText = SwiftyMarkdown(string: description).attributedString()
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        self.navigationController?.navigationBar.isTranslucent = false
        self.navigationController?.setNavigationBarHidden(false, animated: animated)
        super.viewWillAppear(animated)
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
}

extension ShowTokenDescriptionViewController: UIViewControllerTransitioningDelegate {
    
    public func animationController(forPresented presented: UIViewController, presenting: UIViewController, source: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        return FadeTransition(transitionDuration: 0.5, startingAlpha: 0.8)
    }
    
    public func animationController(forDismissed dismissed: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        return FadeTransition(transitionDuration: 0.5, startingAlpha: 0.8)
    }
    
}

extension ShowTokenDescriptionViewController {
    @objc private func showEdit() {
        let vc = EditTokenDescriptionViewController()
        vc.tokenInfo = self.tokenInfo
        vc.delegate = self
        DispatchQueue.main.async {
            self.navigationController?.pushViewController(vc, animated: true)
        }
    }
}

extension ShowTokenDescriptionViewController: UITextViewDelegate {
    
    func textView(_ textView: UITextView, shouldInteractWith URL: URL, in characterRange: NSRange) -> Bool {
        print("Should interact with: \(URL)")
        return true
    }
    
}

extension ShowTokenDescriptionViewController: TokenViewDelegate {
    func backward() { }
    
    func showEditDescription() { }
    
    func shouldReload() { }
    
    func descriptionSelected() { }
    
    func segmentChanged(_ index: Int) { }
    
    func showCreateTokenTask() { }
    
    func showCreateTokenProduct() { }
    
    func updatedImageColors(_ colors: UIImageColors?) { }
    
    
    func updatedTokenDescription(_ desc: String) {
        self.tokenInfo?.desc = desc
        self.textView.attributedText = SwiftyMarkdown(string: desc).attributedString()
        if let delegate = self.delegate {
            delegate.shouldReload()
        }
    }
    
}
