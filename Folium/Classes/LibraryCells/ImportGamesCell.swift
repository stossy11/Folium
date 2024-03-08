//
//  ImportGamesCell.swift
//  Folium
//
//  Created by Jarrod Norwell on 4/3/2024.
//

import Foundation
import UIKit

class ImportGamesCell : UICollectionViewCell {
    fileprivate var textLabel: UILabel!
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = .secondarySystemBackground
        layer.cornerCurve = .continuous
        layer.cornerRadius = 15
        
        textLabel = .init()
        textLabel.translatesAutoresizingMaskIntoConstraints = false
        textLabel.textAlignment = .center
        addSubview(textLabel)
        
        addConstraints([
            textLabel.topAnchor.constraint(equalTo: topAnchor, constant: 20),
            textLabel.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 20),
            textLabel.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -20),
            textLabel.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -20)
        ])
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    
    func set(_ text: String) {
        textLabel.attributedText = .init(string: text, attributes: [
            .font : UIFont.boldSystemFont(ofSize: UIFont.preferredFont(forTextStyle: .headline).pointSize),
            .foregroundColor : UIColor.secondaryLabel
        ])
    }
}
