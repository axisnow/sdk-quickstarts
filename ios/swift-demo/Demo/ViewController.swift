import Starscream
import UIKit

// *** UNCOMMENT THE LINE BELOW FOR SDK ***
// import AXSecurity

class ViewController: UIViewController {
    private var logView: UITextView!

    private let httpURL = "https://example.com" // your HTTP endpoint
    private let wsURL = "wss://echo.websocket.org" // your WebSocket endpoint

    /// WebSocket connection (Starscream).
    private var webSocket: WebSocket?

    override func viewDidLoad() {
        super.viewDidLoad()

        // *** UNCOMMENT THE LINES BELOW FOR SDK ***
        // let config = AXConfig()
        // config.accessKeyID     = "<YOUR_ACCESS_KEY_ID>"
        // config.accessKeySecret = "<YOUR_ACCESS_KEY_SECRET>"
        // config.edgeNodes       = ["<AXISNOW_EDGE_DOH_EIP_OR_DOMAIN>"]
        //
        // let dns = AXDNSConfig()
        // dns.edgeDohResolveDomains = ["<YOUR_DOMAIN>"]
        // config.dns = dns
        //
        // let proxy = AXProxyConfig()
        // proxy.secureProxyEnabled = true
        // config.proxy = proxy
        //
        // let r = AXService.initialize(config)
        // if r != 0 {
        //     NSLog("SDK initialization failed: %d", r)
        // }

        view.backgroundColor = .white
        setupUI()
    }

