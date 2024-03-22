//
//  GameCell.swift
//  Folium
//
//  Created by Jarrod Norwell on 23/1/2024.
//

import Foundation
import UIKit

class GameCell : UICollectionViewCell {
    var imageView, missingImageView: UIImageView!
    var textLabel, secondaryTextLabel: UILabel!
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        imageView = .init()
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.backgroundColor = .secondarySystemBackground
        imageView.clipsToBounds = true
        imageView.contentMode = .scaleAspectFit
        imageView.layer.cornerCurve = .continuous
        imageView.layer.cornerRadius = 15
        addSubview(imageView)
        
        missingImageView = .init()
        missingImageView.translatesAutoresizingMaskIntoConstraints = false
        missingImageView.contentMode = .scaleAspectFit
        missingImageView.tintColor = .tertiarySystemBackground
        imageView.addSubview(missingImageView)
        
        textLabel = .init()
        textLabel.translatesAutoresizingMaskIntoConstraints = false
        addSubview(textLabel)
        
        secondaryTextLabel = .init()
        secondaryTextLabel.translatesAutoresizingMaskIntoConstraints = false
        addSubview(secondaryTextLabel)
        
        addConstraints([
            imageView.topAnchor.constraint(equalTo: topAnchor),
            imageView.leadingAnchor.constraint(equalTo: leadingAnchor),
            imageView.trailingAnchor.constraint(equalTo: trailingAnchor),
            imageView.heightAnchor.constraint(equalTo: imageView.widthAnchor),
            
            missingImageView.centerXAnchor.constraint(equalTo: imageView.centerXAnchor),
            missingImageView.centerYAnchor.constraint(equalTo: imageView.centerYAnchor),
            missingImageView.widthAnchor.constraint(equalToConstant: 44),
            missingImageView.heightAnchor.constraint(equalToConstant: 44),
            
            textLabel.topAnchor.constraint(equalTo: imageView.bottomAnchor, constant: 12),
            textLabel.leadingAnchor.constraint(equalTo: leadingAnchor),
            textLabel.trailingAnchor.constraint(lessThanOrEqualTo: trailingAnchor),
            
            secondaryTextLabel.topAnchor.constraint(equalTo: textLabel.bottomAnchor, constant: 4),
            secondaryTextLabel.leadingAnchor.constraint(equalTo: leadingAnchor),
            secondaryTextLabel.bottomAnchor.constraint(equalTo: bottomAnchor),
            secondaryTextLabel.trailingAnchor.constraint(lessThanOrEqualTo: trailingAnchor)
        ])
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        imageView.image = nil
        missingImageView.image = nil
    }
    
    func set(_ text: String, _ secondaryText: String) {
        textLabel.attributedText = .init(string: text, attributes: [
            .font : UIFont.boldSystemFont(ofSize: UIFont.preferredFont(forTextStyle: .headline).pointSize),
            .foregroundColor : UIColor.label
        ])
        secondaryTextLabel.attributedText = .init(string: secondaryText, attributes: [
            .font : UIFont.preferredFont(forTextStyle: .subheadline),
            .foregroundColor : UIColor.secondaryLabel
        ])
    }
}
