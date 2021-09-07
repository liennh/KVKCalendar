//
//  TimelineView.swift
//  KVKCalendar
//
//  Created by Sergei Kviatkovskii on 02/01/2019.
//

import UIKit

final class TimelineView: UIView, EventDateProtocol {
    
    weak var delegate: TimelineDelegate?
    weak var dataSource: DisplayDataSource?
    
    var deselectEvent: ((Event) -> Void)?
    
    var style: StyleKVK
    var eventPreview: UIView?
    var eventResizePreview: ResizeEventView?
    var eventPreviewSize = CGSize(width: 150, height: 40)
    var isResizeEnableMode = false
    var isFirst: Bool = true
    
    private(set) var tagCurrentHourLine = -10
    private(set) var tagEventPagePreview = -20
    private(set) var tagVerticalLine = -30
    private let tagShadowView = -40
    private let tagBackgroundView = -50
    private(set) var tagAllDayPlaceholder = -60
    private(set) var tagAllDayEvent = -70
    private(set) var tagStubEvent = -80
    private(set) var timeLabels = [TimelineLabel]()
    private(set) var hours: [String]
    private let timeHourSystem: TimeHourSystem
    private var timer: Timer?
    private(set) var events = [Event]()
    private(set) var dates = [Date?]()
    private(set) var selectedDate: Date?
    private(set) var type: CalendarType
    
    private(set) lazy var shadowView: ShadowDayView = {
        let view = ShadowDayView()
        view.backgroundColor = style.timeline.shadowColumnColor
        view.alpha = style.timeline.shadowColumnAlpha
        view.tag = tagShadowView
        return view
    }()
    
    private(set) lazy var movingMinuteLabel: TimelineLabel = {
        let label = TimelineLabel()
        label.adjustsFontSizeToFitWidth = true
        label.textColor = style.timeline.movingMinutesColor
        label.textAlignment = .right
        label.font = style.timeline.timeFont
        return label
    }()
    
    private(set) lazy var currentLineView: CurrentLineView = {
        let view = CurrentLineView(style: style,
                                   frame: CGRect(x: 0, y: 0, width: scrollView.frame.width, height: 15),
                                   timeHourSystem: timeHourSystem)
        view.tag = tagCurrentHourLine
        return view
    }()
    
