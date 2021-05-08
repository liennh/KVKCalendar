//
//  DayView.swift
//  KVKCalendar
//
//  Created by Sergei Kviatkovskii on 02/01/2019.
//

import UIKit

final class DayView: UIView {
    
    weak var delegate: DisplayDelegate?
    weak var dataSource: DisplayDataSource?
    
    private var parameters: Parameters
    private let tagEventViewer = -10
    public var widthViewTask: CGFloat = 98
    public var layoutListTask: UIView = UIView()
    public var didReloadEvent: (([Event]) -> Void)?
    
    struct Parameters {
        var style: StyleKVK
        var data: DayData
    }
    
    //Stack View
    lazy var layoutDisplay: UIStackView = {
        let stackView = UIStackView()
        stackView.axis  = NSLayoutConstraint.Axis.horizontal
        stackView.alignment = UIStackView.Alignment.fill
        stackView.spacing = 2
        var timelineFrame = frame
        if !parameters.style.headerScroll.isHidden {
            timelineFrame.origin.y = scrollHeaderDay.frame.height
            timelineFrame.size.height -= scrollHeaderDay.frame.height
        }
        if UIDevice.current.userInterfaceIdiom == .pad {
            if UIDevice.current.orientation.isPortrait {
                timelineFrame.size.width = UIScreen.main.bounds.width * 0.5
            } else {
                timelineFrame.size.width -= parameters.style.timeline.widthEventViewer ?? 0
            }
        }
        stackView.frame = timelineFrame
        return stackView
    }()
    
    lazy var timelinePages: TimelinePageView = {
        var timelineFrame = layoutDisplay.frame
        if parameters.style.isShowTaskList {
            widthViewTask = UIScreen.main.bounds.width/4
        } else {
            widthViewTask = 0
        }
        if !parameters.style.headerScroll.isHidden {
            timelineFrame.origin.y = 0
        }
        if UIDevice.current.userInterfaceIdiom == .pad {
            if UIDevice.current.orientation.isPortrait {
                timelineFrame.size.width = UIScreen.main.bounds.width * 0.5
            } else {
                timelineFrame.size.width -= parameters.style.timeline.widthEventViewer ?? 0
            }
        }
        timelineFrame.size.width -= self.widthViewTask
        let timelineViews = Array(0..<parameters.style.timeline.maxLimitChachedPages).reduce([]) { (acc, _) -> [TimelineView] in
            return acc + [createTimelineView(frame: timelineFrame)]
        }
        let page = TimelinePageView(maxLimit: parameters.style.timeline.maxLimitChachedPages,
                                    pages: timelineViews,
                                    frame: timelineFrame)
        return page
    }()
    
    lazy var scrollHeaderDay: ScrollDayHeaderView = {
        let heightView: CGFloat
        if parameters.style.headerScroll.isHiddenSubview {
            heightView = parameters.style.headerScroll.heightHeaderWeek
        } else {
            heightView = parameters.style.headerScroll.heightHeaderWeek + parameters.style.headerScroll.heightSubviewHeader
        }
        let view = ScrollDayHeaderView(frame: CGRect(x: 0, y: 0, width: frame.width, height: heightView),
                                       days: parameters.data.days,
                                       date: parameters.data.date,
                                       type: .day,
                                       style: parameters.style)
        view.didSelectDate = { [weak self] (date, type) in
            self?.didSelectDateScrollHeader(date, type: type)
        }
        view.didTrackScrollOffset = { [weak self] (offset, stop) in
            self?.timelinePages.timelineView?.moveEvents(offset: offset, stop: stop)
        }
        view.didChangeDay = { [weak self] (type) in
            guard let self = self else { return }
            
            self.timelinePages.changePage(type)
            let newTimeline = self.createTimelineView(frame: CGRect(origin: .zero, size: self.timelinePages.bounds.size))
            
            switch type {
            case .next:
                self.timelinePages.addNewTimelineView(newTimeline, to: .end)
            case .previous:
                self.timelinePages.addNewTimelineView(newTimeline, to: .begin)
            }
        }
        return view
    }()
    
    private func createTimelineView(frame: CGRect) -> TimelineView {
        var viewFrame = frame
        viewFrame.origin = .zero
        
        let view = TimelineView(type: .day, timeHourSystem: parameters.data.timeSystem, style: parameters.style, frame: viewFrame)
        view.delegate = self
        view.dataSource = self
        view.deselectEvent = { [weak self] (event) in
            self?.delegate?.didDeselectEvent(event, animated: true)
        }
        return view
    }
    
