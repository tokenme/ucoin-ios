//
//  EditTokenTaskViewController.swift
//  ucoin
//
//  Created by Syd on 2018/7/3.
//  Copyright © 2018年 ucoin.io. All rights reserved.
//

import UIKit
import ImageRow
import SnapKit
import Eureka
import Toucan
import Moya
import WSTagsField
import YPImagePicker
import Qiniu
import Hydra

fileprivate let DefaultImageWidth = 320

class EditTokenTaskViewController: FormViewController {
    weak public var delegate: EditTokenTaskDelegate?
    
    weak public var tokenTask: APITokenTask?
    
    fileprivate var submitting: Bool = false
    fileprivate var imagesUploaded: Bool = false
    fileprivate let tagsField = WSTagsField()
    fileprivate var imageGridView = FTImageGridView()
    fileprivate var imageGridHeight: NSLayoutConstraint?
    fileprivate var pickedImages: [UIImage] = []{
        didSet {
            
            // set width for the image grid
            // or set the width to a certain value in storyboard and leave the calculation to `FTImageGridView`
            let gridWidth = self.tableView.bounds.size.width - 16
            
            let gridHeight = FTImageGridView.getHeightWithWidth(gridWidth, imgCount: pickedImages.count)
            
            self.imageGridView.snp.remakeConstraints { (maker) -> Void in
                maker.leading.equalToSuperview().offset(8)
                maker.trailing.equalToSuperview().offset(-8)
                maker.top.equalToSuperview().offset(8)
                maker.height.equalTo(gridHeight)
                maker.bottom.equalToSuperview().offset(-8)
            }
            
            self.imageGridView.setNeedsLayout()
            self.imageGridView.layoutIfNeeded()
        }
    }
    
    fileprivate let spinner = LoaderModal(backgroundColor: UIColor(displayP3Red: 255, green: 255, blue: 255, alpha: 0.6))!
    
    private var tokenTaskServiceProvider = MoyaProvider<UCTokenTaskService>(plugins: [networkActivityPlugin, AccessTokenPlugin(tokenClosure: AccessTokenClosure())])
    private var tokenServiceProvider = MoyaProvider<UCTokenService>(plugins: [networkActivityPlugin, AccessTokenPlugin(tokenClosure: AccessTokenClosure())])
    private var qiniuServiceProvider = MoyaProvider<UCQiniuService>(plugins: [networkActivityPlugin, AccessTokenPlugin(tokenClosure: AccessTokenClosure())])
    
    private var completeUploadTasks: Int = 0
    
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
        guard let tokenTask = self.tokenTask else {
            return
        }
        
        self.navigationItem.title = "编辑\(tokenTask.token!.symbol ?? "")任务"
        
        let saveButton = UIBarButtonItem(barButtonSystemItem: .save, target: self, action: #selector(updateTokenTask))
        self.navigationItem.rightBarButtonItem = saveButton
        
        self.view.addSubview(spinner)
        
        if tokenTask.token?.totalSupply == nil {
            self.spinner.start()
            self.getToken((tokenTask.token?.address)!)
        } else {
            setupForm()
        }
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
    
    static func instantiate() -> EditTokenTaskViewController
    {
        return UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "EditTokenTaskViewController") as! EditTokenTaskViewController
    }
    
