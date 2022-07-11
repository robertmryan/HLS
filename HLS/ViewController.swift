//
//  ViewController.swift
//  HLS
//
//  Created by Robert Ryan on 7/11/22.
//

import UIKit
import AVKit
import os.log

private let logger = Logger(subsystem: "HLS", category: "ViewController")

struct Video {
    let title: String
    let url: URL
}

class ViewController: UIViewController {

    let urls: [Video] = [
        Video(title: "Advanced stream (TS)",         url: URL(string: "https://devstreaming-cdn.apple.com/videos/streaming/examples/img_bipbop_adv_example_ts/master.m3u8")!),
        Video(title: "Advanced stream (fMP4)",       url: URL(string: "https://devstreaming-cdn.apple.com/videos/streaming/examples/img_bipbop_adv_example_fmp4/master.m3u8")!),
        Video(title: "Advanced stream (HEVC/H.264)", url: URL(string: "https://devstreaming-cdn.apple.com/videos/streaming/examples/bipbop_adv_example_hevc/master.m3u8")!),
        Video(title: "Basic stream (iOS 4.3)",       url: URL(string: "https://devstreaming-cdn.apple.com/videos/streaming/examples/bipbop_4x3/bipbop_4x3_variant.m3u8")!),
        Video(title: "Basic stream (iOS 5)",         url: URL(string: "https://devstreaming-cdn.apple.com/videos/streaming/examples/bipbop_16x9/bipbop_16x9_variant.m3u8")!)
    ]

    @IBOutlet weak var captureLabel: UILabel!

    let player = AVPlayer()

    var errorObserver: NSKeyValueObservation?
    var stateObserver: NSKeyValueObservation?
    var capturingObserver: NSObjectProtocol?

    override func viewDidLoad() {
        super.viewDidLoad()

        errorObserver = player.observe(\.error) { player, change in
            logger.debug("\(String(describing: change.newValue))")
        }

        stateObserver = player.observe(\.status) { player, change in
            logger.debug("\(String(describing: change.newValue))")
        }

        capturingObserver = NotificationCenter.default.addObserver(
            forName: UIScreen.capturedDidChangeNotification,
            object: nil,
            queue: .main
        ) { [weak self] notification in
            logger.debug("\(notification.debugDescription)")
            var isCapturing = false
            for screen in UIScreen.screens {
                if screen.isCaptured { isCapturing = true }
            }

            self?.captureLabel.text = isCapturing ? "Currently capturing video; will pause playback" : "Not capturing video"

            if isCapturing {
                self?.player.pause()
            } else {
                self?.player.play()
            }
        }
    }

    deinit {
        if let capturingObserver = capturingObserver {
            NotificationCenter.default.removeObserver(capturingObserver)
            self.capturingObserver = nil
        }
    }

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let destination = segue.destination as? AVPlayerViewController {
            destination.player = player
            destination.showsPlaybackControls = true
            // destination.shouldAutorotate = true
        }
    }
}

extension ViewController: UIPickerViewDataSource {
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 1
    }

    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        return urls.count + 1
    }
}

extension ViewController: UIPickerViewDelegate {
    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        if row == 0 { return "(Pick a video)" }

        return urls[row - 1].title
    }

    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        if row == 0 {
            player.pause()
            player.replaceCurrentItem(with: nil)
            return
        }

        let playerViewController = children.first as! AVPlayerViewController

        let playerItem = AVPlayerItem(url: urls[row - 1].url)
        // playerItem.preferredForwardBufferDuration = TimeInterval(3.0)

        let player = playerViewController.player
        player!.replaceCurrentItem(with: playerItem)
        player!.play()
    }
}

class PlayerView: UIView {
    var player: AVPlayer? {
        get { playerLayer.player }
        set { playerLayer.player = newValue }
    }

    var playerLayer: AVPlayerLayer { layer as! AVPlayerLayer }

    override static var layerClass: AnyClass {
        return AVPlayerLayer.self
    }
}