    private lazy var topBackgroundView: UIView = {
        let heightView: CGFloat
        if parameters.style.headerScroll.isHiddenSubview {
            heightView = parameters.style.headerScroll.heightHeaderWeek
        } else {
            heightView = parameters.style.headerScroll.heightHeaderWeek + parameters.style.headerScroll.heightSubviewHeader
        }
        let view = UIView(frame: CGRect(x: 0, y: 0, width: frame.width, height: heightView))
        if let blur = parameters.style.headerScroll.backgroundBlurStyle {
            view.setBlur(style: blur)
        } else {
            view.backgroundColor = parameters.style.headerScroll.colorBackground
        }
        return view
    }()
    
    init(parameters: Parameters, frame: CGRect) {
        self.parameters = parameters
        super.init(frame: frame)
        setUI()
        
        timelinePages.didSwitchTimelineView = { [weak self] (_, type) in
            guard let self = self else { return }
            
            let newTimeline = self.createTimelineView(frame: self.timelinePages.frame)
            
            switch type {
            case .next:
                self.nextDate()
                self.timelinePages.addNewTimelineView(newTimeline, to: .end)
            case .previous:
                self.previousDate()
                self.timelinePages.addNewTimelineView(newTimeline, to: .begin)
            }
            
            self.didSelectDateScrollHeader(self.scrollHeaderDay.date, type: .day)
        }
        
        timelinePages.willDisplayTimelineView = { [weak self] (timeline, type) in
            guard let self = self else { return }
            
            let nextDate: Date?
            switch type {
            case .next:
                nextDate = self.parameters.style.calendar.date(byAdding: .day, value: 1, to: self.parameters.data.date)
            case .previous:
                nextDate = self.parameters.style.calendar.date(byAdding: .day, value: -1, to: self.parameters.data.date)
            }
            
            timeline.create(dates: [nextDate], events: self.parameters.data.events, selectedDate: self.parameters.data.date)
        }
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func setDate(_ date: Date) {
        parameters.data.date = date
        scrollHeaderDay.setDate(date)
    }
    
    func reloadData(_ events: [Event]) {
        parameters.data.events = events
        timelinePages.timelineView?.create(dates: [parameters.data.date], events: events, selectedDate: parameters.data.date)
    }
    
    func reloadEventViewer() {
        guard UIDevice.current.userInterfaceIdiom == .pad else { return }
        
        var defaultFrame = timelinePages.frame
        if let defaultWidth = parameters.style.timeline.widthEventViewer {
            defaultFrame.size.width = defaultWidth
        }
        updateEventViewer(frame: defaultFrame)
    }
    
    @discardableResult private func updateEventViewer(frame: CGRect) -> CGRect? {
        var viewerFrame = frame
        // hard reset the width when we change the orientation
        if UIDevice.current.orientation.isPortrait {
            viewerFrame.size.width = UIScreen.main.bounds.width * 0.5
            viewerFrame.origin.x = viewerFrame.width
        } else {
            viewerFrame.origin.x = bounds.width - viewerFrame.width
        }
        guard let eventViewer = dataSource?.willDisplayEventViewer(date: parameters.data.date, frame: viewerFrame) else { return nil }
        
        eventViewer.tag = tagEventViewer
        addSubview(eventViewer)
        return viewerFrame
    }
}

extension DayView: DisplayDataSource {
   
    
    
    func willDisplayEventView(_ event: Event, frame: CGRect, date: Date?) -> EventViewGeneral? {
        return dataSource?.willDisplayEventView(event, frame: frame, date: date)
    }
}

extension DayView {
    func didSelectDateScrollHeader(_ date: Date?, type: CalendarType) {
        guard let selectDate = date else { return }
        
        parameters.data.date = selectDate
        delegate?.didSelectDates([selectDate], type: type, frame: nil)
    }
}

extension DayView: TimelineDelegate {
    func didDisplayEvents(_ events: [Event], dates: [Date?]) {
        delegate?.didDisplayEvents(events, dates: dates, type: .day)
    }
    
    func didSelectEvent(_ event: Event, frame: CGRect?) {
        delegate?.didSelectEvent(event, type: .day, frame: frame)
    }
    
    func nextDate() {
        scrollHeaderDay.selectDate(offset: 1, needScrollToDate: true)
    }
    
    func previousDate() {
        scrollHeaderDay.selectDate(offset: -1, needScrollToDate: true)
    }
    
