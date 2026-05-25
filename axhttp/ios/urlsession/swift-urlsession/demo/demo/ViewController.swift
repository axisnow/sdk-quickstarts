import UIKit

// import AXSecurity
// import AXSecurityURLSession

class ViewController: UIViewController {
    @IBOutlet var textView: UITextView!
    @IBOutlet var actionButton: UIButton!
    @IBOutlet var networkButton: UIButton!

    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
    }

    private func setupUI() {
        // Configure text view
        textView.text = ""
        textView.font = UIFont.systemFont(ofSize: 16)
        textView.backgroundColor = UIColor.lightGray
        textView.layer.cornerRadius = 8
        textView.layer.borderWidth = 1
        textView.layer.borderColor = UIColor.gray.cgColor
        textView.isEditable = true
        textView.isScrollEnabled = true

        // Configure buttons
        setupButton(actionButton, title: "初始化", color: UIColor.systemBlue)
        setupButton(networkButton, title: "网络请求", color: UIColor.systemOrange)
    }

    private func setupButton(_ button: UIButton, title: String, color: UIColor) {
        button.setTitle(title, for: .normal)
        button.backgroundColor = color
        button.setTitleColor(UIColor.white, for: .normal)
        button.layer.cornerRadius = 8
        button.titleLabel?.font = UIFont.boldSystemFont(ofSize: 16)
        // Add button shadow for better visual effect
        button.layer.shadowColor = UIColor.black.cgColor
        button.layer.shadowOffset = CGSize(width: 0, height: 2)
        button.layer.shadowOpacity = 0.3
        button.layer.shadowRadius = 4
    }

    @IBAction func buttonTapped(_ sender: UIButton) {
        var outputText = ""

        // *** UNCOMMENT THE LINES BELOW FOR AXHTTP***
        /*
         let config = AXConfig()
         config.accessKeyID = ""
         config.accessKeySecret = ""
         config.edgeNodes = [""]
         let result = AXService.initialize(config)
         if (result == 0) {
           outputText = "初始化成功"
         } else {
           outputText = "初始化失败"
         }
         */
        appendToTextView(" init : \(outputText)")
        animateButton(sender)
    }

    @IBAction func networkButtonTapped(_ sender: UIButton) {
        appendToTextView("🌐 正在发起网络请求...")
        animateButton(sender)

        // 使用URLSession进行网络请求
        performNetworkRequest { [weak self] result in
            DispatchQueue.main.async {
                self?.appendToTextView("📡 网络请求结果: \(result)")
            }
        }
    }

    // MARK: - Helper Methods

    private func appendToTextView(_ newText: String) {
        let currentText = textView.text ?? ""
        let separator = currentText.isEmpty ? "" : "\n"
        textView.text = currentText + separator + newText
        if !textView.text.isEmpty {
            let bottom = NSRange(location: textView.text.count - 1, length: 1)
            textView.scrollRangeToVisible(bottom)
        }
    }

    private func animateButton(_ button: UIButton) {
        UIView.animate(withDuration: 0.1, animations: {
            button.transform = CGAffineTransform(scaleX: 0.95, y: 0.95)
        }) { _ in
            UIView.animate(withDuration: 0.1) {
                button.transform = CGAffineTransform.identity
            }
        }
    }

    private func performNetworkRequest(completion: @escaping (String) -> Void) {
        guard let url = URL(string: "https://example.com") else {
            completion("URL无效")
            return
        }
        let defaultSession = URLSession(configuration: .default)
        // *** UNCOMMENT THE LINE BELOW FOR AXHTTP ***
        // let defaultSession = AXURLSession(configuration: .default)
        let reqeust = URLRequest(url: url)
        let task = defaultSession.dataTask(with: reqeust) { data, response, error in
            if let error {
                completion("请求失败: \(error.localizedDescription)")
                return
            }

            guard let httpResponse = response as? HTTPURLResponse else {
                completion("无效的响应")
                return
            }

            if httpResponse.statusCode == 200 {
                if let data,
                   let json = try? JSONSerialization.jsonObject(with: data, options: []) as? [String: Any]
                {
                    let slideshow = json["slideshow"] as? [String: Any]
                    let title = slideshow?["title"] as? String ?? "未知标题"
                    completion("HTTP 200 - 标题: \(title)")
                } else {
                    completion("HTTP 200 - 数据解析成功")
                }
            } else {
                completion("HTTP \(httpResponse.statusCode)")
            }
        }

        task.resume()
    }
}