    private func setupUI() {
        logView = UITextView()
        logView.translatesAutoresizingMaskIntoConstraints = false
        logView.font = .systemFont(ofSize: 14)
        logView.textColor = .black
        logView.backgroundColor = UIColor(white: 0.95, alpha: 1.0)
        logView.layer.cornerRadius = 8
        logView.layer.borderColor = UIColor.lightGray.cgColor
        logView.layer.borderWidth = 1
        logView.isEditable = false
        view.addSubview(logView)

        let httpButton = makeButton(title: "HTTP Request", color: .systemOrange,
                                    action: #selector(onHTTPTapped))
        let wsButton = makeButton(title: "WebSocket", color: .systemPurple,
                                  action: #selector(onWSTapped))

        let stack = UIStackView(arrangedSubviews: [httpButton, wsButton])
        stack.axis = .vertical
        stack.spacing = 12
        stack.distribution = .fillEqually
        stack.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(stack)

        let guide = view.safeAreaLayoutGuide
        NSLayoutConstraint.activate([
            logView.topAnchor.constraint(equalTo: guide.topAnchor, constant: 16),
            logView.leadingAnchor.constraint(equalTo: guide.leadingAnchor, constant: 16),
            logView.trailingAnchor.constraint(equalTo: guide.trailingAnchor, constant: -16),
            logView.bottomAnchor.constraint(equalTo: stack.topAnchor, constant: -16),

            stack.leadingAnchor.constraint(equalTo: guide.leadingAnchor, constant: 16),
            stack.trailingAnchor.constraint(equalTo: guide.trailingAnchor, constant: -16),
            stack.bottomAnchor.constraint(equalTo: guide.bottomAnchor, constant: -16),
            stack.heightAnchor.constraint(equalToConstant: 124),
        ])
    }

    private func makeButton(title: String, color: UIColor, action: Selector) -> UIButton {
        let button = UIButton(type: .system)
        button.setTitle(title, for: .normal)
        button.setTitleColor(.white, for: .normal)
        button.backgroundColor = color
        button.titleLabel?.font = .boldSystemFont(ofSize: 16)
        button.layer.cornerRadius = 8
        button.addTarget(self, action: action, for: .touchUpInside)
        return button
    }

    // MARK: - HTTP via URLSession + local HTTP proxy

    @objc private func onHTTPTapped() {
        appendLog("HTTP: GET \(httpURL) ...")
        sendHTTPRequest()
    }

    private func sendHTTPRequest() {
        guard let url = URL(string: httpURL) else {
            appendLog("HTTP: invalid URL")
            return
        }

        let cfg = URLSessionConfiguration.default

        // *** UNCOMMENT THE LINES BELOW FOR SDK ***
        // if let proxy = AXService.getLocalHTTPProxy(), proxy.port > 0, !proxy.ip.isEmpty {
        //     let port = Int(proxy.port)
        //     cfg.connectionProxyDictionary = [
        //         "HTTPEnable": 1,
        //         "HTTPProxy": proxy.ip,
        //         "HTTPPort": port,
        //         "HTTPSEnable": 1,
        //         "HTTPSProxy": proxy.ip,
        //         "HTTPSPort": port,
        //     ]
        //     self.appendLog("HTTP: using SDK proxy \(proxy.ip):\(port)")
        // }

        let session = URLSession(configuration: cfg)
        let task = session.dataTask(with: url) { [weak self] data, response, error in
            if let error {
                self?.logOnMain("HTTP error: \(error.localizedDescription)")
                return
            }
            guard let http = response as? HTTPURLResponse else {
                self?.logOnMain("HTTP: no response")
                return
            }
            let body = data.flatMap { String(data: $0, encoding: .utf8) } ?? ""
            self?.logOnMain("HTTP \(http.statusCode): \(body)")
        }
        task.resume()
    }

    // MARK: - WebSocket via Starscream + ProxyWebSocketEngine + local HTTP proxy

    @objc private func onWSTapped() {
        guard #available(iOS 13.0, *) else {
            appendLog("WebSocket requires iOS 13+")
            return
        }
        appendLog("WS: connecting \(wsURL) ...")
        sendWebSocket()
    }

    @available(iOS 13.0, *)
    private func sendWebSocket() {
        guard let url = URL(string: wsURL) else {
            appendLog("WS: invalid URL")
            return
        }
        webSocket?.forceDisconnect()

        var request = URLRequest(url: url)
        request.timeoutInterval = 10
        // The engine carries the SDK proxy injection; Starscream itself is
        // unaware it is being routed through the SDK.
        let engine = ProxyWebSocketEngine()
        let socket = WebSocket(request: request, engine: engine)
        webSocket = socket

        socket.onEvent = { [weak self, weak socket] event in
            DispatchQueue.main.async {
                self?.handleWSEvent(event, engine: engine, socket: socket)
            }
        }
        socket.connect()
    }

    @available(iOS 13.0, *)
    private func handleWSEvent(_ event: WebSocketEvent, engine: ProxyWebSocketEngine, socket: WebSocket?) {
        switch event {
        case let .connected(headers):
            if engine.usedDirectFallback {
                appendLog("WS: SDK proxy unavailable, connected direct")
            }
            appendLog("WS connected: \(headers)")
            appendLog("WS sent: hello")
            socket?.write(string: "hello")
        case let .text(text):
            appendLog("WS recv: \(text)")
        case let .disconnected(reason, code):
            appendLog("WS disconnected: code=\(code) reason=\(reason)")
        case let .error(err):
            appendLog("WS error: \(err?.localizedDescription ?? "unknown")")
        default:
            break
        }
    }

    // MARK: - Logging

    private func appendLog(_ line: String) {
        let current = logView.text ?? ""
        let separator = current.isEmpty ? "" : "\n"
        logView.text = current + separator + line
        let length = logView.text.count
        if length > 0 {
            logView.scrollRangeToVisible(NSRange(location: length - 1, length: 1))
        }
    }

    private func logOnMain(_ line: String) {
        DispatchQueue.main.async { [weak self] in
            self?.appendLog(line)
        }
    }
}

// MARK: - Starscream engine that routes through the SDK's local HTTP proxy

/// Starscream `Engine` that mirrors the stock `NativeEngine`, except it stamps
/// the SDK's local HTTP proxy onto the `URLSessionConfiguration` before creating
/// the session — the one hook Starscream's built-in engines don't expose.
/// Uncomment the SDK lines in `applyProxy(to:)` to route through the SDK;
/// until then it connects directly so the demo runs without the framework.
@available(iOS 13.0, *)
final class ProxyWebSocketEngine: NSObject, Engine {
    private weak var delegate: EngineDelegate?
    private var session: URLSession?
    private var task: URLSessionWebSocketTask?

