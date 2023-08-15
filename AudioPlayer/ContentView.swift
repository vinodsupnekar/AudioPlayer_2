//
//  ContentView.swift
//  AudioPlayer
//
//  Created by Vinod Supnekar on 24/07/23.
//

import SwiftUI
import AVKit
import Combine

struct ContentView: View {

    @ObservedObject var player: Player

    var body: some View {
        
    ZStack {
            VStack {
                HStack (alignment: .center){
                    Button(action: {
                        switch self.player.timeControlStatus {
                        case .paused:
                            self.player.play()
                        case .waitingToPlayAtSpecifiedRate:
                            self.player.pause()
                        case .playing:
                            self.player.pause()
                        @unknown default:
                            fatalError()
                        }
                    })
                    {
                        Image(systemName: self.player.timeControlStatus == .paused ? "play.circle.fill" : "pause.circle.fill").resizable()
                            .imageScale(.large)
                            .frame(width: 30, height: 30)
                    }
                    if self.player.itemDuration > 0 {
                        
                        VStack{
                            Slider(value: self.$player.displayTime, in: (0...self.player.itemDuration), step: 0.1, onEditingChanged: {
                                (scrubStarted) in
                                if scrubStarted {
                                    self.player.scrubState = .scrubStarted
                                } else {
                                    self.player.scrubState = .scrubEnded(self.player.displayTime)
                                }
                            }
                            ).tint(Color.orange)
                            HStack {
                                
                                Text(self.player.strInterval).font(.system(size: 10)).font(.subheadline)
                                Spacer()
                                Text(self.player.strElapsedInterval).font(.system(size: 10)).font(.subheadline)
                            }
                        }
                        
                    } else {
                        Text("Slider will appear here when the player is ready")
                            .font(.footnote)
                    }
                    
                }
                
            }.padding(10).background(Color.gray.opacity(0.25))
       
    }.cornerRadius(15).padding(10)
       
    }
    
   
}


struct UISliderView: UIViewRepresentable {
    @Binding var value: Double
    
    var minValue = 1.0
    var maxValue = 100.0
    var thumbColor: UIColor = .white
    var minTrackColor: UIColor = .blue
    var maxTrackColor: UIColor = .lightGray
    
    class Coordinator: NSObject {
        var value: Binding<Double>
        
        init(value: Binding<Double>) {
            self.value = value
        }
        
        @objc func valueChanged(_ sender: UISlider) {
            self.value.wrappedValue = Double(sender.value)
        }
    }
    
    func makeCoordinator() -> UISliderView.Coordinator {
        Coordinator(value: $value)
    }
    
    func makeUIView(context: Context) -> UISlider {
        let slider = UISlider(frame: .zero)
        slider.thumbTintColor = thumbColor
        slider.minimumTrackTintColor = minTrackColor
        slider.maximumTrackTintColor = maxTrackColor
        slider.minimumValue = Float(minValue)
        slider.maximumValue = Float(maxValue)
        slider.value = Float(value)
        
        slider.addTarget(
            context.coordinator,
            action: #selector(Coordinator.valueChanged(_:)),
            for: .valueChanged
        )
        
        return slider
    }
    
    func updateUIView(_ uiView: UISlider, context: Context) {
        uiView.value = Float(value)
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView(player: Player(avPlayer: AVPlayer()))
    }
}
