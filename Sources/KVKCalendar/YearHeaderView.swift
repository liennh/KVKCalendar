//
//  YearHeaderView.swift
//  KVKCalendar
//
//  Created by Sergei Kviatkovskii on 03/01/2019.
//

import UIKit

final class YearHeaderView: UICollectionReusableView {
    
    private let titleLabel: UILabel = {
        let label = UILabel()
        label.backgroundColor = .clear
        return label
    }()
    
    var date: Date? {
        didSet {
            guard let date = date else { return }
            
            titleLabel.text = date.titleForLocale(style.locale, formatter: style.year.titleFormatter)
            if Date().year == date.year {
                titleLabel.textColor = .systemRed
            } else {
                titleLabel.textColor = style.year.colorTitleHeader
            }
        }
    }
    
    var style: StyleKVK = StyleKVK() {
        didSet {
            titleLabel.textColor = style.year.colorTitleHeader
            titleLabel.font = style.year.fontTitleHeader
            titleLabel.textAlignment = style.year.alignmentTitleHeader
            backgroundColor = style.year.colorBackgroundHeader
        }
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        titleLabel.frame = CGRect(x: 20, y: 0, width: frame.width - 10, height: frame.height)
        addSubview(titleLabel)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

extension YearHeaderView: CalendarSettingProtocol {
    func reloadFrame(_ frame: CGRect) {
        self.frame.size.width = frame.width
        titleLabel.frame.size.width = frame.width
    }
    
    func updateStyle(_ style: StyleKVK) {
        self.style = style
    }
}
