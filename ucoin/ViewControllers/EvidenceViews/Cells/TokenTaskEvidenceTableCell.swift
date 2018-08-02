//
//  TokenTaskEvidenceTableCell.swift
//  ucoin
//
//  Created by Syd on 2018/7/10.
//  Copyright © 2018年 ucoin.io. All rights reserved.
//

import UIKit
import Reusable
import SnapKit
import SwiftyMarkdown
import Moya

fileprivate let DefaultImageHeight = 80.0
fileprivate let DefaultAvatarHeight = 35.0

final class TokenTaskEvidenceTableCell: UITableViewCell, Reusable {
    
    weak public var textViewDelegate: UITextViewDelegate?
    weak public var delegate: TokenTaskEvidencesViewDelegate?
    
    private var evidenceId: UInt64?
    private var isSubmitting: Bool = false
    private var images: [String]?
    private let userView = UIView()
    private let avatarView = UIImageView(frame: CGRect(x: 0, y: 0, width: DefaultAvatarHeight, height: DefaultAvatarHeight))
    private let nickLabel = UILabel()
    private let dateLabel = UILabel()
    private let stackView = UIStackView()
    private let acceptButton = TransitionButton()
    private let rejectButton = TransitionButton()
    
    private let textView  = UITextView()
    private let imageGridView = FTImageGridView(frame: CGRect.zero)
    
    private var tokenTaskEvidenceServiceProvider = MoyaProvider<UCTokenTaskEvidenceService>(plugins: [networkActivityPlugin, AccessTokenPlugin(tokenClosure: AccessTokenClosure())])
    
