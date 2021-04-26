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
    
    private lazy var tableView: ExpyTableView = {
        let table = ExpyTableView(frame: self.frame, style: .plain)
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
        tableView.estimatedRowHeight = 44
        tableView.rowHeight = UITableView.automaticDimension
        tableView.register(HeaderSectionTableViewCell.self, forCellReuseIdentifier: "HeaderSectionTableViewCell")
        tableView.register(ListViewCell.self, forCellReuseIdentifier: "ListViewCell")
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
            if tableView.numberOfRows(inSection: idx) > 0 {
                tableView.scrollToRow(at: IndexPath(row: 0, section: idx), at: .top, animated: true)
            } else {
                let sectionRect = tableView.rect(forSection: idx)
                tableView.scrollRectToVisible(sectionRect, animated: true)
            }
            tableView.expand(idx)
           
        } else if let idx = params.data.sections.firstIndex(where: { $0.date.year == date.year && $0.date.month == date.month }) {
            if tableView.numberOfRows(inSection: idx) > 0 {
                tableView.scrollToRow(at: IndexPath(row: 0, section: idx), at: .top, animated: true)
            } else {
                let sectionRect = tableView.rect(forSection: idx)
                tableView.scrollRectToVisible(sectionRect, animated: true)
            }
            tableView.expand(idx)
        } else if let idx = params.data.sections.firstIndex(where: { $0.date.year == date.year }) {
            if tableView.numberOfRows(inSection: idx) > 0 {
                tableView.scrollToRow(at: IndexPath(row: 0, section: idx), at: .top, animated: true)
            } else {
                let sectionRect = tableView.rect(forSection: idx)
                tableView.scrollRectToVisible(sectionRect, animated: true)
            }
            tableView.expand(idx)
        }
    }
    
}


extension ListView: ExpyTableViewDataSource {
    func tableView(_ tableView: ExpyTableView, expandableCellForSection section: Int) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "HeaderSectionTableViewCell") as! HeaderSectionTableViewCell
        let date = params.data.sections[section].date
        cell.lbTitle.text = self.style.titleListFormatter.string(from: date)
        if let image = self.style.imageAdd {
            cell.btnAdd.setImage(image, for: .normal)
        }
        cell.actionAddDidTouched = { [weak self] in
            guard let _self = self else {return}
            _self.params.delegate?.didAddEventList(date)
        }
        
        return cell
    }
    
    func tableView(_ tableView: ExpyTableView, canExpandSection section: Int) -> Bool {
        return ExpyTableViewDefaultValues.expandableStatus
    }
}

extension ListView: ExpyTableViewDelegate {

    func tableView(_ tableView: ExpyTableView, expyState state: ExpyState, changeForSection section: Int) {
        print("Current state: \(state)")
    }
    
    
}

extension ListView {
    
    func tableView(_ tableView: UITableView, estimatedHeightForRowAt indexPath: IndexPath) -> CGFloat {
        if indexPath.row == 0 {
            return 44
        }
        return 60
    }
    func numberOfSections(in tableView: UITableView) -> Int {
        return params.data.numberOfSection()
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return params.data.numberOfItemsInSection(section) 
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let newIndexPath = IndexPath(row: indexPath.row-1, section: indexPath.section)
        let event = params.data.event(indexPath: newIndexPath)
        if let cell = params.dataSource?.dequeueNibCell(date: event.start, type: .list, view: tableView, indexPath: indexPath, events: [event]) as? UITableViewCell {
            return cell
        } else if let cell = params.dataSource?.dequeueCell(date: event.start, type: .list, view: tableView, indexPath: indexPath, events: [event]) as? UITableViewCell {
            return cell
        } else {
            let cell = tableView.dequeueReusableCell(withIdentifier: "ListViewCell", for: indexPath) as! ListViewCell
            cell.txt = event.textForList
            cell.dotColor = event.color?.value
            return cell
        }
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        if indexPath.row == 0 {
            return UITableView.automaticDimension
        }
        let newIndexPath = IndexPath(row: indexPath.row-1, section: indexPath.section)
        let event = params.data.event(indexPath: newIndexPath)
        if let height = params.delegate?.sizeForCell(event.start, type: .list)?.height {
            return height
        } else {
            return UITableView.automaticDimension
        }
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if indexPath.row == 0 {
            return
        }
        tableView.deselectRow(at: indexPath, animated: true)
        let newIndexPath = IndexPath(row: indexPath.row-1, section: indexPath.section)
        let event = params.data.event(indexPath: newIndexPath)
        let frameCell = tableView.cellForRow(at: newIndexPath)?.frame
        params.delegate?.didSelectEvent(event, type: .list, frame: frameCell)
    }
}