    private func setupForm() {
        guard let tokenTask = self.tokenTask else {
            return
        }
        tagsField.cornerRadius = 5.0
        //tagsField.spaceBetweenLines = 10
        //tagsField.spaceBetweenTags = 10
        
        tagsField.layoutMargins = UIEdgeInsets(top: 2, left: 6, bottom: 2, right: 6)
        tagsField.contentInset = UIEdgeInsets(top: 10, left: 10, bottom: 10, right: 10)
        
        tagsField.placeholder = "添加标签"
        tagsField.placeholderColor = .primaryBlue
        tagsField.placeholderAlwaysVisible = true
        tagsField.backgroundColor = .clear
        tagsField.returnKeyType = .next
        tagsField.delimiter = ","
        tagsField.acceptTagOption = .space
        if let tags = tokenTask.tags {
            tagsField.addTags(tags)
        }
        
        let tagsViewWrapper = UIView()
        tagsViewWrapper.addSubview(tagsField)
        tagsField.snp.remakeConstraints { (maker) -> Void in
            maker.leading.equalToSuperview().offset(8)
            maker.trailing.equalToSuperview().offset(-8)
            maker.top.equalToSuperview().offset(8)
            maker.bottom.equalToSuperview().offset(-8)
        }
        
        let imageGridViewWrapper = UIView()
        
        imageGridViewWrapper.addSubview(self.imageGridView)
        
        TextRow.defaultCellUpdate = { cell, row in
            if !row.isValid {
                cell.titleLabel?.textColor = .red
            }
        }
        
        TextAreaRow.defaultCellUpdate = { cell, row in
            if !row.isValid {
                cell.layer.borderColor = UIColor.red.cgColor
            }
        }
        
        IntRow.defaultCellUpdate = { cell, row in
            if !row.isValid {
                cell.titleLabel?.textColor = .red
            }
        }
        
        var bonus: Double = 0
        var minAmount: Double = 0
        var maxAmount: Double = 0
        if let decimals = tokenTask.token?.decimals {
            minAmount = pow(10, -1 * Double(decimals))
            if let totalSupply = tokenTask.token?.totalSupply {
                maxAmount = Double(totalSupply) * minAmount
            }
            bonus = Double(tokenTask.bonus ?? 0) * minAmount
        }
        
        var onlineStatus: Bool = false
        if let status = tokenTask.onlineStatus {
            onlineStatus = status == 1
        }
        
        var needEvidence: Bool = false
        if let evidence = tokenTask.needEvidence {
            needEvidence = evidence == 1
        }
        
        form +++
            Section()
            <<< TextRow() {
                $0.tag = "title"
                $0.title = "标题"
                $0.value = tokenTask.title
                $0.placeholder = ""
                $0.add(rule: RuleRequired())
                $0.add(rule: RuleMinLength(minLength: 2))
                $0.add(rule: RuleMaxLength(maxLength: 16))
                $0.validationOptions = .validatesOnChange
            }
            <<< DecimalRow(){
                $0.tag = "bonus"
                $0.title = "奖励代币数"
                $0.value = bonus
                $0.formatter = DecimalFormatter()
                $0.useFormatterDuringInput = true
                $0.add(rule: RuleGreaterOrEqualThan(min: minAmount))
                $0.add(rule: RuleSmallerOrEqualThan(max: maxAmount))
                $0.validationOptions = .validatesOnChange
                }.cellSetup { cell, _  in
                    cell.textField.keyboardType = .numberPad
            }
            <<< IntRow() {
                $0.tag = "amount"
                $0.title = "人数限制"
                $0.value = Int(tokenTask.amount ?? 0)
                $0.add(rule: RuleGreaterOrEqualThan(min: 0))
                $0.add(rule: RuleSmallerOrEqualThan(max: 50000))
                $0.validationOptions = .validatesOnChange
            }
            +++ Section()
            <<< DateRow() {
                $0.tag = "startDate"
                $0.value = tokenTask.startDate
                $0.title = "开始日期"
            }
            
            <<< DateRow() {
                $0.tag = "endDate"
                $0.value = tokenTask.endDate
                $0.title = "结束日期"
            }
            
            <<< SwitchRow() {
                $0.tag = "needEvidence"
                $0.title = "是否需要完成证明"
                $0.value = needEvidence
            }
            
            +++ Section()
            <<< SwitchRow() {
                $0.tag = "onlineStatus"
                $0.title = "上线状态"
                $0.value = onlineStatus
            }
            
            <<< ButtonRow() {(row: ButtonRow) -> Void in
                row.title = "选择图片"
                }
                .onCellSelection { [weak self] (cell, row) in
                    guard let weakSelf = self else {
                        return
                    }
                    weakSelf.showImagePicker()
            }
            
            <<< ViewRow<UIView>() { (row) in
                row.tag = "imageGrid"
                }.cellSetup {(cell, _) in
                    cell.view = imageGridViewWrapper
            }
            
            <<< ViewRow<UIView>() { (row) in
                row.tag = "tags"
                }.cellSetup {(cell, _) in
                    cell.view = tagsViewWrapper
            }
            
            <<< TextAreaRow() {
                $0.tag = "desc"
                $0.value = tokenTask.desc
                $0.placeholder = "说明"
                $0.textAreaHeight = .dynamic(initialTextViewHeight: 110)
                $0.add(rule: RuleRequired())
        }
        
        tableView.tableFooterView = UIView()
        
        tagsFieldEvents()
        
        if let imageUrls = tokenTask.images {
            let gridWidth = UIScreen.main.bounds.width - 32
            let gridHeight = FTImageGridView.getHeightWithWidth(gridWidth, imgCount: imageUrls.count)
            imageGridView.frame = CGRect(x: 0, y: 0, width: gridWidth, height: gridHeight)
            
            imageGridView.snp.remakeConstraints { (maker) -> Void in
                maker.leading.equalToSuperview().offset(8)
                maker.trailing.equalToSuperview().offset(-8)
                maker.top.equalToSuperview().offset(8)
                maker.height.equalTo(gridHeight)
                maker.bottom.equalToSuperview().offset(-8)
            }
            
            var resources : [FTImageResource] = []
            for img in imageUrls {
                let resource : FTImageResource = FTImageResource(image: nil, imageURLString:img)
                resources.append(resource)
            }
            
            imageGridView.showWithImageArray(resources) { (buttonsArray, buttonIndex) in
                FTImageViewer.showImages(imageUrls, atIndex: buttonIndex, fromSenderArray: buttonsArray)
            }
            
            imageGridView.setNeedsLayout()
            imageGridView.layoutIfNeeded()
            self.tableView.reloadDataWithAutoSizingCellWorkAround()
        }
    }
}

