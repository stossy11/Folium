//
//  INIEditController.swift
//  Folium
//
//  Created by Jarrod Norwell on 13/3/2024.
//

#if canImport(Cytrus)
import Cytrus
#endif
import Grape
#if canImport(Sudachi)
import Sudachi
#endif

import Foundation
import UIKit

class INIEditController : UIViewController, UITextViewDelegate, UIPickerViewDelegate, UIPickerViewDataSource {
    var console: Core.Console
    var url: URL
    var settings: [String: Any] = [:]
    var titles: [String] = []
    var keys: [String] = []
    var switches: [String: UISwitch] = [:]
    var pickers: [String: UIPickerView] = [:]

    init(console: Core.Console, url: URL) {
        self.console = console
        self.url = url
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        navigationItem.setLeftBarButton(.init(systemItem: .close, primaryAction: .init(handler: { _ in self.dismiss(animated: true) })), animated: true)
        navigationItem.setRightBarButton(.init(systemItem: .save, primaryAction: .init(handler: { _ in
            self.save()

            switch self.console {
            case .nds:
                Grape.shared.settingsSaved()
#if canImport(Cytrus)
            case .n3ds:
                Cytrus.shared.settingsSaved()
#endif
#if canImport(Sudachi)
            case .nSwitch:
                Sudachi.shared.settingsSaved()
#endif
            default:
                break
            }

            self.dismiss(animated: true)
        })), animated: true)
        view.backgroundColor = .systemBackground

        // Parse the .ini file
        guard let lines = try? String(contentsOf: url).split(separator: "\n") else { return }
        var currentTitle = ""
        for line in lines {
            let trimmedLine = line.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)
            if trimmedLine.hasPrefix("[") && trimmedLine.hasSuffix("]") {
                // This is a title
                currentTitle = String(trimmedLine.dropFirst().dropLast())
                titles.append(currentTitle)
            } else if !trimmedLine.hasPrefix("//") && !trimmedLine.hasPrefix("#") {
                // This is a key-value pair
                let components = trimmedLine.components(separatedBy: "=")
                if components.count == 2 {
                    let key = components[0].trimmingCharacters(in: .whitespaces)
                    let value = components[1].trimmingCharacters(in: .whitespaces)
                    settings[currentTitle + "." + key] = value
                    keys.append(currentTitle + "." + key)
                }
            }
        }

        // Create a UIScrollView
        let scrollView = UIScrollView()
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(scrollView)

        // Create constraints for the scroll view
        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: view.topAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor)
        ])

        var yOffset: CGFloat = 20
        for key in keys {
            // Create a UILabel for the title
            let label = UILabel()
            label.text = key
            label.frame = CGRect(x: 20, y: yOffset, width: 200, height: 30)
            scrollView.addSubview(label)

            yOffset += 40

            if key == "Renderer.resolution_setup" {
                let picker = UIPickerView()
                picker.delegate = self
                picker.dataSource = self
                picker.tag = Int(settings[key] as? String ?? "0") ?? 0
                pickers[key] = picker

                // Set the picker's frame
                picker.frame = CGRect(x: 20, y: yOffset, width: self.view.frame.width - 40, height: 100)

                // Add the picker to your view
                scrollView.addSubview(picker)

                yOffset += 120
            } else {
                let switchControl = UISwitch()
                
                // Read the value from the .ini file
                let value = settings[key] as? String ?? "0"
                
                // Set the switch to on if the value is "1", off otherwise
                switchControl.isOn = (value == "1")
                
                switchControl.addTarget(self, action: #selector(switchChanged(_:)), for: .valueChanged)
                switches[key] = switchControl

                // Set the switch's frame or constraints here
                // For example:
                switchControl.frame = CGRect(x: 20, y: yOffset, width: 60, height: 30)

                // Add the switch to your view
                scrollView.addSubview(switchControl)

                yOffset += 40
            }
        }

        // Update the content size of the scroll view
        scrollView.contentSize = CGSize(width: view.frame.width, height: yOffset)
    }

    @objc func switchChanged(_ sender: UISwitch) {
        guard let key = switches.first(where: { $1 == sender })?.key else { return }
        settings[key] = sender.isOn ? "1" : "0"
    }

    // UIPickerViewDataSource methods
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 1
    }

    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        return 8 // For values 0 to 7
    }

    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        return String(row)
    }

    // UIPickerViewDelegate method
    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        guard let key = pickers.first(where: { $1 == pickerView })?.key else { return }
        settings[key] = String(row)
    }

    @objc fileprivate func save() {
        var iniString = ""
        for title in titles {
            iniString += "[\(title)]\n"
            for key in keys where key.hasPrefix(title + ".") {
                let value = settings[key] ?? ""
                iniString += "\(key.dropFirst(title.count + 1)) = \(value)\n"
            }
            iniString += "\n"
        }
        try? iniString.write(to: url, atomically: true, encoding: .utf8)
    }
}






/* class INIEditController : UIViewController, UITextViewDelegate {
    var textView: UITextView!
    
    var console: Core.Console
    var url: URL
    init(console: Core.Console, url: URL) {
        self.console = console
        self.url = url
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    var bottomConstraint: NSLayoutConstraint!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        navigationItem.setLeftBarButton(.init(systemItem: .close, primaryAction: .init(handler: { _ in self.dismiss(animated: true) })), animated: true)
        navigationItem.setRightBarButton(.init(systemItem: .save, primaryAction: .init(handler: { _ in
            self.save()
            
            switch self.console {
            case .nds:
                Grape.shared.settingsSaved()
#if canImport(Cytrus)
            case .n3ds:
                Cytrus.shared.settingsSaved()
#endif
#if canImport(Sudachi)
            case .nSwitch:
                Sudachi.shared.settingsSaved()
#endif
            default:
                break
            }
            
            self.dismiss(animated: true)
        })), animated: true)
        view.backgroundColor = .systemBackground
        
        textView = .init()
        textView.translatesAutoresizingMaskIntoConstraints = false
        textView.backgroundColor = .clear
        textView.font = .preferredFont(forTextStyle: .body)
        view.addSubview(textView)
        bottomConstraint = textView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor)
        bottomConstraint.priority = .defaultLow
        view.addConstraints([
            textView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            textView.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor),
            bottomConstraint,
            textView.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor)
        ])
        
        textView.text = try? String(contentsOf: url)
        
        NotificationCenter.default.addObserver(forName: .init(UIResponder.keyboardWillShowNotification), object: nil, queue: .main) { notification in
            guard let userInfo = notification.userInfo, let frame = userInfo[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect else {
                return
            }
            
            self.bottomConstraint.constant = -frame.height
            UIView.animate(withDuration: 0.2) {
                self.view.layoutIfNeeded()
            }
        }
        
        NotificationCenter.default.addObserver(forName: .init(UIResponder.keyboardWillHideNotification), object: nil, queue: .main) { notification in
            self.bottomConstraint.constant = 0
            UIView.animate(withDuration: 0.2) {
                self.view.layoutIfNeeded()
            }
        }
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        NotificationCenter.default.removeObserver(self)
    }
    
    @objc fileprivate func save() {
        guard let text = textView.text else {
            return
        }
        
        try? text.write(to: url, atomically: true, encoding: .utf8)
    }
}
*/
