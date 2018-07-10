//
//  CreateTokenTaskViewController.swift
//  ucoin
//
//  Created by Syd on 2018/7/2.
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

fileprivate let DefaultImageWidth = 320

class CreateTokenTaskViewController: FormViewController {
    weak public var delegate: CreateTokenTaskDelegate?
    
    weak public var tokenInfo: APIToken?
    
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
        guard let tokenInfo = self.tokenInfo else {
            return
        }
        
        self.navigationItem.title = "新建\(tokenInfo.symbol ?? "")代币任务"
        
        let saveButton = UIBarButtonItem(barButtonSystemItem: .save, target: self, action: #selector(createTokenTask))
        self.navigationItem.rightBarButtonItem = saveButton
        
        self.view.addSubview(spinner)
        
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
        
        DateRow.defaultRowInitializer = { row in row.minimumDate = Date() }
        
        var minAmount: Double = 0
        var maxAmount: Double = 0
        if let decimals = tokenInfo.decimals {
            minAmount = pow(10, -1 * Double(decimals))
            if let totalSupply = tokenInfo.totalSupply {
                maxAmount = Double(totalSupply) * minAmount
            }
        }
        
        form +++
            Section()
            <<< TextRow() {
                $0.tag = "title"
                $0.title = "标题"
                $0.placeholder = ""
                $0.add(rule: RuleRequired())
                $0.add(rule: RuleMinLength(minLength: 2))
                $0.add(rule: RuleMaxLength(maxLength: 16))
                $0.validationOptions = .validatesOnChange
            }
            <<< DecimalRow(){
                $0.tag = "bonus"
                $0.title = "奖励代币数"
                $0.value = 1.0
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
                $0.value = 0
                $0.add(rule: RuleGreaterOrEqualThan(min: 0))
                $0.add(rule: RuleSmallerOrEqualThan(max: 50000))
                $0.validationOptions = .validatesOnChange
            }
            
            +++ Section()
            <<< DateRow() {
                $0.tag = "startDate"
                $0.value = Date()
                $0.title = "开始日期"
            }
            
            <<< DateRow() {
                $0.tag = "endDate"
                $0.value = Date()
                $0.title = "结束日期"
            }
            
            <<< SwitchRow() {
                $0.tag = "needEvidence"
                $0.title = "是否需要完成证明"
                $0.value = false
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
                $0.placeholder = "说明"
                $0.textAreaHeight = .dynamic(initialTextViewHeight: 110)
                $0.add(rule: RuleRequired())
            }
        
        tableView.tableFooterView = UIView()
        
        tagsFieldEvents()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        if let navigationController = self.navigationController {
            navigationController.navigationBar.isTranslucent = false
            navigationController.setNavigationBarHidden(false, animated: animated)
        }
    }
    
    static func instantiate() -> CreateTokenTaskViewController
    {
        return UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "CreateTokenTaskViewController") as! CreateTokenTaskViewController
    }
}

extension CreateTokenTaskViewController {
    @objc private func createTokenTask() {
        if self.submitting {
            return
        }
        if self.form.validate().count > 0 {
            return
        }
        let values = self.form.values()
        guard let tokenInfo = self.tokenInfo else {
            return
        }
        var tags: [String] = []
        for tag in self.tagsField.tags {
            tags.append(tag.text)
        }
        
        guard let tokenTask = APITokenTask(form: values, token: tokenInfo, tags: tags, images: self.pickedImages) else {
            return
        }
        
        self.submitting = true
        self.spinner.start()
        if self.pickedImages.count > 0 {
            UCQiniuService.getTokenTask(
                tokenInfo.address!,
                self.pickedImages.count,
                provider: self.qiniuServiceProvider,
                success: {[weak self] upTokens in
                    guard let weakSelf = self else {
                        return
                    }
                    for upToken in upTokens {
                        weakSelf.uploadImage(upToken, success: { [weak weakSelf] () -> Void in
                            guard let weakSelfSub = weakSelf else {
                                return
                            }
                            var images: [String] = []
                            for upToken in upTokens {
                                if !upToken.uploaded {
                                    continue
                                }
                                if let link = upToken.link {
                                    images.append(link)
                                }
                            }
                            tokenTask.images = images
                            weakSelfSub.doCreateTokenTask(tokenTask)
                        })
                    }
                },
                failed: {[weak self] error in
                    guard let weakSelf = self else {
                        return
                    }
                    DispatchQueue.main.async {
                        UCAlert.showAlert(imageName: "Error", title: "错误", desc: error.description, closeBtn: "关闭")
                        weakSelf.spinner.stop()
                    }
                },complete: {[weak self] in
                    guard let weakSelf = self else {
                        return
                    }
                    weakSelf.submitting = false
            })
        } else {
            self.doCreateTokenTask(tokenTask)
        }
    }
    
    private func uploadImage(_ upToken: APIQiniu, success:@escaping ()->Void) {
        let magager = QiniuManager.sharedInstance
        let totalTasks = self.pickedImages.count
        let img = self.pickedImages[upToken.index!]
        
        magager.uploader.put(
            img.data(),
            key: upToken.key,
            token: upToken.upToken,
            complete: { [weak self](info: QNResponseInfo?, key: String?, resp: [AnyHashable : Any]?) -> Void in
                guard let weakSelf = self else {
                    return
                }
                if info!.isOK {
                    upToken.uploaded = true
                }
                weakSelf.completeUploadTasks += 1
                if weakSelf.completeUploadTasks >= totalTasks && !weakSelf.imagesUploaded {
                    weakSelf.imagesUploaded = true
                    success()
                }
            }, option: nil)
    }
    
    private func doCreateTokenTask(_ tokenTask: APITokenTask) {
        UCTokenTaskService.createTokenTask(
            tokenTask,
            provider: self.tokenTaskServiceProvider,
            success: {[weak self] task in
                guard let weakSelf = self else {
                    return
                }
                DispatchQueue.main.async {
                    weakSelf.delegate?.tokenTaskCreated(task: task)
                    weakSelf.navigationController?.popViewController(animated: true)
                }
            },
            failed: { error in
                DispatchQueue.main.async {
                    UCAlert.showAlert(imageName: "Error", title: "错误", desc: error.description, closeBtn: "关闭")
                }
            },complete: {[weak self] in
                guard let weakSelf = self else {
                    return
                }
                weakSelf.completeUploadTasks = 0
                weakSelf.imagesUploaded = false
                weakSelf.submitting = false
                weakSelf.spinner.stop()
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
}

extension CreateTokenTaskViewController {
    
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

public protocol CreateTokenTaskDelegate: NSObjectProtocol {
    func tokenTaskCreated(task: APITokenTask)
}
