//
//  CreateTokenViewController.swift
//  ucoin
//
//  Created by Syd on 2018/6/10.
//  Copyright © 2018年 ucoin.io. All rights reserved.
//

import UIKit
import ImageRow
import SnapKit
import Eureka
import Toucan
import Moya
import Qiniu
import Hydra

fileprivate let DefaultLogoWidth = 180

class CreateTokenViewController: FormViewController {
    weak public var delegate: CreateTokenViewDelegate?
    
    fileprivate var submitting: Bool = false
    
    private var tokenServiceProvider = MoyaProvider<UCTokenService>(plugins: [networkActivityPlugin, AccessTokenPlugin(tokenClosure: AccessTokenClosure())])
    private var qiniuServiceProvider = MoyaProvider<UCQiniuService>(plugins: [networkActivityPlugin, AccessTokenPlugin(tokenClosure: AccessTokenClosure())])
    
    fileprivate let spinner = LoaderModal(backgroundColor: UIColor(displayP3Red: 255, green: 255, blue: 255, alpha: 0.6))!
    
    //=============
    // MARK: - denit
    //=============
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        if let navigationController = self.navigationController {
            if #available(iOS 11.0, *) {
                navigationController.navigationBar.prefersLargeTitles = true
                self.navigationItem.largeTitleDisplayMode = .automatic;
            }
            navigationController.navigationBar.isTranslucent = false
            navigationController.navigationBar.setBackgroundImage(UIImage(), for: .default)
            navigationController.navigationBar.shadowImage = UIImage()
        }
        
        self.navigationItem.title = "造币"
        
        let saveButton = UIBarButtonItem(barButtonSystemItem: .save, target: self, action: #selector(createToken))
        self.navigationItem.rightBarButtonItem = saveButton
        
        self.view.addSubview(spinner)
        
        TextRow.defaultCellUpdate = { cell, row in
            if !row.isValid {
                cell.titleLabel?.textColor = .red
            }
        }
        
        IntRow.defaultCellUpdate = { cell, row in
            if !row.isValid {
                cell.titleLabel?.textColor = .red
            }
        }
        
        form +++
            
            Section(header: "填写代币信息", footer: "如: Ethereum, BtcCoin")
            <<< TextRow() {
                $0.tag = "name"
                $0.title = "名称"
                $0.placeholder = ""
                $0.add(rule: RuleRequired())
                $0.add(rule: RuleMinLength(minLength: 2))
                $0.add(rule: RuleMaxLength(maxLength: 16))
                $0.add(rule: RuleRegExp(regExpr: "^[_A-Za-z0-9-+\\.\\s]+$"))
                $0.validationOptions = .validatesOnChange
            }
            
            +++ Section(footer: "如: ETH, BTC")
            <<< TextRow() {
                $0.tag = "symbol"
                $0.title = "缩写"
                $0.placeholder = ""
                $0.add(rule: RuleRequired())
                $0.add(rule: RuleMinLength(minLength: 2))
                $0.add(rule: RuleMaxLength(maxLength: 8))
                $0.add(rule: RuleRegExp(regExpr: "^[A-Za-z0-9]+$"))
                $0.validationOptions = .validatesOnChange
            }.onChange{ row in
                row.value = (row.value ?? "").uppercased()
                row.updateCell()
            }
            
            +++ Section()
            <<< IntRow(){
                $0.tag = "totalSupply"
                $0.title = "发行量"
                $0.value = 1000000000
                let formatter = NumberFormatter()
                formatter.locale = .current
                formatter.numberStyle = .scientific
                $0.formatter = formatter
                $0.add(rule: RuleGreaterOrEqualThan(min: 10))
                $0.add(rule: RuleSmallerOrEqualThan(max: 1000000000))
                $0.validationOptions = .validatesOnChange
            }
            
            <<< IntRow() {
                $0.tag = "decimals"
                $0.title = "小数位"
                $0.value = 9
                $0.add(rule: RuleGreaterOrEqualThan(min: 2))
                $0.add(rule: RuleSmallerOrEqualThan(max: 9))
                $0.validationOptions = .validatesOnChange
            }
            
            +++ Section()
            <<< ImageRow(){
                $0.tag = "logo"
                $0.title = "图标"
                $0.sourceTypes = .PhotoLibrary
                $0.useEditedImage = true
                $0.allowEditor = true
            }.onChange{ row in
                if let image = row.value {
                    if image != row.placeholderImage {
                        let newImage = Toucan(image: image).resize(CGSize(width: DefaultLogoWidth, height: DefaultLogoWidth), fitMode: Toucan.Resize.FitMode.scale).image
                        row.placeholderImage = newImage
                        row.value = newImage
                    }
                } else {
                    row.placeholderImage = nil
                }
                row.updateCell()
            }.cellUpdate { cell, row in
                cell.accessoryView?.layer.cornerRadius = 17
                cell.accessoryView?.frame = CGRect(x: 0, y: 0, width: 34, height: 34)
            }
        
        tableView.tableFooterView = UIView()
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
            navigationController.navigationBar.setBackgroundImage(UIImage(), for: .default)
            navigationController.navigationBar.shadowImage = UIImage()
        }
    }
    
    static func instantiate() -> CreateTokenViewController
    {
        return UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "CreateTokenViewController") as! CreateTokenViewController
    }
    
    @objc public func createToken() {
        if self.submitting {
            return
        }
        if self.form.validate().count > 0 {
            return
        }
        let values = self.form.values()
        guard let token = APIToken(form: values) else {
            return
        }
        
        self.submitting = true
        self.spinner.start()
        if let logo = token.logoImage {
            async({[weak self] _ -> APIToken in
                guard let weakSelf = self else {
                    throw UCAPIError.ignore
                }
                var upToken = try! ..UCQiniuService.getTokenLogo(
                    token.address,
                    provider: weakSelf.qiniuServiceProvider)
                upToken = try! ..weakSelf.uploadImage(upToken, image: logo)
                if let logo = upToken.link {
                    token.logo = logo
                }
                let createdToken = try! ..weakSelf.doCreateToken(token)
                return createdToken
            }).then(in: .main, {[weak self] token in
                guard let weakSelf = self else {
                    return
                }
                weakSelf.delegate?.tokenCreated(token: token)
                weakSelf.navigationController?.popViewController(animated: true)
            }).catch(in: .main, {error in
                UCAlert.showAlert(imageName: "Error", title: "错误", desc: (error as! UCAPIError).description, closeBtn: "关闭")
            }).always(in: .main, body: {
                [weak self] in
                guard let weakSelf = self else {
                    return
                }
                weakSelf.submitting = false
                weakSelf.spinner.stop()
            })
        } else {
            self.doCreateToken(token)
            .then(in: .main, {[weak self] token in
                guard let weakSelf = self else {
                    return
                }
                weakSelf.delegate?.tokenCreated(token: token)
                weakSelf.navigationController?.popViewController(animated: true)
            }).catch(in: .main, {error in
                UCAlert.showAlert(imageName: "Error", title: "错误", desc: (error as! UCAPIError).description, closeBtn: "关闭")
            }).always(in: .main, body: {
                [weak self] in
                guard let weakSelf = self else {
                    return
                }
                weakSelf.submitting = false
                weakSelf.spinner.stop()
            })
        }
    }
    
    private func doCreateToken(_ token: APIToken) -> Promise<APIToken> {
        return Promise<APIToken>(in: .background, {[weak self] resolve, reject, _ in
            guard let weakSelf = self else {
                reject(UCAPIError.ignore)
                return
            }
            weakSelf.submitting = true
            UCTokenService.createToken(
                token,
                provider: weakSelf.tokenServiceProvider)
            .then(in: .background, { token in
                resolve(token)
            }).catch(in: .background, { error in
                reject(error)
            })
        })
    }
    
    private func uploadImage(_ upToken: APIQiniu, image: UIImage) -> Promise<APIQiniu> {
        return Promise<APIQiniu>(in: .background, { resolve, reject, _ in
            let magager = QiniuManager.sharedInstance
            magager.uploader.put(
                image.data(),
                key: upToken.key,
                token: upToken.upToken,
                complete: { (info: QNResponseInfo?, key: String?, resp: [AnyHashable : Any]?) -> Void in
                    if let resp = info, resp.isOK {
                        upToken.uploaded = true
                        resolve(upToken)
                        return
                    }
                    reject(UCAPIError.unknown(msg: "upload image failed"))
            }, option: nil)
        })
    }
}

public protocol CreateTokenViewDelegate: NSObjectProtocol {
    func tokenCreated(token: APIToken)
}
