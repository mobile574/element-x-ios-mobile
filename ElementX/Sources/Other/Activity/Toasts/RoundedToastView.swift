// 
// Copyright 2021 New Vector Ltd
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
// http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.
//

import Foundation
import UIKit

class RoundedToastView: UIView {
    private struct Constants {
        static let padding = UIEdgeInsets(top: 10, left: 12, bottom: 10, right: 12)
        static let activityIndicatorScale = CGFloat(0.75)
        static let imageViewSize = CGFloat(15)
        static let shadowOffset = CGSize(width: 0, height: 4)
        static let shadowRadius = CGFloat(12)
        static let shadowOpacity = Float(0.1)
    }
    
    private lazy var activityIndicator: UIActivityIndicatorView = {
        let indicator = UIActivityIndicatorView()
        indicator.transform = .init(scaleX: Constants.activityIndicatorScale, y: Constants.activityIndicatorScale)
        indicator.startAnimating()
        return indicator
    }()
    
    private lazy var imagView: UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFit
        imageView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            imageView.widthAnchor.constraint(equalToConstant: Constants.imageViewSize),
            imageView.heightAnchor.constraint(equalToConstant: Constants.imageViewSize)
        ])
        return imageView
    }()
    
    private let stackView: UIStackView = {
        let stack = UIStackView()
        stack.axis = .horizontal
        stack.alignment = .center
        stack.spacing = 5
        return stack
    }()
    
    private let label: UILabel = {
        return UILabel()
    }()

    init(viewState: ViewState) {
        super.init(frame: .zero)
        setup(viewState: viewState)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setup(viewState: ViewState) {
        
        backgroundColor = .gray.withAlphaComponent(0.75)
        
        setupLayer()
        setupStackView()
        stackView.addArrangedSubview(toastView(for: viewState.style))
        stackView.addArrangedSubview(label)
        label.text = viewState.label
    }
    
    private func setupStackView() {
        addSubview(stackView)
        stackView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            stackView.topAnchor.constraint(equalTo: topAnchor, constant: Constants.padding.top),
            stackView.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -Constants.padding.bottom),
            stackView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: Constants.padding.left),
            stackView.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -Constants.padding.right)
        ])
    }
    
    private func setupLayer() {
        layer.shadowColor = UIColor.black.cgColor
        layer.shadowOffset = Constants.shadowOffset
        layer.shadowRadius = Constants.shadowRadius
        layer.shadowOpacity = Constants.shadowOpacity
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        layer.cornerRadius = layer.frame.height / 2
    }
        
    private func toastView(for style: Style) -> UIView {
        switch style {
        case .loading:
            return activityIndicator
        case .success:
            imagView.image = UIImage(systemName: "checkmark.circle")
            return imagView
        }
    }
}

extension RoundedToastView {
    enum Style {
        case loading
        case success
    }
    struct ViewState {
        let style: Style
        let label: String
    }
}
