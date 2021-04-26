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
    
    override func awakeFromNib() {
        super.awakeFromNib()
  
        // Initialization code
    }
    
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        self.addSubview(stackContent)
        self.selectionStyle = .none
        stackContent.addArrangedSubview(lbTitle)
        stackContent.translatesAutoresizingMaskIntoConstraints = false
        stackContent.leadingAnchor.constraint(equalTo: self.leadingAnchor, constant: 16).isActive = true
        stackContent.trailingAnchor.constraint(equalTo: self.trailingAnchor, constant: -16).isActive = true
        stackContent.topAnchor.constraint(equalTo: self.topAnchor, constant: 8).isActive = true
        stackContent.bottomAnchor.constraint(equalTo: self.bottomAnchor, constant: -8).isActive = true
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
    
}
