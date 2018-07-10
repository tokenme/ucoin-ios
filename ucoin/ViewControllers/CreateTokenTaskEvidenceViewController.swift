//
//  CreateTokenTaskEvidenceViewController.swift
//  ucoin
//
//  Created by Syd on 2018/7/9.
//  Copyright © 2018年 ucoin.io. All rights reserved.
//

import UIKit
import ImageRow
import SnapKit
import Eureka
import Toucan
import Moya
import YPImagePicker
import Qiniu

fileprivate let DefaultImageWidth = 320

class CreateTokenTaskEvidenceViewController: FormViewController {
    
    weak public var tokenTask: APITokenTask?
    
    fileprivate var submitting: Bool = false
    fileprivate var imagesUploaded: Bool = false
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
    
    private var tokenTaskEvidenceServiceProvider = MoyaProvider<UCTokenTaskEvidenceService>(plugins: [networkActivityPlugin, AccessTokenPlugin(tokenClosure: AccessTokenClosure())])
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
        guard let task = self.tokenTask else {
            return
        }
        guard let token = task.token else {
            return
        }
        self.navigationItem.title = "提交\(token.symbol ?? "")代币任务证明"
        
        let saveButton = UIBarButtonItem(barButtonSystemItem: .save, target: self, action: #selector(createTokenTaskEvidence))
        self.navigationItem.rightBarButtonItem = saveButton
        
        self.view.addSubview(spinner)
        
        let imageGridViewWrapper = UIView()
        
        imageGridViewWrapper.addSubview(self.imageGridView)
        
        TextAreaRow.defaultCellUpdate = { cell, row in
            if !row.isValid {
                cell.layer.borderColor = UIColor.red.cgColor
            }
        }
        
        form +++
            Section()
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
            
            <<< TextAreaRow() {
                $0.tag = "desc"
                $0.placeholder = "说明"
                $0.textAreaHeight = .dynamic(initialTextViewHeight: 110)
                $0.add(rule: RuleRequired())
        }
        
        tableView.tableFooterView = UIView()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        if let navigationController = self.navigationController {
            navigationController.navigationBar.isTranslucent = false
            navigationController.setNavigationBarHidden(false, animated: animated)
        }
    }
    
    static func instantiate() -> CreateTokenTaskEvidenceViewController
    {
        return UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "CreateTokenTaskEvidenceViewController") as! CreateTokenTaskEvidenceViewController
    }
}

extension CreateTokenTaskEvidenceViewController {
    @objc private func createTokenTaskEvidence() {
        if self.submitting {
            return
        }
        if self.form.validate().count > 0 {
            return
        }
        let values = self.form.values()
        guard let task = self.tokenTask else {
            return
        }
        
        guard let evidence = APITokenTaskEvidence(form: values, task: task, images: self.pickedImages) else {
            return
        }
        
        self.submitting = true
        self.spinner.start()
        if self.pickedImages.count > 0 {
            UCQiniuService.getTokenTaskEvidence(
                task.id!,
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
                            evidence.images = images
                            weakSelfSub.doCreateTokenTaskEvidence(evidence)
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
            self.doCreateTokenTaskEvidence(evidence)
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
    
    private func doCreateTokenTaskEvidence(_ evidence: APITokenTaskEvidence) {
        UCTokenTaskEvidenceService.createEvidence(
            evidence,
            provider: self.tokenTaskEvidenceServiceProvider,
            success: {[weak self] evidence in
                guard let weakSelf = self else {
                    return
                }
                DispatchQueue.main.async {
                    UCAlert.showAlert(imageName: "Success", title: "提交成功", desc: "请耐心等待项目方处理", closeBtn: "关闭")
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
