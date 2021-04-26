//
//  ListView.swift
//  KVKCalendar
//
//  Created by Sergei Kviatkovskii on 26.12.2020.
//

import UIKit

final class ListView: UIView, CalendarSettingProtocol {
    
    struct Parameters {
        let style: StyleKVK
        let data: ListViewData
        weak var dataSource: DisplayDataSource?
        weak var delegate: DisplayDelegate?
    }
    
    private let params: Parameters
    
    private lazy var tableView: UITableView = {
        let table = UITableView()
        table.tableFooterView = UIView()
        table.dataSource = self
        table.delegate = self
        return table
    }()
    
    private var style: ListViewStyle {
        return params.style.list
    }
    
    init(parameters: Parameters, frame: CGRect) {
        self.params = parameters
        super.init(frame: frame)
        setUI()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func setUI() {
        backgroundColor = style.backgroundColor
        tableView.backgroundColor = style.backgroundColor
        tableView.frame = CGRect(origin: .zero, size: frame.size)
        addSubview(tableView)
    }
    
    func reloadFrame(_ frame: CGRect) {
        self.frame = frame
        tableView.frame = CGRect(origin: .zero, size: frame.size)
    }
    
    func reloadData(_ events: [Event]) {
        params.data.reloadEvents(events)
        tableView.reloadData()
    }
    
    func setDate(_ date: Date) {
        params.delegate?.didSelectDates([date], type: .list, frame: nil)
        params.data.date = date
        
        if let idx = params.data.sections.firstIndex(where: { $0.date.year == date.year && $0.date.month == date.month && $0.date.day == date.day }) {
            params.data.sections[idx].isExplain = true
            self.tableView.reloadData()
            if tableView.numberOfRows(inSection: idx) > 0 {
                tableView.scrollToRow(at: IndexPath(row: 0, section: idx), at: .top, animated: true)
            } else {
                let sectionRect = tableView.rect(forSection: idx)
                tableView.scrollRectToVisible(sectionRect, animated: true)
            }
           
        } else if let idx = params.data.sections.firstIndex(where: { $0.date.year == date.year && $0.date.month == date.month }) {
            params.data.sections[idx].isExplain = true
            self.tableView.reloadData()
            if tableView.numberOfRows(inSection: idx) > 0 {
                tableView.scrollToRow(at: IndexPath(row: 0, section: idx), at: .top, animated: true)
            } else {
                let sectionRect = tableView.rect(forSection: idx)
                tableView.scrollRectToVisible(sectionRect, animated: true)
            }
        } else if let idx = params.data.sections.firstIndex(where: { $0.date.year == date.year }) {
            params.data.sections[idx].isExplain = true
            self.tableView.reloadData()
            if tableView.numberOfRows(inSection: idx) > 0 {
                tableView.scrollToRow(at: IndexPath(row: 0, section: idx), at: .top, animated: true)
            } else {
                let sectionRect = tableView.rect(forSection: idx)
                tableView.scrollRectToVisible(sectionRect, animated: true)
            }
        }
    }
    
}

extension ListView: UITableViewDataSource, UITableViewDelegate {
    func numberOfSections(in tableView: UITableView) -> Int {
        return params.data.numberOfSection()
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if params.data.sections[section].isExplain == true {
            return params.data.numberOfItemsInSection(section)
        }
        return 0
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let event = params.data.event(indexPath: indexPath)
        if let cell = params.dataSource?.dequeueNibCell(date: event.start, type: .list, view: tableView, indexPath: indexPath, events: [event]) as? UITableViewCell {
            return cell
        } else if let cell = params.dataSource?.dequeueCell(date: event.start, type: .list, view: tableView, indexPath: indexPath, events: [event]) as? UITableViewCell {
            return cell
        } else {
            return tableView.dequeueCell(indexPath: indexPath) { (cell: ListViewCell) in
                cell.txt = event.textForList
                cell.dotColor = event.color?.value
            }
        }
    }
    
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let date = params.data.sections[section].date
        if let headerView = params.dataSource?.dequeueHeader(date: date, type: .list, view: tableView, indexPath: IndexPath(row: 0, section: section)) as? UIView {
            return headerView
        } else {
            return tableView.dequeueView { (view: ListViewHeader) in
                view.title = self.style.titleListFormatter.string(from: date)
                
                let backgroundView = UIView()
                backgroundView.backgroundColor = self.style.backgroundColor
                view.backgroundView = backgroundView
                view.titleLabel.font = self.style.fontTitle
                view.setExplainButton()
                
                view.isExplain = params.data.sections[section].isExplain
                view.actionExplain = { [weak self] isExplain in
                    guard let _self = self else {
                        return
                    }
                    let rowCount = _self.params.data.sections[section].events.count
                    _self.params.data.sections[section].isExplain = isExplain
                    _self.tableView.beginUpdates()
                    _self.tableView.layer.removeAllAnimations()
                    var indexInsers = [IndexPath]()
                    for index in 0..<_self.params.data.sections[section].events.count {
                        indexInsers.append(IndexPath(row: index, section: section))
                    }
                    if isExplain {
                        if _self.tableView.numberOfRows(inSection: section) == 0 {
                            _self.tableView.insertRows(at: indexInsers, with: .none)
                        }
                        
                    } else {
                        if _self.tableView.numberOfRows(inSection: section) == _self.params.data.sections[section].events.count  {
                            _self.tableView.deleteRows(at: indexInsers, with: .none)
                        }
                    }
                    
                    _self.tableView.endUpdates()
                    if isExplain, rowCount > 0 {
                        _self.tableView.scrollToRow(at: IndexPath(row: 0, section: section), at: .middle, animated: true)
                    }
                    
                }
            }
        }
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        let event = params.data.event(indexPath: indexPath)
        if let height = params.delegate?.sizeForCell(event.start, type: .list)?.height {
            return height
        } else {
            return UITableView.automaticDimension
        }
    }
    
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        let date = params.data.sections[section].date
        if let height = params.delegate?.sizeForHeader(date, type: .list)?.height {
            return height
        } else {
            return params.style.list.heightHeaderView
        }
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        
        let event = params.data.event(indexPath: indexPath)
        let frameCell = tableView.cellForRow(at: indexPath)?.frame
        params.delegate?.didSelectEvent(event, type: .list, frame: frameCell)
    }
}
