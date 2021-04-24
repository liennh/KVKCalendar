//
//  ListViewHeader.swift
//  KVKCalendar
//
//  Created by Sergei Kviatkovskii on 27.12.2020.
//

import UIKit

final class ListViewHeader: UITableViewHeaderFooterView {
    
    private let titleLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 17, weight: .medium)
        label.numberOfLines = 0
        return label
    }()
    
    private let btnExplain: UIButton = {
       let button = UIButton()
        
        return button
    }()
    
    var actionExplain: ((Bool) -> Void)?
    var isExplain: Bool = false
    
    var title: String? {
        didSet {
            titleLabel.text = title
        }
    }
    
    override init(reuseIdentifier: String?) {
        super.init(reuseIdentifier: reuseIdentifier)
        addSubview(titleLabel)
        addSubview(btnExplain)
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        btnExplain.translatesAutoresizingMaskIntoConstraints = false    
        let top = titleLabel.topAnchor.constraint(equalTo: topAnchor)
        let bottom = titleLabel.bottomAnchor.constraint(equalTo: bottomAnchor)
        let left = titleLabel.leftAnchor.constraint(equalTo: leftAnchor)
        let right = titleLabel.rightAnchor.constraint(equalTo: rightAnchor)
        
        let topBtn = btnExplain.topAnchor.constraint(equalTo: topAnchor)
        let bottomBtn = btnExplain.bottomAnchor.constraint(equalTo: bottomAnchor)
        let leftBtn = btnExplain.leftAnchor.constraint(equalTo: leftAnchor)
        let rightBtn = btnExplain.rightAnchor.constraint(equalTo: rightAnchor)
       
        left.constant = 15
        right.constant = -15
        
        NSLayoutConstraint.activate([top, bottom, left, right])
        NSLayoutConstraint.activate([topBtn, bottomBtn, leftBtn, rightBtn])
        
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
