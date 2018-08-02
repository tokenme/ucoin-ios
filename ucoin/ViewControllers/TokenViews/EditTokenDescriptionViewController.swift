//
//  EditTokenDescriptionView.swift
//  ucoin
//
//  Created by Syd on 2018/6/19.
//  Copyright © 2018年 ucoin.io. All rights reserved.
//

import UIKit
import Marklight
import SnapKit
import Moya

class EditTokenDescriptionViewController: UIViewController {
    
    weak public var delegate: TokenViewDelegate?
    weak public var tokenInfo: APIToken?
    
    private var tokenServiceProvider = MoyaProvider<UCTokenService>(plugins: [networkActivityPlugin, AccessTokenPlugin(tokenClosure: AccessTokenClosure())])
    
    fileprivate var spinner = LoaderModal(backgroundColor: UIColor.white.withAlphaComponent(0.6))!
    
    fileprivate var textView : UITextView?
    fileprivate let textStorage = MarklightTextStorage()
    //=============
    // MARK: - denit
    //=============
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.title = "编辑代币介绍"
        self.transitioningDelegate = self
        
        if let navigationController = self.navigationController {
            if #available(iOS 11.0, *) {
                navigationController.navigationBar.prefersLargeTitles = true
                self.navigationItem.largeTitleDisplayMode = .automatic;
            }
            navigationController.navigationBar.isTranslucent = false
            navigationController.navigationBar.setBackgroundImage(UIImage(), for: .default)
            navigationController.navigationBar.shadowImage = UIImage()
        }
        
        guard let tokenInfo = self.tokenInfo else {
            return
        }
        
        self.title = tokenInfo.name!
        
        let saveButton = UIBarButtonItem(barButtonSystemItem: .save, target: self, action: #selector(save))
        self.navigationItem.rightBarButtonItem = saveButton
        
        textStorage.marklightTextProcessor.codeColor = UIColor.orange
        textStorage.marklightTextProcessor.quoteColor = UIColor.darkGray
        textStorage.marklightTextProcessor.syntaxColor = UIColor.blue
        textStorage.marklightTextProcessor.codeFontName = "Courier"
        textStorage.marklightTextProcessor.fontTextStyle = UIFontTextStyle.subheadline.rawValue
        textStorage.marklightTextProcessor.hideSyntax = false
        
        let layoutManager = NSLayoutManager()
        
        // Assign the `UITextView`'s `NSLayoutManager` to the `NSTextStorage` subclass
        textStorage.addLayoutManager(layoutManager)
        
        let textContainer = NSTextContainer()
        layoutManager.addTextContainer(textContainer)
        
        self.textView = UITextView(frame: view.bounds, textContainer: textContainer)
        
        guard let textView = textView else { return }
        
        textView.textContainerInset = UIEdgeInsetsMake(4, 4, 4, 4)
        textView.isEditable = true
        
        if #available(iOS 11.0, *) {
            textView.smartDashesType = .no
            textView.smartQuotesType = .no
        }
        
        self.view.addSubview(textView)
        textView.snp.remakeConstraints { (maker) -> Void in
            maker.leading.equalToSuperview().offset(8)
            maker.trailing.equalToSuperview().offset(-8)
            maker.top.equalToSuperview().offset(8)
            maker.bottom.equalToSuperview().offset(-8)
        }
        
        if let description = self.tokenInfo?.desc {
            let attributedString = NSAttributedString(string: description)
            
            // Set the loaded string to the `UITextView`
            textStorage.append(attributedString)
        }
        
        self.view.addSubview(spinner)
        
        textView.becomeFirstResponder()
        
        self.view.backgroundColor = UIColor.white
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        if let navigationController = self.navigationController {
            if #available(iOS 11.0, *) {
                navigationController.navigationBar.prefersLargeTitles = true
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
    
}

extension EditTokenDescriptionViewController: UIViewControllerTransitioningDelegate {
    
    public func animationController(forPresented presented: UIViewController, presenting: UIViewController, source: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        return FadeTransition(transitionDuration: 0.5, startingAlpha: 0.8)
    }
    
    public func animationController(forDismissed dismissed: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        return FadeTransition(transitionDuration: 0.5, startingAlpha: 0.8)
    }
    
}

extension EditTokenDescriptionViewController {
    @objc private func save() {
        guard let desc = textView?.text else {
            return
        }
        guard let token = self.tokenInfo else {
            return
        }
        guard let updateToken = APIToken.init() else {
            return
        }
        updateToken.desc = desc
        updateToken.address = token.address
        
        self.spinner.start()
        UCTokenService.updateToken(
            updateToken,
            provider: self.tokenServiceProvider)
        .then(in: .main, {[weak self] token in
            guard let weakSelf = self else {
                return
            }
            guard let desc = token.desc else {
                return
            }
            if let delegate = weakSelf.delegate {
                delegate.updatedTokenDescription(desc)
            }
            weakSelf.navigationController?.popViewController(animated: true)
        }).catch(in: .main, {error in
            UCAlert.showAlert(imageName: "Error", title: "错误", desc: (error as! UCAPIError).description, closeBtn: "关闭")
        }).always(in: .main, body: { [weak self] in
            guard let weakSelf = self else {
                return
            }
            weakSelf.spinner.stop()
        })
    }
}
