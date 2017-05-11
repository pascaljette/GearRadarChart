// The MIT License (MIT)
//
// Copyright (c) 2015 pascaljette
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in all
// copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
// SOFTWARE.

import UIKit
import GearRadarChart

/// Model containing the data necessary to display the radar graph view controller.
struct GKRadarGraphModel {
    
    //
    // MARK: Randomization
    //
    private static let allowedColors = [UIColor.red,
                                        UIColor.black,
                                        UIColor.blue,
                                        UIColor.purple,
                                        UIColor.cyan,
                                        UIColor.yellow,
                                        UIColor.orange,
                                        UIColor.green,
                                        UIColor.magenta,
                                        UIColor.brown]
    
    private static let randomParameterMaxLength: UInt32 = 8
    
    private static let allowedDecorations: [GKRadarGraphView.Serie.DecorationType] = [
        .square(8.0),
        .circle(6.0),
        .diamond(8.0)
    ]
    
    private static func randomAlphaNumericString(length: Int) -> String {
        let allowedChars = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"
        let allowedCharsCount = UInt32(allowedChars.characters.count)
        var randomString = ""
        
        for _ in 0..<length {
            let randomNum = Int(arc4random_uniform(allowedCharsCount))
            let randomIndex = allowedChars.index(allowedChars.startIndex, offsetBy: randomNum)
            let newCharacter = allowedChars[randomIndex]
            randomString += String(newCharacter)
        }
        
        return randomString
    }

    static var random: GKRadarGraphModel {
        
        var model = GKRadarGraphModel()

        // Randomize parameters.
        let numberOfParameters = arc4random_uniform(10) + 3
        model.parameters = (1...numberOfParameters).map { _ in
            let name = randomAlphaNumericString(length: Int(arc4random_uniform(randomParameterMaxLength) + 1))
            return GKRadarGraphView.Parameter(name: name)
        }
        
        // Randomize series.
        var randomizedAllowedColors = GKRadarGraphModel.allowedColors.shuffled()
        let numberOfSeries = arc4random_uniform(UInt32(allowedColors.count)) + 1
        
        model.series = (1...numberOfSeries).map { _ in
            var serie = GKRadarGraphView.Serie()
            
            let color = randomizedAllowedColors.popLast()!
            
            serie.strokeColor = color
            serie.strokeWidth = 4.0
            serie.fillMode = .solid(color.withAlphaComponent(0.7))
            serie.decoration = allowedDecorations.shuffled().first!
            
            serie.percentageValues = (1...numberOfParameters).map { _ in
                return CGFloat(arc4random_uniform(100)) / 100
            }
            
            return serie
        }
        
        return model
    }
    
    static var defaultModel: GKRadarGraphModel {
        
        var model = GKRadarGraphModel()

        let hpParameter: GKRadarGraphView.Parameter = GKRadarGraphView.Parameter(name: "HP")
        let mpParameter: GKRadarGraphView.Parameter = GKRadarGraphView.Parameter(name: "MP")
        let strengthParameter: GKRadarGraphView.Parameter = GKRadarGraphView.Parameter(name: "STR")
        let defenseParameter: GKRadarGraphView.Parameter = GKRadarGraphView.Parameter(name: "DF")
        let magicParameter: GKRadarGraphView.Parameter = GKRadarGraphView.Parameter(name: "MGC")
        
        model.parameters = [hpParameter, mpParameter, strengthParameter, defenseParameter, magicParameter]
        
        // We only support gradients for a single serie radar graph
        var firstSerie = GKRadarGraphView.Serie()
        firstSerie.strokeColor = UIColor.blue
        firstSerie.strokeWidth = 4.0
        firstSerie.name = "blue"
        let firstFillColor: UIColor = UIColor(red: 0.1, green: 0.1, blue: 0.7, alpha: 0.7)
        
        firstSerie.fillMode = .solid(firstFillColor)
        firstSerie.percentageValues = [0.9, 0.5, 0.6, 0.2, 0.9]
        firstSerie.decoration = .square(8.0)
        
        var secondSerie = GKRadarGraphView.Serie()
        secondSerie.strokeColor = UIColor.green
        secondSerie.strokeWidth = 4.0
        secondSerie.name = "green"
        let secondFillColor: UIColor = UIColor(red: 0.1, green: 0.7, blue: 0.1, alpha: 0.7)
        
        secondSerie.fillMode = .solid(secondFillColor)
        secondSerie.percentageValues = [0.9, 0.1, 0.2, 0.9, 0.3]
        secondSerie.decoration = .circle(6.0)
        
        var thirdSerie = GKRadarGraphView.Serie()
        thirdSerie.strokeColor = UIColor.red
        thirdSerie.strokeWidth = 4.0
        thirdSerie.name = "red"
        let thirdSerieFillColor: UIColor = UIColor(red: 0.7, green: 0.1, blue: 0.1, alpha: 0.7)
        
        thirdSerie.fillMode = .solid(thirdSerieFillColor)
        thirdSerie.percentageValues = [0.5, 0.9, 0.5, 0.5, 0.6]
        thirdSerie.decoration = .diamond(8.0)
        
        model.series = [firstSerie, secondSerie, thirdSerie]

        return model
    }
    
    //
    // MARK: Stored properties
    //

    /// Array of parameters for the plot.
    var parameters: [GKRadarGraphView.Parameter] = []
    
    /// Series representing the data in the plot.
    var series: [GKRadarGraphView.Serie] = []
}