    private lazy var containerView: UIView = {
        let containerView = UIView()
        
        avatarView.layer.borderWidth = 0
        avatarView.layer.cornerRadius = CGFloat(DefaultAvatarHeight / 2.0)
        avatarView.contentMode = .scaleAspectFill
        avatarView.clipsToBounds = true
        userView.addSubview(avatarView)
        avatarView.snp.remakeConstraints { (maker) -> Void in
            maker.centerY.equalToSuperview()
            maker.width.equalTo(DefaultAvatarHeight)
            maker.height.equalTo(DefaultAvatarHeight)
            maker.leading.equalToSuperview()
        }
        
        nickLabel.font = MainFont.medium.with(size: 13)
        nickLabel.adjustsFontSizeToFitWidth = true
        nickLabel.numberOfLines = 1
        nickLabel.minimumScaleFactor = 8.0 / nickLabel.font.pointSize
        userView.addSubview(nickLabel)
        nickLabel.snp.remakeConstraints { (maker) -> Void in
            maker.leading.equalTo(avatarView.snp.trailing).offset(16)
            maker.trailing.equalToSuperview()
            maker.top.equalToSuperview().offset(8)
        }
        
        dateLabel.font = MainFont.thin.with(size: 11)
        dateLabel.textColor = UIColor.lightGray
        dateLabel.adjustsFontSizeToFitWidth = true
        dateLabel.numberOfLines = 1
        dateLabel.minimumScaleFactor = 8.0 / dateLabel.font.pointSize
        userView.addSubview(dateLabel)
        dateLabel.snp.remakeConstraints { (maker) -> Void in
            maker.leading.equalTo(nickLabel.snp.leading)
            maker.trailing.equalToSuperview()
            maker.top.equalTo(nickLabel.snp.bottom).offset(4)
            maker.bottom.equalToSuperview().offset(-8)
        }
        
        
        containerView.addSubview(userView)
        userView.snp.remakeConstraints { (maker) -> Void in
            maker.leading.equalToSuperview().offset(16)
            maker.trailing.equalToSuperview().offset(-16)
            maker.top.equalToSuperview().offset(16)
        }
        
        stackView.axis = .horizontal
        stackView.alignment = .center
        stackView.spacing = 25.0
        stackView.distribution = .fillEqually
        
        
        acceptButton.setTitle("通过", for: .normal)
        //let successImage = UIImage(named: "Success")?.withRenderingMode(.alwaysTemplate)
        //acceptButton.setImage(successImage, for: .normal)
        acceptButton.titleLabel?.font = MainFont.medium.with(size: 12)
        acceptButton.tintColor = .white
        acceptButton.clipsToBounds = true
        acceptButton.contentMode = .scaleAspectFit
        //acceptButton.imageEdgeInsets = UIEdgeInsets(top: 0, left: -8, bottom: 0, right: 0)
        acceptButton.backgroundColor = UIColor.greenGrass
        acceptButton.cornerRadius = 10
        acceptButton.frame = CGRect(x: 0, y: 0, width: 80, height: 30)
        acceptButton.addTarget(self, action: #selector(accept), for: .touchUpInside)
        
        rejectButton.setTitle("拒绝", for: .normal)
        //let cancelImage = UIImage(named: "Cancel")?.withRenderingMode(.alwaysTemplate)
        //rejectButton.setImage(cancelImage, for: .normal)
        rejectButton.tintColor = .white
        rejectButton.titleLabel?.font = MainFont.medium.with(size: 12)
        rejectButton.clipsToBounds = true
        rejectButton.contentMode = .scaleAspectFit
        //rejectButton.imageEdgeInsets = UIEdgeInsets(top: 0, left: -8, bottom: 0, right: 0)
        rejectButton.backgroundColor = UIColor.red
        rejectButton.cornerRadius = 10
        rejectButton.frame = CGRect(x: 0, y: 0, width: 80, height: 30)
        rejectButton.addTarget(self, action: #selector(reject), for: .touchUpInside)
        
        stackView.addArrangedSubview(acceptButton)
        stackView.addArrangedSubview(rejectButton)
        containerView.addSubview(stackView)
        
        stackView.snp.remakeConstraints {[unowned self](maker) -> Void in
            maker.leading.equalToSuperview().offset(28)
            maker.trailing.equalToSuperview().offset(-28)
            maker.top.equalTo(self.userView.snp.bottom).offset(8)
            maker.height.equalTo(30)
        }
        
        textView.isUserInteractionEnabled = true
        textView.isEditable = false
        textView.isSelectable = false
        textView.dataDetectorTypes = .all
        textView.delegate = textViewDelegate
        containerView.addSubview(textView)
        textView.snp.remakeConstraints {[unowned self] (maker) -> Void in
            maker.leading.equalToSuperview().offset(16)
            maker.trailing.equalToSuperview().offset(-16)
            maker.top.equalTo(self.stackView).offset(8)
        }
        
        containerView.addSubview(imageGridView)
        
        self.contentView.addSubview(containerView)
        
        containerView.snp.remakeConstraints { (maker) -> Void in
            maker.leading.equalToSuperview().offset(8)
            maker.trailing.equalToSuperview().offset(-8)
            maker.top.equalToSuperview().offset(8)
            maker.bottom.equalToSuperview().offset(-8)
        }
        
        return containerView
    }()
    
    public func fill(_ taskEvidence: APITokenTaskEvidence?) {
        self.containerView.needsUpdateConstraints()
        guard let evidence = taskEvidence else {
            return
        }
        self.evidenceId = evidence.id
        if let user = evidence.user {
            if let avatar = user.avatar {
                avatarView.kf.setImage(with: URL(string: avatar))
            }
            nickLabel.text = user.showName
        }
        
        if let createTime = evidence.createTime {
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "yyyy-MM-dd H:m:s"
            let t = dateFormatter.string(from: createTime)
            dateLabel.text = "提交日期: \(t)"
        }
        
        if evidence.approveStatus ?? 0 == 0 {
            stackView.isHidden = false
            stackView.snp.remakeConstraints {[weak self] (maker) -> Void in
                guard let weakSelf = self else {
                    return
                }
                maker.leading.equalToSuperview().offset(28)
                maker.trailing.equalToSuperview().offset(-28)
                maker.top.equalTo(weakSelf.userView.snp.bottom).offset(8)
                maker.height.equalTo(30)
            }
        } else {
            stackView.isHidden = true
            stackView.snp.removeConstraints()
        }
        if let description = evidence.desc {
            let attributedString = SwiftyMarkdown(string: description).attributedString()
            let textHeight = attributedString.heightWithConstrainedWidth(width: UIScreen.main.bounds.width - 32)
            if evidence.approveStatus ?? 0 == 0 {
                textView.snp.remakeConstraints {[weak self] (maker) -> Void in
                    guard let weakSelf = self else {
                        return
                    }
                    maker.leading.equalToSuperview().offset(16)
                    maker.trailing.equalToSuperview().offset(-16)
                    maker.top.equalTo(weakSelf.stackView.snp.bottom).offset(8)
                    maker.height.equalTo(textHeight + 16)
                }
            } else {
                textView.snp.remakeConstraints {[weak self] (maker) -> Void in
                    guard let weakSelf = self else {
                        return
                    }
                    maker.leading.equalToSuperview().offset(16)
                    maker.trailing.equalToSuperview().offset(-16)
                    maker.top.equalTo(weakSelf.userView.snp.bottom).offset(8)
                    maker.height.equalTo(textHeight + 16)
                }
            }
            textView.attributedText = attributedString
        }
        
        if evidence.images?.count ?? 0 > 0 {
            let gridWidth = UIScreen.main.bounds.width - 32
            let gridHeight = FTImageGridView.getHeightWithWidth(gridWidth, imgCount: evidence.images!.count)
            imageGridView.frame = CGRect(x: 0, y: 0, width: gridWidth, height: gridHeight)
            
            imageGridView.snp.remakeConstraints { (maker) -> Void in
                maker.leading.equalToSuperview().offset(8)
                maker.trailing.equalToSuperview().offset(-8)
                maker.top.equalTo(textView.snp.bottom).offset(16)
                maker.height.equalTo(gridHeight)
                maker.bottom.equalToSuperview().offset(-8)
            }
            
            var resources : [FTImageResource] = []
            for img in evidence.images! {
                let resource : FTImageResource = FTImageResource(image: nil, imageURLString:img)
                resources.append(resource)
            }
            
            imageGridView.showWithImageArray(resources) { (buttonsArray, buttonIndex) in
                FTImageViewer.showImages(evidence.images!, atIndex: buttonIndex, fromSenderArray: buttonsArray)
            }
            
            imageGridView.setNeedsLayout()
            imageGridView.layoutIfNeeded()
            
        } else {
            for subView in imageGridView.subviews {
                subView.removeFromSuperview()
            }
            imageGridView.snp.remakeConstraints { (maker) -> Void in
                maker.leading.equalToSuperview().offset(8)
                maker.trailing.equalToSuperview().offset(-8)
                maker.top.equalTo(textView.snp.bottom).offset(16)
                maker.height.equalTo(0)
                maker.bottom.equalToSuperview().offset(-8)
            }
        }
        containerView.setNeedsLayout()
        containerView.layoutIfNeeded()
    }
}

extension TokenTaskEvidenceTableCell {
    @objc private func accept() {
        if self.isSubmitting {
            return
        }
        self.isSubmitting = true
        acceptButton.startAnimation()
        self.approveEvidence(self.evidenceId!, approveStatus: 1)
    }
    
    @objc private func reject() {
        if self.isSubmitting {
            return
        }
        self.isSubmitting = true
        rejectButton.startAnimation()
        self.approveEvidence(self.evidenceId!, approveStatus: -1)
    }
    
    private func approveEvidence(_ evidenceId: UInt64, approveStatus: Int8) {
        UCTokenTaskEvidenceService.approveEvidence(
            evidenceId,
            approveStatus: approveStatus,
            provider: self.tokenTaskEvidenceServiceProvider)
        .then(in: .main, {[weak self] evidence in
            guard let weakSelf = self else {
                return
            }
            if let delegate = weakSelf.delegate {
                delegate.approveEvidence(evidence.id!, approveStatus: evidence.approveStatus!)
            }
        }).catch(in: .main, { error in
            UCAlert.showAlert(imageName: "Error", title: "错误", desc: (error as! UCAPIError).description, closeBtn: "关闭")
        }).always(in: .main, body: {[weak self] in
            guard let weakSelf = self else {
                return
            }
            weakSelf.isSubmitting = false
            if approveStatus == 1 {
                weakSelf.acceptButton.stopAnimation()
            } else if approveStatus == -1 {
                weakSelf.rejectButton.stopAnimation()
            }
        })
    }
}
