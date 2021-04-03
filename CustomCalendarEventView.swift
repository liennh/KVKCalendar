//
//  CustomCalendarEventView.swift
//  KVKCalendar
//
//  Created by KhacTao on 4/3/21.
//

import Foundation

final class CustomCalendarEventView: EventViewGeneral {
    
    let lbTitle: UILabel = {
        let label = UILabel()
        label.textColor = .white
        label.numberOfLines = 0
        label.font = UIFont.systemFont(ofSize: 14)
        label.lineBreakMode = .byWordWrapping
        label.clipsToBounds = true
        return label
    }()
    
    let textView: UITextView = {
        let textView = UITextView()
        textView.backgroundColor = .clear
        textView.isScrollEnabled = false
        textView.isUserInteractionEnabled = false
        textView.textContainer.lineBreakMode = .byTruncatingTail
        textView.textContainer.lineFragmentPadding = 0
        textView.textColor = .white
        return textView
    }()
    
    let ivDots: UIImageView = {
        let viewDots = UIImageView()
        return viewDots
    }()
    
    override init(style: StyleKVK, event: Event, frame: CGRect) {
        super.init(style: style, event: event, frame: frame)
        backgroundColor = event.backgroundColor.withAlphaComponent(0.7)
        self.clipsToBounds = true
        self.addSubview(ivDots)
        self.addSubview(textView)
        self.color = event.backgroundColor
        let dotsFrame = CGRect(x: 4, y: 10, width: 8, height: 8)
        let lbtitleFrame = CGRect(x: 16, y: 0, width: frame.size.width-15, height: frame.size.height)
        ivDots.frame = dotsFrame
        textView.frame = lbtitleFrame
//        if let task = CompanyTaskModel.get(by: event.ID) {
//            ivDots.image = task.status.image
//        }
//        ivDots.setImageColor(color: .white)
        textView.text = event.text
    
        if frame.width > 8 {
            ivDots.isHidden = false
            if frame.width > 18 {
                textView.isHidden = false
            }
        } else {
            ivDots.isHidden = true
            textView.isHidden = true
        }
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

}
