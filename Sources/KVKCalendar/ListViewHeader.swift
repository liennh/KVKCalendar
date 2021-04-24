//
//  ListViewHeader.swift
//  KVKCalendar
//
//  Created by Sergei Kviatkovskii on 27.12.2020.
//

import UIKit

final class ListViewHeader: UITableViewHeaderFooterView {
    
    public let titleLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 17, weight: .medium)
        label.numberOfLines = 0
        return label
    }()
    
    private let btnExplain: UIButton = {
       let button = UIButton()
        
        return button
    }()
    
    private let lineView: UIView = {
        let view = UIView()
        view.backgroundColor = .lightGray
        return view
    } ()
    
    private let ivExpand: UIImageView = {
       let imageView = UIImageView()
        imageView.image = UIImage(named: "ic_expand")
        return imageView
    }()
    
    var actionExplain: ((Bool) -> Void)?
    var isExplain: Bool = false {
        didSet {
            if self.isExplain {
                self.ivExpand.transform = CGAffineTransform(rotationAngle: -.pi)
                
            } else {
                self.ivExpand.transform = CGAffineTransform(rotationAngle: 0)
            }
        }
    }
    
    var title: String? {
        didSet {
            titleLabel.text = title
        }
    }
    
    override init(reuseIdentifier: String?) {
        super.init(reuseIdentifier: reuseIdentifier)
        addSubview(titleLabel)
        addSubview(btnExplain)
        addSubview(ivExpand)
        addSubview(lineView)
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        btnExplain.translatesAutoresizingMaskIntoConstraints = false
        ivExpand.translatesAutoresizingMaskIntoConstraints = false
        lineView.translatesAutoresizingMaskIntoConstraints = false
        let top = titleLabel.topAnchor.constraint(equalTo: topAnchor)
        let bottom = titleLabel.bottomAnchor.constraint(equalTo: bottomAnchor)
        let left = titleLabel.leftAnchor.constraint(equalTo: leftAnchor)
        let right = titleLabel.rightAnchor.constraint(equalTo: rightAnchor)
        
        let topBtn = btnExplain.topAnchor.constraint(equalTo: topAnchor)
        let bottomBtn = btnExplain.bottomAnchor.constraint(equalTo: bottomAnchor)
        let leftBtn = btnExplain.leftAnchor.constraint(equalTo: leftAnchor)
        let rightBtn = btnExplain.rightAnchor.constraint(equalTo: rightAnchor)
        
        let ivExpandCenterY = ivExpand.centerYAnchor.constraint(equalTo: centerYAnchor)
        let ivExpandWidth = ivExpand.widthAnchor.constraint(equalToConstant: 16)
        let ivExpandHeight = ivExpand.heightAnchor.constraint(equalToConstant: 8)
        let ivExpandRight = ivExpand.rightAnchor.constraint(equalTo: rightAnchor, constant: -8)
      
        let linViewBot = lineView.bottomAnchor.constraint(equalTo: bottomAnchor)
        let linViewHeight = lineView.heightAnchor.constraint(equalToConstant: 0.5)
        let linViewleft = lineView.leftAnchor.constraint(equalTo: leftAnchor, constant: 15)
        let linViewRight = lineView.rightAnchor.constraint(equalTo: rightAnchor)
        
        left.constant = 15
        right.constant = -15
        
        NSLayoutConstraint.activate([ivExpandCenterY, ivExpandWidth, ivExpandHeight, ivExpandRight])
        NSLayoutConstraint.activate([top, bottom, left, right])
        NSLayoutConstraint.activate([topBtn, bottomBtn, leftBtn, rightBtn])
        NSLayoutConstraint.activate([linViewBot, linViewHeight, linViewleft, linViewRight])
        
    }
    
    func setExplainButton() {
        btnExplain.addTarget(self, action: #selector(btnExplainDidTouched), for: .touchUpInside)
    }

    
    @objc func btnExplainDidTouched() {
        self.isExplain = !isExplain
   
        self.actionExplain?(self.isExplain)
        
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
}
