//
//  HeaderSectionTableViewCell.swift
//  KVKCalendar
//
//  Created by KhacTao on 4/26/21.
//

import UIKit

class HeaderSectionTableViewCell: UITableViewCell {

    var stackContent: UIStackView = {
        let stack = UIStackView()
        stack.axis = .horizontal
        return stack
    } ()
    
    var lbTitle: UILabel = {
       let label = UILabel()
        return label
    }()
    
    var lineView: UIView = {
        let view = UIView()
        view.backgroundColor = .lightGray
        return view
    }()
    
    var btnAdd: UIButton = {
        let button = UIButton()
        return button
    }()
    
    var actionAddDidTouched: (() -> Void)?
    
    override func awakeFromNib() {
        super.awakeFromNib()
  
        // Initialization code
    }
    
    
    
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        self.contentView.addSubview(stackContent)
        self.contentView.addSubview(lineView)
        self.selectionStyle = .none
        stackContent.addArrangedSubview(lbTitle)
        stackContent.addArrangedSubview(btnAdd)
        
        
        stackContent.translatesAutoresizingMaskIntoConstraints = false
        stackContent.leadingAnchor.constraint(equalTo: self.leadingAnchor, constant: 16).isActive = true
        stackContent.trailingAnchor.constraint(equalTo: self.trailingAnchor, constant: -16).isActive = true
        stackContent.topAnchor.constraint(equalTo: self.topAnchor, constant: 5).isActive = true
        stackContent.bottomAnchor.constraint(equalTo: self.bottomAnchor, constant: -5).isActive = true
        
        btnAdd.translatesAutoresizingMaskIntoConstraints = false
        btnAdd.widthAnchor.constraint(equalTo: btnAdd.heightAnchor).isActive = true
        lineView.translatesAutoresizingMaskIntoConstraints = false
        lineView.leadingAnchor.constraint(equalTo: self.leadingAnchor, constant: 16).isActive = true
        lineView.trailingAnchor.constraint(equalTo: self.trailingAnchor).isActive = true
        lineView.bottomAnchor.constraint(equalTo: self.bottomAnchor).isActive = true
        lineView.heightAnchor.constraint(equalToConstant: 0.5).isActive = true
        
    }
    
    
    func setUpButton() {
        self.btnAdd.addTarget(self, action: #selector(btnAddDidTouched), for: .touchUpInside)
    }
    
    
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    @objc func btnAddDidTouched() {
        self.actionAddDidTouched?()
    }
    
    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
        // Configure the view for the selected state
    }
    
}


extension UIImageView {
    static func imageWithColor(color: UIColor) -> UIImage {
        let rect = CGRect(x: 0.0, y: 0.0, width: 1.0, height: 0.5)
        UIGraphicsBeginImageContextWithOptions(rect.size, false, 0.0)
        color.setFill()
        UIRectFill(rect)
        let image : UIImage = UIGraphicsGetImageFromCurrentImageContext()!
        UIGraphicsEndImageContext()
        return image
    }
}