    private(set) lazy var scrollView: UIScrollView = {
        let scroll = UIScrollView()
        scroll.delegate = self
        scroll.backgroundColor = style.timeline.backgroundColor
        if #available(iOS 11.0, *) {
            scroll.contentInset.bottom = 49 + 28 + (UIApplication.shared.keyWindow?.safeAreaInsets.bottom ?? 0)
        } else {
            // Fallback on earlier versions
        }
        return scroll
    }()
    
    init(type: CalendarType, timeHourSystem: TimeHourSystem, style: StyleKVK, frame: CGRect) {
        self.type = type
        self.timeHourSystem = timeHourSystem
        self.hours = timeHourSystem.hours
        self.style = style
        super.init(frame: frame)
        
        var scrollFrame = frame
        scrollFrame.origin.y = 0
        scrollView.frame = scrollFrame
        addSubview(scrollView)
        
        if style.timeline.isEnabledCreateNewEvent {
            // long tap to create a new event preview
            let longTap = UILongPressGestureRecognizer(target: self, action: #selector(addNewEvent))
            longTap.minimumPressDuration = style.timeline.minimumPressDuration
            addGestureRecognizer(longTap)
        }
        
        let tap = UITapGestureRecognizer(target: self, action: #selector(forceDeselectEvent))
        addGestureRecognizer(tap)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    deinit {
        stopTimer()
    }
    
    private func calculateSectionEvent(_ events: [Event]) -> [[Event]] {
        var groupsOfEvents = [[Event]]()
        var overlappingEvents = [Event]()
        for event in events {
            if overlappingEvents.isEmpty {
              overlappingEvents.append(event)
              continue
            }
            
            let start = overlappingEvents.first!.start
            let longEvent = overlappingEvents.sorted { (event1, event2) -> Bool in
                return event1.end < event2.end
            }.last
            
            if (start...longEvent!.end).overlaps(event.start...event.end) && longEvent!.end != event.start {
                overlappingEvents.append(event)
                continue
            }
            if style.timeline.isSortCreatAt {
                groupsOfEvents.append(overlappingEvents.sorted(by: { (event1, event2) -> Bool in
                    event1.createAt < event2.createAt
                }))
            } else {
                groupsOfEvents.append(overlappingEvents)
            }
           
            overlappingEvents = [event]
        }
        if style.timeline.isSortCreatAt {
            groupsOfEvents.append(overlappingEvents.sorted(by: { (event1, event2) -> Bool in
                event1.createAt < event2.createAt
            }))
        } else {
            groupsOfEvents.append(overlappingEvents)
        }
 
        return groupsOfEvents
    }
    
    
    private func calculateCrossEvents(_ events: [Event]) -> [TimeInterval: CrossEvent] {
        var eventsTemp = events
        var crossEvents = [TimeInterval: CrossEvent]()
        
        var indexSection = 0
        var sectionDate: ClosedRange<Date>?
        
        while let event = eventsTemp.first {
            let start = event.start.timeIntervalSince1970
            let end = event.end.timeIntervalSince1970
            
            if sectionDate == nil {
                sectionDate = event.start...event.end
            }

            var crossEventNew = CrossEvent(eventTime: EventTime(start: start, end: end))
            let endCalculated: TimeInterval = crossEventNew.eventTime.end - TimeInterval(style.timeline.offsetEvent)
            let eventsFiltered = events.filter({ (item) in
                let itemEnd = item.end.timeIntervalSince1970 - TimeInterval(style.timeline.offsetEvent)
                let itemStart = item.start.timeIntervalSince1970
                return (itemStart...itemEnd).contains(start) || (itemStart...itemEnd).contains(endCalculated) || (start...endCalculated).contains(itemStart) || (start...endCalculated).contains(itemEnd)
            })
            if !eventsFiltered.isEmpty {
                crossEventNew.count = eventsFiltered.count
            }

            crossEvents[crossEventNew.eventTime.start] = crossEventNew
            eventsTemp.removeFirst()
        }
        
        return crossEvents
    }
    
    private func setOffsetScrollView() {
        var offsetY: CGFloat = 0
        if !subviews.filter({ $0 is AllDayTitleView }).isEmpty || !scrollView.subviews.filter({ $0 is AllDayTitleView }).isEmpty {
            offsetY = style.allDay.height
        }
        if #available(iOS 11.0, *) {
            scrollView.contentInset = UIEdgeInsets(top: offsetY, left: 0, bottom: 49 + 28 + (UIApplication.shared.keyWindow?.safeAreaInsets.bottom ?? 0), right: 0)
        } else {
            // Fallback on earlier versions
        }
    }
    
    private func getTimelineLabel(hour: Int) -> TimelineLabel? {
        return scrollView.subviews .filter({ (view) -> Bool in
            guard let time = view as? TimelineLabel else { return false }
            return time.valueHash == hour.hashValue }).first as? TimelineLabel
    }
    
    private func stopTimer() {
        if timer?.isValid ?? true {
            timer?.invalidate()
            timer = nil
        }
    }
    
    private func movingCurrentLineHour() {
        guard !(timer?.isValid ?? false) else { return }
        
        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] (_) in
            guard let self = self else { return }
            
            let nextDate = Date().convertTimeZone(TimeZone.current, to: self.style.timezone)
            guard self.currentLineView.valueHash != nextDate.minute.hashValue, let time = self.getTimelineLabel(hour: nextDate.hour) else { return }
            
            var pointY = time.frame.origin.y
            if !self.subviews.filter({ $0 is AllDayTitleView }).isEmpty, self.style.allDay.isPinned {
                pointY -= self.style.allDay.height
            }
            
            pointY = self.calculatePointYByMinute(nextDate.minute, time: time)
            
            self.currentLineView.frame.origin.y = pointY - (self.currentLineView.frame.height * 0.5)
            self.currentLineView.valueHash = nextDate.minute.hashValue
            
            let formatter = DateFormatter()
            formatter.dateFormat = self.timeHourSystem.format
            formatter.locale = Locale(identifier: "en_GB")
            self.currentLineView.time = formatter.string(from: nextDate)
            self.currentLineView.date = nextDate
            
            if let timeNext = self.getTimelineLabel(hour: nextDate.hour + 1) {
                timeNext.isHidden = self.currentLineView.frame.intersects(timeNext.frame)
            }
            time.isHidden = time.frame.intersects(self.currentLineView.frame)
        }
        
        guard let timer = timer else { return }
        RunLoop.current.add(timer, forMode: .default)
    }
    
    private func showCurrentLineHour() {
        let date = Date().convertTimeZone(TimeZone.current, to: self.style.timezone)
        guard style.timeline.showLineHourMode.showForDates(dates), let time = getTimelineLabel(hour: date.hour) else {
            currentLineView.removeFromSuperview()
            timer?.invalidate()
            return
        }
        
        var pointY = time.frame.origin.y
        if !subviews.filter({ $0 is AllDayTitleView }).isEmpty, style.allDay.isPinned {
            pointY -= style.allDay.height
        }
        
        pointY = calculatePointYByMinute(date.minute, time: time)
        currentLineView.frame.origin.y = pointY - (currentLineView.frame.height * 0.5)
        scrollView.addSubview(currentLineView)
        movingCurrentLineHour()
        
        if let timeNext = getTimelineLabel(hour: date.hour + 1) {
            timeNext.isHidden = currentLineView.frame.intersects(timeNext.frame)
        }
        time.isHidden = currentLineView.frame.intersects(time.frame)
    }
    
    private func calculatePointYByMinute(_ minute: Int, time: TimelineLabel) -> CGFloat {
        let pointY: CGFloat
        if 1...59 ~= minute {
            let minutePercent = 59.0 / CGFloat(minute)
            let newY = (style.timeline.offsetTimeY + time.frame.height) / minutePercent
            let summY = (CGFloat(time.tag) * (style.timeline.offsetTimeY + time.frame.height)) + (time.frame.height / 2)
            if time.tag == 0 {
                pointY = newY + (time.frame.height / 2)
            } else {
                pointY = summY + newY
            }
        } else {
            pointY = (CGFloat(time.tag) * (style.timeline.offsetTimeY + time.frame.height)) + (time.frame.height / 2)
        }
        return pointY
    }
    
    private func scrollToCurrentTime(_ startHour: Int) {
        guard isFirst, style.timeline.scrollLineHourMode.scrollForDates(dates) else { return }
        isFirst = false
        let date = Date().convertTimeZone(TimeZone.current, to: style.timezone)
        guard let time = getTimelineLabel(hour: date.hour)else {
            scrollView.setContentOffset(.zero, animated: true)
            return
        }
                
        var frame = scrollView.frame
        frame.origin.y = time.frame.origin.y - 10
        scrollView.scrollRectToVisible(frame, animated: true)
    }
    
    func create(dates: [Date?], events: [Event], selectedDate: Date?) {
        isResizeEnableMode = false
        delegate?.didDisplayEvents(events, dates: dates)
        
        self.dates = dates
        self.events = events
        self.selectedDate = selectedDate
        
        if style.allDay.isPinned {
            subviews.filter({ $0.tag == tagAllDayEvent || $0.tag == tagAllDayPlaceholder }).forEach({ $0.removeFromSuperview() })
        }
        subviews.filter({ $0.tag == tagStubEvent }).forEach({ $0.removeFromSuperview() })
        scrollView.subviews.filter({ $0.tag != tagCurrentHourLine }).forEach({ $0.removeFromSuperview() })
        
        // filter events
        let recurringEvents = events.filter({ $0.recurringType != .none })
        let startDays = dates.first??.startOfDay ?? Date()
        let endDays = dates.last??.endOfDay ?? Date()
        let allEventsForDates = events.filter { (event) -> Bool in
            return (startDays...endDays).overlaps(event.start...event.end)
        }
        let isTypeDay = self.type == .day
        let filteredEvents: [Event]
        if isTypeDay, style.isShowTaskList {//loai bo event la task: enum CalendarEventType TASK == 1
            filteredEvents = allEventsForDates.filter({ !$0.isAllDay && $0.eventType != 1 })
        } else {
            filteredEvents = allEventsForDates.filter({ !$0.isAllDay })
        }
        
        let filteredAllDayEvents = events.filter({ $0.isAllDay })

        // calculate a start hour
        let startHour: Int
        if !style.timeline.startFromFirstEvent {
            startHour = 0
        } else {
            if dates.count > 1 {
                startHour = filteredEvents.sorted(by: { $0.start.hour < $1.start.hour }).first?.start.hour ?? style.timeline.startHour
            } else {
                startHour = filteredEvents.filter({ compareStartDate(selectedDate, with: $0) })
                    .sorted(by: { $0.start.hour < $1.start.hour })
                    .first?.start.hour ?? style.timeline.startHour
            }
        }
        
        // add time label to timeline
        timeLabels = createTimesLabel(start: startHour)
        // add separator line
        let lines = createLines(times: timeLabels)
        
        // calculate all height by time label minus the last offset
        let heightAllTimes = timeLabels.reduce(0, { $0 + ($1.frame.height + style.timeline.offsetTimeY) }) - style.timeline.offsetTimeY
        scrollView.contentSize = CGSize(width: frame.width, height: heightAllTimes)
        timeLabels.forEach({ scrollView.addSubview($0) })
        lines.forEach({ scrollView.addSubview($0) })

        let leftOffset = style.timeline.widthTime + style.timeline.offsetTimeX + style.timeline.offsetLineLeft
        let widthPage = (frame.width - leftOffset) / CGFloat(dates.count)
        let heightPage = scrollView.contentSize.height
        let midnight = 24
        
        // horror
        for (idx, date) in dates.enumerated() {
            let pointX: CGFloat
            if idx == 0 {
                pointX = leftOffset
            } else {
                pointX = CGFloat(idx) * widthPage + leftOffset
            }
            
            let verticalLine = createVerticalLine(pointX: pointX, date: date)
            scrollView.addSubview(verticalLine)
            
            let startOfDay = date?.startOfDay ?? Date()
            let endOfDay = date?.endOfDay ?? Date()
            
            let eventsByDate = filteredEvents.filter({ (startOfDay...endOfDay).overlaps($0.start...$0.end) })
            let allDayEvents = filteredAllDayEvents.filter({ (startOfDay...endOfDay).overlaps($0.start...$0.end) }).sorted(by: { (event1, event2) -> Bool in
                return event1.eventType > event2.eventType
            })
            
            var recurringEventByDate: [Event] = [Event]()
            if self.style.isShowRepeat {
                if !recurringEvents.isEmpty, let dt = date {
                    recurringEventByDate = recurringEvents.reduce([], { (acc, event) -> [Event] in
    //                    guard !eventsByDate.contains(where: { $0.ID == event.ID })
    //                            && dt.compare(event.start) == .orderedDescending else { return acc }
                        guard let recurringEvent = event.updateListDateRepeatEveryDay(newDate: dt, calendar: style.calendar) else {
                            return acc
                        }
                        return acc + recurringEvent
                        
                    })
                } else {
                    recurringEventByDate = []
                }
            }
       
            let filteredRecurringEvents = recurringEventByDate.filter({ !$0.isAllDay })
            let filteredAllDayRecurringEvents = recurringEventByDate.filter({ $0.isAllDay })
            let sortedEventsByDate = (eventsByDate + filteredRecurringEvents).sorted(by: { $0.start < $1.start })
            
            // create an all day events
            if style.isShowSectionAllDay {
                createAllDayEvents(events: allDayEvents + filteredAllDayRecurringEvents, date: date, width: widthPage, originX: pointX)
            }
            
            // count event cross in one hour
            let crossEvents = calculateCrossEvents(sortedEventsByDate)
            
            let groupSections = calculateSectionEvent(sortedEventsByDate)
            var pagesCached = [EventViewGeneral]()
            
            if !sortedEventsByDate.isEmpty {
                // create event
                groupSections.forEach { (events) in
                    let countEvents = events.count
                    if countEvents == 0 {
                        return
                    }
                    let widthEvent = widthPage/CGFloat(events.count)
                   
                    for indexEvent in 0..<countEvents {
                        let event = events[indexEvent]
                        var newFrame = CGRect(x: 0, y: 0, width: 0, height: heightPage)
                        let originX = widthEvent*CGFloat(indexEvent) + pointX
                        newFrame.origin.x = originX
                        newFrame.size.width = widthEvent
                        timeLabels.forEach({ (time) in
                            // calculate position 'y'
                            if event.start.hour.hashValue == time.valueHash, compareStartDate(date, with: event) {
                                if time.tag == midnight, let newTime = timeLabels.first(where: { $0.tag == 0 }) {
                                    newFrame.origin.y = calculatePointYByMinute(event.start.minute, time: newTime)
                                } else {
                                    newFrame.origin.y = calculatePointYByMinute(event.start.minute, time: time)
                                }
                            }
//                            else if let firstTimeLabel = getTimelineLabel(hour: startHour), !compareStartDate(date, with: event) {
//                                newFrame.origin.y = calculatePointYByMinute(startHour, time: firstTimeLabel)
//                            }
//
                            // calculate 'height' event
                            if let defaultHeight = event.style?.defaultHeight {
                                newFrame.size.height = defaultHeight
                            } else if let globalDefaultHeight = style.event.defaultHeight {
                                newFrame.size.height = globalDefaultHeight
                            } else if event.end.hour.hashValue == time.valueHash, compareEndDate(date, with: event) {
                                var timeTemp = time
                                if time.tag == midnight, let newTime = timeLabels.first(where: { $0.tag == 0 }) {
                                    timeTemp = newTime
                                }
                                let summHeight = (CGFloat(timeTemp.tag) * (style.timeline.offsetTimeY + timeTemp.frame.height)) - newFrame.origin.y + (timeTemp.frame.height / 2)
                                if 0...59 ~= event.end.minute {
                                    let minutePercent = 59.0 / CGFloat(event.end.minute)
                                    let newY = (style.timeline.offsetTimeY + timeTemp.frame.height) / minutePercent
                                    newFrame.size.height = summHeight + newY - style.timeline.offsetEvent
                                } else {
                                    newFrame.size.height = summHeight - style.timeline.offsetEvent
                                }
                            } else if !compareEndDate(date, with: event) {
                                newFrame.size.height = (CGFloat(time.tag) * (style.timeline.offsetTimeY + time.frame.height)) - newFrame.origin.y + (time.frame.height / 2)
                            }
                        })
                        let page = getEventView(style: style, event: event, frame: newFrame, date: date)
                        page.delegate = self
                        page.dataSource = self
                        scrollView.addSubview(page)
                        pagesCached.append(page)
                    }
                }
                
                
                
//                var newFrame = CGRect(x: 0, y: 0, width: 0, height: heightPage)
//                sortedEventsByDate.forEach { (event) in
//                    timeLabels.forEach({ (time) in
//                        // calculate position 'y'
//                        if event.start.hour.hashValue == time.valueHash, event.start.day == date?.day {
//                            if time.tag == midnight, let newTime = timeLabels.first(where: { $0.tag == 0 }) {
//                                newFrame.origin.y = calculatePointYByMinute(event.start.minute, time: newTime)
//                            } else {
//                                newFrame.origin.y = calculatePointYByMinute(event.start.minute, time: time)
//                            }
//                        } else if let firstTimeLabel = getTimelineLabel(hour: startHour), event.start.day != date?.day {
//                            newFrame.origin.y = calculatePointYByMinute(startHour, time: firstTimeLabel)
//                        }
//
//                        // calculate 'height' event
//                        if let defaultHeight = event.style?.defaultHeight {
//                            newFrame.size.height = defaultHeight
//                        } else if let globalDefaultHeight = style.event.defaultHeight {
//                            newFrame.size.height = globalDefaultHeight
//                        } else if event.end.hour.hashValue == time.valueHash, event.end.day == date?.day {
//                            var timeTemp = time
//                            if time.tag == midnight, let newTime = timeLabels.first(where: { $0.tag == 0 }) {
//                                timeTemp = newTime
//                            }
//                            let summHeight = (CGFloat(timeTemp.tag) * (style.timeline.offsetTimeY + timeTemp.frame.height)) - newFrame.origin.y + (timeTemp.frame.height / 2)
//                            if 0...59 ~= event.end.minute {
//                                let minutePercent = 59.0 / CGFloat(event.end.minute)
//                                let newY = (style.timeline.offsetTimeY + timeTemp.frame.height) / minutePercent
//                                newFrame.size.height = summHeight + newY - style.timeline.offsetEvent
//                            } else {
//                                newFrame.size.height = summHeight - style.timeline.offsetEvent
//                            }
//                        } else if event.end.day != date?.day {
//                            newFrame.size.height = (CGFloat(time.tag) * (style.timeline.offsetTimeY + time.frame.height)) - newFrame.origin.y + (time.frame.height / 2)
//                        }
//                    })
//
//                    // calculate 'width' and position 'x'
//                    var newWidth = widthPage
//                    var newPointX = pointX
//                    if let crossEvent = crossEvents[event.start.timeIntervalSince1970] {
//                        newWidth /= CGFloat(crossEvent.count)
//                        newWidth -= style.timeline.offsetEvent
//                        newFrame.size.width = newWidth
//
//                        if crossEvent.count > 1, !pagesCached.isEmpty {
//                            for page in pagesCached {
//                                while page.frame.intersects(CGRect(x: newPointX, y: newFrame.origin.y, width: newFrame.width, height: newFrame.height)) {
//                                    newPointX += (page.frame.width + style.timeline.offsetEvent).rounded()
//                                }
//                            }
//                        }
//                    }
//
//                    newFrame.origin.x = newPointX
//
//                    let page = getEventView(style: style, event: event, frame: newFrame, date: date)
//                    page.delegate = self
//                    page.dataSource = self
//                    scrollView.addSubview(page)
//                    pagesCached.append(page)
//                }
            }
            
            if !style.timeline.isHiddenStubEvent, let day = date?.day {
                let y = topStabStackOffsetY(allDayEventsIsPinned: style.allDay.isPinned,
                                            axis: style.allDay.axis,
                                            eventsCount: (allDayEvents + filteredAllDayRecurringEvents).count,
                                            height: style.allDay.height)
                let topStackFrame = CGRect(x: pointX, y: y, width: widthPage - style.timeline.offsetEvent, height: style.event.heightStubView)
                let bottomStackFrame = CGRect(x: pointX, y: frame.height - bottomStabStackOffsetY, width: widthPage - style.timeline.offsetEvent, height: style.event.heightStubView)
                
                addSubview(createStackView(day: day, type: .top, frame: topStackFrame))
                addSubview(createStackView(day: day, type: .bottom, frame: bottomStackFrame))
            }
        }
        setOffsetScrollView()
        scrollToCurrentTime(startHour)
        showCurrentLineHour()
        addStubInvisibleEvents()
    }
}


