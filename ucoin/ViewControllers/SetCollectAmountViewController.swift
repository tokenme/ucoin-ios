//
//  SetPaymentAmountViewControllerView.swift
//  ucoin
//
//  Created by Syd on 2018/7/12.
//  Copyright © 2018年 ucoin.io. All rights reserved.
//

import Foundation
import UIKit

class SetCollectAmountViewController: UIViewController {
    weak public var delegate: SetCollectAmountViewControllerDelegate?
    
    weak public var tokenInfo: APIToken?
    public var amount: UInt64?
    
    @IBOutlet private weak var balanceLabel: UILabel!
    @IBOutlet private weak var amountTextField: UITextField!
    
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
            if #available(iOS 11.0, *) {
                navigationController.navigationBar.prefersLargeTitles = false
                self.navigationItem.largeTitleDisplayMode = .automatic;
            }
            navigationController.navigationBar.isTranslucent = true
            navigationController.navigationBar.setBackgroundImage(UIImage(), for: .default)
            navigationController.navigationBar.shadowImage = UIImage()
        }
        
        self.extendedLayoutIncludesOpaqueBars = true
        
        var balance: Double = 0
        if let decimals = tokenInfo?.decimals {
            if decimals > 0 {
                balance = Double(tokenInfo?.balance ?? 0) / pow(10, Double(decimals))
            }
        }
        let numberFormatter = NumberFormatter()
        numberFormatter.numberStyle = .decimal
        numberFormatter.minimumFractionDigits = 1
        numberFormatter.maximumFractionDigits = 4
        numberFormatter.alwaysShowsDecimalSeparator = true
        let balanceStr = balance.formate(formatter: numberFormatter)
        balanceLabel.text = "余额: \(balanceStr)"
        
        if (amount ?? 0) > 0 {
            let amountDouble = NSDecimalNumber(value: Double(amount ?? 0) * pow(10, Double(self.tokenInfo?.decimals ?? 0)))
            amountTextField.text = numberFormatter.string(from: amountDouble)
        }
        amountTextField.becomeFirstResponder()
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
        
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    static func instantiate() -> SetCollectAmountViewController
    {
        return UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "SetCollectAmountViewController") as! SetCollectAmountViewController
    }
    
    @IBAction private func confirm() {
        var amount: UInt64 = 0
        if let amountTxt = self.amountTextField.text {
            let amountDouble = Double(amountTxt)
            amount = UInt64((amountDouble ?? 0) * pow(10, Double(self.tokenInfo?.decimals ?? 0)))
        }
        if let delegate = self.delegate {
            delegate.setAmount(amount)
        }
        self.navigationController?.popViewController(animated: true)
    }
}

extension SetCollectAmountViewController: UIViewControllerTransitioningDelegate {
    
    public func animationController(forPresented presented: UIViewController, presenting: UIViewController, source: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        return FadeTransition(transitionDuration: 0.5, startingAlpha: 0.8)
    }
    
    public func animationController(forDismissed dismissed: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        return FadeTransition(transitionDuration: 0.5, startingAlpha: 0.8)
    }
}

protocol SetCollectAmountViewControllerDelegate: NSObjectProtocol {
    func setAmount(_ amount: UInt64)
}