    /// True when proxy injection was skipped (SDK not initialized / proxy not
    /// ready); the engine still connects directly instead of failing.
    private(set) var usedDirectFallback = false

    func register(delegate: EngineDelegate) {
        self.delegate = delegate
    }

    func start(request: URLRequest) {
        let cfg = URLSessionConfiguration.default

        // *** UNCOMMENT THE LINES BELOW FOR SDK ***
        // Route the underlying URLSession through the SDK's local HTTP proxy.
        // if let proxy = AXService.getLocalHTTPProxy(), proxy.port > 0, !proxy.ip.isEmpty {
        //     let port = Int(proxy.port)
        //     cfg.connectionProxyDictionary = [
        //         "HTTPEnable": 1,
        //         "HTTPProxy": proxy.ip,
        //         "HTTPPort": port,
        //         "HTTPSEnable": 1,
        //         "HTTPSProxy": proxy.ip,
        //         "HTTPSPort": port,
        //     ]
        // } else {
        //     usedDirectFallback = true
        // }

        let newSession = URLSession(configuration: cfg, delegate: self, delegateQueue: OperationQueue())
        let newTask = newSession.webSocketTask(with: request)
        session = newSession
        task = newTask
        doRead()
        newTask.resume()
    }

    func stop(closeCode: UInt16) {
        let code = URLSessionWebSocketTask.CloseCode(rawValue: Int(closeCode)) ?? .normalClosure
        task?.cancel(with: code, reason: nil)
    }

    func forceStop() {
        task?.cancel(with: .abnormalClosure, reason: nil)
    }

    func write(data: Data, opcode: FrameOpCode, completion: (() -> Void)?) {
        switch opcode {
        case .binaryFrame:
            task?.send(.data(data)) { _ in completion?() }
        case .textFrame:
            let text = String(data: data, encoding: .utf8) ?? ""
            task?.send(.string(text)) { _ in completion?() }
        case .ping:
            task?.sendPing { _ in completion?() }
        default:
            completion?()
        }
    }

    func write(string: String, completion: (() -> Void)?) {
        task?.send(.string(string)) { _ in completion?() }
    }

    private func doRead() {
        task?.receive { [weak self] result in
            switch result {
            case let .success(message):
                switch message {
                case let .string(text):
                    self?.delegate?.didReceive(event: .text(text))
                case let .data(data):
                    self?.delegate?.didReceive(event: .binary(data))
                @unknown default:
                    break
                }
                self?.doRead()
            case let .failure(err):
                self?.delegate?.didReceive(event: .error(err))
            }
        }
    }
}

@available(iOS 13.0, *)
extension ProxyWebSocketEngine: URLSessionDataDelegate, URLSessionWebSocketDelegate {
    func urlSession(
        _: URLSession,
        webSocketTask _: URLSessionWebSocketTask,
        didOpenWithProtocol wsProtocol: String?
    ) {
        delegate?.didReceive(event: .connected(["Sec-WebSocket-Protocol": wsProtocol ?? ""]))
    }

    func urlSession(
        _: URLSession,
        webSocketTask _: URLSessionWebSocketTask,
        didCloseWith closeCode: URLSessionWebSocketTask.CloseCode,
        reason: Data?
    ) {
        let reasonString = reason.flatMap { String(data: $0, encoding: .utf8) } ?? ""
        delegate?.didReceive(event: .disconnected(reasonString, UInt16(closeCode.rawValue)))
    }
}
