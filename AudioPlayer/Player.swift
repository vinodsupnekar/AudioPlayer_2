//
//  Player.swift
//  AudioPlayer
//
//  Created by Vinod Supnekar on 26/07/23.
//

import Foundation
import SwiftUI
import AVKit
import Combine

let timeScale = CMTimeScale(1000)
let time = CMTime(seconds: 0.5, preferredTimescale: timeScale)


enum PlayerScrubState {
    case reset
    case scrubStarted
    case scrubEnded(TimeInterval)
}

/// support a slider for scrubbing.
final class Player: NSObject, ObservableObject {
    
    /// Display time that will be bound to the scrub slider.
    @Published var displayTime: TimeInterval = 0
    
    /// The observed time, which may not be needed by the UI.
    @Published var observedTime: TimeInterval = 0
    
    @Published var itemDuration: TimeInterval = 0
    fileprivate var itemDurationKVOPublisher: AnyCancellable!

    /// Publish timeControlStatus
    @Published var timeControlStatus: AVPlayer.TimeControlStatus = .paused
    fileprivate var timeControlStatusKVOPublisher: AnyCancellable!
    
    public var formatter: DateComponentsFormatter =  DateComponentsFormatter()
    
    /// The AVPlayer
    fileprivate var avPlayer: AVPlayer

    /// Time observer.
    fileprivate var periodicTimeObserver: Any?
    
    var strInterval: String {
        let ti = NSInteger(displayTime)
        let seconds = ti % 60
        let minutes = (ti / 60) % 60
        return String(format: "%0.2d:%0.2d",minutes,seconds)
    }
    
    var strElapsedInterval: String {
        let leftTime = itemDuration - displayTime
        let ti = NSInteger(leftTime)
        let seconds = ti % 60
        let minutes = (ti / 60) % 60
        return String(format: "%0.2d:%0.2d",minutes,seconds)
    }

    var scrubState: PlayerScrubState = .reset {
        didSet {
            switch scrubState {
            case .reset:
                return
            case .scrubStarted:
                return
            case .scrubEnded(let seekTime):
                avPlayer.seek(to: CMTime(seconds: seekTime, preferredTimescale: 1000))
            }
        }
    }
    
    func timeFormater() -> DateComponentsFormatter {
//            print("Slider value changed to \(self.$player.displayTime)")
        
        let formatter = DateComponentsFormatter()

        formatter.unitsStyle = .abbreviated
        formatter.zeroFormattingBehavior = .pad
        formatter.allowedUnits = [.hour, .minute]
        return formatter
        }
    
    init(avPlayer: AVPlayer) {
        self.avPlayer = avPlayer
        super.init()

        self.addPeriodicTimeObserver()
        self.addTimeControlStatusObserver()
        self.addItemDurationPublisher()
        self.formatter = self.timeFormater()
        
    }

    deinit {
        removePeriodicTimeObserver()
        timeControlStatusKVOPublisher.cancel()
        itemDurationKVOPublisher.cancel()
    }
    
    
    func play() {
        self.avPlayer.play()
    }

    func pause() {
        self.avPlayer.pause()
    }
    
    fileprivate func addPeriodicTimeObserver() {
        self.periodicTimeObserver = avPlayer.addPeriodicTimeObserver(forInterval: time, queue: .main) { [weak self] (time) in
            guard let self = self else { return }

            // Always update observed time.
            self.observedTime = time.seconds

            switch self.scrubState {
            case .reset:
                self.displayTime = time.seconds
            case .scrubStarted:
                // When scrubbing, the displayTime is bound to the Slider view, so
                // do not update it here.
                break
            case .scrubEnded(let seekTime):
                self.scrubState = .reset
                self.displayTime = seekTime
            }
        }
    }
    
    fileprivate func removePeriodicTimeObserver() {
        guard let periodicTimeObserver = self.periodicTimeObserver else {
            return
        }
        avPlayer.removeTimeObserver(periodicTimeObserver)
        self.periodicTimeObserver = nil
    }

    
    fileprivate func addTimeControlStatusObserver() {
        timeControlStatusKVOPublisher = avPlayer
            .publisher(for: \.timeControlStatus)
            .receive(on: DispatchQueue.main)
            .sink(receiveValue: { [weak self] (newStatus) in
                guard let self = self else { return }
                self.timeControlStatus = newStatus
                }
        )
    }

    fileprivate func addItemDurationPublisher() {
        itemDurationKVOPublisher = avPlayer
            .publisher(for: \.currentItem?.duration)
            .receive(on: DispatchQueue.main)
            .sink(receiveValue: { [weak self] (newStatus) in
                guard let newStatus = newStatus,
                    let self = self else { return }
                self.itemDuration = newStatus.seconds
                }
        )
    }
}
