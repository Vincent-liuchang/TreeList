//
//  UIViewController+Extensions.swift
//  TreeList
//
//  Created by ChangLiu on 2021/12/6.
//

import Foundation
import UIKit

extension UIViewController {
    func addChildViewController(_ viewController: UIViewController) {
        addChild(viewController)
        view.addSubview(viewController.view)
        viewController.didMove(toParent: self)
    }
}
