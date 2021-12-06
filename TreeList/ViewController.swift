//
//  ViewController.swift
//  TreeList
//
//  Created by ChangLiu on 2021/11/2.
//

import UIKit

class ViewController: UIViewController {
    private lazy var listButton: UIButton = {
        let button = UIButton(frame: .zero)
        button.accessibilityIdentifier = "sortButton"
        button.accessibilityLabel = NSLocalizedString("Sort", comment: "")
        button.addTarget(self, action: #selector(onSort(_:)), for: .touchUpInside)
        return button
    }()
                         
    override func viewDidLoad() {
        super.viewDidLoad()
        print("Original: \(array)")
        print("bubbleSort: \(bubbleSort(array))")
        print("SelectSort: \(selectSort(array))")
        print("InsertSort: \(insertSort(array))")
        print("QuickSort: \(quickSort(array))")
    }
                         
    @objc func onSort(_ sender: UIButton) {
          present(TreeListViewController(), animated: true)
    }
    
    var array: [Int] = (1...10).map( {_ in Int.random(in: 1...100)} )
    
    private func bubbleSort(_ array: [Int]) -> [Int] {
        var arrayCopy = array
        for i in 0..<arrayCopy.count {
            for j in i..<arrayCopy.count {
                if arrayCopy[i] > arrayCopy[j] {
                    let temp = arrayCopy[i]
                    arrayCopy[i] = arrayCopy[j]
                    arrayCopy[j] = temp
                }
            }
        }
        return arrayCopy
    }
    
    private func selectSort(_ array: [Int]) -> [Int] {
        var arrayCopy = array
        for i in 0..<arrayCopy.count {
            var pilot = arrayCopy[i]
            var index = i
            for j in i..<arrayCopy.count {
                if arrayCopy[j] < pilot {
                    index = j
                    pilot = arrayCopy[j]
                }
            }
            let temp = arrayCopy[i]
            arrayCopy[i] = arrayCopy[index]
            arrayCopy[index] = temp
        }
        return arrayCopy
    }
    
    private func insertSort(_ array: [Int]) -> [Int] {
        var arrayCopy = array
        for i in 1..<array.count {
            var index = i
            let pilot = arrayCopy[index]
            while index >= 1 && arrayCopy[index - 1] > pilot {
                arrayCopy[index] = arrayCopy[index - 1]
                index -= 1
            }
            arrayCopy[index] = pilot
        }
        return arrayCopy
    }
    
    private func quickSort(_ array: [Int]) -> [Int] {
        return quickSortHelpFunction(array, start: 0, end: array.count)
    }
    
    private func quickSortHelpFunction(_ array: [Int], start: Int, end: Int) -> [Int] {
        if start + 1 < end {
            var arrayCopy = array
            let pilot = arrayCopy[start]
            var index = start + 1
            for i in index..<end {
                if (arrayCopy[i] < pilot) {
                    let temp = arrayCopy[index]
                    arrayCopy[index] = arrayCopy[i]
                    arrayCopy[i] = temp
                    index += 1
                }
            }
            
            let temp = arrayCopy[start]
            arrayCopy[start] = arrayCopy[index - 1]
            arrayCopy[index - 1] = temp
            return quickSortHelpFunction(arrayCopy, start: start, end: index) + quickSortHelpFunction(arrayCopy, start: index, end: end)
        }
        return [array[start]]
    }
}

