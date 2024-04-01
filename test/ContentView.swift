import UIKit
import SwiftUI

struct ContentView: View {
    var body: some View {
        UIKitTableViewWrapper()
    }
}

struct UIKitTableViewWrapper: UIViewControllerRepresentable {
    func makeUIViewController(context: Context) -> UINavigationController {
        let navigationController = UINavigationController(rootViewController: TableViewController())
        navigationController.navigationBar.isHidden = true
        return navigationController
    }
    
    func updateUIViewController(_ uiViewController: UINavigationController, context: Context) {
    }
    
    typealias UIViewControllerType = UINavigationController
}

protocol TableCellDelegate: AnyObject {
    func updateLabelAtIndex(row: Int, index: Int, value: String)
}

class TableViewController: UITableViewController, TableCellDelegate {
    
    var visibleValuesArray = [[String]]()
    var horizontalValues: [[String]] = []
    var timer: Timer?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.register(YourTableViewCellSubclass.self, forCellReuseIdentifier: "Cell")
        tableView.rowHeight = 45
        tableView.separatorStyle = .none
        tableView.delegate = self
        tableView.dataSource = self
        
        timer = Timer.scheduledTimer(timeInterval: 1.0, target: self, selector: #selector(updateValues), userInfo: nil, repeats: true)
        
        generateRandomValues()
        tableView.reloadData()
    }
    
    func generateRandomValues() {
        horizontalValues.removeAll() 
        visibleValuesArray.removeAll()
        
        (0...101).forEach { _ in
            let randomCount = Int.random(in: 11...50)
            let values = (0..<randomCount).map { _ in String(Int.random(in: 0..<100)) }
            horizontalValues.append(values)
            visibleValuesArray.append(Array(repeating: "", count: values.count))
        }
    }
    
    @objc func updateValues() {
        updateRandomValueInVisibleIndexes()
    }
    
    func updateRandomValueInVisibleIndexes() {
        let visibleIndexes = findVisibleIndexesInHorizontalValues()
        
        for visibleIndex in visibleIndexes {
            let rowIndex = visibleIndex.row
            let indexes = visibleIndex.indexes
            
            guard !indexes.isEmpty else { continue }
            
            let randomIndex = indexes.randomElement()!
            let updatedValue = String(Int.random(in: 0..<100))
            
            horizontalValues[rowIndex][randomIndex] = updatedValue
            
            DispatchQueue.main.async {
                self.updateLabelAtIndex(row: rowIndex, index: randomIndex, value: updatedValue)
            }
        }
    }
    
    func updateLabelAtIndex(row: Int, index: Int, value: String) {
        tableView.reloadRows(at: [IndexPath(row: row, section: 0)], with: .none)
    }
    
    func findVisibleIndexesInHorizontalValues() -> [(row: Int, indexes: [Int])] {
        var visibleIndexes: [(row: Int, indexes: [Int])] = []
        
        guard let visibleIndexPaths = tableView.indexPathsForVisibleRows else { return visibleIndexes }
        
        for indexPath in visibleIndexPaths {
            if let cell = tableView.cellForRow(at: indexPath) as? YourTableViewCellSubclass {
                let values = cell.horizontalValues
                let contentOffset = cell.scrollView?.contentOffset ?? .zero
                
                var indexes: [Int] = []
                
                for (index, _) in values.enumerated() {
                    let valueRect = CGRect(x: CGFloat(index) * 40 - contentOffset.x, y: cell.frame.origin.y - contentOffset.y, width: 35, height: 35)
                    if valueRect.intersects(tableView.bounds) {
                        indexes.append(index)
                    }
                }
                
                if !indexes.isEmpty {
                    visibleIndexes.append((row: indexPath.row, indexes: indexes))
                }
            }
        }
        return visibleIndexes
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return horizontalValues.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "Cell", for: indexPath) as! YourTableViewCellSubclass
        let values = horizontalValues[indexPath.row]
        
        cell.horizontalValues = values
        cell.delegate = self // Установка делегата для передачи обновлений
        
        cell.contentView.subviews.forEach { $0.removeFromSuperview() }
        
        let scrollView = UIScrollView()
        scrollView.showsHorizontalScrollIndicator = false
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.delegate = self
        cell.scrollView = scrollView
        
        let contentView = UIStackView()
        contentView.axis = .horizontal
        contentView.distribution = .fillEqually
        contentView.spacing = 5
        contentView.translatesAutoresizingMaskIntoConstraints = false
        
        for value in values {
            let label = UILabel()
            label.text = value
            label.layer.borderColor = UIColor.black.cgColor
            label.layer.borderWidth = 1.0
            label.layer.cornerRadius = 10
            label.textAlignment = .center
            label.translatesAutoresizingMaskIntoConstraints = false
            NSLayoutConstraint.activate([
                label.widthAnchor.constraint(equalToConstant: 35),
                label.heightAnchor.constraint(equalToConstant: 35)
            ])
            let tapGestureRecognizer = UITapGestureRecognizer(target: cell, action: #selector(YourTableViewCellSubclass.handleTap(_:)))
            label.addGestureRecognizer(tapGestureRecognizer)
            label.isUserInteractionEnabled = true
            
            contentView.addArrangedSubview(label)
            cell.labels.append(label)
        }
        
        scrollView.addSubview(contentView)
        cell.contentView.addSubview(scrollView)
        
        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: cell.contentView.topAnchor),
            scrollView.leadingAnchor.constraint(equalTo: cell.contentView.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: cell.contentView.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: cell.contentView.bottomAnchor),
            
            contentView.topAnchor.constraint(equalTo: scrollView.topAnchor),
            contentView.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor),
            contentView.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor),
            contentView.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor),
            contentView.widthAnchor.constraint(equalToConstant: CGFloat(35 * values.count) + CGFloat(5 * (values.count - 1)))
        ])
        
        return cell
    }
}

class YourTableViewCellSubclass: UITableViewCell {
    var scrollView: UIScrollView?
    var horizontalValues: [String] = []
    var labels: [UILabel] = []
    weak var delegate: TableCellDelegate? 
  
    override func prepareForReuse() {
        super.prepareForReuse()
        
        labels.removeAll()
    }
    
    @objc func handleTap(_ sender: UITapGestureRecognizer) {
        guard let label = sender.view as? UILabel else { return }
        UIView.animate(withDuration: 0.2, animations: {
            label.transform = label.transform.scaledBy(x: 0.8, y: 0.8)
        }) { _ in
            UIView.animate(withDuration: 0.2) {
                label.transform = .identity
            }
        }
    }
}