extension EditTokenTaskViewController {
    @objc private func updateTokenTask() {
        if self.submitting {
            return
        }
        if self.form.validate().count > 0 {
            return
        }
        let values = self.form.values()
        guard let tokenTask = self.tokenTask else {
            return
        }
        var tags: [String] = []
        for tag in self.tagsField.tags {
            tags.append(tag.text)
        }
        
        guard let newTokenTask = APITokenTask(form: values, token: tokenTask.token!, tags: tags, images: self.pickedImages) else {
            return
        }
        
        newTokenTask.id = tokenTask.id
        self.submitting = true
        self.spinner.start()
        if self.pickedImages.count > 0 {
            async({[weak self] _ -> APITokenTask in
                guard let weakSelf = self else {
                    throw UCAPIError.ignore
                }
                let upTokens = try! ..UCQiniuService.getTokenTask(
                    newTokenTask.token!.address!,
                    weakSelf.pickedImages.count,
                    provider: weakSelf.qiniuServiceProvider)
                let promises = upTokens.map { return weakSelf.uploadImage($0) }
                let _ = try! ..all(promises)
                var images: [String] = []
                for upToken in upTokens {
                    if !upToken.uploaded {
                        continue
                    }
                    if let link = upToken.link {
                        images.append(link)
                    }
                }
                newTokenTask.images = images
                let createdTokenTask = try! ..UCTokenTaskService.updateTokenTask(
                    newTokenTask,
                    provider: weakSelf.tokenTaskServiceProvider)
                return createdTokenTask
            }).then(in: .main, {[weak self] task in
                guard let weakSelf = self else {
                    return
                }
                weakSelf.delegate?.tokenTaskUpdated(task: task)
                weakSelf.navigationController?.popViewController(animated: true)
            }).catch(in: .main, {error in
                UCAlert.showAlert(imageName: "Error", title: "错误", desc: (error as! UCAPIError).description, closeBtn: "关闭")
            }).always(in: .main, body: {[weak self] in
                guard let weakSelf = self else {
                    return
                }
                weakSelf.submitting = false
                weakSelf.spinner.stop()
            })
        } else {
            UCTokenTaskService.updateTokenTask(
                newTokenTask,
                provider: self.tokenTaskServiceProvider)
            .then(in: .main, {[weak self] task in
                guard let weakSelf = self else {
                    return
                }
                weakSelf.delegate?.tokenTaskUpdated(task: task)
                weakSelf.navigationController?.popViewController(animated: true)
            }).catch(in: .main, {error in
                UCAlert.showAlert(imageName: "Error", title: "错误", desc: (error as! UCAPIError).description, closeBtn: "关闭")
            }).always(in: .main, body: {[weak self] in
                guard let weakSelf = self else {
                    return
                }
                weakSelf.submitting = false
                weakSelf.spinner.stop()
            })
        }
    }
    