    func didResizeEvent(_ event: Event, startTime: ResizeTime, endTime: ResizeTime) {
        var startComponents = DateComponents()
        startComponents.year = event.start.year
        startComponents.month = event.start.month
        startComponents.day = event.start.day
        startComponents.hour = startTime.hour
        startComponents.minute = startTime.minute
        let startDate = parameters.style.calendar.date(from: startComponents)
        
        var endComponents = DateComponents()
        endComponents.year = event.end.year
        endComponents.month = event.end.month
        endComponents.day = event.end.day
        endComponents.hour = endTime.hour
        endComponents.minute = endTime.minute
        let endDate = parameters.style.calendar.date(from: endComponents)
                
        delegate?.didChangeEvent(event, start: startDate, end: endDate)
    }
    
    func didAddNewEvent(_ event: Event, minute: Int, hour: Int, point: CGPoint) {
        var components = DateComponents()
        components.year = parameters.data.date.year
        components.month = parameters.data.date.month
        components.day = parameters.data.date.day
        components.hour = hour
        components.minute = minute
        let date = parameters.style.calendar.date(from: components)
        delegate?.didAddNewEvent(event, date)
    }
    
    func didChangeEvent(_ event: Event, minute: Int, hour: Int, point: CGPoint, newDay: Int?, month: Int?, year: Int?) {
        var startComponents = DateComponents()
        startComponents.year = event.start.year
        startComponents.month = event.start.month
        startComponents.day = event.start.day
        startComponents.hour = hour
        startComponents.minute = minute
        let startDate = parameters.style.calendar.date(from: startComponents)
        
        let hourOffset = event.end.hour - event.start.hour
        let minuteOffset = event.end.minute - event.start.minute
        var endComponents = DateComponents()
        endComponents.year = event.end.year
        endComponents.month = event.end.month
        endComponents.day = event.end.day
        endComponents.hour = hour + hourOffset
        endComponents.minute = minute + minuteOffset
        let endDate = parameters.style.calendar.date(from: endComponents)
                
        delegate?.didChangeEvent(event, start: startDate, end: endDate)
    }
}

extension DayView: CalendarSettingProtocol {
    func reloadFrame(_ frame: CGRect) {
        if parameters.style.isShowTaskList {
            widthViewTask = UIScreen.main.bounds.width/4
        } else {
            widthViewTask = 0
        }
        self.frame = frame
        var timelineFrame = layoutDisplay.frame
        timelineFrame.size.width -= self.widthViewTask
        timelinePages.frame = timelineFrame
        timelinePages.timelineView?.reloadFrame(CGRect(origin: .zero, size: timelineFrame.size))
        timelinePages.timelineView?.create(dates: [parameters.data.date], events: parameters.data.events, selectedDate: parameters.data.date)
        timelinePages.reloadCacheControllers()
    }
    
    func updateStyle(_ style: StyleKVK) {
        self.parameters.style = style
        scrollHeaderDay.updateStyle(style)
        timelinePages.timelineView?.updateStyle(style)
        setUI()
        setDate(parameters.data.date)
    }
    
    func setUI() {
        subviews.forEach({ $0.removeFromSuperview() })
        
        if !parameters.style.headerScroll.isHidden {
            addSubview(topBackgroundView)
            topBackgroundView.addSubview(scrollHeaderDay)
        }
       
      
     
        
        if parameters.style.isShowTaskList {
            addSubview(layoutDisplay)
            timelinePages.setContentHuggingPriority(UILayoutPriority(rawValue: 250), for: .horizontal)
            timelinePages.setContentCompressionResistancePriority(UILayoutPriority(rawValue: 250), for: .horizontal)
            layoutListTask.setContentHuggingPriority(UILayoutPriority(rawValue: 999), for: .horizontal)
            layoutListTask.setContentCompressionResistancePriority(UILayoutPriority(rawValue: 999), for: .horizontal)
            layoutDisplay.addArrangedSubview(timelinePages)
            self.layoutListTask.backgroundColor = .red
            var listTaskFrame = layoutDisplay.frame
            listTaskFrame.origin.x = UIScreen.main.bounds.width - self.widthViewTask
            listTaskFrame.size.width = self.widthViewTask
            layoutListTask.frame = listTaskFrame
            addSubview(layoutListTask)
            self.bringSubviewToFront(layoutListTask)
        } else {
            addSubview(timelinePages)
        }
      
    }
}