    private func uploadImage(_ upToken: APIQiniu) -> Promise<APIQiniu> {
        return Promise<APIQiniu>(in: .background, {[weak self] resolve, reject, _ in
            let magager = QiniuManager.sharedInstance
            guard let weakSelf = self else {
                reject(UCAPIError.ignore)
                return
            }
            let img = weakSelf.pickedImages[upToken.index!]
            magager.uploader.put(
                img.data(),
                key: upToken.key,
                token: upToken.upToken,
                complete: { (info: QNResponseInfo?, key: String?, resp: [AnyHashable : Any]?) -> Void in
                    if let ret = info?.isOK, ret {
                        upToken.uploaded = true
                        resolve(upToken)
                        return
                    }
                    reject(UCAPIError.unknown(msg: "upload image failed"))
            }, option: nil)
        })
    }
    
    private func showImagePicker() {
        if self.submitting {
            return
        }
        var config = YPImagePickerConfiguration()
        config.library.mediaType = .photo
        config.library.onlySquare  = false
        config.onlySquareImagesFromCamera = true
        config.targetImageSize = .original
        config.usesFrontCamera = true
        config.showsFilters = true
        config.albumName = "UCoin"
        config.filters = [YPFilterDescriptor(name: "Normal", filterName: ""),
                          YPFilterDescriptor(name: "Mono", filterName: "CIPhotoEffectMono")]
        config.shouldSaveNewPicturesToAlbum = true
        config.screens = [.library, .photo]
        config.startOnScreen = .library
        config.showsCrop = .rectangle(ratio: 1)
        config.wordings.libraryTitle = "Gallery"
        config.hidesStatusBar = false
        config.library.maxNumberOfItems = 9
        
        // Build a picker with your configuration
        let picker = YPImagePicker(configuration: config)
        var pickedImages: [UIImage] = []
        picker.didFinishPicking { [unowned picker, weak self] items, cancelled in
            guard let weakSelf = self else {
                return
            }
            for item in items {
                switch item {
                case .photo(let photo):
                    if let img = photo.modifiedImage {
                        if let newImage = Toucan(image: img).resize(CGSize(width: DefaultImageWidth, height: DefaultImageWidth), fitMode: Toucan.Resize.FitMode.scale).image {
                            pickedImages.append(newImage)
                        }
                    } else {
                        if let newImage = Toucan(image: photo.image).resize(CGSize(width: DefaultImageWidth, height: DefaultImageWidth), fitMode: Toucan.Resize.FitMode.scale).image {
                            pickedImages.append(newImage)
                        }
                    }
                case .video(let video):
                    print(video)
                }
            }
            
            weakSelf.pickedImages = pickedImages
            
            var resources : [FTImageResource] = []
            for img in weakSelf.pickedImages {
                let resource : FTImageResource = FTImageResource(image: img, imageURLString:nil)
                resources.append(resource)
            }
            weakSelf.imageGridView.showWithImageArray(resources) { (buttonsArray, buttonIndex) in
                FTImageViewer.showImages(pickedImages, atIndex: buttonIndex, fromSenderArray: buttonsArray)
            }
            DispatchQueue.main.async {
                weakSelf.tableView.reloadDataWithAutoSizingCellWorkAround()
            }
            picker.dismiss(animated: true, completion: nil)
        }
        self.present(picker, animated: true, completion: nil)
    }
    
    private func getToken(_ tokenAddress: String) {
        UCTokenService.getInfo(
            tokenAddress,
            provider: self.tokenServiceProvider)
        .then(in: .main, {[weak self] token in
            guard let weakSelf = self else {
                return
            }
            weakSelf.tokenTask?.token = token
        }).catch(in: .main, { error in
            UCAlert.showAlert(imageName: "Error", title: "错误", desc: (error as! UCAPIError).description, closeBtn: "关闭")
        }).always(in: .main, body: { [weak self] in
            guard let weakSelf = self else {
                return
            }
            weakSelf.spinner.stop()
            weakSelf.setupForm()
        })
    }
}

extension EditTokenTaskViewController {
    
    fileprivate func tagsFieldEvents() {
        tagsField.onDidChangeHeightTo = {[weak self] _, height in
            guard let weakSelf = self else {
                return
            }
            DispatchQueue.main.async {
                weakSelf.tableView.reloadDataWithAutoSizingCellWorkAround()
            }
        }
    }
    
}

public protocol EditTokenTaskDelegate: NSObjectProtocol {
    func tokenTaskUpdated(task: APITokenTask)
}
